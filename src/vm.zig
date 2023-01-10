const std = @import("std");

const chunk_mod = @import("chunk.zig");
const Chunk = chunk_mod.Chunk;
const OpCode = chunk_mod.OpCode;

const compiler_mod = @import("compiler.zig");

const debug_mod = @import("debug.zig");

const utils_mod = @import("utils.zig");
const print = utils_mod.print;

const value_mod = @import("value.zig");
const Value = value_mod.Value;

const debug_trace_execution = @import("builtin").mode == .Debug and !@import("builtin").is_test;
const stack_max = 256;

pub const VM = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    chunk: *Chunk,
    ip: usize,
    stack: [stack_max]*Value,
    stack_top: usize,

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .allocator = allocator,
            .chunk = undefined,
            .ip = 0,
            .stack = undefined,
            .stack_top = 0,
        };
    }

    pub fn deinit(self: *Self) void {
        _ = self;
    }

    pub fn interpret(self: *Self, source: []const u8) !*Value {
        var chunk = Chunk.init(self.allocator);
        defer chunk.deinit();

        compiler_mod.compile(source, &chunk) catch return error.interpret_compile_error;

        self.chunk = &chunk;
        self.ip = 0;

        return self.run();
    }

    fn push(self: *Self, value: *Value) void {
        self.stack[self.stack_top] = value;
        self.stack_top += 1;
    }

    fn pop(self: *Self) *Value {
        self.stack_top -= 1;
        return self.stack[self.stack_top];
    }

    fn run(self: *Self) !*Value {
        while (true) {
            if (comptime debug_trace_execution) {
                print("          ", .{});
                for (self.stack[0..self.stack_top]) |slot| {
                    print("[ {} ]", .{slot});
                }
                print("\n", .{});
                _ = debug_mod.disassembleInstruction(self.chunk, self.ip);
            }

            const instruction = @intToEnum(OpCode, self.readByte());
            switch (instruction) {
                .op_constant => self.opConstant(),
                .op_return => return self.pop(),
            }
        }
    }

    fn readByte(self: *Self) u8 {
        defer self.ip += 1;
        return self.chunk.code.items[self.ip];
    }

    fn readConstant(self: *Self) *Value {
        return self.chunk.constants.items[self.readByte()];
    }

    fn opConstant(self: *Self) void {
        const constant = self.readConstant();
        self.push(constant);
    }
};
