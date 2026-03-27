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
        .discard => {
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
            compiler.lambda.as.lambda.arity = @intCast(params.len);

            for (nodes) |n| try compiler.compileNode(n);

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
            const add: *Value = try .operator(c.gpa, .add);
            errdefer add.deref(c.gpa);
            try c.emitConstant(add);
        },
        .minus => {
            const subtract: *Value = try .operator(c.gpa, .subtract);
            errdefer subtract.deref(c.gpa);
            try c.emitConstant(subtract);
        },
        .asterisk => {
            const multiply: *Value = try .operator(c.gpa, .multiply);
            errdefer multiply.deref(c.gpa);
            try c.emitConstant(multiply);
        },
        .percent => {
            const divide: *Value = try .operator(c.gpa, .divide);
            errdefer divide.deref(c.gpa);
            try c.emitConstant(divide);
        },

        .call => {
            const nodes = tree.extraDataSlice(tree.nodeData(node).extra_range, Node.Index);
            var it = std.mem.reverseIterator(nodes);
            while (it.next()) |n| try c.compileNode(n);
            try c.emitOpCode(.apply);
        },

        .apply_unary => {
            const lhs, const rhs = tree.nodeData(node).node_and_node;
            try c.compileNode(rhs);
            try c.compileUnaryNode(lhs);
            try c.emitOpCode(.apply);
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

        .minus => {
            const neg: *Value = try .unaryPrimitive(c.gpa, .neg);
            errdefer neg.deref(c.gpa);
            try c.emitConstant(neg);
        },

        else => try c.compileNode(node),
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

fn emitOpCode(c: *Compiler, code: k.OpCode) !void {
    try c.emitByte(code);
}

fn emitByte(c: *Compiler, byte: anytype) !void {
    try c.currentChunk().write(c.gpa, byte, c.line);
}
