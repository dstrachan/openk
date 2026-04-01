const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

const k = @import("../root.zig");
const Ast = k.Ast;
const Chunk = k.Chunk;
const Node = k.Node;
const Value = k.Value;
const Vm = k.Vm;
const OpCode = k.OpCode;

const Compiler = @This();

pub const Error = Allocator.Error || std.fmt.ParseFloatError || Io.Writer.Error || error{
    TooManyConstants,
    TooManyLocalVariables,
    TooManyGlobalVariables,
    LocalAssignToGlobal,
};

gpa: Allocator,
vm: *Vm,
tree: Ast,
lambda: *Value,
line: u32 = 0,
locals: std.ArrayList([]const u8),
globals: std.ArrayList([]const u8),

pub fn init(c: *Compiler, vm: *Vm, tree: Ast) !void {
    var locals: std.ArrayList([]const u8) = try .initCapacity(vm.gpa, std.math.maxInt(u8));
    errdefer locals.deinit(vm.gpa);
    var globals: std.ArrayList([]const u8) = try .initCapacity(vm.gpa, std.math.maxInt(u8));
    errdefer globals.deinit(vm.gpa);

    const lambda: *Value = try .lambda(vm.gpa, .{
        .source = try vm.intern(""),
        .arity = 0,
        .chunk = .empty,
    });
    errdefer comptime unreachable;

    c.* = .{
        .gpa = vm.gpa,
        .vm = vm,
        .tree = tree,
        .lambda = lambda,
        .locals = locals,
        .globals = globals,
    };
}

pub fn deinit(c: *Compiler) void {
    c.locals.deinit(c.gpa);
    c.globals.deinit(c.gpa);
}

pub fn compile(c: *Compiler) !*Value {
    const nodes = c.tree.extraDataSlice(c.tree.nodeData(.root).extra_range, Node.Index);
    for (nodes) |n| try c.compileNode(n);

    return c.endCompiler();
}

fn compileNode(c: *Compiler, node: Node.Index) Error!void {
    const tree = c.tree;

    switch (tree.nodeTag(node)) {
        .root => unreachable,

        .pop => {
            try c.compileNode(tree.nodeData(node).node);
            try c.emitOpCode(.pop);
        },
        .print => {
            try c.compileNode(tree.nodeData(node).node);
            try c.emitOpCode(.print);
        },

        .grouped_expression => try c.compileNode(tree.nodeData(node).node_and_token[0]),

        .lambda => {
            const data = tree.extraData(tree.nodeData(node).extra_and_token[0], Node.Lambda);
            const params = tree.extraDataSlice(.{
                .start = data.params_start,
                .end = data.body_start,
            }, Node.Index);
            const body = tree.extraDataSlice(.{
                .start = data.body_start,
                .end = data.body_end,
            }, Node.Index);

            var compiler: Compiler = undefined;
            try compiler.init(c.vm, tree);
            errdefer compiler.lambda.deref(c.gpa);
            defer compiler.deinit();

            for (params) |n| {
                assert(tree.nodeTag(n) == .identifier);
                const identifier = tree.nodeMainToken(n);
                const slice = tree.tokenSlice(identifier);
                _ = try compiler.addLocal(slice);
            }
            for (body) |n| try compiler.findLocals(n);

            const arity: usize = if (params.len == 0) arity: {
                // Implicit params which are never assigned are incorrectly identified as globals, move them to locals.
                var i: usize = 0;
                while (i < compiler.globals.items.len) {
                    const slice = compiler.globals.items[i];
                    if (slice.len == 1) {
                        switch (slice[0]) {
                            'x', 'y', 'z' => {
                                compiler.locals.appendAssumeCapacity(slice);
                                _ = compiler.globals.swapRemove(i);
                                continue;
                            },
                            else => {},
                        }
                    }
                    i += 1;
                }

                var has_y = false;
                var has_z = false;
                for (compiler.locals.items) |name| {
                    if (!has_z and std.mem.eql(u8, name, "z")) {
                        has_z = true;
                        break;
                    }
                    if (!has_y and std.mem.eql(u8, name, "y")) has_y = true;
                }
                break :arity if (has_z) 3 else if (has_y) 2 else 1;
            } else params.len;

            compiler.lambda.as.lambda.source = try c.vm.intern(tree.nodeSlice(node));
            compiler.lambda.as.lambda.arity = arity;

            for (body) |n| try compiler.compileNode(n);
            const value: ?*Value = if (data.trailing_semicolon) blk: {
                const value: *Value = try .unaryPrimitive(c.gpa, .identity);
                errdefer value.deref(c.gpa);
                try compiler.emitConstant(value);
                break :blk value;
            } else null;
            errdefer if (value) |v| v.deref(c.gpa);

            const lambda = try compiler.endCompiler();
            try c.emitConstant(lambda);
        },

        .negation => {
            const number_literal = tree.nodeData(node).node;
            assert(tree.nodeTag(number_literal) == .number_literal);
            const token = tree.nodeMainToken(number_literal);
            const slice = tree.tokenSlice(token);
            const number = try std.fmt.parseFloat(f64, slice);
            const value: *Value = try .float(c.gpa, -number);
            errdefer value.deref(c.gpa);
            try c.emitConstant(value);
        },

        .colon, .colon_colon => unreachable,
        .plus => {
            const v: *Value = try .operator(c.gpa, .add);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .minus => {
            const v: *Value = try .operator(c.gpa, .subtract);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .asterisk => {
            const v: *Value = try .operator(c.gpa, .multiply);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .percent => {
            const v: *Value = try .operator(c.gpa, .divide);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .ampersand => {
            const v: *Value = try .operator(c.gpa, .@"and");
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .pipe => {
            const v: *Value = try .operator(c.gpa, .@"or");
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .caret => {
            const v: *Value = try .operator(c.gpa, .fill);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .equal => {
            const v: *Value = try .operator(c.gpa, .equals);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .l_angle_bracket => {
            const v: *Value = try .operator(c.gpa, .less_than);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .r_angle_bracket => {
            const v: *Value = try .operator(c.gpa, .greater_than);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .dollar => {
            const v: *Value = try .operator(c.gpa, .cast);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .comma => {
            const v: *Value = try .operator(c.gpa, .join);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .hash => {
            const v: *Value = try .operator(c.gpa, .take);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .underscore => {
            const v: *Value = try .operator(c.gpa, .drop);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .tilde => {
            const v: *Value = try .operator(c.gpa, .match);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .bang => {
            const v: *Value = try .operator(c.gpa, .dict);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .question_mark => {
            const v: *Value = try .operator(c.gpa, .find);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .at => {
            const v: *Value = try .operator(c.gpa, .apply_at);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .dot => {
            const v: *Value = try .operator(c.gpa, .apply);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .zero_colon => {
            const v: *Value = try .operator(c.gpa, .file_text);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .one_colon => {
            const v: *Value = try .operator(c.gpa, .file_binary);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .two_colon => {
            const v: *Value = try .operator(c.gpa, .dynamic_load);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },

        .call => {
            const nodes = tree.extraDataSlice(tree.nodeData(node).extra_range, Node.Index);
            assert(nodes.len > 0);
            if (nodes.len == 1) {
                const identity: *Value = try .unaryPrimitive(c.gpa, .identity);
                errdefer identity.deref(c.gpa);
                try c.emitConstant(identity);
            } else if (nodes.len == 3) {
                switch (tree.nodeTag(tree.unwrap(nodes[0]))) {
                    .colon => return c.compileColon(nodes[1], nodes[2]),
                    .colon_colon => return c.compileColonColon(nodes[1], nodes[2]),
                    else => {},
                }
            }
            var it = std.mem.reverseIterator(nodes);
            while (it.next()) |n| try c.compileNode(n);
            try c.emitOpCode(.apply);
            try c.emitByte(@max(1, nodes.len - 1));
        },

        .apply_unary => {
            const lhs, const rhs = tree.nodeData(node).node_and_node;
            try c.compileNode(rhs);
            try c.compileUnaryNode(lhs);
            try c.emitOpCode(.apply);
            try c.emitByte(1);
        },

        .apply_binary => {
            const lhs, const maybe_rhs = tree.nodeData(node).node_and_opt_node;
            const op: Node.Index = @enumFromInt(tree.nodeMainToken(node));

            switch (tree.nodeTag(op)) {
                .colon => return c.compileColon(lhs, maybe_rhs.unwrap().?),
                .colon_colon => return c.compileColonColon(lhs, maybe_rhs.unwrap().?),
                else => {},
            }

            if (maybe_rhs.unwrap()) |rhs| {
                try c.compileNode(rhs);
            } else unreachable;
            try c.compileNode(lhs);
            try c.compileNode(op);
            try c.emitOpCode(.apply);
            try c.emitByte(2);
        },

        .number_literal => {
            const token = tree.nodeMainToken(node);
            const slice = tree.tokenSlice(token);
            const number = try std.fmt.parseFloat(f64, slice);
            const value: *Value = try .float(c.gpa, number);
            errdefer value.deref(c.gpa);
            try c.emitConstant(value);
        },
        .number_list_literal => unreachable,
        .string_literal => {
            const token = tree.nodeMainToken(node);
            const slice = tree.tokenSlice(token);
            const value: *Value = try .copyCharList(c.gpa, slice[1 .. slice.len - 1]);
            errdefer value.deref(c.gpa);
            try c.emitConstant(value);
        },
        .symbol_literal => {
            const token = tree.nodeMainToken(node);
            const slice = tree.tokenSlice(token);
            const value: *Value = try .symbol(c.gpa, try c.vm.intern(slice[1..]));
            errdefer value.deref(c.gpa);
            try c.emitConstant(value);
        },
        .symbol_list_literal => {
            const first_token = tree.nodeMainToken(node);
            const last_token = tree.nodeData(node).token;
            const len = last_token - first_token + 1;
            const symbols = try c.gpa.alloc([*:0]const u8, len);
            errdefer c.gpa.free(symbols);
            for (symbols, first_token..) |*symbol, token| {
                const slice = tree.tokenSlice(@intCast(token));
                symbol.* = try c.vm.intern(slice[1..]);
            }
            const value: *Value = try .symbolList(c.gpa, symbols);
            errdefer value.deref(c.gpa);
            try c.emitConstant(value);
        },
        .identifier => {
            if (c.lambda.as.lambda.arity > 0) {
                const name = tree.tokenSlice(tree.nodeMainToken(node));
                if (c.getLocal(name)) |local| {
                    try c.emitOpCode(.get_local);
                    try c.emitByte(local);
                    return;
                }
            }

            const constant = try c.identifierConstant(node);
            try c.emitOpCode(.get_global);
            try c.emitByte(constant);
        },

        inline else => |t| std.debug.panic("{t}", .{t}),
    }
}

fn compileUnaryNode(c: *Compiler, node: Node.Index) !void {
    const tree = c.tree;

    switch (tree.nodeTag(node)) {
        .grouped_expression => try c.compileUnaryNode(tree.nodeData(node).node_and_token[0]),

        .colon, .colon_colon => unreachable,
        .plus, .plus_colon => {
            const v: *Value = try .unaryPrimitive(c.gpa, .flip);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .minus, .minus_colon => {
            const v: *Value = try .unaryPrimitive(c.gpa, .neg);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .asterisk, .asterisk_colon => {
            const v: *Value = try .unaryPrimitive(c.gpa, .first);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .percent, .percent_colon => {
            const v: *Value = try .unaryPrimitive(c.gpa, .reciprocal);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .ampersand, .ampersand_colon => {
            const v: *Value = try .unaryPrimitive(c.gpa, .where);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .pipe, .pipe_colon => {
            const v: *Value = try .unaryPrimitive(c.gpa, .reverse);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .caret, .caret_colon => {
            const v: *Value = try .unaryPrimitive(c.gpa, .null);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .equal, .equal_colon => {
            const v: *Value = try .unaryPrimitive(c.gpa, .group);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .l_angle_bracket, .l_angle_bracket_colon => {
            const v: *Value = try .unaryPrimitive(c.gpa, .asc);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .r_angle_bracket, .r_angle_bracket_colon => {
            const v: *Value = try .unaryPrimitive(c.gpa, .desc);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .dollar, .dollar_colon => {
            const v: *Value = try .unaryPrimitive(c.gpa, .string);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .comma, .comma_colon => {
            const v: *Value = try .unaryPrimitive(c.gpa, .list);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .hash, .hash_colon => {
            const v: *Value = try .unaryPrimitive(c.gpa, .count);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .underscore, .underscore_colon => {
            const v: *Value = try .unaryPrimitive(c.gpa, .lower);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .tilde, .tilde_colon => {
            const v: *Value = try .unaryPrimitive(c.gpa, .not);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .bang, .bang_colon => {
            const v: *Value = try .unaryPrimitive(c.gpa, .key);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .question_mark, .question_mark_colon => {
            const v: *Value = try .unaryPrimitive(c.gpa, .distinct);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .at, .at_colon => {
            const v: *Value = try .unaryPrimitive(c.gpa, .type);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .dot, .dot_colon => {
            const v: *Value = try .unaryPrimitive(c.gpa, .value);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .zero_colon, .zero_colon_colon => {
            const v: *Value = try .unaryPrimitive(c.gpa, .read_text);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },
        .one_colon, .one_colon_colon => {
            const v: *Value = try .unaryPrimitive(c.gpa, .read_binary);
            errdefer v.deref(c.gpa);
            try c.emitConstant(v);
        },

        else => try c.compileNode(node),
    }
}

fn compileColon(c: *Compiler, lhs: Node.Index, rhs: Node.Index) !void {
    const tree = c.tree;

    const identifier = tree.unwrap(lhs);
    assert(tree.nodeTag(identifier) == .identifier);

    try c.compileNode(rhs);

    if (c.lambda.as.lambda.arity > 0) {
        const name = tree.tokenSlice(tree.nodeMainToken(identifier));
        if (c.getLocal(name)) |local| {
            try c.emitOpCode(.set_local);
            try c.emitByte(local);
        } else return error.LocalAssignToGlobal;
    } else {
        const constant = try c.identifierConstant(identifier);
        try c.emitOpCode(.set_global);
        try c.emitByte(constant);
    }
}

fn compileColonColon(c: *Compiler, lhs: Node.Index, rhs: Node.Index) !void {
    const tree = c.tree;

    const identifier = tree.unwrap(lhs);
    assert(tree.nodeTag(identifier) == .identifier);

    try c.compileNode(rhs);

    if (c.lambda.as.lambda.arity > 0) {
        const constant = try c.identifierConstant(identifier);
        try c.emitOpCode(.set_global);
        try c.emitByte(constant);
    } else {
        @panic("NYI: set_view");
    }
}

fn identifierConstant(c: *Compiler, node: Node.Index) !u8 {
    assert(c.tree.nodeTag(node) == .identifier);
    const token = c.tree.nodeMainToken(node);
    const slice = c.tree.tokenSlice(token);
    const value: *Value = try .symbol(c.gpa, try c.vm.intern(slice));
    errdefer value.deref(c.gpa);
    const constant = try c.makeConstant(value);
    return constant;
}

fn currentChunk(c: *Compiler) *Chunk {
    return &c.lambda.as.lambda.chunk;
}

fn endCompiler(c: *Compiler) !*Value {
    try c.emitReturn();
    const slice: [:0]const u8 = std.mem.span(c.lambda.as.lambda.source);
    try c.currentChunk().disassemble(c.vm.stderr, if (slice.len > 0) slice else "<script>");
    return c.lambda;
}

fn emitConstant(c: *Compiler, value: *Value) !void {
    const constant = try c.makeConstant(value);
    try c.emitOpCode(.constant);
    try c.emitByte(constant);
}

fn makeConstant(c: *Compiler, value: *Value) !u8 {
    const constant = try c.currentChunk().addConstant(c.gpa, value);
    if (constant > std.math.maxInt(u8)) {
        return error.TooManyConstants;
    }
    return @intCast(constant);
}

fn emitReturn(c: *Compiler) !void {
    try c.emitOpCode(.@"return");
}

fn emitOpCode(c: *Compiler, code: OpCode) !void {
    try c.emitByte(code);
}

fn emitByte(c: *Compiler, byte: anytype) !void {
    try c.currentChunk().write(c.gpa, byte, c.line);
}

fn getLocal(c: *Compiler, name: []const u8) ?u32 {
    for (c.locals.items, 0..) |local, i| {
        if (std.mem.eql(u8, local, name)) return @intCast(i);
    }
    return null;
}

fn getGlobal(c: *Compiler, name: []const u8) ?u32 {
    for (c.globals.items, 0..) |global, i| {
        if (std.mem.eql(u8, global, name)) return @intCast(i);
    }
    return null;
}

fn addLocal(c: *Compiler, name: []const u8) !u32 {
    assert(name.len > 0);
    assert(c.getGlobal(name) == null);
    for (c.locals.items, 0..) |local, i| {
        if (std.mem.eql(u8, local, name)) return @intCast(i);
    }

    if (c.locals.items.len == std.math.maxInt(u8)) return error.TooManyLocalVariables;

    c.locals.appendAssumeCapacity(name);
    return @intCast(c.locals.items.len - 1);
}

fn addGlobal(c: *Compiler, name: []const u8) !u32 {
    assert(name.len > 0);
    assert(c.getLocal(name) == null);
    for (c.globals.items, 0..) |global, i| {
        if (std.mem.eql(u8, global, name)) return @intCast(i);
    }

    if (c.globals.items.len == std.math.maxInt(u8)) return error.TooManyGlobalVariables;

    c.globals.appendAssumeCapacity(name);
    return @intCast(c.globals.items.len - 1);
}

fn findLocals(c: *Compiler, node: Node.Index) !void {
    const tree = c.tree;
    switch (tree.nodeTag(node)) {
        .root => unreachable,
        .no_op => {},

        .pop,
        .print,
        => try c.findLocals(tree.nodeData(node).node),

        .grouped_expression => try c.findLocals(tree.nodeData(node).node_and_token[0]),
        .empty_list => {},
        .list => {
            for (tree.extraDataSlice(tree.nodeData(node).extra_range, Node.Index)) |n| try c.findLocals(n);
        },
        .table_literal => |t| std.debug.panic("NYI: findLocals({t})", .{t}),

        .lambda => {},

        .expr_block => {
            for (tree.extraDataSlice(tree.nodeData(node).extra_range, Node.Index)) |n| try c.findLocals(n);
        },

        .negation => try c.findLocals(tree.nodeData(node).node),

        .colon,
        .colon_colon,
        .plus,
        .plus_colon,
        .minus,
        .minus_colon,
        .asterisk,
        .asterisk_colon,
        .percent,
        .percent_colon,
        .ampersand,
        .ampersand_colon,
        .pipe,
        .pipe_colon,
        .caret,
        .caret_colon,
        .equal,
        .equal_colon,
        .l_angle_bracket,
        .l_angle_bracket_colon,
        .r_angle_bracket,
        .r_angle_bracket_colon,
        .dollar,
        .dollar_colon,
        .comma,
        .comma_colon,
        .hash,
        .hash_colon,
        .underscore,
        .underscore_colon,
        .tilde,
        .tilde_colon,
        .bang,
        .bang_colon,
        .question_mark,
        .question_mark_colon,
        .at,
        .at_colon,
        .dot,
        .dot_colon,
        .zero_colon,
        .zero_colon_colon,
        .one_colon,
        .one_colon_colon,
        .two_colon,
        => {},

        .apostrophe,
        .apostrophe_colon,
        .slash,
        .slash_colon,
        .backslash,
        .backslash_colon,
        => if (tree.nodeData(node).opt_node.unwrap()) |n| try c.findLocals(n),

        .call => {
            const nodes = tree.extraDataSlice(tree.nodeData(node).extra_range, Node.Index);
            assert(nodes.len > 0);
            if (nodes.len == 3) {
                try c.findLocals(nodes[2]);
                if (tree.nodeTag(tree.unwrap(nodes[0])) == .colon) {
                    const identifier = tree.unwrap(nodes[1]);
                    assert(tree.nodeTag(identifier) == .identifier);
                    const name = tree.tokenSlice(tree.nodeMainToken(identifier));
                    if (c.getGlobal(name) == null) {
                        _ = try c.addLocal(name);
                    }
                }
                try c.findLocals(nodes[1]);
            } else {
                var it = std.mem.reverseIterator(nodes);
                while (it.next()) |n| try c.findLocals(n);
            }
        },
        .apply_unary => {
            const lhs, const rhs = tree.nodeData(node).node_and_node;
            try c.findLocals(rhs);
            try c.findLocals(lhs);
        },
        .apply_binary => {
            const lhs, const maybe_rhs = tree.nodeData(node).node_and_opt_node;
            const op: Node.Index = @enumFromInt(tree.nodeMainToken(node));
            if (maybe_rhs.unwrap()) |rhs| {
                try c.findLocals(rhs);
                if (tree.nodeTag(op) == .colon) {
                    const identifier = tree.unwrap(lhs);
                    assert(tree.nodeTag(identifier) == .identifier);
                    const name = tree.tokenSlice(tree.nodeMainToken(identifier));
                    if (c.getGlobal(name) == null) {
                        _ = try c.addLocal(name);
                    }
                }
            }
            try c.findLocals(lhs);
        },

        .number_literal,
        .number_list_literal,
        .string_literal,
        .symbol_literal,
        .symbol_list_literal,
        => {},
        .identifier => {
            const name = tree.tokenSlice(tree.nodeMainToken(node));
            if (c.getLocal(name) == null) {
                _ = try c.addGlobal(name);
            }
        },

        .system => {},
    }
}
