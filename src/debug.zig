const std = @import("std");

const chunk_mod = @import("chunk.zig");
const Chunk = chunk_mod.Chunk;
const OpCode = chunk_mod.OpCode;

const utils_mod = @import("utils.zig");
const print = utils_mod.print;

const Sign = enum {
    positive,
    negative,
};

pub fn disassembleChunk(chunk: *const Chunk, name: []const u8) void {
    print("== {s} ==\n", .{name});

    var offset: usize = 0;
    while (offset < chunk.code.items.len) {
        offset = disassembleInstruction(chunk, offset);
    }
}

fn simpleInstruction(comptime instruction: OpCode, offset: usize) usize {
    print("{s}\n", .{@tagName(instruction)});
    return offset + 1;
}

fn byteInstruction(comptime instruction: OpCode, chunk: *const Chunk, offset: usize) usize {
    const slot = chunk.code.items[offset + 1];
    print("{s:<16} {d:4}\n", .{ @tagName(instruction), slot });
    return offset + 2;
}

fn shortInstruction(comptime instruction: OpCode, chunk: *const Chunk, offset: usize) usize {
    const slot = (@as(u16, chunk.code.items[offset + 1]) << 8) | chunk.code.items[offset + 2];
    print("{s:<16} {d:4}\n", .{ @tagName(instruction), slot });
    return offset + 3;
}

fn jumpInstruction(comptime instruction: OpCode, sign: Sign, chunk: *const Chunk, offset: usize) usize {
    const jump = (@as(u16, chunk.code.items[offset + 1]) << 8) | chunk.code.items[offset + 2];
    const addr = switch (sign) {
        .positive => offset + 3 + jump,
        .negative => offset + 3 - jump,
    };
    print("{s:<16} {d:4} -> {d}\n", .{ @tagName(instruction), offset, addr });
    return offset + 3;
}

fn constantInstruction(comptime instruction: OpCode, chunk: *const Chunk, offset: usize) usize {
    const constant = chunk.code.items[offset + 1];
    print("{s:<16} {d:4} {}\n", .{ @tagName(instruction), constant, chunk.constants.items[constant] });
    return offset + 2;
}

pub fn disassembleInstruction(chunk: *const Chunk, offset: usize) usize {
    print("{d:0>4} ", .{offset});
    if (offset > 0 and chunk.lines.items[offset] == chunk.lines.items[offset - 1]) {
        print("   | ", .{});
    } else {
        print("{d:4} ", .{chunk.lines.items[offset]});
    }

    const instruction = @intToEnum(OpCode, chunk.code.items[offset]);
    return switch (instruction) {
        .op_constant => constantInstruction(.op_constant, chunk, offset),
        .op_return => simpleInstruction(.op_return, offset),
    };
}
