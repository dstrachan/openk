const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;

const k = @import("../root.zig");
const Value = k.Value;
const Vm = k.Vm;
const NullTerminatedString = k.NullTerminatedString;

const Chunk = @This();

data: std.MultiArrayList(struct { code: u8, line: u32 }) = .empty,
params: std.ArrayList(NullTerminatedString) = .empty,
locals: std.ArrayList(NullTerminatedString) = .empty,
globals: std.ArrayList(NullTerminatedString) = .empty,
constants: std.ArrayList(*Value) = .empty,

pub const empty: Chunk = .{};

pub const OpCode = enum(u8) {
    @"return" = 0,
    print = 1,
    pop = 2,
    assign = 3,
    amend = 4,
    call = 10,

    // builtins
    empty_list = 11,
    zero = 12,
    one = 13,
    comma = 14,
    null_symbol = 15,
    nil = 16,
    empty = 17,

    // unary primitives
    identity = 32,
    flip = 33,
    neg = 34,
    first = 35,
    reciprocal = 36,
    where = 37,
    reverse = 38,
    null = 39,
    group = 40,
    asc = 41,
    desc = 42,
    string = 43,
    list = 44,
    count = 45,
    lower = 46,
    not = 47,
    key = 48,
    distinct = 49,
    type = 50,
    value = 51,
    read_text = 52,
    read_binary = 53,
    _unused_unary_primitive = 54,
    avg = 55,
    last = 56,
    sum = 57,
    prd = 58,
    min = 59,
    max = 60,
    exit = 61,
    getenv = 62,
    abs = 63,

    // operators
    _unused_operator = 64,
    add = 65,
    subtract = 66,
    multiply = 67,
    divide = 68,
    @"and" = 69,
    @"or" = 70,
    fill = 71,
    equals = 72,
    less_than = 73,
    greater_than = 74,
    cast = 75,
    join = 76,
    take = 77,
    drop = 78,
    match = 79,
    dict = 80,
    find = 81,
    apply_at = 82,
    apply = 83,
    file_text = 84,
    file_binary = 85,
    dynamic_load = 86,
    in = 87,
    within = 88,
    like = 89,
    bin = 90,
    ss = 91,
    insert = 92,
    wsum = 93,
    wavg = 94,
    div = 95,

    local = 96,

    global = 129,

    constant = 160,

    pub const Index = enum(u32) { _ };
};

pub fn opCode(chunk: *const Chunk, index: OpCode.Index) OpCode {
    return @enumFromInt(chunk.data.items(.code)[@intFromEnum(index)]);
}

pub fn deinit(chunk: *Chunk, gpa: Allocator) void {
    chunk.data.deinit(gpa);
    chunk.params.deinit(gpa);
    chunk.locals.deinit(gpa);
    chunk.globals.deinit(gpa);
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
        .@"return" => |t| return simpleInstruction(writer, t, offset),
        .print => |t| return simpleInstruction(writer, t, offset),
        .pop => |t| return simpleInstruction(writer, t, offset),
        .assign => |t| return chunk.assignInstruction(vm, writer, t, offset),
        .amend => |t| return chunk.byteInstruction2(writer, t, offset, Value.Operator),
        .call => |t| return chunk.byteInstruction(writer, t, offset),

        .empty_list,
        .zero,
        .one,
        .comma,
        .null_symbol,
        .nil,
        .empty,
        => |t| return simpleInstruction(writer, t, offset),

        .identity,
        .flip,
        .neg,
        .first,
        .reciprocal,
        .where,
        .reverse,
        .null,
        .group,
        .asc,
        .desc,
        .string,
        .list,
        .count,
        .lower,
        .not,
        .key,
        .distinct,
        .type,
        .value,
        .read_text,
        .read_binary,
        ._unused_unary_primitive,
        .avg,
        .last,
        .sum,
        .prd,
        .min,
        .max,
        .exit,
        .getenv,
        .abs,
        => |t| return simpleInstruction(writer, t, offset),

        ._unused_operator,
        .add,
        .subtract,
        .multiply,
        .divide,
        .@"and",
        .@"or",
        .fill,
        .equals,
        .less_than,
        .greater_than,
        .cast,
        .join,
        .take,
        .drop,
        .match,
        .dict,
        .find,
        .apply_at,
        .apply,
        .file_text,
        .file_binary,
        .dynamic_load,
        .in,
        .within,
        .like,
        .bin,
        .ss,
        .insert,
        .wsum,
        .wavg,
        .div,
        => |t| return simpleInstruction(writer, t, offset),

        .local => |t| return chunk.localInstruction(vm, writer, t, offset),

        .global => |t| return chunk.globalInstruction(vm, writer, t, offset),

        .constant => |t| return chunk.constantInstruction(vm, writer, t, offset),
    }
}

fn simpleInstruction(writer: *Io.Writer, op_code: OpCode, offset: usize) !usize {
    try writer.print("{t}\n", .{op_code});
    return offset + 1;
}

fn assignInstruction(chunk: Chunk, vm: *Vm, writer: *Io.Writer, op_code: OpCode, offset: usize) !usize {
    const constant = chunk.data.items(.code)[offset + 1];
    const name = vm.nullTerminatedString(
        if (constant < 9) chunk.params.items[constant - 1] else chunk.locals.items[constant - 9],
    );
    try writer.print("{t: <16} {d:4} '{s}'\n", .{ op_code, constant, name });
    return offset + 2;
}

fn localInstruction(chunk: Chunk, vm: *Vm, writer: *Io.Writer, op_code: OpCode, offset: usize) !usize {
    const constant = chunk.data.items(.code)[offset + 1];
    const name = vm.nullTerminatedString(
        if (constant < 9) chunk.params.items[constant - 1] else chunk.locals.items[constant - 9],
    );
    try writer.print("{t: <16} {d:4} '{s}'\n", .{ op_code, constant, name });
    return offset + 2;
}

fn globalInstruction(chunk: Chunk, vm: *Vm, writer: *Io.Writer, op_code: OpCode, offset: usize) !usize {
    const constant = chunk.data.items(.code)[offset + 1];
    const name = vm.nullTerminatedString(chunk.globals.items[constant]);
    try writer.print("{t: <16} {d:4} '{s}'\n", .{ op_code, constant, name });
    return offset + 2;
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

fn byteInstruction2(chunk: Chunk, writer: *Io.Writer, op_code: OpCode, offset: usize, comptime T: type) !usize {
    const slot1 = chunk.data.items(.code)[offset + 1];
    const slot2: T = @enumFromInt(chunk.data.items(.code)[offset + 2]);
    try writer.print("{t: <16} {d:4} {t}\n", .{ op_code, slot1, slot2 });
    return offset + 3;
}

test {
    std.testing.refAllDecls(@This());
}
