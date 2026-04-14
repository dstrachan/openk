const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const ErrorBundle = std.zig.ErrorBundle;
const ErrorMessage = ErrorBundle.ErrorMessage;

const k = @import("../root.zig");
const Ast = k.Ast;
const Chunk = k.Chunk;
const Node = k.Node;
const Value = k.Value;
const Vm = k.Vm;
const OpCode = k.OpCode;
const NullTerminatedString = k.NullTerminatedString;
const parseNumber = k.parseNumber;

const Compiler = @This();

const InnerError = Allocator.Error || error{CompilerError};
pub const Error = std.fmt.ParseFloatError || Io.Terminal.SetColorError || ErrorBundle.RenderToStderrError || InnerError;

gpa: Allocator,
vm: *Vm,
tree: Ast,
lambda: *Value,
src_path: []const u8,
line: u32 = 0,
eb: *ErrorBundle.Wip,

pub fn init(c: *Compiler, vm: *Vm, tree: Ast, eb: *ErrorBundle.Wip, src_path: []const u8) !void {
    const lambda: *Value = try .lambda(vm.gpa, .{ .source = try vm.intern(src_path) });
    errdefer comptime unreachable;

    c.* = .{
        .gpa = vm.gpa,
        .vm = vm,
        .tree = tree,
        .lambda = lambda,
        .src_path = src_path,
        .eb = eb,
    };
}

pub fn compile(c: *Compiler) !*Value {
    const nodes = c.tree.extraDataSlice(c.tree.nodeData(.root).extra_range, Node.Index);
    for (nodes) |n| try c.compileNode(n);

    return c.endCompiler();
}

fn compileNode(c: *Compiler, node: Node.Index) Error!void {
    const tree = c.tree;

    switch (tree.nodeTag(tree.unwrap(node))) {
        .root => unreachable,
        .no_op => try c.emitOpCode(.empty),

        .pop => {
            try c.compileNode(tree.nodeData(node).node);
            try c.emitOpCode(.pop);
        },
        .print => {
            try c.compileNode(tree.nodeData(node).node);
            try c.emitOpCode(.print);
        },

        .grouped_expression => unreachable,

        .empty_list => try c.emitEmptyList(),
        .list => {
            const nodes = tree.extraDataSlice(tree.nodeData(node).extra_range, Node.Index);
            assert(nodes.len > 1);

            var it = std.mem.reverseIterator(nodes);
            while (it.next()) |n| try c.compileNode(n);
            const value: *Value = try .unaryPrimitive(c.gpa, .enlist);
            errdefer value.deref(c.gpa);
            try c.emitConstant(value, node);
            try c.emitOpCode(.call);
            try c.emitByte(nodes.len);
        },

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
            try compiler.init(c.vm, tree, c.eb, c.src_path);
            errdefer compiler.lambda.deref(c.gpa);

            const chunk = &compiler.lambda.as.lambda.chunk;
            try chunk.params.ensureTotalCapacity(c.gpa, 8);

            if (params.len > 0 and tree.nodeTag(params[0]) != .no_op) {
                for (params) |identifier| {
                    assert(tree.nodeTag(identifier) == .identifier);
                    const name = try c.vm.intern(tree.tokenSlice(tree.nodeMainToken(identifier)));
                    chunk.params.appendAssumeCapacity(name);
                }
            }
            for (body) |n| try compiler.findLocals(n, params.len == 0);

            const arity: usize = if (params.len == 0) arity: {
                const locals = compiler.lambda.as.lambda.chunk.locals.items;
                if (locals.len > 2 and locals[2] == .z) break :arity 3;
                if (locals.len > 1 and locals[1] == .y) break :arity 2;
                break :arity 1;
            } else params.len;

            compiler.lambda.as.lambda.source = try c.vm.intern(tree.nodeSlice(node));
            compiler.lambda.as.lambda.arity = arity;
            compiler.lambda.as.lambda.locals = compiler.lambda.as.lambda.chunk.locals.items.len -| arity;

            for (body) |n| try compiler.compileNode(n);
            if (body.len == 0 or data.trailing_semicolon) try compiler.emitNil();

            const lambda = try compiler.endCompiler();
            try c.emitConstant(lambda, node);
        },

        .negation => {
            const number_literal = tree.nodeData(node).node;
            assert(tree.nodeTag(number_literal) == .number_literal);
            const token = tree.nodeMainToken(number_literal);
            const slice = tree.tokenSlice(token);
            const value = parseNumber(c.gpa, slice, .neg) catch |err| switch (err) {
                error.OutOfMemory => return error.OutOfMemory,
                error.Overflow => return c.failNode(node, "Overflow", .{}),
                error.InvalidCharacter => return c.failNode(node, "Invalid character", .{}),
            };
            errdefer value.deref(c.gpa);
            try c.emitConstant(value, number_literal);
        },

        .colon, .colon_colon => try c.emitNil(),
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
            const func = nodes[0];
            const args = nodes[1..];

            if (args.len == 0) {
                try c.emitNil();
                try c.compileNode(func);
                try c.emitCall(1);
                return;
            }

            if (args.len == 2) {
                switch (tree.nodeTag(func)) {
                    .colon => return c.failNode(node, "nyi", .{}),
                    .colon_colon => return c.failNode(node, "nyi", .{}),
                    else => {},
                }
            }

            var it = std.mem.reverseIterator(args);
            while (it.next()) |n| {
                try c.compileNode(n);
            }
            try c.compileNode(func);
            try c.emitCall(args.len);
        },

        .apply_unary => {
            const lhs, const rhs = tree.nodeData(node).node_and_node;
            try c.emitApplyUnary(lhs, rhs);
        },

        .apply_binary => {
            const lhs, const maybe_rhs = tree.nodeData(node).node_and_opt_node;
            const op: Node.Index = @enumFromInt(tree.nodeMainToken(node));
            try c.emitApplyBinary(lhs, op, maybe_rhs);
        },

        .number_literal => {
            const token = tree.nodeMainToken(node);
            const slice = tree.tokenSlice(token);
            if (slice.len == 1 or (slice.len == 2 and slice[1] == 'j')) {
                switch (slice[0]) {
                    '0' => return c.emitZero(),
                    '1' => return c.emitOne(),
                    else => {},
                }
            }
            const value = parseNumber(c.gpa, slice, .pos) catch |err| switch (err) {
                error.OutOfMemory => return error.OutOfMemory,
                error.Overflow => return c.failNode(node, "Overflow", .{}),
                error.InvalidCharacter => return c.failNode(node, "Invalid character", .{}),
            };
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
            if (slice.len == 1) return c.emitNullSymbol();
            const value: *Value = try .symbol(c.gpa, try c.vm.intern(slice[1..]));
            errdefer value.deref(c.gpa);
            try c.emitConstant(value, node);
        },
        .symbol_list_literal => {
            const first_token = tree.nodeMainToken(node);
            const last_token = tree.nodeData(node).token;
            const len = last_token - first_token + 1;
            const symbols = try c.gpa.alloc(NullTerminatedString, len);
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
            const name = try c.vm.intern(tree.tokenSlice(tree.nodeMainToken(node)));

            if (c.lambda.as.lambda.arity > 0) {
                if (c.getLocal(name)) |local| {
                    try c.emitLocal(local);
                    return;
                }
            }

            const global: u8 = c.getGlobal(name) orelse global: {
                try c.addGlobal(name);
                const globals = c.lambda.as.lambda.chunk.globals.items;
                assert(globals[globals.len - 1] == name);
                break :global @intCast(globals.len - 1);
            };
            try c.emitGlobal(global);
        },

        inline else => |t| std.debug.panic("{t}", .{t}),
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

    if (c.vm.print_code and !c.hasErrors()) {
        try c.currentChunk().disassemble(c.vm, c.vm.stdout, c.vm.nullTerminatedString(c.lambda.as.lambda.source));
    }

    return c.lambda;
}

fn emitAssign(c: *Compiler, local: u8) !void {
    try c.emitOpCode(.assign);
    try c.emitByte(local);
}

fn emitAmend(c: *Compiler, identifier: u8, operator: Value.Operator) !void {
    try c.emitOpCode(.empty_list);
    try c.emitOpCode(.amend);
    try c.emitByte(identifier);
    try c.emitByte(@intFromEnum(operator));
}

fn emitCall(c: *Compiler, arg_count: usize) !void {
    try c.emitOpCode(.call);
    try c.emitByte(arg_count);
}

fn emitLocal(c: *Compiler, local: u8) !void {
    try c.emitOpCode(.local);
    try c.emitByte(local);
}

fn emitGlobal(c: *Compiler, global: u8) !void {
    try c.emitOpCode(.global);
    try c.emitByte(global);
}

fn emitApplyUnary(c: *Compiler, lhs: Node.Index, rhs: Node.Index) !void {
    const tree = c.tree;

    try c.compileNode(rhs);
    switch (tree.nodeTag(tree.unwrap(lhs))) {
        .grouped_expression => unreachable,

        .colon, .colon_colon => try c.emitUnaryPrimitive(.identity),
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

        else => {
            try c.compileNode(lhs);
            try c.emitOpCode(.apply_at);
        },
    }
}

// TODO: binary iterator
fn emitApplyBinary(c: *Compiler, lhs: Node.Index, op: Node.Index, maybe_rhs: Node.OptionalIndex) !void {
    const tree = c.tree;

    if (maybe_rhs.unwrap()) |rhs| {
        const tag = tree.nodeTag(tree.unwrap(op));
        switch (tag) {
            .grouped_expression => unreachable,

            inline .colon,
            .colon_colon,
            => |t| {
                const identifier = tree.unwrap(lhs);
                if (tree.nodeTag(identifier) != .identifier) {
                    return c.failNode(lhs, "Expected identifier, found '{t}'", .{tree.nodeTag(identifier)});
                }

                try c.compileNode(rhs);

                const name = try c.vm.intern(tree.tokenSlice(tree.nodeMainToken(identifier)));
                if (comptime t == .colon) {
                    try c.emitAssign(c.getLocal(name).?);
                } else {
                    if (c.getLocal(name)) |local| {
                        try c.emitAssign(local);
                    } else {
                        try c.emitAmend(c.getGlobal(name).?, .assign);
                    }
                }
            },

            else => {
                try c.compileNode(rhs);
                try c.compileNode(lhs);
                switch (tree.nodeTag(tree.unwrap(op))) {
                    .plus => return c.emitOperator(.add),
                    .plus_colon => return c.failNode(op, "nyi", .{}),
                    .minus => return c.emitOperator(.subtract),
                    .minus_colon => return c.failNode(op, "nyi", .{}),
                    .asterisk => return c.emitOperator(.multiply),
                    .asterisk_colon => return c.failNode(op, "nyi", .{}),
                    .percent => return c.emitOperator(.divide),
                    .percent_colon => return c.failNode(op, "nyi", .{}),
                    .ampersand => return c.emitOperator(.@"and"),
                    .ampersand_colon => return c.failNode(op, "nyi", .{}),
                    .pipe => return c.emitOperator(.@"or"),
                    .pipe_colon => return c.failNode(op, "nyi", .{}),
                    .caret => return c.emitOperator(.fill),
                    .caret_colon => return c.failNode(op, "nyi", .{}),
                    .equal => return c.emitOperator(.equals),
                    .equal_colon => return c.failNode(op, "nyi", .{}),
                    .l_angle_bracket => return c.emitOperator(.less_than),
                    .l_angle_bracket_colon => return c.failNode(op, "nyi", .{}),
                    .r_angle_bracket => return c.emitOperator(.greater_than),
                    .r_angle_bracket_colon => return c.failNode(op, "nyi", .{}),
                    .dollar => return c.emitOperator(.cast),
                    .dollar_colon => return c.failNode(op, "nyi", .{}),
                    .comma => return c.emitOperator(.join),
                    .comma_colon => return c.failNode(op, "nyi", .{}),
                    .hash => return c.emitOperator(.take),
                    .hash_colon => return c.failNode(op, "nyi", .{}),
                    .underscore => return c.emitOperator(.drop),
                    .underscore_colon => return c.failNode(op, "nyi", .{}),
                    .tilde => return c.emitOperator(.match),
                    .tilde_colon => return c.failNode(op, "nyi", .{}),
                    .bang => return c.emitOperator(.dict),
                    .bang_colon => return c.failNode(op, "nyi", .{}),
                    .question_mark => return c.emitOperator(.find),
                    .question_mark_colon => return c.failNode(op, "nyi", .{}),
                    .at => return c.emitOperator(.apply_at),
                    .at_colon => return c.failNode(op, "nyi", .{}),
                    .dot => return c.emitOperator(.apply),
                    .dot_colon => return c.failNode(op, "nyi", .{}),
                    .zero_colon => return c.emitOperator(.file_text),
                    .zero_colon_colon => return c.failNode(op, "nyi", .{}),
                    .one_colon => return c.emitOperator(.file_binary),
                    .one_colon_colon => return c.failNode(op, "nyi", .{}),
                    .two_colon => return c.emitOperator(.dynamic_load),
                    else => unreachable,
                }
            },
        }
    } else {
        try c.compileNode(lhs);
        try c.compileNode(op);
        try c.emitOperator(.apply_at);
    }
}

fn emitUnaryPrimitive(c: *Compiler, unary_primitive: Value.UnaryPrimitive) !void {
    const op_code: OpCode = @enumFromInt(@intFromEnum(unary_primitive) + 32);
    try c.emitOpCode(op_code);
}

fn emitEmptyList(c: *Compiler) !void {
    try c.emitOpCode(.empty_list);
}

fn emitZero(c: *Compiler) !void {
    try c.emitOpCode(.zero);
}

fn emitOne(c: *Compiler) !void {
    try c.emitOpCode(.one);
}

fn emitComma(c: *Compiler) !void {
    try c.emitOpCode(.comma);
}

fn emitNullSymbol(c: *Compiler) !void {
    try c.emitOpCode(.null_symbol);
}

fn emitNil(c: *Compiler) !void {
    try c.emitOpCode(.nil);
}

fn emitEmpty(c: *Compiler) !void {
    try c.emitOpCode(.empty);
}

fn emitOperator(c: *Compiler, operator: Value.Operator) !void {
    const op_code: OpCode = @enumFromInt(@intFromEnum(operator) + 64);
    try c.emitOpCode(op_code);
}

fn emitConstant(c: *Compiler, value: *Value, node: Node.Index) !void {
    const constant = try c.makeConstant(value, node);
    try c.emitOpCode(.constant);
    try c.emitByte(constant);
}

fn addImplicitParam(c: *Compiler, name: NullTerminatedString) void {
    const params = &c.lambda.as.lambda.chunk.params;
    assert(params.capacity >= 8);
    switch (name) {
        .x => if (params.items.len < 1) {
            params.items.len = 1;
            params.items[0] = .x;
        },
        .y => if (params.items.len < 2) {
            params.items.len = 2;
            params.items[0] = .x;
            params.items[1] = .y;
        },
        .z => if (params.items.len < 3) {
            params.items.len = 3;
            params.items[0] = .x;
            params.items[1] = .y;
            params.items[2] = .z;
        },
        else => unreachable,
    }
}

fn addLocal(c: *Compiler, name: NullTerminatedString, node: Node.Index) !void {
    if (c.getGlobal(name) != null) {
        return c.failNode(node, "Cannot assign to global variable '{s}'", .{c.vm.nullTerminatedString(name)});
    }
    if (c.getLocal(name) != null) return;
    try c.lambda.as.lambda.chunk.locals.append(c.gpa, name);
}

fn addGlobal(c: *Compiler, name: NullTerminatedString) !void {
    if (c.getLocal(name) != null) return;
    if (c.getGlobal(name) != null) return;
    try c.lambda.as.lambda.chunk.globals.append(c.gpa, name);
}

fn addIdentifier(c: *Compiler, node: Node.Index, implicit_args: bool, scope: enum { local, global }) !void {
    assert(c.tree.nodeTag(node) == .identifier);
    const name = try c.vm.intern(c.tree.tokenSlice(c.tree.nodeMainToken(node)));
    if (scope == .local) {
        if (implicit_args) {
            switch (name) {
                .x, .y, .z => return c.addImplicitParam(name),
                else => {},
            }
        }
        try c.addLocal(name, node);
    } else {
        if (implicit_args) {
            switch (name) {
                .x, .y, .z => return c.addImplicitParam(name),
                else => {},
            }
        }
        try c.addGlobal(name);
    }
}

fn makeConstant(c: *Compiler, value: *Value, node: Node.Index) !u8 {
    if (c.currentChunk().constants.items.len >= std.math.maxInt(u8)) {
        return c.failNode(node, "Too many constants", .{});
    }
    const constant = try c.currentChunk().addConstant(c.gpa, value);
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

fn errNoteTok(c: *Compiler, token_index: Ast.TokenIndex, comptime fmt: []const u8, args: anytype) !ErrorMessage {
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

fn failNodeNotes(
    c: *Compiler,
    node: Node.Index,
    comptime fmt: []const u8,
    args: anytype,
    notes: []const ErrorMessage,
) InnerError {
    try c.appendErrorNodeNotes(node, fmt, args, notes);
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
    notes: []const ErrorMessage,
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

fn getParam(c: *Compiler, name: NullTerminatedString) ?u8 {
    for (c.lambda.as.lambda.chunk.params.items, 1..) |value, i| {
        if (value == name) return @intCast(i);
    }
    return null;
}

fn getLocal(c: *Compiler, name: NullTerminatedString) ?u8 {
    if (c.getParam(name)) |param| return param;
    for (c.lambda.as.lambda.chunk.locals.items, 9..) |value, i| {
        if (value == name) return @intCast(i);
    }
    return null;
}

fn getGlobal(c: *Compiler, name: NullTerminatedString) ?u8 {
    for (c.lambda.as.lambda.chunk.globals.items, 0..) |value, i| {
        if (value == name) return @intCast(i);
    }
    return null;
}

fn findLocals(c: *Compiler, node: Node.Index, implicit_args: bool) !void {
    const tree = c.tree;
    switch (tree.nodeTag(node)) {
        .root => unreachable,
        .no_op => {},

        .pop,
        .print,
        => try c.findLocals(tree.nodeData(node).node, implicit_args),

        .grouped_expression => try c.findLocals(tree.nodeData(node).node_and_token[0], implicit_args),
        .empty_list => {},
        .list => for (tree.extraDataSlice(tree.nodeData(node).extra_range, Node.Index)) |n| {
            try c.findLocals(n, implicit_args);
        },
        .table_literal => |t| std.debug.panic("NYI: findLocals({t})", .{t}),

        .lambda => {},

        .expr_block => for (tree.extraDataSlice(tree.nodeData(node).extra_range, Node.Index)) |n| {
            try c.findLocals(n, implicit_args);
        },

        .negation => try c.findLocals(tree.nodeData(node).node, implicit_args),

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
        => if (tree.nodeData(node).opt_node.unwrap()) |n| try c.findLocals(n, implicit_args),

        .call => {
            const nodes = tree.extraDataSlice(tree.nodeData(node).extra_range, Node.Index);
            assert(nodes.len > 0);

            if (nodes.len == 3) {
                try c.findLocals(nodes[2], implicit_args);
                if (tree.nodeTag(tree.unwrap(nodes[0])) == .colon) {
                    try c.addIdentifier(tree.unwrap(nodes[1]), implicit_args, .local);
                }
                try c.findLocals(nodes[1], implicit_args);
                try c.findLocals(nodes[0], implicit_args);
            } else {
                var it = std.mem.reverseIterator(nodes);
                while (it.next()) |n| try c.findLocals(n, implicit_args);
            }
        },
        .apply_unary => {
            const lhs, const rhs = tree.nodeData(node).node_and_node;
            try c.findLocals(rhs, implicit_args);
            try c.findLocals(lhs, implicit_args);
        },
        .apply_binary => {
            const lhs, const maybe_rhs = tree.nodeData(node).node_and_opt_node;
            const op: Node.Index = @enumFromInt(tree.nodeMainToken(node));
            if (maybe_rhs.unwrap()) |rhs| {
                try c.findLocals(rhs, implicit_args);
                if (tree.nodeTag(op) == .colon) {
                    try c.addIdentifier(tree.unwrap(lhs), implicit_args, .local);
                }
            }
            try c.findLocals(lhs, implicit_args);
        },

        .number_literal,
        .number_list_literal,
        .string_literal,
        .symbol_literal,
        .symbol_list_literal,
        => {},
        .identifier => try c.addIdentifier(node, implicit_args, .global),

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

    var wip: ErrorBundle.Wip = undefined;
    try wip.init(gpa);
    defer wip.deinit();

    var compiler: Compiler = undefined;
    try compiler.init(&vm, tree, &wip, "<test>");

    const lambda: *Value = compiler.compile() catch |err| switch (err) {
        error.CompilerError => blk: {
            try std.testing.expect(compiler.hasErrors());
            break :blk compiler.lambda;
        },
        else => return err,
    };
    defer lambda.deref(gpa);

    if (compiler.hasErrors()) {
        var eb = try wip.toOwnedBundle("");
        defer eb.deinit(gpa);
        try eb.renderToWriter(.{}, stdout);
    }

    try std.testing.expectEqualStrings(
        std.mem.trim(u8, expected, &std.ascii.whitespace),
        std.mem.trim(u8, stdout_writer.written(), &std.ascii.whitespace),
    );
}

test "implicit params" {
    try testCompiler("{x}",
        \\== {x} ==
        \\0000    0 local               1 'x'
        \\0002    | return
        \\== <test> ==
        \\0000    0 constant            0 '{x}'
        \\0002    | print
        \\0003    | return
    );
    try testCompiler("{a:x}",
        \\== {a:x} ==
        \\0000    0 local               1 'x'
        \\0002    | assign              9 'a'
        \\0004    | return
        \\== <test> ==
        \\0000    0 constant            0 '{a:x}'
        \\0002    | print
        \\0003    | return
    );
    try testCompiler("{y:x}",
        \\== {y:x} ==
        \\0000    0 local               1 'x'
        \\0002    | assign              2 'y'
        \\0004    | return
        \\== <test> ==
        \\0000    0 constant            0 '{y:x}'
        \\0002    | print
        \\0003    | return
    );
    try testCompiler("{x;x+1;x}",
        \\== {x;x+1;x} ==
        \\0000    0 local               1 'x'
        \\0002    | pop
        \\0003    | one
        \\0004    | local               1 'x'
        \\0006    | add
        \\0007    | pop
        \\0008    | local               1 'x'
        \\0010    | return
        \\== <test> ==
        \\0000    0 constant            0 '{x;x+1;x}'
        \\0002    | print
        \\0003    | return
    );
    try testCompiler("{x;x:1}",
        \\== {x;x:1} ==
        \\0000    0 local               1 'x'
        \\0002    | pop
        \\0003    | one
        \\0004    | assign              1 'x'
        \\0006    | return
        \\== <test> ==
        \\0000    0 constant            0 '{x;x:1}'
        \\0002    | print
        \\0003    | return
    );
    try testCompiler("{x;x::1}",
        \\== {x;x::1} ==
        \\0000    0 local               1 'x'
        \\0002    | pop
        \\0003    | one
        \\0004    | assign              1 'x'
        \\0006    | return
        \\== <test> ==
        \\0000    0 constant            0 '{x;x::1}'
        \\0002    | print
        \\0003    | return
    );
}

test "explicit params" {
    try testCompiler("{[]x;x+1;x}",
        \\== {[]x;x+1;x} ==
        \\0000    0 global              0 'x'
        \\0002    | pop
        \\0003    | one
        \\0004    | global              0 'x'
        \\0006    | add
        \\0007    | pop
        \\0008    | global              0 'x'
        \\0010    | return
        \\== <test> ==
        \\0000    0 constant            0 '{[]x;x+1;x}'
        \\0002    | print
        \\0003    | return
    );
    try testCompiler("{[]x;x::1}",
        \\== {[]x;x::1} ==
        \\0000    0 global              0 'x'
        \\0002    | pop
        \\0003    | one
        \\0004    | empty_list
        \\0005    | amend               0 assign
        \\0008    | return
        \\== <test> ==
        \\0000    0 constant            0 '{[]x;x::1}'
        \\0002    | print
        \\0003    | return
    );
    try testCompiler("{[]x;x:1}",
        \\<test>:1:6: error: Cannot assign to global variable 'x'
        \\{[]x;x:1}
        \\     ^
    );
    try testCompiler("{[x]a:x}",
        \\== {[x]a:x} ==
        \\0000    0 local               1 'x'
        \\0002    | assign              9 'a'
        \\0004    | return
        \\== <test> ==
        \\0000    0 constant            0 '{[x]a:x}'
        \\0002    | print
        \\0003    | return
    );
}
