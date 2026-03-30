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
};

gpa: Allocator,
vm: *Vm,
tree: Ast,
lambda: *Value,
line: u32 = 0,
in_lambda: bool = false,
locals: std.ArrayList([]const u8),

pub fn init(c: *Compiler, vm: *Vm, tree: Ast) !void {
    var locals: std.ArrayList([]const u8) = try .initCapacity(vm.gpa, std.math.maxInt(u8));
    errdefer locals.deinit(vm.gpa);
    // Reserve stack slot zero
    locals.appendAssumeCapacity(&.{});

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
    };
}

pub fn deinit(c: *Compiler) void {
    c.locals.deinit(c.gpa);
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
            const nodes = tree.extraDataSlice(.{
                .start = data.body_start,
                .end = data.body_end,
            }, Node.Index);

            var compiler: Compiler = undefined;
            try compiler.init(c.vm, tree);
            defer compiler.deinit();

            compiler.in_lambda = true;
            compiler.lambda.as.lambda.source = try c.vm.intern(tree.nodeSlice(node));
            compiler.lambda.as.lambda.arity = @intCast(@max(1, params.len));

            for (nodes) |n| try compiler.compileNode(n);
            const value: ?*Value = if (data.trailing_semicolon) blk: {
                const value: *Value = try .unaryPrimitive(c.gpa, .identity);
                errdefer value.deref(c.gpa);
                try compiler.emitConstant(value);
                break :blk value;
            } else null;
            errdefer if (value) |v| v.deref(c.gpa);

            const lambda = try compiler.endCompiler();
            errdefer lambda.deref(c.gpa);

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

        .colon => unreachable,
        .colon_colon => unreachable,
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
                .colon => {
                    assert(tree.nodeTag(lhs) == .identifier);
                    if (maybe_rhs.unwrap()) |rhs| {
                        try c.compileNode(rhs);
                    } else unreachable;
                    const identifier = try c.identifierConstant(lhs);
                    try c.emitOpCode(.set_global);
                    try c.emitByte(identifier);
                    return;
                },
                .colon_colon => unreachable,
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
            if (c.in_lambda) {
                const name = tree.tokenSlice(tree.nodeMainToken(node));
                for (c.locals.items) |local| {
                    if (std.mem.eql(u8, local, name)) unreachable;
                }

                if (c.locals.items.len == std.math.maxInt(u8)) return error.TooManyLocalVariables;

                c.locals.appendAssumeCapacity(name);
            } else {
                const constant = try c.identifierConstant(node);
                try c.emitOpCode(.get_global);
                try c.emitByte(constant);
            }
        },

        inline else => |t| std.debug.panic("{t}", .{t}),
    }
}

fn compileUnaryNode(c: *Compiler, node: Node.Index) !void {
    const tree = c.tree;

    switch (tree.nodeTag(node)) {
        .grouped_expression => try c.compileUnaryNode(tree.nodeData(node).node_and_token[0]),

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

        inline else => |t| std.debug.panic("NYI: {t}", .{t}),
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
