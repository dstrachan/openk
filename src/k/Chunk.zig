const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;

const k = @import("../root.zig");
const Value = k.Value;
const Vm = k.Vm;

const Chunk = @This();

data: std.MultiArrayList(struct { code: u8, line: u32 }) = .empty,
constants: std.ArrayList(*Value) = .empty,

pub const empty: Chunk = .{};

pub const OpCode = enum(u8) {
    constant,
    unary_primitive,
    operator,
    get_global,
    set_global,
    get_local,
    set_local,

    @"return",
    pop,
    print,
    store_stack_len,
    apply,

    pub const Index = enum(u32) { _ };
};

pub fn opCode(chunk: *const Chunk, index: OpCode.Index) OpCode {
    return @enumFromInt(chunk.data.items(.code)[@intFromEnum(index)]);
}

pub fn deinit(chunk: *Chunk, gpa: Allocator) void {
    chunk.data.deinit(gpa);
    for (chunk.constants.items) |v| v.deref(gpa);
    chunk.constants.deinit(gpa);
}

pub fn write(chunk: *Chunk, gpa: Allocator, code: anytype, line: u32) !void {
    const byte: u8 = switch (@typeInfo(@TypeOf(code))) {
        .int, .comptime_int => @intCast(code),
        .@"enum" => @intFromEnum(code),
        else => |t| @compileError(@tagName(t)),
    };
    try chunk.data.append(gpa, .{ .code = byte, .line = line });
}

pub fn addConstant(chunk: *Chunk, gpa: Allocator, value: *Value) !usize {
    for (chunk.constants.items, 0..) |constant, i| {
        if (constant.match(value)) {
            defer value.deref(gpa);
            return i;
        }
    }
    try chunk.constants.append(gpa, value);
    return chunk.constants.items.len - 1;
}

pub fn disassemble(chunk: Chunk, vm: *Vm, writer: *Io.Writer, name: []const u8) !void {
    try writer.print("== {s} ==\n", .{name});

    var offset: usize = 0;
    while (offset < chunk.data.len) {
        offset = try chunk.disassembleInstruction(vm, writer, offset);
    }

    try writer.flush();
}

pub fn disassembleInstruction(chunk: Chunk, vm: *Vm, writer: *Io.Writer, offset: usize) !usize {
    try writer.print("{d:04} ", .{offset});
    if (offset > 0 and chunk.data.items(.line)[offset] == chunk.data.items(.line)[offset - 1]) {
        try writer.writeAll("   | ");
    } else {
        try writer.print("{d:4} ", .{chunk.data.items(.line)[offset]});
    }

    switch (chunk.opCode(@enumFromInt(offset))) {
        .constant,
        .get_global,
        .set_global,
        => |t| return chunk.constantInstruction(vm, writer, t, offset),

        .unary_primitive => return chunk.unaryPrimitiveInstruction(writer, offset),
        .operator => return chunk.operatorInstruction(writer, offset),

        .get_local,
        .set_local,
        => |t| return chunk.byteInstruction(writer, t, offset),

        .@"return",
        .pop,
        .print,
        .store_stack_len,
        .apply,
        => |t| return simpleInstruction(writer, t, offset),
    }
}

fn simpleInstruction(writer: *Io.Writer, op_code: OpCode, offset: usize) !usize {
    try writer.print("{t}\n", .{op_code});
    return offset + 1;
}

fn constantInstruction(chunk: Chunk, vm: *Vm, writer: *Io.Writer, op_code: OpCode, offset: usize) !usize {
    const constant = chunk.data.items(.code)[offset + 1];
    try writer.print("{t: <16} {d:4} '{f}'\n", .{ op_code, constant, chunk.constants.items[constant].alt(vm) });
    return offset + 2;
}

fn unaryPrimitiveInstruction(chunk: Chunk, writer: *Io.Writer, offset: usize) !usize {
    const unary_primitive: Value.UnaryPrimitive = @enumFromInt(chunk.data.items(.code)[offset + 1]);
    try writer.print("{t: <16} {d:4} '{f}'\n", .{ OpCode.unary_primitive, unary_primitive, unary_primitive });
    return offset + 2;
}

fn operatorInstruction(chunk: Chunk, writer: *Io.Writer, offset: usize) !usize {
    const operator: Value.Operator = @enumFromInt(chunk.data.items(.code)[offset + 1]);
    try writer.print("{t: <16} {d:4} '{f}'\n", .{ OpCode.operator, operator, operator });
    return offset + 2;
}

fn byteInstruction(chunk: Chunk, writer: *Io.Writer, op_code: OpCode, offset: usize) !usize {
    const slot = chunk.data.items(.code)[offset + 1];
    try writer.print("{t: <16} {d:4}\n", .{ op_code, slot });
    return offset + 2;
}

test {
    std.testing.refAllDecls(@This());
}
