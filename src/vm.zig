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
const ValueFunction = value_mod.ValueFunction;
const ValueUnion = value_mod.ValueUnion;

const debug_trace_execution = @import("builtin").mode == .Debug and !@import("builtin").is_test;
const frames_max = 64;
const stack_max = frames_max * std.math.maxInt(u8);

const CallFrame = struct {
    function: *ValueFunction,
    ip: usize,
    slots: []*Value,
};

pub const VM = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    frame: *CallFrame,
    frames: [frames_max]CallFrame,
    frame_count: usize,
    stack: [stack_max]*Value,
    stack_top: usize,
    globals: std.StringHashMap(*Value),

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .allocator = allocator,
            .frame = undefined,
            .frames = undefined,
            .frame_count = 0,
            .stack = undefined,
            .stack_top = 0,
            .globals = std.StringHashMap(*Value).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        while (self.frame_count > 0) : (self.frame_count -= 1) {
            self.frames[self.frame_count - 1].function.deinit(self.allocator);
        }

        var it = self.globals.iterator();
        while (it.next()) |entry| entry.value_ptr.*.deinit(self.allocator);
        self.globals.deinit();
    }

    pub fn initValue(self: *Self, data: ValueUnion) *Value {
        return Value.init(data, self.allocator);
    }

    pub fn interpret(self: *Self, source: []const u8) !*Value {
        const function = compiler_mod.compile(source, self) catch return error.interpret_compile_error;

        if (comptime debug_trace_execution) debug_mod.disassembleChunk(function.chunk, "script");

        try self.call(function, std.bit_set.IntegerBitSet(8).initEmpty());
        return self.run() catch |e| {
            self.stack_top = 0;
            return e;
        };
    }

    fn push(self: *Self, value: *Value) void {
        value.reference_count += 1;
        self.stack[self.stack_top] = value;
        self.stack_top += 1;
    }

    fn pop(self: *Self) *Value {
        self.stack_top -= 1;
        return self.stack[self.stack_top];
    }

    fn peek(self: *Self, distance: usize) *Value {
        return self.stack[self.stack_top - 1 - distance];
    }

    fn call(self: *Self, function: *ValueFunction, arg_indices: std.bit_set.IntegerBitSet(8)) !void {
        const arg_count = @intCast(u8, arg_indices.count());
        if (arg_count != function.arity) {
            return self.runtimeError("Expected {d} arguments but got {d}.", .{ function.arity, arg_count });
        }

        if (self.frame_count == frames_max) {
            return self.runtimeError("Stack overflow.", .{});
        }

        // Add locals to stack and rearrange
        var i: u8 = arg_count;
        while (i < function.local_count - arg_count) : (i += 1) {
            const value = self.initValue(.nil);
            self.push(value);
        }
        while (i < function.local_count) : (i += 1) {
            self.push(self.stack[self.stack_top - 1 - arg_count]);
        }

        self.frames[self.frame_count] = CallFrame{
            .function = function,
            .ip = 0,
            .slots = self.stack[self.stack_top - function.local_count .. self.stack_top],
        };
        self.frame_count += 1;
    }

    fn run(self: *Self) !*Value {
        while (true) {
            self.frame = &self.frames[self.frame_count - 1];
            if (comptime debug_trace_execution) {
                print("          ", .{});
                for (self.stack[0..self.stack_top]) |slot| {
                    print("[ {} ]", .{slot});
                }
                print("\n", .{});
                _ = debug_mod.disassembleInstruction(self.frame.function.chunk, self.frame.ip);
            }

            const instruction = @intToEnum(OpCode, self.readByte());
            switch (instruction) {
                .op_constant => self.opConstant(),
                .op_pop => self.opPop(),
                .op_get_global => try self.opGetGlobal(),
                .op_set_global => try self.opSetGlobal(),
                .op_add => try self.opAdd(),
                .op_return => if (self.opReturn()) |value| return value,
            }
        }
    }

    fn readByte(self: *Self) u8 {
        defer self.frame.ip += 1;
        return self.frame.function.chunk.code.items[self.frame.ip];
    }

    fn readConstant(self: *Self) *Value {
        return self.frame.function.chunk.constants.items[self.readByte()];
    }

    fn readSymbol(self: *Self) []const u8 {
        return self.readConstant().data.symbol;
    }

    fn opConstant(self: *Self) void {
        const constant = self.readConstant();
        self.push(constant);
    }

    fn opPop(self: *Self) void {
        const value = self.pop();
        value.deinit(self.allocator);
    }

    fn opGetGlobal(self: *Self) !void {
        const name = self.readSymbol();
        const value = self.globals.get(name) orelse return self.runtimeError("Undefined variable '{s}'", .{name});
        self.push(value);
    }

    fn opSetGlobal(self: *Self) !void {
        const name = self.readSymbol();
        const value = self.peek(0);
        value.reference_count += 1;
        const result = self.globals.getOrPut(name) catch return self.runtimeError("Failed to set global variable '{s}'", .{name});
        if (result.found_existing) {
            result.value_ptr.*.deinit(self.allocator);
        }
        result.value_ptr.* = value;
    }

    fn opAdd(self: *Self) !void {
        const a = self.pop();
        defer a.deinit(self.allocator);
        const b = self.pop();
        defer b.deinit(self.allocator);

        const value = switch (a.data) {
            .float => |float_a| switch (b.data) {
                .float => |float_b| self.initValue(.{ .float = float_a + float_b }),
                else => unreachable,
            },
            else => unreachable,
        };
        defer value.deinit(self.allocator);

        self.push(value);
    }

    fn opReturn(self: *Self) ?*Value {
        const result = self.pop();
        self.frame_count -= 1;
        if (self.frame_count == 0) {
            self.frame.function.deinit(self.allocator);
            return result;
        }
        defer result.deinit(self.allocator);

        self.stack_top -= self.frame.slots.len;
        self.push(result);
        return null;
    }

    fn runtimeError(self: *Self, comptime format: []const u8, args: anytype) !void {
        print(format ++ "\n", args);

        print("runtimeError {d}\n", .{self.stack_top});

        var i = self.frame_count;
        while (i > 0) {
            i -= 1;
            const frame = self.frames[i];
            const function = frame.function;
            const instruction = function.chunk.lines.items[frame.ip];
            print("[line {d}] in ", .{instruction});
            if (function.name) |name| {
                print("{s}()\n", .{name});
            } else {
                print("script\n", .{});
            }
        }

        return error.interpret_runtime_error;
    }
};
