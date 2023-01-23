const std = @import("std");

const chunk_mod = @import("chunk.zig");
const Chunk = chunk_mod.Chunk;
const OpCode = chunk_mod.OpCode;

const compiler_mod = @import("compiler.zig");
const Compiler = compiler_mod.Compiler;

const debug_mod = @import("debug.zig");

const utils_mod = @import("utils.zig");
const print = utils_mod.print;

const value_mod = @import("value.zig");
const Value = value_mod.Value;
const ValueFn = value_mod.ValueFunction;
const ValueProjection = value_mod.ValueProjection;
const ValueType = value_mod.ValueType;
const ValueUnion = value_mod.ValueUnion;

const debug_trace_execution = @import("builtin").mode == .Debug and !@import("builtin").is_test;
const frames_max = 64;
const stack_max = frames_max * 256;

const CallFrame = struct {
    const Self = @This();

    value: *Value,
    ip: usize,
    slots: []*Value,
};

fn BinaryFn(comptime TIn: type, comptime TOut: type) type {
    return *const fn (x: TIn, y: TIn) TOut;
}

pub const VM = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    frame: *CallFrame,
    frames: [frames_max]CallFrame,
    frame_count: usize,
    stack: [stack_max]*Value,
    stack_top: usize,
    globals: std.StringHashMap(*Value),
    symbols: std.StringHashMap(*Value),

    pub fn init(allocator: std.mem.Allocator) *Self {
        const self = allocator.create(Self) catch std.debug.panic("Failed to create VM", .{});
        self.* = Self{
            .allocator = allocator,
            .frame = undefined,
            .frames = undefined,
            .frame_count = 0,
            .stack = undefined,
            .stack_top = 0,
            .globals = std.StringHashMap(*Value).init(allocator),
            .symbols = std.StringHashMap(*Value).init(allocator),
        };
        return self;
    }

    pub fn deinit(self: *Self) void {
        while (self.frame_count > 0) : (self.frame_count -= 1) {
            self.frames[self.frame_count - 1].value.deref(self.allocator);
        }

        var it = self.globals.iterator();
        while (it.next()) |entry| entry.value_ptr.*.deref(self.allocator);
        self.globals.deinit();

        it = self.symbols.iterator();
        while (it.next()) |entry| entry.value_ptr.*.deref(self.allocator);
        self.symbols.deinit();

        self.allocator.destroy(self);
    }

    pub fn initValue(self: *Self, data: ValueUnion) *Value {
        return Value.init(data, self.allocator);
    }

    pub fn copySymbol(self: *Self, chars: []const u8) *Value {
        const interned = self.symbols.get(chars);
        if (interned) |value| {
            return value.ref();
        }

        const heap_chars = self.allocator.dupe(u8, chars) catch std.debug.panic("Failed to create symbol", .{});
        return self.internSymbol(heap_chars).ref();
    }

    pub fn takeSymbol(self: *Self, chars: []const u8) *Value {
        const interned = self.symbols.get(chars);
        if (interned) |value| {
            self.allocator.free(chars);
            return value.ref();
        }

        return self.internSymbol(chars).ref();
    }

    fn internSymbol(self: *Self, chars: []const u8) *Value {
        const value = self.initValue(.{ .symbol = chars });
        self.symbols.put(chars, value) catch std.debug.panic("Failed to intern symbol", .{});
        return value;
    }

    pub fn interpret(self: *Self, source: []const u8) !*Value {
        const value = compiler_mod.compile(source, self) catch return error.interpret_compile_error;

        if (comptime debug_trace_execution) debug_mod.disassembleChunk(value.as.function.chunk, "script");

        try self.call(value, std.bit_set.IntegerBitSet(8).initEmpty());
        return self.run() catch |e| {
            self.stack_top = 0;
            return e;
        };
    }

    fn push(self: *Self, value: *Value) !void {
        if (self.stack_top == stack_max) return self.runtimeError("Stack overflow.", .{});

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

    fn call(self: *Self, function_value: *Value, arg_indices: std.bit_set.IntegerBitSet(8)) !void {
        const function = function_value.as.function;
        const arg_count = @intCast(u8, arg_indices.count());
        if (arg_count < function.arity) {
            return self.projection(function_value, arg_indices);
        }

        errdefer function_value.deref(self.allocator);
        if (arg_count != function.arity) return self.runtimeError("Expected {d} arguments but got {d}.", .{ function.arity, arg_count });
        if (self.frame_count == frames_max) return self.runtimeError("Stack overflow.", .{});

        const extra_values_needed = function.local_count - arg_count;
        if (extra_values_needed > 0) {
            if (self.stack_top + extra_values_needed >= stack_max) return self.runtimeError("Stack overflow.", .{});

            const starting_index = self.stack_top - arg_count;
            const stack_copy = self.allocator.dupe(*Value, self.stack[starting_index..self.stack_top]) catch return self.runtimeError("Failed to copy stack", .{});
            defer self.allocator.free(stack_copy);

            var i: u8 = 0;
            while (i < extra_values_needed) : (i += 1) {
                self.stack[starting_index + i] = self.initValue(.nil);
            }

            std.mem.copy(*Value, self.stack[starting_index + i ..], stack_copy);
            self.stack_top += extra_values_needed;
        }

        self.frames[self.frame_count] = CallFrame{
            .value = function_value,
            .ip = 0,
            .slots = self.stack[self.stack_top - function.local_count .. self.stack_top],
        };
        self.frame_count += 1;
    }

    fn projection(self: *Self, function_value: *Value, arg_indices: std.bit_set.IntegerBitSet(8)) !void {
        const proj = ValueProjection.init(.{ .arg_indices = arg_indices, .value = function_value.ref() }, self.allocator);

        var it = arg_indices.iterator(.{});
        while (it.next()) |i| proj.arguments[i] = self.pop();

        const value = self.initValue(.{ .projection = proj });
        try self.push(value);
    }

    fn printStack(self: *Self) void {
        print("          ", .{});
        for (self.stack[0..self.stack_top]) |slot| {
            print("[ {} ]", .{slot});
        }
        print("\n", .{});
    }

    fn callValue(self: *Self, callee: *Value, arg_indices: std.bit_set.IntegerBitSet(8)) !void {
        switch (callee.as) {
            .function => try self.call(callee, arg_indices),
            .projection => |proj| {
                var forward_iter = proj.arg_indices.iterator(.{ .kind = .unset });
                var index: u8 = 0;
                while (forward_iter.next()) |i| : (index += 1) {
                    if (arg_indices.isSet(index)) {
                        proj.arguments[i] = self.pop();
                        proj.arg_indices.set(i);
                    }
                }

                var reverse_iter = proj.arg_indices.iterator(.{ .direction = .reverse });
                while (reverse_iter.next()) |i| {
                    try self.push(proj.arguments[i].ref());
                }

                defer callee.deref(self.allocator);
                try self.call(proj.value, proj.arg_indices);
            },
            else => return self.runtimeError("Can only call functions", .{}),
        }
    }

    fn run(self: *Self) !*Value {
        while (true) {
            self.frame = &self.frames[self.frame_count - 1];
            if (comptime debug_trace_execution) {
                self.printStack();
                _ = debug_mod.disassembleInstruction(self.frame.value.as.function.chunk, self.frame.ip);
            }

            const instruction = @intToEnum(OpCode, self.readByte());
            switch (instruction) {
                .op_nil => try self.opNil(),
                .op_constant => try self.opConstant(),
                .op_pop => self.opPop(),
                .op_get_local => try self.opGetLocal(),
                .op_set_local => self.opSetLocal(),
                .op_get_global => try self.opGetGlobal(),
                .op_set_global => try self.opSetGlobal(),
                .op_flip => try self.opFlip(),
                .op_add => try self.opAdd(),
                .op_negate => try self.opNegate(),
                .op_subtract => try self.opSubtract(),
                .op_first => try self.opFirst(),
                .op_multiply => try self.opMultiply(),
                .op_sqrt => try self.opSqrt(),
                .op_divide => try self.opDivide(),
                .op_where => try self.opWhere(),
                .op_min => try self.opMin(),
                .op_reverse => try self.opReverse(),
                .op_max => try self.opMax(),
                .op_ascend => try self.opAscend(),
                .op_less => try self.opLess(),
                .op_descend => try self.opDescend(),
                .op_more => try self.opMore(),
                .op_group => try self.opGroup(),
                .op_equal => try self.opEqual(),
                .op_enlist => try self.opEnlist(),
                .op_merge => try self.opMerge(),
                .op_concat => try self.opConcat(),
                .op_key => try self.opKey(),
                .op_dict => try self.opDict(),
                .op_call => try self.opCall(),
                .op_return => if (try self.opReturn()) |value| return value,
            }
        }
    }

    fn readByte(self: *Self) u8 {
        defer self.frame.ip += 1;
        return self.frame.value.as.function.chunk.code.items[self.frame.ip];
    }

    fn readConstant(self: *Self) *Value {
        return self.frame.value.as.function.chunk.constants.items[self.readByte()];
    }

    fn readSymbol(self: *Self) []const u8 {
        return self.readConstant().as.symbol;
    }

    fn opNil(self: *Self) !void {
        const value = self.initValue(.nil);
        try self.push(value);
    }

    fn opConstant(self: *Self) !void {
        const constant = self.readConstant();
        try self.push(constant.ref());
    }

    fn opPop(self: *Self) void {
        self.pop().deref(self.allocator);
    }

    fn opGetLocal(self: *Self) !void {
        const slot = self.readByte();
        const value = self.frame.slots[self.frame.slots.len - 1 - slot];
        try self.push(value.ref());
    }

    fn opSetLocal(self: *Self) void {
        const index = self.frame.slots.len - 1 - self.readByte();
        self.frame.slots[index].deref(self.allocator);
        self.frame.slots[index] = self.peek(0).ref();
    }

    fn opGetGlobal(self: *Self) !void {
        const name = self.readSymbol();
        const value = self.globals.get(name) orelse return self.runtimeError("Undefined variable '{s}'", .{name});
        try self.push(value.ref());
    }

    fn opSetGlobal(self: *Self) !void {
        const name = self.readSymbol();
        const value = self.peek(0);

        const result = self.globals.getOrPut(name) catch return self.runtimeError("Failed to set global variable '{s}'", .{name});
        if (result.found_existing) {
            result.value_ptr.*.deref(self.allocator);
        }
        result.value_ptr.* = value.ref();
    }

    fn opFlip(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);

        const value = switch (x.as) {
            .list => |list_x| blk: {
                var has_list = false;
                var list_len: usize = 0;
                for (list_x) |value| {
                    switch (value.as) {
                        .list,
                        .boolean_list,
                        .int_list,
                        .float_list,
                        .char_list,
                        .symbol_list,
                        => |inner_list| {
                            if (has_list) {
                                if (list_len != inner_list.len) return self.runtimeError("Can only flip list values of equal length.", .{});
                            } else {
                                has_list = true;
                                list_len = inner_list.len;
                            }
                        },
                        else => {},
                    }
                }
                if (!has_list) return self.runtimeError("Can only flip list values.", .{});
                const value = self.allocator.alloc(*Value, list_len) catch std.debug.panic("Failed to create list.", .{});
                var i: usize = 0;
                while (i < list_len) : (i += 1) {
                    const inner_list = self.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    var list_type: ValueType = switch (list_x[0].as) {
                        .boolean_list => .boolean,
                        .int_list => .int,
                        .float_list => .float,
                        .char_list => .char,
                        .symbol_list => .symbol,
                        else => .list,
                    };
                    for (list_x) |list_value, j| {
                        inner_list[j] = switch (list_value.as) {
                            .nil,
                            .boolean,
                            .int,
                            .float,
                            .char,
                            .symbol,
                            .function,
                            .projection,
                            => list_value.ref(),
                            .list,
                            .boolean_list,
                            .int_list,
                            .float_list,
                            .char_list,
                            .symbol_list,
                            => |inner_list_value| inner_list_value[i].ref(),
                        };
                        if (list_type != .list and list_type != inner_list[j].as) {
                            list_type = .list;
                        }
                    }
                    print("list_type = {}\n", .{list_type});
                    value[i] = switch (list_type) {
                        .boolean => self.initValue(.{ .boolean_list = inner_list }),
                        .int => self.initValue(.{ .int_list = inner_list }),
                        .float => self.initValue(.{ .float_list = inner_list }),
                        .char => self.initValue(.{ .char_list = inner_list }),
                        .symbol => self.initValue(.{ .symbol_list = inner_list }),
                        else => self.initValue(.{ .list = inner_list }),
                    };
                }
                break :blk self.initValue(.{ .list = value });
            },
            else => return self.runtimeError("Can only flip mixed lists.", .{}),
        };
        try self.push(value);
    }

    fn binary(self: *Self, int_fn: BinaryFn(i64, i64), float_fn: BinaryFn(f64, f64), x: *Value, y: *Value) *Value {
        return switch (x.as) {
            .boolean => |bool_x| switch (y.as) {
                .boolean => |bool_y| self.initValue(.{ .int = int_fn(@boolToInt(bool_x), @as(i64, @boolToInt(bool_y))) }),
                .int => |int_y| self.initValue(.{ .int = int_fn(@boolToInt(bool_x), int_y) }),
                .float => |float_y| self.initValue(.{ .float = float_fn(utils_mod.intToFloat(@boolToInt(bool_x)), float_y) }),
                .list => |list_y| blk: {
                    const list = self.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    var list_type: ValueType = switch (list_y[0].as) {
                        .boolean => .int,
                        .int => .int,
                        .float => .float,
                        else => .list,
                    };
                    for (list_y) |value, i| {
                        list[i] = self.binary(int_fn, float_fn, x, value);
                        if (list_type != .list and list_type != list[i].as) list_type = .list;
                    }
                    break :blk self.initValue(switch (list_type) {
                        .int => .{ .int_list = list },
                        .float => .{ .float_list = list },
                        else => .{ .list = list },
                    });
                },
                .boolean_list => |boolean_list_y| blk: {
                    const list = self.allocator.alloc(*Value, boolean_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    for (boolean_list_y) |value, i| {
                        list[i] = self.initValue(.{ .int = int_fn(@boolToInt(bool_x), @as(i64, @boolToInt(value.as.boolean))) });
                    }
                    break :blk self.initValue(.{ .int_list = list });
                },
                .int_list => |int_list_y| blk: {
                    const list = self.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    for (int_list_y) |value, i| {
                        list[i] = self.initValue(.{ .int = int_fn(@boolToInt(bool_x), value.as.int) });
                    }
                    break :blk self.initValue(.{ .int_list = list });
                },
                .float_list => |float_list_y| blk: {
                    const list = self.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    for (float_list_y) |value, i| {
                        list[i] = self.initValue(.{ .float = float_fn(utils_mod.intToFloat(@boolToInt(bool_x)), value.as.float) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                else => unreachable,
            },
            .int => |int_x| switch (y.as) {
                .boolean => |bool_y| self.initValue(.{ .int = int_fn(int_x, @boolToInt(bool_y)) }),
                .int => |int_y| self.initValue(.{ .int = int_fn(int_x, int_y) }),
                .float => |float_y| self.initValue(.{ .float = float_fn(utils_mod.intToFloat(int_x), float_y) }),
                .list => |list_y| blk: {
                    const list = self.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    var list_type: ValueType = switch (list_y[0].as) {
                        .boolean => .int,
                        .int => .int,
                        .float => .float,
                        else => .list,
                    };
                    for (list_y) |value, i| {
                        list[i] = self.binary(int_fn, float_fn, x, value);
                        if (list_type != .list and list_type != list[i].as) list_type = .list;
                    }
                    break :blk self.initValue(switch (list_type) {
                        .int => .{ .int_list = list },
                        .float => .{ .float_list = list },
                        else => .{ .list = list },
                    });
                },
                .boolean_list => |boolean_list_y| blk: {
                    const list = self.allocator.alloc(*Value, boolean_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    for (boolean_list_y) |value, i| {
                        list[i] = self.initValue(.{ .int = int_fn(int_x, @boolToInt(value.as.boolean)) });
                    }
                    break :blk self.initValue(.{ .int_list = list });
                },
                .int_list => |int_list_y| blk: {
                    const list = self.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    for (int_list_y) |value, i| {
                        list[i] = self.initValue(.{ .int = int_fn(int_x, value.as.int) });
                    }
                    break :blk self.initValue(.{ .int_list = list });
                },
                .float_list => |float_list_y| blk: {
                    const list = self.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    for (float_list_y) |value, i| {
                        list[i] = self.initValue(.{ .float = float_fn(utils_mod.intToFloat(int_x), value.as.float) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                else => unreachable,
            },
            .float => |float_x| switch (y.as) {
                .boolean => |bool_y| self.initValue(.{ .float = float_fn(float_x, utils_mod.intToFloat(@boolToInt(bool_y))) }),
                .int => |int_y| self.initValue(.{ .float = float_fn(float_x, utils_mod.intToFloat(int_y)) }),
                .float => |float_y| self.initValue(.{ .float = float_fn(float_x, float_y) }),
                .list => |list_y| blk: {
                    const list = self.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    var list_type: ValueType = switch (list_y[0].as) {
                        .boolean => .float,
                        .int => .float,
                        .float => .float,
                        else => .list,
                    };
                    for (list_y) |value, i| {
                        list[i] = self.binary(int_fn, float_fn, x, value);
                        if (list_type != .list and list_type != list[i].as) list_type = .list;
                    }
                    break :blk self.initValue(switch (list_type) {
                        .float => .{ .float_list = list },
                        else => .{ .list = list },
                    });
                },
                .boolean_list => |boolean_list_y| blk: {
                    const list = self.allocator.alloc(*Value, boolean_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    for (boolean_list_y) |value, i| {
                        list[i] = self.initValue(.{ .float = float_fn(float_x, utils_mod.intToFloat(@boolToInt(value.as.boolean))) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .int_list => |int_list_y| blk: {
                    const list = self.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    for (int_list_y) |value, i| {
                        list[i] = self.initValue(.{ .float = float_fn(float_x, utils_mod.intToFloat(value.as.int)) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .float_list => |float_list_y| blk: {
                    const list = self.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    for (float_list_y) |value, i| {
                        list[i] = self.initValue(.{ .float = float_fn(float_x, value.as.float) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                else => unreachable,
            },
            .list => |list_x| switch (y.as) {
                .boolean, .int => blk: {
                    const list = self.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    var list_type: ValueType = switch (list_x[0].as) {
                        .boolean => .int,
                        .int => .int,
                        .float => .float,
                        else => .list,
                    };
                    for (list_x) |value, i| {
                        list[i] = self.binary(int_fn, float_fn, value, y);
                        if (list_type != .list and list_type != list[i].as) list_type = .list;
                    }
                    break :blk self.initValue(switch (list_type) {
                        .int => .{ .int_list = list },
                        .float => .{ .float_list = list },
                        else => .{ .list = list },
                    });
                },
                .float => blk: {
                    const list = self.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    var list_type: ValueType = switch (list_x[0].as) {
                        .boolean => .float,
                        .int => .float,
                        .float => .float,
                        else => .list,
                    };
                    for (list_x) |value, i| {
                        list[i] = self.binary(int_fn, float_fn, value, y);
                        if (list_type != .list and list_type != list[i].as) list_type = .list;
                    }
                    break :blk self.initValue(switch (list_type) {
                        .float => .{ .float_list = list },
                        else => .{ .list = list },
                    });
                },
                .list,
                .boolean_list,
                .int_list,
                .float_list,
                => |list_y| blk: {
                    const list = self.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    var list_type: ?ValueType = null;
                    for (list_x) |value, i| {
                        list[i] = self.binary(int_fn, float_fn, value, list_y[i]);
                        if (list_type == null and @as(ValueType, list[0].as) != @as(ValueType, list[i].as)) list_type = .list;
                    }
                    break :blk self.initValue(switch (if (list_type) |value_type| value_type else @as(ValueType, list[0].as)) {
                        .int => .{ .int_list = list },
                        .float => .{ .float_list = list },
                        else => .{ .list = list },
                    });
                },
                else => unreachable,
            },
            .boolean_list => |boolean_list_x| switch (y.as) {
                .boolean => |bool_y| blk: {
                    const list = self.allocator.alloc(*Value, boolean_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (boolean_list_x) |value, i| {
                        list[i] = self.initValue(.{ .int = int_fn(@boolToInt(value.as.boolean), @as(i64, @boolToInt(bool_y))) });
                    }
                    break :blk self.initValue(.{ .int_list = list });
                },
                .int => |int_y| blk: {
                    const list = self.allocator.alloc(*Value, boolean_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (boolean_list_x) |value, i| {
                        list[i] = self.initValue(.{ .int = int_fn(@boolToInt(value.as.boolean), int_y) });
                    }
                    break :blk self.initValue(.{ .int_list = list });
                },
                .float => |float_y| blk: {
                    const list = self.allocator.alloc(*Value, boolean_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (boolean_list_x) |value, i| {
                        list[i] = self.initValue(.{ .float = float_fn(utils_mod.intToFloat(@boolToInt(value.as.boolean)), float_y) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .list => |list_y| blk: {
                    const list = self.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    var list_type: ValueType = switch (list_y[0].as) {
                        .boolean => .int,
                        .int => .int,
                        .float => .float,
                        else => .list,
                    };
                    for (boolean_list_x) |value, i| {
                        list[i] = self.binary(int_fn, float_fn, value, list_y[i]);
                        if (list_type != .list and list_type != list[i].as) list_type = .list;
                    }
                    break :blk self.initValue(switch (list_type) {
                        .int => .{ .int_list = list },
                        .float => .{ .float_list = list },
                        else => .{ .list = list },
                    });
                },
                .boolean_list => |boolean_list_y| blk: {
                    const list = self.allocator.alloc(*Value, boolean_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (boolean_list_x) |value, i| {
                        list[i] = self.initValue(.{ .int = int_fn(@boolToInt(value.as.boolean), @as(i64, @boolToInt(boolean_list_y[i].as.boolean))) });
                    }
                    break :blk self.initValue(.{ .int_list = list });
                },
                .int_list => |int_list_y| blk: {
                    const list = self.allocator.alloc(*Value, boolean_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (boolean_list_x) |value, i| {
                        list[i] = self.initValue(.{ .int = int_fn(@boolToInt(value.as.boolean), int_list_y[i].as.int) });
                    }
                    break :blk self.initValue(.{ .int_list = list });
                },
                .float_list => |float_list_y| blk: {
                    const list = self.allocator.alloc(*Value, boolean_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (boolean_list_x) |value, i| {
                        list[i] = self.initValue(.{ .float = float_fn(utils_mod.intToFloat(@boolToInt(value.as.boolean)), float_list_y[i].as.float) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                else => unreachable,
            },
            .int_list => |int_list_x| switch (y.as) {
                .boolean => |bool_y| blk: {
                    const list = self.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (int_list_x) |value, i| {
                        list[i] = self.initValue(.{ .int = int_fn(value.as.int, @boolToInt(bool_y)) });
                    }
                    break :blk self.initValue(.{ .int_list = list });
                },
                .int => |int_y| blk: {
                    const list = self.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (int_list_x) |value, i| {
                        list[i] = self.initValue(.{ .int = int_fn(value.as.int, int_y) });
                    }
                    break :blk self.initValue(.{ .int_list = list });
                },
                .float => |float_y| blk: {
                    const list = self.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (int_list_x) |value, i| {
                        list[i] = self.initValue(.{ .float = float_fn(utils_mod.intToFloat(value.as.int), float_y) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .list => |list_y| blk: {
                    const list = self.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    var list_type: ValueType = switch (list_y[0].as) {
                        .boolean => .int,
                        .int => .int,
                        .float => .float,
                        else => .list,
                    };
                    for (int_list_x) |value, i| {
                        list[i] = self.binary(int_fn, float_fn, value, list_y[i]);
                        if (list_type != .list and list_type != list[i].as) list_type = .list;
                    }
                    break :blk self.initValue(switch (list_type) {
                        .int => .{ .int_list = list },
                        .float => .{ .float_list = list },
                        else => .{ .list = list },
                    });
                },
                .boolean_list => |boolean_list_y| blk: {
                    const list = self.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (int_list_x) |value, i| {
                        list[i] = self.initValue(.{ .int = int_fn(value.as.int, @boolToInt(boolean_list_y[i].as.boolean)) });
                    }
                    break :blk self.initValue(.{ .int_list = list });
                },
                .int_list => |int_list_y| blk: {
                    const list = self.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (int_list_x) |value, i| {
                        list[i] = self.initValue(.{ .int = int_fn(value.as.int, int_list_y[i].as.int) });
                    }
                    break :blk self.initValue(.{ .int_list = list });
                },
                .float_list => |float_list_y| blk: {
                    const list = self.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (int_list_x) |value, i| {
                        list[i] = self.initValue(.{ .float = float_fn(utils_mod.intToFloat(value.as.int), float_list_y[i].as.float) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                else => unreachable,
            },
            .float_list => |float_list_x| switch (y.as) {
                .boolean => |bool_y| blk: {
                    const list = self.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (float_list_x) |value, i| {
                        list[i] = self.initValue(.{ .float = float_fn(value.as.float, utils_mod.intToFloat(@boolToInt(bool_y))) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .int => |int_y| blk: {
                    const list = self.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (float_list_x) |value, i| {
                        list[i] = self.initValue(.{ .float = float_fn(value.as.float, utils_mod.intToFloat(int_y)) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .float => |float_y| blk: {
                    const list = self.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (float_list_x) |value, i| {
                        list[i] = self.initValue(.{ .float = float_fn(value.as.float, float_y) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .list => |list_y| blk: {
                    const list = self.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    var list_type: ValueType = switch (list_y[0].as) {
                        .boolean => .float,
                        .int => .float,
                        .float => .float,
                        else => .list,
                    };
                    for (float_list_x) |value, i| {
                        list[i] = self.binary(int_fn, float_fn, value, list_y[i]);
                        if (list_type != .list and list_type != list[i].as) list_type = .list;
                    }
                    break :blk self.initValue(switch (list_type) {
                        .float => .{ .float_list = list },
                        else => .{ .list = list },
                    });
                },
                .boolean_list => |boolean_list_y| blk: {
                    const list = self.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (float_list_x) |value, i| {
                        list[i] = self.initValue(.{ .float = float_fn(value.as.float, utils_mod.intToFloat(@boolToInt(boolean_list_y[i].as.boolean))) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .int_list => |int_list_y| blk: {
                    const list = self.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (float_list_x) |value, i| {
                        list[i] = self.initValue(.{ .float = float_fn(value.as.float, utils_mod.intToFloat(int_list_y[i].as.int)) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .float_list => |float_list_y| blk: {
                    const list = self.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (float_list_x) |value, i| {
                        list[i] = self.initValue(.{ .float = float_fn(value.as.float, float_list_y[i].as.float) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                else => unreachable,
            },
            else => unreachable,
        };
    }

    fn addInt(x: i64, y: i64) i64 {
        if (x == Value.null_int or y == Value.null_int) return Value.null_int;
        return x +% y;
    }

    fn addFloat(x: f64, y: f64) f64 {
        return x + y;
    }

    fn opAdd(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);
        const y = self.pop();
        defer y.deref(self.allocator);

        // TODO: Check that all nested lists have equal length
        if (!areAllNumericValues(x) or !areAllNumericValues(y)) return self.runtimeError("Can only add numeric values.", .{});
        const value = self.binary(addInt, addFloat, x, y);
        try self.push(value);
    }

    fn opNegate(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);

        const value = switch (x.as) {
            .boolean => |bool_x| self.initValue(.{ .int = if (bool_x) -1 else 0 }),
            .int => |int_x| self.initValue(.{ .int = -int_x }),
            .float => |float_x| self.initValue(.{ .float = -float_x }),
            .boolean_list => |bool_list_x| blk: {
                const list = self.allocator.alloc(*Value, bool_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_x) |value, i| {
                    list[i] = self.initValue(.{ .int = if (value.as.boolean) -1 else 0 });
                }
                break :blk self.initValue(.{ .int_list = list });
            },
            .int_list => |int_list_x| blk: {
                const list = self.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_x) |value, i| {
                    list[i] = self.initValue(.{ .int = -value.as.int });
                }
                break :blk self.initValue(.{ .int_list = list });
            },
            .float_list => |float_list_x| blk: {
                const list = self.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_x) |value, i| {
                    list[i] = self.initValue(.{ .float = -value.as.float });
                }
                break :blk self.initValue(.{ .int_list = list });
            },
            else => return self.runtimeError("Can only negate numeric values.", .{}),
        };
        try self.push(value);
    }

    fn subtractInt(x: i64, y: i64) i64 {
        if (x == Value.null_int or y == Value.null_int) return Value.null_int;
        return x -% y;
    }

    fn subtractFloat(x: f64, y: f64) f64 {
        return x - y;
    }

    fn opSubtract(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);
        const y = self.pop();
        defer y.deref(self.allocator);

        // TODO: Check that all nested lists have equal length
        if (!areAllNumericValues(x) or !areAllNumericValues(y)) return self.runtimeError("Can only add numeric values.", .{});
        const value = self.binary(subtractInt, subtractFloat, x, y);
        try self.push(value);
    }

    fn opFirst(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);

        const value = switch (x.as) {
            .nil, .boolean, .int, .float, .char, .symbol, .function, .projection => x.ref(),
            .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list| list[0].ref(),
        };
        try self.push(value);
    }

    fn multiplyInt(x: i64, y: i64) i64 {
        if (x == Value.null_int or y == Value.null_int) return Value.null_int;
        return x *% y;
    }

    fn multiplyFloat(x: f64, y: f64) f64 {
        return x * y;
    }

    fn opMultiply(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);
        const y = self.pop();
        defer y.deref(self.allocator);

        // TODO: Check that all nested lists have equal length
        if (!areAllNumericValues(x) or !areAllNumericValues(y)) return self.runtimeError("Can only add numeric values.", .{});
        const value = self.binary(multiplyInt, multiplyFloat, x, y);
        try self.push(value);
    }

    fn sqrt(self: *Self, x: *Value) *Value {
        return switch (x.as) {
            .boolean => |bool_x| self.initValue(.{ .float = if (bool_x) 1 else std.math.inf(f64) }),
            .int => |int_x| self.initValue(.{ .float = std.math.sqrt(utils_mod.intToFloat(int_x)) }),
            .float => |float_x| self.initValue(.{ .float = std.math.sqrt(float_x) }),
            .list => |list_x| blk: {
                const list = self.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type = ValueType.float_list;
                for (list_x) |value, i| {
                    const sqrt_value = self.sqrt(value);
                    if (list_type != .list and sqrt_value.as != .float) list_type = .list;
                    list[i] = sqrt_value;
                }
                break :blk self.initValue(if (list_type == .float_list) .{ .float_list = list } else .{ .list = list });
            },
            .boolean_list => |boolean_list_x| blk: {
                const list = self.allocator.alloc(*Value, boolean_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (boolean_list_x) |value, i| {
                    list[i] = self.initValue(.{ .float = if (value.as.boolean) 1 else std.math.inf(f64) });
                }
                break :blk self.initValue(.{ .float_list = list });
            },
            .int_list => |int_list_x| blk: {
                const list = self.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_x) |value, i| {
                    list[i] = self.initValue(.{ .float = std.math.sqrt(utils_mod.intToFloat(value.as.int)) });
                }
                break :blk self.initValue(.{ .float_list = list });
            },
            .float_list => |float_list_x| blk: {
                const list = self.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_x) |value, i| {
                    list[i] = self.initValue(.{ .float = std.math.sqrt(value.as.float) });
                }
                break :blk self.initValue(.{ .float_list = list });
            },
            else => unreachable,
        };
    }

    fn opSqrt(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);

        // Workaround for try self.sqrt(x) with !*Value return type not working as expected
        if (areAllNumericValues(x)) {
            const value = self.sqrt(x);
            try self.push(value);
        } else {
            return self.runtimeError("Can only calculate square root of numeric values.", .{});
        }
    }

    fn divide(self: *Self, x: *Value, y: *Value) *Value {
        return switch (x.as) {
            .boolean => |bool_x| switch (y.as) {
                .boolean => |bool_y| self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(@boolToInt(bool_x)), utils_mod.intToFloat(@boolToInt(bool_y))) }),
                .int => |int_y| self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(@boolToInt(bool_x)), utils_mod.intToFloat(int_y)) }),
                .float => |float_y| self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(@boolToInt(bool_x)), float_y) }),
                .list => |list_y| blk: {
                    const list = self.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    var list_type: ValueType = switch (list_y[0].as) {
                        .boolean, .int, .float => .float,
                        else => .list,
                    };
                    for (list_y) |value, i| {
                        list[i] = self.divide(x, value);
                        if (list_type != .list and list_type != list[i].as) list_type = .list;
                    }
                    break :blk self.initValue(switch (list_type) {
                        .float => .{ .float_list = list },
                        else => .{ .list = list },
                    });
                },
                .boolean_list => |boolean_list_y| blk: {
                    const list = self.allocator.alloc(*Value, boolean_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    for (boolean_list_y) |value, i| {
                        list[i] = self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(@boolToInt(bool_x)), utils_mod.intToFloat(@boolToInt(value.as.boolean))) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .int_list => |int_list_y| blk: {
                    const list = self.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    for (int_list_y) |value, i| {
                        list[i] = self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(@boolToInt(bool_x)), utils_mod.intToFloat(value.as.int)) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .float_list => |float_list_y| blk: {
                    const list = self.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    for (float_list_y) |value, i| {
                        list[i] = self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(@boolToInt(bool_x)), value.as.float) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                else => unreachable,
            },
            .int => |int_x| switch (y.as) {
                .boolean => |bool_y| self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(int_x), utils_mod.intToFloat(@boolToInt(bool_y))) }),
                .int => |int_y| self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(int_x), utils_mod.intToFloat(int_y)) }),
                .float => |float_y| self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(int_x), float_y) }),
                .list => |list_y| blk: {
                    const list = self.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    var list_type: ValueType = switch (list_y[0].as) {
                        .boolean, .int, .float => .float,
                        else => .list,
                    };
                    for (list_y) |value, i| {
                        list[i] = self.divide(x, value);
                        if (list_type != .list and list_type != list[i].as) list_type = .list;
                    }
                    break :blk self.initValue(switch (list_type) {
                        .float => .{ .float_list = list },
                        else => .{ .list = list },
                    });
                },
                .boolean_list => |boolean_list_y| blk: {
                    const list = self.allocator.alloc(*Value, boolean_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    for (boolean_list_y) |value, i| {
                        list[i] = self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(int_x), utils_mod.intToFloat(@boolToInt(value.as.boolean))) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .int_list => |int_list_y| blk: {
                    const list = self.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    for (int_list_y) |value, i| {
                        list[i] = self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(int_x), utils_mod.intToFloat(value.as.int)) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .float_list => |float_list_y| blk: {
                    const list = self.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    for (float_list_y) |value, i| {
                        list[i] = self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(int_x), value.as.float) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                else => unreachable,
            },
            .float => |float_x| switch (y.as) {
                .boolean => |bool_y| self.initValue(.{ .float = divideFloat(float_x, utils_mod.intToFloat(@boolToInt(bool_y))) }),
                .int => |int_y| self.initValue(.{ .float = divideFloat(float_x, utils_mod.intToFloat(int_y)) }),
                .float => |float_y| self.initValue(.{ .float = divideFloat(float_x, float_y) }),
                .list => |list_y| blk: {
                    const list = self.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    var list_type: ValueType = switch (list_y[0].as) {
                        .boolean, .int, .float => .float,
                        else => .list,
                    };
                    for (list_y) |value, i| {
                        list[i] = self.divide(x, value);
                        if (list_type != .list and list_type != list[i].as) list_type = .list;
                    }
                    break :blk self.initValue(switch (list_type) {
                        .float => .{ .float_list = list },
                        else => .{ .list = list },
                    });
                },
                .boolean_list => |boolean_list_y| blk: {
                    const list = self.allocator.alloc(*Value, boolean_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    for (boolean_list_y) |value, i| {
                        list[i] = self.initValue(.{ .float = divideFloat(float_x, utils_mod.intToFloat(@boolToInt(value.as.boolean))) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .int_list => |int_list_y| blk: {
                    const list = self.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    for (int_list_y) |value, i| {
                        list[i] = self.initValue(.{ .float = divideFloat(float_x, utils_mod.intToFloat(value.as.int)) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .float_list => |float_list_y| blk: {
                    const list = self.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    for (float_list_y) |value, i| {
                        list[i] = self.initValue(.{ .float = divideFloat(float_x, value.as.float) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                else => unreachable,
            },
            .list => |list_x| switch (y.as) {
                .boolean, .int => blk: {
                    const list = self.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    var list_type: ValueType = switch (list_x[0].as) {
                        .boolean, .int, .float => .float,
                        else => .list,
                    };
                    for (list_x) |value, i| {
                        list[i] = self.divide(value, y);
                        if (list_type != .list and list_type != list[i].as) list_type = .list;
                    }
                    break :blk self.initValue(switch (list_type) {
                        .float => .{ .float_list = list },
                        else => .{ .list = list },
                    });
                },
                .float => blk: {
                    const list = self.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    var list_type: ValueType = switch (list_x[0].as) {
                        .boolean, .int, .float => .float,
                        else => .list,
                    };
                    for (list_x) |value, i| {
                        list[i] = self.divide(value, y);
                        if (list_type != .list and list_type != list[i].as) list_type = .list;
                    }
                    break :blk self.initValue(switch (list_type) {
                        .float => .{ .float_list = list },
                        else => .{ .list = list },
                    });
                },
                .list,
                .boolean_list,
                .int_list,
                .float_list,
                => |list_y| blk: {
                    const list = self.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    var list_type: ?ValueType = null;
                    for (list_x) |value, i| {
                        list[i] = self.divide(value, list_y[i]);
                        if (list_type == null and @as(ValueType, list[0].as) != @as(ValueType, list[i].as)) list_type = .list;
                    }
                    break :blk self.initValue(switch (if (list_type) |value_type| value_type else @as(ValueType, list[0].as)) {
                        .float => .{ .float_list = list },
                        else => .{ .list = list },
                    });
                },
                else => unreachable,
            },
            .boolean_list => |boolean_list_x| switch (y.as) {
                .boolean => |bool_y| blk: {
                    const list = self.allocator.alloc(*Value, boolean_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (boolean_list_x) |value, i| {
                        list[i] = self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(@boolToInt(value.as.boolean)), utils_mod.intToFloat(@boolToInt(bool_y))) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .int => |int_y| blk: {
                    const list = self.allocator.alloc(*Value, boolean_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (boolean_list_x) |value, i| {
                        list[i] = self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(@boolToInt(value.as.boolean)), utils_mod.intToFloat(int_y)) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .float => |float_y| blk: {
                    const list = self.allocator.alloc(*Value, boolean_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (boolean_list_x) |value, i| {
                        list[i] = self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(@boolToInt(value.as.boolean)), float_y) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .list => |list_y| blk: {
                    const list = self.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    var list_type: ValueType = switch (list_y[0].as) {
                        .boolean, .int, .float => .float,
                        else => .list,
                    };
                    for (boolean_list_x) |value, i| {
                        list[i] = self.divide(value, list_y[i]);
                        if (list_type != .list and list_type != list[i].as) list_type = .list;
                    }
                    break :blk self.initValue(switch (list_type) {
                        .float => .{ .float_list = list },
                        else => .{ .list = list },
                    });
                },
                .boolean_list => |boolean_list_y| blk: {
                    const list = self.allocator.alloc(*Value, boolean_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (boolean_list_x) |value, i| {
                        list[i] = self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(@boolToInt(value.as.boolean)), utils_mod.intToFloat(@boolToInt(boolean_list_y[i].as.boolean))) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .int_list => |int_list_y| blk: {
                    const list = self.allocator.alloc(*Value, boolean_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (boolean_list_x) |value, i| {
                        list[i] = self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(@boolToInt(value.as.boolean)), utils_mod.intToFloat(int_list_y[i].as.int)) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .float_list => |float_list_y| blk: {
                    const list = self.allocator.alloc(*Value, boolean_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (boolean_list_x) |value, i| {
                        list[i] = self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(@boolToInt(value.as.boolean)), float_list_y[i].as.float) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                else => unreachable,
            },
            .int_list => |int_list_x| switch (y.as) {
                .boolean => |bool_y| blk: {
                    const list = self.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (int_list_x) |value, i| {
                        list[i] = self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(value.as.int), utils_mod.intToFloat(@boolToInt(bool_y))) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .int => |int_y| blk: {
                    const list = self.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (int_list_x) |value, i| {
                        list[i] = self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(value.as.int), utils_mod.intToFloat(int_y)) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .float => |float_y| blk: {
                    const list = self.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (int_list_x) |value, i| {
                        list[i] = self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(value.as.int), float_y) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .list => |list_y| blk: {
                    const list = self.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    var list_type: ValueType = switch (list_y[0].as) {
                        .boolean, .int, .float => .float,
                        else => .list,
                    };
                    for (int_list_x) |value, i| {
                        list[i] = self.divide(value, list_y[i]);
                        if (list_type != .list and list_type != list[i].as) list_type = .list;
                    }
                    break :blk self.initValue(switch (list_type) {
                        .float => .{ .float_list = list },
                        else => .{ .list = list },
                    });
                },
                .boolean_list => |boolean_list_y| blk: {
                    const list = self.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (int_list_x) |value, i| {
                        list[i] = self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(value.as.int), utils_mod.intToFloat(@boolToInt(boolean_list_y[i].as.boolean))) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .int_list => |int_list_y| blk: {
                    const list = self.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (int_list_x) |value, i| {
                        list[i] = self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(value.as.int), utils_mod.intToFloat(int_list_y[i].as.int)) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .float_list => |float_list_y| blk: {
                    const list = self.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (int_list_x) |value, i| {
                        list[i] = self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(value.as.int), float_list_y[i].as.float) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                else => unreachable,
            },
            .float_list => |float_list_x| switch (y.as) {
                .boolean => |bool_y| blk: {
                    const list = self.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (float_list_x) |value, i| {
                        list[i] = self.initValue(.{ .float = divideFloat(value.as.float, utils_mod.intToFloat(@boolToInt(bool_y))) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .int => |int_y| blk: {
                    const list = self.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (float_list_x) |value, i| {
                        list[i] = self.initValue(.{ .float = divideFloat(value.as.float, utils_mod.intToFloat(int_y)) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .float => |float_y| blk: {
                    const list = self.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (float_list_x) |value, i| {
                        list[i] = self.initValue(.{ .float = divideFloat(value.as.float, float_y) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .list => |list_y| blk: {
                    const list = self.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    var list_type: ValueType = switch (list_y[0].as) {
                        .boolean, .int, .float => .float,
                        else => .list,
                    };
                    for (float_list_x) |value, i| {
                        list[i] = self.divide(value, list_y[i]);
                        if (list_type != .list and list_type != list[i].as) list_type = .list;
                    }
                    break :blk self.initValue(switch (list_type) {
                        .float => .{ .float_list = list },
                        else => .{ .list = list },
                    });
                },
                .boolean_list => |boolean_list_y| blk: {
                    const list = self.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (float_list_x) |value, i| {
                        list[i] = self.initValue(.{ .float = divideFloat(value.as.float, utils_mod.intToFloat(@boolToInt(boolean_list_y[i].as.boolean))) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .int_list => |int_list_y| blk: {
                    const list = self.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (float_list_x) |value, i| {
                        list[i] = self.initValue(.{ .float = divideFloat(value.as.float, utils_mod.intToFloat(int_list_y[i].as.int)) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .float_list => |float_list_y| blk: {
                    const list = self.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (float_list_x) |value, i| {
                        list[i] = self.initValue(.{ .float = divideFloat(value.as.float, float_list_y[i].as.float) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                else => unreachable,
            },
            else => unreachable,
        };
    }

    fn divideFloat(x: f64, y: f64) f64 {
        return if (std.math.isNan(x) or std.math.isNan(y)) Value.null_float else x / y;
    }

    fn opDivide(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);
        const y = self.pop();
        defer y.deref(self.allocator);

        // TODO: Check that all nested lists have equal length
        if (!areAllNumericValues(x) or !areAllNumericValues(y)) return self.runtimeError("Can only add numeric values.", .{});
        const value = self.divide(x, y);
        try self.push(value);
    }

    fn opWhere(self: *Self) !void {
        _ = self;
    }

    fn minMax(self: *Self, bool_fn: BinaryFn(bool, bool), int_fn: BinaryFn(i64, i64), float_fn: BinaryFn(f64, f64), x: *Value, y: *Value) *Value {
        return switch (x.as) {
            .boolean => |bool_x| switch (y.as) {
                .boolean => |bool_y| self.initValue(.{ .boolean = bool_fn(bool_x, bool_y) }),
                .int => |int_y| self.initValue(.{ .int = int_fn(@boolToInt(bool_x), int_y) }),
                .float => |float_y| self.initValue(.{ .float = float_fn(utils_mod.intToFloat(@boolToInt(bool_x)), float_y) }),
                .list => |list_y| blk: {
                    const list = self.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    var list_type: ?ValueType = null;
                    for (list_y) |value, i| {
                        list[i] = self.minMax(bool_fn, int_fn, float_fn, x, value);
                        if (list_type == null and @as(ValueType, list[0].as) != @as(ValueType, list[i].as)) list_type = .list;
                    }
                    break :blk self.initValue(switch (if (list_type) |list_type_value| list_type_value else @as(ValueType, list[0].as)) {
                        .int => .{ .int_list = list },
                        .float => .{ .float_list = list },
                        else => .{ .list = list },
                    });
                },
                .boolean_list => |bool_list_y| blk: {
                    const list = self.allocator.alloc(*Value, bool_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    for (bool_list_y) |value, i| {
                        list[i] = self.initValue(.{ .boolean = bool_fn(bool_x, value.as.boolean) });
                    }
                    break :blk self.initValue(.{ .boolean_list = list });
                },
                .int_list => |int_list_y| blk: {
                    const list = self.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    for (int_list_y) |value, i| {
                        list[i] = self.initValue(.{ .int = int_fn(@boolToInt(bool_x), value.as.int) });
                    }
                    break :blk self.initValue(.{ .int_list = list });
                },
                .float_list => |float_list_y| blk: {
                    const list = self.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    for (float_list_y) |value, i| {
                        list[i] = self.initValue(.{ .float = float_fn(utils_mod.intToFloat(@boolToInt(bool_x)), value.as.float) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                else => unreachable,
            },
            .int => |int_x| switch (y.as) {
                .boolean => |bool_y| self.initValue(.{ .int = int_fn(int_x, @boolToInt(bool_y)) }),
                .int => |int_y| self.initValue(.{ .int = int_fn(int_x, int_y) }),
                .float => |float_y| self.initValue(.{ .float = float_fn(utils_mod.intToFloat(int_x), float_y) }),
                .list => |list_y| blk: {
                    const list = self.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    var list_type: ?ValueType = null;
                    for (list_y) |value, i| {
                        list[i] = self.minMax(bool_fn, int_fn, float_fn, x, value);
                        if (list_type == null and @as(ValueType, list[0].as) != @as(ValueType, list[i].as)) list_type = .list;
                    }
                    break :blk self.initValue(switch (if (list_type) |list_type_value| list_type_value else @as(ValueType, list[0].as)) {
                        .int => .{ .int_list = list },
                        .float => .{ .float_list = list },
                        else => .{ .list = list },
                    });
                },
                .boolean_list => |bool_list_y| blk: {
                    const list = self.allocator.alloc(*Value, bool_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    for (bool_list_y) |value, i| {
                        list[i] = self.initValue(.{ .int = int_fn(int_x, @boolToInt(value.as.boolean)) });
                    }
                    break :blk self.initValue(.{ .int_list = list });
                },
                .int_list => |int_list_y| blk: {
                    const list = self.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    for (int_list_y) |value, i| {
                        list[i] = self.initValue(.{ .int = int_fn(int_x, value.as.int) });
                    }
                    break :blk self.initValue(.{ .int_list = list });
                },
                .float_list => |float_list_y| blk: {
                    const list = self.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    for (float_list_y) |value, i| {
                        list[i] = self.initValue(.{ .float = float_fn(utils_mod.intToFloat(int_x), value.as.float) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                else => unreachable,
            },
            .float => |float_x| switch (y.as) {
                .boolean => |bool_y| self.initValue(.{ .float = float_fn(float_x, utils_mod.intToFloat(@boolToInt(bool_y))) }),
                .int => |int_y| self.initValue(.{ .float = float_fn(float_x, utils_mod.intToFloat(int_y)) }),
                .float => |float_y| self.initValue(.{ .float = float_fn(float_x, float_y) }),
                .list => |list_y| blk: {
                    const list = self.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    var list_type: ?ValueType = null;
                    for (list_y) |value, i| {
                        list[i] = self.minMax(bool_fn, int_fn, float_fn, x, value);
                        if (list_type == null and @as(ValueType, list[0].as) != @as(ValueType, list[i].as)) list_type = .list;
                    }
                    break :blk self.initValue(switch (if (list_type) |list_type_value| list_type_value else @as(ValueType, list[0].as)) {
                        .float => .{ .float_list = list },
                        else => .{ .list = list },
                    });
                },
                .boolean_list => |bool_list_y| blk: {
                    const list = self.allocator.alloc(*Value, bool_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    for (bool_list_y) |value, i| {
                        list[i] = self.initValue(.{ .float = float_fn(float_x, utils_mod.intToFloat(@boolToInt(value.as.boolean))) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .int_list => |int_list_y| blk: {
                    const list = self.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    for (int_list_y) |value, i| {
                        list[i] = self.initValue(.{ .float = float_fn(float_x, utils_mod.intToFloat(value.as.int)) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .float_list => |float_list_y| blk: {
                    const list = self.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    for (float_list_y) |value, i| {
                        list[i] = self.initValue(.{ .float = float_fn(float_x, value.as.float) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                else => unreachable,
            },
            .list => |list_x| switch (y.as) {
                .boolean, .int, .float => blk: {
                    const list = self.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    var list_type: ?ValueType = null;
                    for (list_x) |value, i| {
                        list[i] = self.minMax(bool_fn, int_fn, float_fn, value, y);
                        if (list_type == null and @as(ValueType, list[0].as) != @as(ValueType, list[i].as)) list_type = .list;
                    }
                    break :blk self.initValue(switch (if (list_type) |list_type_value| list_type_value else @as(ValueType, list[0].as)) {
                        .int => .{ .int_list = list },
                        .float => .{ .float_list = list },
                        else => .{ .list = list },
                    });
                },
                .list, .boolean_list, .int_list, .float_list => |list_y| blk: {
                    const list = self.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    var list_type: ?ValueType = null;
                    for (list_x) |value, i| {
                        list[i] = self.minMax(bool_fn, int_fn, float_fn, value, list_y[i]);
                        if (list_type == null and @as(ValueType, list[0].as) != @as(ValueType, list[i].as)) list_type = .list;
                    }
                    break :blk self.initValue(switch (if (list_type) |list_type_value| list_type_value else @as(ValueType, list[0].as)) {
                        .int => .{ .int_list = list },
                        .float => .{ .float_list = list },
                        else => .{ .list = list },
                    });
                },
                else => unreachable,
            },
            .boolean_list => |bool_list_x| switch (y.as) {
                .boolean => |bool_y| blk: {
                    const list = self.allocator.alloc(*Value, bool_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (bool_list_x) |value, i| {
                        list[i] = self.initValue(.{ .boolean = bool_fn(value.as.boolean, bool_y) });
                    }
                    break :blk self.initValue(.{ .boolean_list = list });
                },
                .int => |int_y| blk: {
                    const list = self.allocator.alloc(*Value, bool_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (bool_list_x) |value, i| {
                        list[i] = self.initValue(.{ .int = int_fn(@boolToInt(value.as.boolean), int_y) });
                    }
                    break :blk self.initValue(.{ .int_list = list });
                },
                .float => |float_y| blk: {
                    const list = self.allocator.alloc(*Value, bool_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (bool_list_x) |value, i| {
                        list[i] = self.initValue(.{ .float = float_fn(utils_mod.intToFloat(@boolToInt(value.as.boolean)), float_y) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .list => |list_y| blk: {
                    const list = self.allocator.alloc(*Value, bool_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    var list_type: ?ValueType = null;
                    for (bool_list_x) |value, i| {
                        list[i] = self.minMax(bool_fn, int_fn, float_fn, value, list_y[i]);
                        if (list_type == null and @as(ValueType, list[0].as) != @as(ValueType, list[i].as)) list_type = .list;
                    }
                    break :blk self.initValue(switch (if (list_type) |list_type_value| list_type_value else @as(ValueType, list[0].as)) {
                        .int => .{ .int_list = list },
                        .float => .{ .float_list = list },
                        else => .{ .list = list },
                    });
                },
                .boolean_list => |bool_list_y| blk: {
                    const list = self.allocator.alloc(*Value, bool_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (bool_list_x) |value, i| {
                        list[i] = self.initValue(.{ .boolean = bool_fn(value.as.boolean, bool_list_y[i].as.boolean) });
                    }
                    break :blk self.initValue(.{ .boolean_list = list });
                },
                .int_list => |int_list_y| blk: {
                    const list = self.allocator.alloc(*Value, bool_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (bool_list_x) |value, i| {
                        list[i] = self.initValue(.{ .int = int_fn(@boolToInt(value.as.boolean), int_list_y[i].as.int) });
                    }
                    break :blk self.initValue(.{ .int_list = list });
                },
                .float_list => |float_list_y| blk: {
                    const list = self.allocator.alloc(*Value, bool_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (bool_list_x) |value, i| {
                        list[i] = self.initValue(.{ .float = float_fn(utils_mod.intToFloat(@boolToInt(value.as.boolean)), float_list_y[i].as.float) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                else => unreachable,
            },
            .int_list => |int_list_x| switch (y.as) {
                .boolean => |bool_y| blk: {
                    const list = self.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (int_list_x) |value, i| {
                        list[i] = self.initValue(.{ .int = int_fn(value.as.int, @boolToInt(bool_y)) });
                    }
                    break :blk self.initValue(.{ .int_list = list });
                },
                .int => |int_y| blk: {
                    const list = self.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (int_list_x) |value, i| {
                        list[i] = self.initValue(.{ .int = int_fn(value.as.int, int_y) });
                    }
                    break :blk self.initValue(.{ .int_list = list });
                },
                .float => |float_y| blk: {
                    const list = self.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (int_list_x) |value, i| {
                        list[i] = self.initValue(.{ .float = float_fn(utils_mod.intToFloat(value.as.int), float_y) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .list => |list_y| blk: {
                    const list = self.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    var list_type: ?ValueType = null;
                    for (int_list_x) |value, i| {
                        list[i] = self.minMax(bool_fn, int_fn, float_fn, value, list_y[i]);
                        if (list_type == null and @as(ValueType, list[0].as) != @as(ValueType, list[i].as)) list_type = .list;
                    }
                    break :blk self.initValue(switch (if (list_type) |list_type_value| list_type_value else @as(ValueType, list[0].as)) {
                        .int => .{ .int_list = list },
                        .float => .{ .float_list = list },
                        else => .{ .list = list },
                    });
                },
                .boolean_list => |bool_list_y| blk: {
                    const list = self.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (int_list_x) |value, i| {
                        list[i] = self.initValue(.{ .int = int_fn(value.as.int, @boolToInt(bool_list_y[i].as.boolean)) });
                    }
                    break :blk self.initValue(.{ .int_list = list });
                },
                .int_list => |int_list_y| blk: {
                    const list = self.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (int_list_x) |value, i| {
                        list[i] = self.initValue(.{ .int = int_fn(value.as.int, int_list_y[i].as.int) });
                    }
                    break :blk self.initValue(.{ .int_list = list });
                },
                .float_list => |float_list_y| blk: {
                    const list = self.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (int_list_x) |value, i| {
                        list[i] = self.initValue(.{ .float = float_fn(utils_mod.intToFloat(value.as.int), float_list_y[i].as.float) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                else => unreachable,
            },
            .float_list => |float_list_x| switch (y.as) {
                .boolean => |bool_y| blk: {
                    const list = self.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (float_list_x) |value, i| {
                        list[i] = self.initValue(.{ .float = float_fn(value.as.float, utils_mod.intToFloat(@boolToInt(bool_y))) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .int => |int_y| blk: {
                    const list = self.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (float_list_x) |value, i| {
                        list[i] = self.initValue(.{ .float = float_fn(value.as.float, utils_mod.intToFloat(int_y)) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .float => |float_y| blk: {
                    const list = self.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (float_list_x) |value, i| {
                        list[i] = self.initValue(.{ .float = float_fn(value.as.float, float_y) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .list => |list_y| blk: {
                    const list = self.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    var list_type: ?ValueType = null;
                    for (float_list_x) |value, i| {
                        list[i] = self.minMax(bool_fn, int_fn, float_fn, value, list_y[i]);
                        if (list_type == null and @as(ValueType, list[0].as) != @as(ValueType, list[i].as)) list_type = .list;
                    }
                    break :blk self.initValue(switch (if (list_type) |list_type_value| list_type_value else @as(ValueType, list[0].as)) {
                        .int => .{ .int_list = list },
                        .float => .{ .float_list = list },
                        else => .{ .list = list },
                    });
                },
                .boolean_list => |bool_list_y| blk: {
                    const list = self.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (float_list_x) |value, i| {
                        list[i] = self.initValue(.{ .float = float_fn(value.as.float, utils_mod.intToFloat(@boolToInt(bool_list_y[i].as.boolean))) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .int_list => |int_list_y| blk: {
                    const list = self.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (float_list_x) |value, i| {
                        list[i] = self.initValue(.{ .float = float_fn(value.as.float, utils_mod.intToFloat(int_list_y[i].as.int)) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                .float_list => |float_list_y| blk: {
                    const list = self.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (float_list_x) |value, i| {
                        list[i] = self.initValue(.{ .float = float_fn(value.as.float, float_list_y[i].as.float) });
                    }
                    break :blk self.initValue(.{ .float_list = list });
                },
                else => unreachable,
            },
            else => unreachable,
        };
    }

    fn minBool(x: bool, y: bool) bool {
        return x and y;
    }

    fn minInt(x: i64, y: i64) i64 {
        return std.math.min(x, y);
    }

    fn minFloat(x: f64, y: f64) f64 {
        if (std.math.isNan(x) or std.math.isNan(y)) return Value.null_float;
        return std.math.min(x, y);
    }

    fn opMin(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);
        const y = self.pop();
        defer y.deref(self.allocator);

        // TODO: Check that all nested lists have equal length
        if (!areAllNumericValues(x) or !areAllNumericValues(y)) return self.runtimeError("Can only add numeric values.", .{});
        const value = self.minMax(minBool, minInt, minFloat, x, y);
        try self.push(value);
    }

    fn opReverse(self: *Self) !void {
        _ = self;
    }

    fn maxBool(x: bool, y: bool) bool {
        return x or y;
    }

    fn maxInt(x: i64, y: i64) i64 {
        return std.math.max(x, y);
    }

    fn maxFloat(x: f64, y: f64) f64 {
        if (std.math.isNan(x)) return y;
        if (std.math.isNan(y)) return x;
        return std.math.max(x, y);
    }

    fn opMax(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);
        const y = self.pop();
        defer y.deref(self.allocator);

        // TODO: Check that all nested lists have equal length
        if (!areAllNumericValues(x) or !areAllNumericValues(y)) return self.runtimeError("Can only add numeric values.", .{});
        const value = self.minMax(maxBool, maxInt, maxFloat, x, y);
        try self.push(value);
    }

    fn opAscend(self: *Self) !void {
        _ = self;
    }

    fn booleanVerb(self: *Self, bool_fn: BinaryFn(bool, bool), int_fn: BinaryFn(i64, bool), float_fn: BinaryFn(f64, bool), x: *Value, y: *Value) *Value {
        return switch (x.as) {
            .boolean => |bool_x| switch (y.as) {
                .boolean => |bool_y| self.initValue(.{ .boolean = bool_fn(bool_x, bool_y) }),
                .int => |int_y| self.initValue(.{ .boolean = int_fn(@boolToInt(bool_x), int_y) }),
                .float => |float_y| self.initValue(.{ .boolean = float_fn(utils_mod.intToFloat(@boolToInt(bool_x)), float_y) }),
                .list => |list_y| blk: {
                    const list = self.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    var list_type: ?ValueType = null;
                    for (list_y) |value, i| {
                        list[i] = self.booleanVerb(bool_fn, int_fn, float_fn, x, value);
                        if (list_type == null and @as(ValueType, list[0].as) != @as(ValueType, list[i].as)) list_type = .list;
                    }
                    break :blk self.initValue(switch (if (list_type) |list_type_value| list_type_value else @as(ValueType, list[0].as)) {
                        .boolean => .{ .boolean_list = list },
                        else => .{ .list = list },
                    });
                },
                .boolean_list => |bool_list_y| blk: {
                    const list = self.allocator.alloc(*Value, bool_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    for (bool_list_y) |value, i| {
                        list[i] = self.initValue(.{ .boolean = bool_fn(bool_x, value.as.boolean) });
                    }
                    break :blk self.initValue(.{ .boolean_list = list });
                },
                .int_list => |int_list_y| blk: {
                    const list = self.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    for (int_list_y) |value, i| {
                        list[i] = self.initValue(.{ .boolean = int_fn(@boolToInt(bool_x), value.as.int) });
                    }
                    break :blk self.initValue(.{ .boolean_list = list });
                },
                .float_list => |float_list_y| blk: {
                    const list = self.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    for (float_list_y) |value, i| {
                        list[i] = self.initValue(.{ .boolean = float_fn(utils_mod.intToFloat(@boolToInt(bool_x)), value.as.float) });
                    }
                    break :blk self.initValue(.{ .boolean_list = list });
                },
                else => unreachable,
            },
            .int => |int_x| switch (y.as) {
                .boolean => |bool_y| self.initValue(.{ .boolean = int_fn(int_x, @boolToInt(bool_y)) }),
                .int => |int_y| self.initValue(.{ .boolean = int_fn(int_x, int_y) }),
                .float => |float_y| self.initValue(.{ .boolean = float_fn(utils_mod.intToFloat(int_x), float_y) }),
                .list => |list_y| blk: {
                    const list = self.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    var list_type: ?ValueType = null;
                    for (list_y) |value, i| {
                        list[i] = self.booleanVerb(bool_fn, int_fn, float_fn, x, value);
                        if (list_type == null and @as(ValueType, list[0].as) != @as(ValueType, list[i].as)) list_type = .list;
                    }
                    break :blk self.initValue(switch (if (list_type) |list_type_value| list_type_value else @as(ValueType, list[0].as)) {
                        .boolean => .{ .boolean_list = list },
                        else => .{ .list = list },
                    });
                },
                .boolean_list => |bool_list_y| blk: {
                    const list = self.allocator.alloc(*Value, bool_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    for (bool_list_y) |value, i| {
                        list[i] = self.initValue(.{ .boolean = int_fn(int_x, @boolToInt(value.as.boolean)) });
                    }
                    break :blk self.initValue(.{ .boolean_list = list });
                },
                .int_list => |int_list_y| blk: {
                    const list = self.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    for (int_list_y) |value, i| {
                        list[i] = self.initValue(.{ .boolean = int_fn(int_x, value.as.int) });
                    }
                    break :blk self.initValue(.{ .boolean_list = list });
                },
                .float_list => |float_list_y| blk: {
                    const list = self.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    for (float_list_y) |value, i| {
                        list[i] = self.initValue(.{ .boolean = float_fn(utils_mod.intToFloat(int_x), value.as.float) });
                    }
                    break :blk self.initValue(.{ .boolean_list = list });
                },
                else => unreachable,
            },
            .float => |float_x| switch (y.as) {
                .boolean => |bool_y| self.initValue(.{ .boolean = float_fn(float_x, utils_mod.intToFloat(@boolToInt(bool_y))) }),
                .int => |int_y| self.initValue(.{ .boolean = float_fn(float_x, utils_mod.intToFloat(int_y)) }),
                .float => |float_y| self.initValue(.{ .boolean = float_fn(float_x, float_y) }),
                .list => |list_y| blk: {
                    const list = self.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    var list_type: ?ValueType = null;
                    for (list_y) |value, i| {
                        list[i] = self.booleanVerb(bool_fn, int_fn, float_fn, x, value);
                        if (list_type == null and @as(ValueType, list[0].as) != @as(ValueType, list[i].as)) list_type = .list;
                    }
                    break :blk self.initValue(switch (if (list_type) |list_type_value| list_type_value else @as(ValueType, list[0].as)) {
                        .boolean => .{ .boolean_list = list },
                        else => .{ .list = list },
                    });
                },
                .boolean_list => |bool_list_y| blk: {
                    const list = self.allocator.alloc(*Value, bool_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    for (bool_list_y) |value, i| {
                        list[i] = self.initValue(.{ .boolean = float_fn(float_x, utils_mod.intToFloat(@boolToInt(value.as.boolean))) });
                    }
                    break :blk self.initValue(.{ .boolean_list = list });
                },
                .int_list => |int_list_y| blk: {
                    const list = self.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    for (int_list_y) |value, i| {
                        list[i] = self.initValue(.{ .boolean = float_fn(float_x, utils_mod.intToFloat(value.as.int)) });
                    }
                    break :blk self.initValue(.{ .boolean_list = list });
                },
                .float_list => |float_list_y| blk: {
                    const list = self.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                    for (float_list_y) |value, i| {
                        list[i] = self.initValue(.{ .boolean = float_fn(float_x, value.as.float) });
                    }
                    break :blk self.initValue(.{ .boolean_list = list });
                },
                else => unreachable,
            },
            .list => |list_x| switch (y.as) {
                .boolean, .int, .float => blk: {
                    const list = self.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    var list_type: ?ValueType = null;
                    for (list_x) |value, i| {
                        list[i] = self.booleanVerb(bool_fn, int_fn, float_fn, value, y);
                        if (list_type == null and @as(ValueType, list[0].as) != @as(ValueType, list[i].as)) list_type = .list;
                    }
                    break :blk self.initValue(switch (if (list_type) |list_type_value| list_type_value else @as(ValueType, list[0].as)) {
                        .boolean => .{ .boolean_list = list },
                        else => .{ .list = list },
                    });
                },
                .list, .boolean_list, .int_list, .float_list => |list_y| blk: {
                    const list = self.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    var list_type: ?ValueType = null;
                    for (list_x) |value, i| {
                        list[i] = self.booleanVerb(bool_fn, int_fn, float_fn, value, list_y[i]);
                        if (list_type == null and @as(ValueType, list[0].as) != @as(ValueType, list[i].as)) list_type = .list;
                    }
                    break :blk self.initValue(switch (if (list_type) |list_type_value| list_type_value else @as(ValueType, list[0].as)) {
                        .boolean => .{ .boolean_list = list },
                        else => .{ .list = list },
                    });
                },
                else => unreachable,
            },
            .boolean_list => |bool_list_x| switch (y.as) {
                .boolean => |bool_y| blk: {
                    const list = self.allocator.alloc(*Value, bool_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (bool_list_x) |value, i| {
                        list[i] = self.initValue(.{ .boolean = bool_fn(value.as.boolean, bool_y) });
                    }
                    break :blk self.initValue(.{ .boolean_list = list });
                },
                .int => |int_y| blk: {
                    const list = self.allocator.alloc(*Value, bool_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (bool_list_x) |value, i| {
                        list[i] = self.initValue(.{ .boolean = int_fn(@boolToInt(value.as.boolean), int_y) });
                    }
                    break :blk self.initValue(.{ .boolean_list = list });
                },
                .float => |float_y| blk: {
                    const list = self.allocator.alloc(*Value, bool_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (bool_list_x) |value, i| {
                        list[i] = self.initValue(.{ .boolean = float_fn(utils_mod.intToFloat(@boolToInt(value.as.boolean)), float_y) });
                    }
                    break :blk self.initValue(.{ .boolean_list = list });
                },
                .list => |list_y| blk: {
                    const list = self.allocator.alloc(*Value, bool_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    var list_type: ?ValueType = null;
                    for (bool_list_x) |value, i| {
                        list[i] = self.booleanVerb(bool_fn, int_fn, float_fn, value, list_y[i]);
                        if (list_type == null and @as(ValueType, list[0].as) != @as(ValueType, list[i].as)) list_type = .list;
                    }
                    break :blk self.initValue(switch (if (list_type) |list_type_value| list_type_value else @as(ValueType, list[0].as)) {
                        .boolean => .{ .boolean_list = list },
                        else => .{ .list = list },
                    });
                },
                .boolean_list => |bool_list_y| blk: {
                    const list = self.allocator.alloc(*Value, bool_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (bool_list_x) |value, i| {
                        list[i] = self.initValue(.{ .boolean = bool_fn(value.as.boolean, bool_list_y[i].as.boolean) });
                    }
                    break :blk self.initValue(.{ .boolean_list = list });
                },
                .int_list => |int_list_y| blk: {
                    const list = self.allocator.alloc(*Value, bool_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (bool_list_x) |value, i| {
                        list[i] = self.initValue(.{ .boolean = int_fn(@boolToInt(value.as.boolean), int_list_y[i].as.int) });
                    }
                    break :blk self.initValue(.{ .boolean_list = list });
                },
                .float_list => |float_list_y| blk: {
                    const list = self.allocator.alloc(*Value, bool_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (bool_list_x) |value, i| {
                        list[i] = self.initValue(.{ .boolean = float_fn(utils_mod.intToFloat(@boolToInt(value.as.boolean)), float_list_y[i].as.float) });
                    }
                    break :blk self.initValue(.{ .boolean_list = list });
                },
                else => unreachable,
            },
            .int_list => |int_list_x| switch (y.as) {
                .boolean => |bool_y| blk: {
                    const list = self.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (int_list_x) |value, i| {
                        list[i] = self.initValue(.{ .boolean = int_fn(value.as.int, @boolToInt(bool_y)) });
                    }
                    break :blk self.initValue(.{ .boolean_list = list });
                },
                .int => |int_y| blk: {
                    const list = self.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (int_list_x) |value, i| {
                        list[i] = self.initValue(.{ .boolean = int_fn(value.as.int, int_y) });
                    }
                    break :blk self.initValue(.{ .boolean_list = list });
                },
                .float => |float_y| blk: {
                    const list = self.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (int_list_x) |value, i| {
                        list[i] = self.initValue(.{ .boolean = float_fn(utils_mod.intToFloat(value.as.int), float_y) });
                    }
                    break :blk self.initValue(.{ .boolean_list = list });
                },
                .list => |list_y| blk: {
                    const list = self.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    var list_type: ?ValueType = null;
                    for (int_list_x) |value, i| {
                        list[i] = self.booleanVerb(bool_fn, int_fn, float_fn, value, list_y[i]);
                        if (list_type == null and @as(ValueType, list[0].as) != @as(ValueType, list[i].as)) list_type = .list;
                    }
                    break :blk self.initValue(switch (if (list_type) |list_type_value| list_type_value else @as(ValueType, list[0].as)) {
                        .boolean => .{ .boolean_list = list },
                        else => .{ .list = list },
                    });
                },
                .boolean_list => |bool_list_y| blk: {
                    const list = self.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (int_list_x) |value, i| {
                        list[i] = self.initValue(.{ .boolean = int_fn(value.as.int, @boolToInt(bool_list_y[i].as.boolean)) });
                    }
                    break :blk self.initValue(.{ .boolean_list = list });
                },
                .int_list => |int_list_y| blk: {
                    const list = self.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (int_list_x) |value, i| {
                        list[i] = self.initValue(.{ .boolean = int_fn(value.as.int, int_list_y[i].as.int) });
                    }
                    break :blk self.initValue(.{ .boolean_list = list });
                },
                .float_list => |float_list_y| blk: {
                    const list = self.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (int_list_x) |value, i| {
                        list[i] = self.initValue(.{ .boolean = float_fn(utils_mod.intToFloat(value.as.int), float_list_y[i].as.float) });
                    }
                    break :blk self.initValue(.{ .boolean_list = list });
                },
                else => unreachable,
            },
            .float_list => |float_list_x| switch (y.as) {
                .boolean => |bool_y| blk: {
                    const list = self.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (float_list_x) |value, i| {
                        list[i] = self.initValue(.{ .boolean = float_fn(value.as.float, utils_mod.intToFloat(@boolToInt(bool_y))) });
                    }
                    break :blk self.initValue(.{ .boolean_list = list });
                },
                .int => |int_y| blk: {
                    const list = self.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (float_list_x) |value, i| {
                        list[i] = self.initValue(.{ .boolean = float_fn(value.as.float, utils_mod.intToFloat(int_y)) });
                    }
                    break :blk self.initValue(.{ .boolean_list = list });
                },
                .float => |float_y| blk: {
                    const list = self.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (float_list_x) |value, i| {
                        list[i] = self.initValue(.{ .boolean = float_fn(value.as.float, float_y) });
                    }
                    break :blk self.initValue(.{ .boolean_list = list });
                },
                .list => |list_y| blk: {
                    const list = self.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    var list_type: ?ValueType = null;
                    for (float_list_x) |value, i| {
                        list[i] = self.booleanVerb(bool_fn, int_fn, float_fn, value, list_y[i]);
                        if (list_type == null and @as(ValueType, list[0].as) != @as(ValueType, list[i].as)) list_type = .list;
                    }
                    break :blk self.initValue(switch (if (list_type) |list_type_value| list_type_value else @as(ValueType, list[0].as)) {
                        .boolean => .{ .boolean_list = list },
                        else => .{ .list = list },
                    });
                },
                .boolean_list => |bool_list_y| blk: {
                    const list = self.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (float_list_x) |value, i| {
                        list[i] = self.initValue(.{ .boolean = float_fn(value.as.float, utils_mod.intToFloat(@boolToInt(bool_list_y[i].as.boolean))) });
                    }
                    break :blk self.initValue(.{ .boolean_list = list });
                },
                .int_list => |int_list_y| blk: {
                    const list = self.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (float_list_x) |value, i| {
                        list[i] = self.initValue(.{ .boolean = float_fn(value.as.float, utils_mod.intToFloat(int_list_y[i].as.int)) });
                    }
                    break :blk self.initValue(.{ .boolean_list = list });
                },
                .float_list => |float_list_y| blk: {
                    const list = self.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                    for (float_list_x) |value, i| {
                        list[i] = self.initValue(.{ .boolean = float_fn(value.as.float, float_list_y[i].as.float) });
                    }
                    break :blk self.initValue(.{ .boolean_list = list });
                },
                else => unreachable,
            },
            else => unreachable,
        };
    }

    fn lessBool(x: bool, y: bool) bool {
        return @boolToInt(x) < @boolToInt(y);
    }

    fn lessInt(x: i64, y: i64) bool {
        return x < y;
    }

    fn lessFloat(x: f64, y: f64) bool {
        if (std.math.isNan(x)) return !std.math.isNan(y);
        return x < y;
    }

    fn opLess(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);
        const y = self.pop();
        defer y.deref(self.allocator);

        // TODO: Check that all nested lists have equal length
        if (!areAllNumericValues(x) or !areAllNumericValues(y)) return self.runtimeError("Can only add numeric values.", .{});
        const value = self.booleanVerb(lessBool, lessInt, lessFloat, x, y);
        try self.push(value);
    }

    fn opDescend(self: *Self) !void {
        _ = self;
    }

    fn moreBool(x: bool, y: bool) bool {
        return @boolToInt(x) > @boolToInt(y);
    }

    fn moreInt(x: i64, y: i64) bool {
        return x > y;
    }

    fn moreFloat(x: f64, y: f64) bool {
        if (std.math.isNan(y)) return !std.math.isNan(x);
        return x > y;
    }

    fn opMore(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);
        const y = self.pop();
        defer y.deref(self.allocator);

        // TODO: Check that all nested lists have equal length
        if (!areAllNumericValues(x) or !areAllNumericValues(y)) return self.runtimeError("Can only add numeric values.", .{});
        const value = self.booleanVerb(moreBool, moreInt, moreFloat, x, y);
        try self.push(value);
    }

    fn opGroup(self: *Self) !void {
        _ = self;
    }

    fn equalBool(x: bool, y: bool) bool {
        return x == y;
    }

    fn equalInt(x: i64, y: i64) bool {
        return x == y;
    }

    fn equalFloat(x: f64, y: f64) bool {
        if (std.math.isNan(x) and std.math.isNan(y)) return true;
        return x == y;
    }

    fn opEqual(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);
        const y = self.pop();
        defer y.deref(self.allocator);

        // TODO: Check that all nested lists have equal length
        if (!areAllNumericValues(x) or !areAllNumericValues(y)) return self.runtimeError("Can only add numeric values.", .{});
        const value = self.booleanVerb(equalBool, equalInt, equalFloat, x, y);
        try self.push(value);
    }

    fn enlist(self: *Self, x: *Value) []*Value {
        const list = self.allocator.alloc(*Value, 1) catch std.debug.panic("Failed to create list.", .{});
        list[0] = x.ref();
        return list;
    }

    fn opEnlist(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);

        const value = switch (x.as) {
            .nil => self.initValue(.{ .list = self.enlist(x) }),
            .boolean => self.initValue(.{ .boolean_list = self.enlist(x) }),
            .int => self.initValue(.{ .int_list = self.enlist(x) }),
            .float => self.initValue(.{ .float_list = self.enlist(x) }),
            .char => self.initValue(.{ .char_list = self.enlist(x) }),
            .symbol => self.initValue(.{ .symbol_list = self.enlist(x) }),
            .list,
            .boolean_list,
            .int_list,
            .float_list,
            .char_list,
            .symbol_list,
            => self.initValue(.{ .list = self.enlist(x) }),
            .function => self.initValue(.{ .list = self.enlist(x) }),
            .projection => self.initValue(.{ .list = self.enlist(x) }),
        };
        try self.push(value);
    }

    fn mergeAtoms(self: *Self, x: *Value, y: *Value) []*Value {
        const list = self.allocator.alloc(*Value, 2) catch std.debug.panic("Failed to create list.", .{});
        list[0] = x.ref();
        list[1] = y.ref();
        return list;
    }

    fn mergeAtomList(self: *Self, x: *Value, y: []*Value) []*Value {
        const list = self.allocator.alloc(*Value, y.len + 1) catch std.debug.panic("Failed to create list.", .{});
        list[0] = x.ref();
        for (y) |value| _ = value.ref();
        std.mem.copy(*Value, list[1..], y);
        return list;
    }

    fn mergeListAtom(self: *Self, x: []*Value, y: *Value) []*Value {
        const list = self.allocator.alloc(*Value, x.len + 1) catch std.debug.panic("Failed to create list.", .{});
        for (x) |value| _ = value.ref();
        std.mem.copy(*Value, list, x);
        list[list.len - 1] = y.ref();
        return list;
    }

    fn mergeLists(self: *Self, x: []*Value, y: []*Value) []*Value {
        const list = self.allocator.alloc(*Value, x.len + y.len) catch std.debug.panic("Failed to create list.", .{});
        for (x) |value| _ = value.ref();
        std.mem.copy(*Value, list, x);
        for (y) |value| _ = value.ref();
        std.mem.copy(*Value, list[x.len..], y);
        return list;
    }

    fn opMerge(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);
        const y = self.pop();
        defer y.deref(self.allocator);

        const value = switch (x.as) {
            .nil => switch (y.as) {
                .nil, .boolean, .int, .float, .char, .symbol, .function, .projection => self.initValue(.{ .list = self.mergeAtoms(x, y) }),
                .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list_y| self.initValue(.{ .list = self.mergeAtomList(x, list_y) }),
            },
            .boolean => switch (y.as) {
                .boolean => self.initValue(.{ .boolean_list = self.mergeAtoms(x, y) }),
                .boolean_list => |list_y| self.initValue(.{ .boolean_list = self.mergeAtomList(x, list_y) }),
                .nil, .int, .float, .char, .symbol, .function, .projection => self.initValue(.{ .list = self.mergeAtoms(x, y) }),
                .list, .int_list, .float_list, .char_list, .symbol_list => |list_y| self.initValue(.{ .list = self.mergeAtomList(x, list_y) }),
            },
            .int => switch (y.as) {
                .int => self.initValue(.{ .int_list = self.mergeAtoms(x, y) }),
                .int_list => |list_y| self.initValue(.{ .int_list = self.mergeAtomList(x, list_y) }),
                .nil, .boolean, .float, .char, .symbol, .function, .projection => self.initValue(.{ .list = self.mergeAtoms(x, y) }),
                .list, .boolean_list, .float_list, .char_list, .symbol_list => |list_y| self.initValue(.{ .list = self.mergeAtomList(x, list_y) }),
            },
            .float => switch (y.as) {
                .float => self.initValue(.{ .float_list = self.mergeAtoms(x, y) }),
                .float_list => |list_y| self.initValue(.{ .float_list = self.mergeAtomList(x, list_y) }),
                .nil, .boolean, .int, .char, .symbol, .function, .projection => self.initValue(.{ .list = self.mergeAtoms(x, y) }),
                .list, .boolean_list, .int_list, .char_list, .symbol_list => |list_y| self.initValue(.{ .list = self.mergeAtomList(x, list_y) }),
            },
            .char => switch (y.as) {
                .char => self.initValue(.{ .char_list = self.mergeAtoms(x, y) }),
                .char_list => |list_y| self.initValue(.{ .char_list = self.mergeAtomList(x, list_y) }),
                .nil, .boolean, .int, .float, .symbol, .function, .projection => self.initValue(.{ .list = self.mergeAtoms(x, y) }),
                .list, .boolean_list, .int_list, .float_list, .symbol_list => |list_y| self.initValue(.{ .list = self.mergeAtomList(x, list_y) }),
            },
            .symbol => switch (y.as) {
                .symbol => self.initValue(.{ .symbol_list = self.mergeAtoms(x, y) }),
                .symbol_list => |list_y| self.initValue(.{ .symbol_list = self.mergeAtomList(x, list_y) }),
                .nil, .boolean, .int, .float, .char, .function, .projection => self.initValue(.{ .list = self.mergeAtoms(x, y) }),
                .list, .boolean_list, .int_list, .float_list, .char_list => |list_y| self.initValue(.{ .list = self.mergeAtomList(x, list_y) }),
            },
            .function => switch (y.as) {
                .nil, .boolean, .int, .float, .char, .symbol, .function, .projection => self.initValue(.{ .list = self.mergeAtoms(x, y) }),
                .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list_y| self.initValue(.{ .list = self.mergeAtomList(x, list_y) }),
            },
            .projection => switch (y.as) {
                .nil, .boolean, .int, .float, .char, .symbol, .function, .projection => self.initValue(.{ .list = self.mergeAtoms(x, y) }),
                .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list_y| self.initValue(.{ .list = self.mergeAtomList(x, list_y) }),
            },
            .list => |list_x| switch (y.as) {
                .nil, .boolean, .int, .float, .char, .symbol, .function, .projection => self.initValue(.{ .list = self.mergeListAtom(list_x, y) }),
                .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list_y| self.initValue(.{ .list = self.mergeLists(list_x, list_y) }),
            },
            .boolean_list => |list_x| switch (y.as) {
                .boolean => self.initValue(.{ .boolean_list = self.mergeListAtom(list_x, y) }),
                .boolean_list => |list_y| self.initValue(.{ .boolean_list = self.mergeLists(list_x, list_y) }),
                .nil, .int, .float, .char, .symbol, .function, .projection => self.initValue(.{ .list = self.mergeListAtom(list_x, y) }),
                .list, .int_list, .float_list, .char_list, .symbol_list => |list_y| self.initValue(.{ .list = self.mergeLists(list_x, list_y) }),
            },
            .int_list => |list_x| switch (y.as) {
                .int => self.initValue(.{ .int_list = self.mergeListAtom(list_x, y) }),
                .int_list => |list_y| self.initValue(.{ .int_list = self.mergeLists(list_x, list_y) }),
                .nil, .boolean, .float, .char, .symbol, .function, .projection => self.initValue(.{ .list = self.mergeListAtom(list_x, y) }),
                .list, .boolean_list, .float_list, .char_list, .symbol_list => |list_y| self.initValue(.{ .list = self.mergeLists(list_x, list_y) }),
            },
            .float_list => |list_x| switch (y.as) {
                .float => self.initValue(.{ .float_list = self.mergeListAtom(list_x, y) }),
                .float_list => |list_y| self.initValue(.{ .float_list = self.mergeLists(list_x, list_y) }),
                .nil, .boolean, .int, .char, .symbol, .function, .projection => self.initValue(.{ .list = self.mergeListAtom(list_x, y) }),
                .list, .boolean_list, .int_list, .char_list, .symbol_list => |list_y| self.initValue(.{ .list = self.mergeLists(list_x, list_y) }),
            },
            .char_list => |list_x| switch (y.as) {
                .char => self.initValue(.{ .char_list = self.mergeListAtom(list_x, y) }),
                .char_list => |list_y| self.initValue(.{ .char_list = self.mergeLists(list_x, list_y) }),
                .nil, .boolean, .int, .float, .symbol, .function, .projection => self.initValue(.{ .list = self.mergeListAtom(list_x, y) }),
                .list, .boolean_list, .int_list, .float_list, .symbol_list => |list_y| self.initValue(.{ .list = self.mergeLists(list_x, list_y) }),
            },
            .symbol_list => |list_x| switch (y.as) {
                .symbol => self.initValue(.{ .symbol_list = self.mergeListAtom(list_x, y) }),
                .symbol_list => |list_y| self.initValue(.{ .symbol_list = self.mergeLists(list_x, list_y) }),
                .nil, .boolean, .int, .float, .char, .function, .projection => self.initValue(.{ .list = self.mergeListAtom(list_x, y) }),
                .list, .boolean_list, .int_list, .float_list, .char_list => |list_y| self.initValue(.{ .list = self.mergeLists(list_x, list_y) }),
            },
        };
        try self.push(value);
    }

    fn concat(self: *Self, x: *Value, y: *Value) []*Value {
        const list = self.allocator.alloc(*Value, 2) catch std.debug.panic("Failed to create list.", .{});
        list[0] = x.ref();
        list[1] = y.ref();
        return list;
    }

    fn opConcat(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);
        const y = self.pop();
        defer y.deref(self.allocator);

        const value = switch (x.as) {
            .nil => switch (y.as) {
                .nil, .boolean, .int, .float, .char, .symbol, .function, .projection => self.initValue(.{ .list = self.mergeAtoms(x, y) }),
                .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => self.initValue(.{ .list = self.concat(x, y) }),
            },
            .boolean => switch (y.as) {
                .boolean => self.initValue(.{ .boolean_list = self.mergeAtoms(x, y) }),
                .nil, .int, .float, .char, .symbol, .function, .projection => self.initValue(.{ .list = self.mergeAtoms(x, y) }),
                .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => self.initValue(.{ .list = self.concat(x, y) }),
            },
            .int => switch (y.as) {
                .int => self.initValue(.{ .int_list = self.mergeAtoms(x, y) }),
                .nil, .boolean, .float, .char, .symbol, .function, .projection => self.initValue(.{ .list = self.mergeAtoms(x, y) }),
                .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => self.initValue(.{ .list = self.concat(x, y) }),
            },
            .float => switch (y.as) {
                .float => self.initValue(.{ .float_list = self.mergeAtoms(x, y) }),
                .nil, .boolean, .int, .char, .symbol, .function, .projection => self.initValue(.{ .list = self.mergeAtoms(x, y) }),
                .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => self.initValue(.{ .list = self.concat(x, y) }),
            },
            .char => switch (y.as) {
                .char => self.initValue(.{ .char_list = self.mergeAtoms(x, y) }),
                .nil, .boolean, .int, .float, .symbol, .function, .projection => self.initValue(.{ .list = self.mergeAtoms(x, y) }),
                .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => self.initValue(.{ .list = self.concat(x, y) }),
            },
            .symbol => switch (y.as) {
                .symbol => self.initValue(.{ .symbol_list = self.mergeAtoms(x, y) }),
                .nil, .boolean, .int, .float, .char, .function, .projection => self.initValue(.{ .list = self.mergeAtoms(x, y) }),
                .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => self.initValue(.{ .list = self.concat(x, y) }),
            },
            .list,
            .boolean_list,
            .int_list,
            .float_list,
            .char_list,
            .symbol_list,
            => switch (y.as) {
                .nil, .boolean, .int, .float, .char, .symbol, .function, .projection => self.initValue(.{ .list = self.concat(x, y) }),
                .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => self.initValue(.{ .list = self.concat(x, y) }),
            },
            .function => switch (y.as) {
                .nil, .boolean, .int, .float, .char, .symbol, .function, .projection => self.initValue(.{ .list = self.mergeAtoms(x, y) }),
                .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => self.initValue(.{ .list = self.concat(x, y) }),
            },
            .projection => switch (y.as) {
                .nil, .boolean, .int, .float, .char, .symbol, .function, .projection => self.initValue(.{ .list = self.mergeAtoms(x, y) }),
                .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => self.initValue(.{ .list = self.concat(x, y) }),
            },
        };
        try self.push(value);
    }

    fn opKey(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);

        const value = switch (x.as) {
            .int => |int_x| blk: {
                const list = self.allocator.alloc(*Value, std.math.absCast(int_x)) catch std.debug.panic("Failed to create list.", .{});
                if (int_x < 0) {
                    for (list) |_, i| {
                        list[i] = self.initValue(.{ .int = int_x + @intCast(i64, i) });
                    }
                } else {
                    for (list) |_, i| {
                        list[i] = self.initValue(.{ .int = @intCast(i64, i) });
                    }
                }
                break :blk self.initValue(.{ .int_list = list });
            },
            else => unreachable,
        };
        try self.push(value);
    }

    fn opDict(self: *Self) !void {
        _ = self;
    }

    fn opCall(self: *Self) !void {
        const func = self.pop();

        const arg_indices = std.bit_set.IntegerBitSet(8){ .mask = self.readByte() };
        try self.callValue(func, arg_indices);
    }

    fn opReturn(self: *Self) !?*Value {
        const result = self.pop();

        self.frame.value.deref(self.allocator);

        self.frame_count -= 1;
        if (self.frame_count == 0) return result;

        for (self.frame.slots) |value| value.deref(self.allocator);
        self.stack_top -= self.frame.slots.len;

        try self.push(result);
        return null;
    }

    fn runtimeError(self: *Self, comptime format: []const u8, args: anytype) !void {
        print(format ++ "\n", args);

        var i = self.frame_count;
        while (i > 0) {
            i -= 1;
            var frame = self.frames[i];
            const token = frame.value.as.function.chunk.tokens.items[frame.ip];
            print("[line {d}] in {}\n", .{ token.line, frame.value });
            if (i > 0) print("at '{s}'\n", .{token.lexeme});
        }

        while (self.stack_top > 0) {
            self.pop().deref(self.allocator);
        }

        while (self.frame_count > 0) : (self.frame_count -= 1) {
            self.frames[self.frame_count - 1].value.deref(self.allocator);
        }

        return error.interpret_runtime_error;
    }

    fn runtimeErrorValue(_: *Self, comptime format: []const u8, args: anytype) !*Value {
        print(format ++ "\n", args);

        return error.interpret_runtime_error;
    }
};

fn areAllNumericValues(x: *Value) bool {
    return switch (x.as) {
        .boolean, .int, .float, .boolean_list, .int_list, .float_list => true,
        .list => |list| {
            for (list) |value| {
                if (!areAllNumericValues(value)) return false;
            }
            return true;
        },
        else => false,
    };
}
