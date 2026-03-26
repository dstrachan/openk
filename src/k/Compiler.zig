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

const Error = Allocator.Error || std.fmt.ParseFloatError || error{
    TooManyConstants,
};

gpa: Allocator,
vm: *Vm,
tree: Ast = undefined,
compiling_chunk: *Chunk = undefined,
line: u32 = 0,

pub fn init(c: *Compiler, gpa: Allocator, vm: *Vm) !void {
    c.* = .{
        .gpa = gpa,
        .vm = vm,
    };
}

pub fn deinit(c: *Compiler) void {
    _ = c; // autofix
}

pub fn compile(c: *Compiler, tree: Ast, chunk: *Chunk) !void {
    c.tree = tree;
    c.compiling_chunk = chunk;

    const nodes = tree.extraDataSlice(tree.nodeData(.root).extra_range, Node.Index);
    for (nodes) |n| try c.compileNode(n);

    try c.endCompiler();
}

fn compileNode(c: *Compiler, node: Node.Index) Error!void {
    const tree = c.tree;

    switch (tree.nodeTag(node)) {
        .root => unreachable,
        .grouped_expression => try c.compileNode(tree.nodeData(node).node_and_token[0]),

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

        .plus => try c.emitOpCode(.add),
        .minus => try c.emitOpCode(.subtract),
        .asterisk => try c.emitOpCode(.multiply),
        .percent => try c.emitOpCode(.divide),

        .apply_unary => {
            const lhs, const rhs = tree.nodeData(node).node_and_node;
            try c.compileNode(rhs);
            try c.compileUnaryNode(lhs);
        },

        .apply_binary => {
            const lhs, const maybe_rhs = tree.nodeData(node).node_and_opt_node;
            const op: Node.Index = @enumFromInt(tree.nodeMainToken(node));

            if (maybe_rhs.unwrap()) |rhs| {
                try c.compileNode(rhs);
            } else {
                unreachable;
            }
            try c.compileNode(lhs);
            try c.compileNode(op);
        },

        .number_literal => {
            const token = tree.nodeMainToken(node);
            const slice = tree.tokenSlice(token);
            const number = try std.fmt.parseFloat(f64, slice);
            const value: *Value = try .float(c.gpa, number);
            errdefer value.deref(c.gpa);
            try c.emitConstant(value);
        },

        inline else => |t| std.debug.panic("{t}", .{t}),
    }
}

fn compileUnaryNode(c: *Compiler, node: Node.Index) !void {
    const tree = c.tree;

    switch (tree.nodeTag(node)) {
        .grouped_expression => try c.compileUnaryNode(tree.nodeData(node).node_and_token[0]),

        .minus => try c.emitOpCode(.negate),

        else => try c.compileNode(node),
    }
}

fn currentChunk(c: *Compiler) *Chunk {
    return c.compiling_chunk;
}

fn endCompiler(c: *Compiler) !void {
    try c.emitReturn();
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
