const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const ErrorBundle = std.zig.ErrorBundle;

const k = @import("../root.zig");
const Ast = k.Ast;
const Chunk = k.Chunk;
const Node = k.Node;
const Value = k.Value;
const Vm = k.Vm;
const OpCode = k.OpCode;

const Compiler = @This();

const InnerError = Allocator.Error || error{CompilerError};
pub const Error = std.fmt.ParseFloatError || Io.Terminal.SetColorError || InnerError;

gpa: Allocator,
vm: *Vm,
tree: Ast,
lambda: *Value,
src_path: []const u8,
line: u32 = 0,
locals: std.ArrayList([]const u8),
globals: std.ArrayList(Ast.TokenIndex),
eb: ErrorBundle.Wip,

pub fn init(c: *Compiler, vm: *Vm, tree: Ast, src_path: []const u8) !void {
    var locals: std.ArrayList([]const u8) = try .initCapacity(vm.gpa, std.math.maxInt(u8));
    errdefer locals.deinit(vm.gpa);
    var globals: std.ArrayList(Ast.TokenIndex) = try .initCapacity(vm.gpa, std.math.maxInt(u8));
    errdefer globals.deinit(vm.gpa);

    var eb: ErrorBundle.Wip = undefined;
    try eb.init(vm.gpa);
    errdefer eb.deinit();

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
        .src_path = src_path,
        .locals = locals,
        .globals = globals,
        .eb = eb,
    };
}

pub fn deinit(c: *Compiler) void {
    c.locals.deinit(c.gpa);
    c.globals.deinit(c.gpa);
    c.eb.deinit();
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
            try compiler.init(c.vm, tree, c.src_path);
            errdefer compiler.lambda.deref(c.gpa);
            defer compiler.deinit();

            if (params.len > 0 and tree.nodeTag(params[0]) != .no_op) {
                for (params) |n| {
                    assert(tree.nodeTag(n) == .identifier);
                    const identifier = tree.nodeMainToken(n);
                    const slice = tree.tokenSlice(identifier);
                    _ = try compiler.addLocal(slice, n);
                }
            }
            for (body) |n| try compiler.findLocals(n);

            const arity: usize = if (params.len == 0) arity: {
                // Implicit params which are never assigned are incorrectly identified as globals, move them to locals.
                var i: usize = 0;
                while (i < compiler.globals.items.len) {
                    const token_index = compiler.globals.items[i];
                    const slice = tree.tokenSlice(token_index);
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
            if (data.trailing_semicolon) try compiler.emitUnaryPrimitive(.identity);

            const lambda = try compiler.endCompiler();
            try c.emitConstant(lambda, node);

            if (compiler.hasErrors()) {
                var eb = try compiler.eb.toOwnedBundle("");
                defer eb.deinit(c.gpa);
                try c.eb.addBundleAsRoots(eb);
            }
        },

        .negation => {
            const number_literal = tree.nodeData(node).node;
            assert(tree.nodeTag(number_literal) == .number_literal);
            const token = tree.nodeMainToken(number_literal);
            const slice = tree.tokenSlice(token);
            const number = try std.fmt.parseFloat(f64, slice);
            const value: *Value = try .float(c.gpa, -number);
            errdefer value.deref(c.gpa);
            try c.emitConstant(value, number_literal);
        },

        .colon, .colon_colon => unreachable,
        .plus => try c.emitOperator(.add),
        .minus => try c.emitOperator(.subtract),
        .asterisk => try c.emitOperator(.multiply),
        .percent => try c.emitOperator(.divide),
        .ampersand => try c.emitOperator(.@"and"),
        .pipe => try c.emitOperator(.@"or"),
        .caret => try c.emitOperator(.fill),
        .equal => try c.emitOperator(.equals),
        .l_angle_bracket => try c.emitOperator(.less_than),
        .r_angle_bracket => try c.emitOperator(.greater_than),
        .dollar => try c.emitOperator(.cast),
        .comma => try c.emitOperator(.join),
        .hash => try c.emitOperator(.take),
        .underscore => try c.emitOperator(.drop),
        .tilde => try c.emitOperator(.match),
        .bang => try c.emitOperator(.dict),
        .question_mark => try c.emitOperator(.find),
        .at => try c.emitOperator(.apply_at),
        .dot => try c.emitOperator(.apply),
        .zero_colon => try c.emitOperator(.file_text),
        .one_colon => try c.emitOperator(.file_binary),
        .two_colon => try c.emitOperator(.dynamic_load),

        .call => {
            const nodes = tree.extraDataSlice(tree.nodeData(node).extra_range, Node.Index);
            assert(nodes.len > 0);
            if (nodes.len == 1) {
                try c.emitUnaryPrimitive(.identity);
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
            try c.emitConstant(value, node);
        },
        .number_list_literal => unreachable,
        .string_literal => {
            const token = tree.nodeMainToken(node);
            const slice = tree.tokenSlice(token);
            const value: *Value = try .copyCharList(c.gpa, slice[1 .. slice.len - 1]);
            errdefer value.deref(c.gpa);
            try c.emitConstant(value, node);
        },
        .symbol_literal => {
            const token = tree.nodeMainToken(node);
            const slice = tree.tokenSlice(token);
            const value: *Value = try .symbol(c.gpa, try c.vm.intern(slice[1..]));
            errdefer value.deref(c.gpa);
            try c.emitConstant(value, node);
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
            try c.emitConstant(value, node);
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
        .plus, .plus_colon => try c.emitUnaryPrimitive(.flip),
        .minus, .minus_colon => try c.emitUnaryPrimitive(.neg),
        .asterisk, .asterisk_colon => try c.emitUnaryPrimitive(.first),
        .percent, .percent_colon => try c.emitUnaryPrimitive(.reciprocal),
        .ampersand, .ampersand_colon => try c.emitUnaryPrimitive(.where),
        .pipe, .pipe_colon => try c.emitUnaryPrimitive(.reverse),
        .caret, .caret_colon => try c.emitUnaryPrimitive(.null),
        .equal, .equal_colon => try c.emitUnaryPrimitive(.group),
        .l_angle_bracket, .l_angle_bracket_colon => try c.emitUnaryPrimitive(.asc),
        .r_angle_bracket, .r_angle_bracket_colon => try c.emitUnaryPrimitive(.desc),
        .dollar, .dollar_colon => try c.emitUnaryPrimitive(.string),
        .comma, .comma_colon => try c.emitUnaryPrimitive(.list),
        .hash, .hash_colon => try c.emitUnaryPrimitive(.count),
        .underscore, .underscore_colon => try c.emitUnaryPrimitive(.lower),
        .tilde, .tilde_colon => try c.emitUnaryPrimitive(.not),
        .bang, .bang_colon => try c.emitUnaryPrimitive(.key),
        .question_mark, .question_mark_colon => try c.emitUnaryPrimitive(.distinct),
        .at, .at_colon => try c.emitUnaryPrimitive(.type),
        .dot, .dot_colon => try c.emitUnaryPrimitive(.value),
        .zero_colon, .zero_colon_colon => try c.emitUnaryPrimitive(.read_text),
        .one_colon, .one_colon_colon => try c.emitUnaryPrimitive(.read_binary),

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
        } else {
            try c.appendErrorNodeNotes(
                identifier,
                "Cannot assign to global variable '{s}'",
                .{name},
                &.{
                    try c.errNoteTok(
                        c.getGlobal(name).?,
                        "Variable promoted to global here",
                        .{},
                    ),
                },
            );
        }
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
        const name = tree.tokenSlice(tree.nodeMainToken(identifier));
        if (c.getLocal(name)) |local| {
            try c.emitOpCode(.set_local);
            try c.emitByte(local);
        } else {
            const constant = try c.identifierConstant(identifier);
            try c.emitOpCode(.set_global);
            try c.emitByte(constant);
        }
    } else {
        @panic("NYI: set_view");
    }
}

pub fn hasErrors(c: *Compiler) bool {
    return c.eb.root_list.items.len > 0;
}

fn identifierConstant(c: *Compiler, node: Node.Index) !u8 {
    assert(c.tree.nodeTag(node) == .identifier);
    const token = c.tree.nodeMainToken(node);
    const slice = c.tree.tokenSlice(token);
    const value: *Value = try .symbol(c.gpa, try c.vm.intern(slice));
    errdefer value.deref(c.gpa);
    const constant = try c.makeConstant(value, node);
    return constant;
}

fn currentChunk(c: *Compiler) *Chunk {
    return &c.lambda.as.lambda.chunk;
}

fn endCompiler(c: *Compiler) !*Value {
    try c.emitReturn();

    if (!c.hasErrors()) {
        const slice: [:0]const u8 = std.mem.span(c.lambda.as.lambda.source);
        try c.currentChunk().disassemble(c.vm.stdout, if (slice.len > 0) slice else c.src_path);
    }

    return c.lambda;
}

fn emitUnaryPrimitive(c: *Compiler, unary_primitive: Value.UnaryPrimitive) !void {
    try c.emitOpCode(.unary_primitive);
    try c.emitByte(@intFromEnum(unary_primitive));
}

fn emitOperator(c: *Compiler, operator: Value.Operator) !void {
    try c.emitOpCode(.operator);
    try c.emitByte(@intFromEnum(operator));
}

fn emitConstant(c: *Compiler, value: *Value, node: Node.Index) !void {
    const constant = try c.makeConstant(value, node);
    try c.emitOpCode(.constant);
    try c.emitByte(constant);
}

fn makeConstant(c: *Compiler, value: *Value, node: Node.Index) !u8 {
    const constant = try c.currentChunk().addConstant(c.gpa, value);
    if (constant > std.math.maxInt(u8)) {
        return c.failNode(node, "Too many constants", .{});
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

fn errNoteTok(c: *Compiler, token_index: Ast.TokenIndex, comptime fmt: []const u8, args: anytype) !ErrorBundle.ErrorMessage {
    const byte_offset = c.tree.tokenStart(token_index);
    const loc = std.zig.findLineColumn(c.tree.source, byte_offset);
    return .{
        .msg = try c.eb.printString(fmt, args),
        .src_loc = try c.eb.addSourceLocation(.{
            .src_path = try c.eb.addString(c.src_path),
            .line = @intCast(loc.line),
            .column = @intCast(loc.column),
            .span_start = byte_offset,
            .span_main = byte_offset,
            .span_end = byte_offset,
            .source_line = try c.eb.addString(loc.source_line),
        }),
    };
}

fn failNode(c: *Compiler, node: Node.Index, comptime fmt: []const u8, args: anytype) InnerError {
    try c.appendErrorNodeNotes(node, fmt, args, &.{});
    return error.CompilerError;
}

fn appendErrorNode(c: *Compiler, node: Node.Index, comptime fmt: []const u8, args: anytype) !void {
    try c.appendErrorNodeNotes(node, fmt, args, &.{});
}

fn appendErrorNodeNotes(
    c: *Compiler,
    node: Node.Index,
    comptime fmt: []const u8,
    args: anytype,
    notes: []const ErrorBundle.ErrorMessage,
) Allocator.Error!void {
    const span = c.tree.nodeToSpan(node);
    const loc = std.zig.findLineColumn(c.tree.source, span.main);
    try c.eb.addRootErrorMessageWithNotes(.{
        .msg = try c.eb.printString(fmt, args),
        .src_loc = try c.eb.addSourceLocation(.{
            .src_path = try c.eb.addString(c.src_path),
            .line = @intCast(loc.line),
            .column = @intCast(loc.column),
            .span_start = span.start,
            .span_main = span.main,
            .span_end = span.end,
            .source_line = try c.eb.addString(loc.source_line),
        }),
        .notes_len = @intCast(notes.len),
    }, notes);
}

fn getLocal(c: *Compiler, name: []const u8) ?u32 {
    for (c.locals.items, 0..) |local, i| {
        if (std.mem.eql(u8, local, name)) return @intCast(i);
    }
    return null;
}

fn getGlobal(c: *Compiler, name: []const u8) ?Ast.TokenIndex {
    for (c.globals.items) |global| {
        if (std.mem.eql(u8, c.tree.tokenSlice(global), name)) return global;
    }
    return null;
}

fn addLocal(c: *Compiler, name: []const u8, node: Node.Index) !u32 {
    assert(name.len > 0);
    assert(c.getGlobal(name) == null);
    for (c.locals.items, 0..) |local, i| {
        if (std.mem.eql(u8, local, name)) return @intCast(i);
    }

    if (c.locals.items.len == std.math.maxInt(u8)) {
        try c.appendErrorNode(node, "Too many local variables", .{});
    }

    c.locals.appendAssumeCapacity(name);
    return @intCast(c.locals.items.len - 1);
}

fn addGlobal(c: *Compiler, token_index: Ast.TokenIndex, node: Node.Index) !u32 {
    const name = c.tree.tokenSlice(token_index);
    assert(name.len > 0);
    assert(c.getLocal(name) == null);
    if (c.getGlobal(name)) |global| return global;

    if (c.globals.items.len == std.math.maxInt(u8)) {
        try c.appendErrorNode(node, "Too many global variables", .{});
    }

    c.globals.appendAssumeCapacity(token_index);
    return token_index;
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
                        _ = try c.addLocal(name, identifier);
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
                        _ = try c.addLocal(name, identifier);
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
            const identifier = tree.nodeMainToken(node);
            const name = tree.tokenSlice(identifier);
            if (c.getLocal(name) == null) {
                _ = try c.addGlobal(identifier, node);
            }
        },

        .system => {},
    }
}

fn testCompiler(source: [:0]const u8, expected: []const u8) !void {
    const gpa = std.testing.allocator;

    var stdout_writer: std.Io.Writer.Allocating = .init(gpa);
    defer stdout_writer.deinit();
    const stdout = &stdout_writer.writer;

    var vm: Vm = undefined;
    try vm.init(std.testing.io, gpa, stdout, .off);
    defer vm.deinit();

    var tree: Ast = try .parse(gpa, source);
    defer tree.deinit(gpa);

    var compiler: Compiler = undefined;
    try compiler.init(&vm, tree, "<test>");
    defer compiler.deinit();

    const lambda: *Value = compiler.compile() catch |err| switch (err) {
        error.CompilerError => blk: {
            try std.testing.expect(compiler.hasErrors());
            break :blk try .long(gpa, 0);
        },
        else => return err,
    };
    defer lambda.deref(gpa);

    if (compiler.hasErrors()) {
        var eb = try compiler.eb.toOwnedBundle("");
        defer eb.deinit(gpa);
        try eb.renderToWriter(.{}, stdout);
    }

    try std.testing.expectEqualStrings(
        std.mem.trim(u8, expected, &std.ascii.whitespace),
        std.mem.trim(u8, stdout_writer.written(), &std.ascii.whitespace),
    );
}

test {
    try testCompiler("{x;x+1;x}",
        \\== {x;x+1;x} ==
        \\0000    0 get_local           0
        \\0002    | pop
        \\0003    | constant            0 '1f'
        \\0005    | get_local           0
        \\0007    | operator            1 '+'
        \\0009    | apply               2
        \\0011    | pop
        \\0012    | get_local           0
        \\0014    | return
        \\== <test> ==
        \\0000    0 constant            0 '{x;x+1;x}'
        \\0002    | print
        \\0003    | return
    );
    try testCompiler("{[]x;x+1;x}",
        \\== {[]x;x+1;x} ==
        \\0000    0 get_global          0 '`x'
        \\0002    | pop
        \\0003    | constant            1 '1f'
        \\0005    | get_global          0 '`x'
        \\0007    | operator            1 '+'
        \\0009    | apply               2
        \\0011    | pop
        \\0012    | get_global          0 '`x'
        \\0014    | return
        \\== <test> ==
        \\0000    0 constant            0 '{[]x;x+1;x}'
        \\0002    | print
        \\0003    | return
    );
    try testCompiler("{x;x:1}",
        \\== {x;x:1} ==
        \\0000    0 get_local           0
        \\0002    | pop
        \\0003    | constant            0 '1f'
        \\0005    | set_local           0
        \\0007    | return
        \\== <test> ==
        \\0000    0 constant            0 '{x;x:1}'
        \\0002    | print
        \\0003    | return
    );
    try testCompiler("{x;x::1}",
        \\== {x;x::1} ==
        \\0000    0 get_local           0
        \\0002    | pop
        \\0003    | constant            0 '1f'
        \\0005    | set_local           0
        \\0007    | return
        \\== <test> ==
        \\0000    0 constant            0 '{x;x::1}'
        \\0002    | print
        \\0003    | return
    );
    try testCompiler("{[]x;x:1}",
        \\<test>:1:6: error: Cannot assign to global variable 'x'
        \\{[]x;x:1}
        \\     ^
        \\<test>:1:4: note: Variable promoted to global here
        \\{[]x;x:1}
        \\   ^
    );
    try testCompiler("{[]x;x::1}",
        \\== {[]x;x::1} ==
        \\0000    0 get_global          0 '`x'
        \\0002    | pop
        \\0003    | constant            1 '1f'
        \\0005    | set_global          0 '`x'
        \\0007    | return
        \\== <test> ==
        \\0000    0 constant            0 '{[]x;x::1}'
        \\0002    | print
        \\0003    | return
    );
}
