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
const ValueTable = value_mod.ValueTable;
const ValueType = value_mod.ValueType;
const ValueUnion = value_mod.ValueUnion;

const verbs = @import("verbs.zig");

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

    pub fn initNull(self: *Self, value_type: ValueType) *Value {
        return switch (value_type) {
            .nil => self.initValue(.nil),
            .boolean, .boolean_list => self.initValue(.{ .boolean = false }),
            .int, .int_list => self.initValue(.{ .int = Value.null_int }),
            .float, .float_list => self.initValue(.{ .float = Value.null_float }),
            .char, .char_list => self.initValue(.{ .char = ' ' }),
            .symbol, .symbol_list => self.copySymbol(""),
            .list => self.initValue(.{ .list = &[_]*Value{} }),
            else => unreachable,
        };
    }

    pub fn initValue(self: *Self, data: ValueUnion) *Value {
        return Value.init(.{ .data = data }, self.allocator);
    }

    pub fn initValueWithRefCount(self: *Self, reference_count: u32, data: ValueUnion) *Value {
        return Value.init(.{ .reference_count = reference_count, .data = data }, self.allocator);
    }

    pub fn initList(self: *Self, list: []*Value, list_type: ?ValueType) *Value {
        return self.initValue(switch (if (list_type) |list_value_type| list_value_type else @as(ValueType, list[0].as)) {
            .boolean, .boolean_list => .{ .boolean_list = list },
            .int, .int_list => .{ .int_list = list },
            .float, .float_list => .{ .float_list = list },
            .char, .char_list => .{ .char_list = list },
            .symbol, .symbol_list => .{ .symbol_list = list },
            else => .{ .list = list },
        });
    }

    pub fn initListAtoms(self: *Self, list: []*Value, list_type: ?ValueType) *Value {
        return self.initValue(switch (if (list_type) |list_value_type| list_value_type else @as(ValueType, list[0].as)) {
            .boolean => .{ .boolean_list = list },
            .int => .{ .int_list = list },
            .float => .{ .float_list = list },
            .char => .{ .char_list = list },
            .symbol => .{ .symbol_list = list },
            else => .{ .list = list },
        });
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

        if (comptime debug_mod.debug_trace_execution) debug_mod.disassembleChunk(value.as.function.chunk, "script");

        try self.call(value, std.bit_set.IntegerBitSet(8).initEmpty());
        return self.run() catch |e| {
            self.reset();
            return e;
        };
    }

    fn reset(self: *Self) void {
        while (self.stack_top > 0) {
            self.pop().deref(self.allocator);
        }

        while (self.frame_count > 0) : (self.frame_count -= 1) {
            self.frames[self.frame_count - 1].value.deref(self.allocator);
        }
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
        const proj = ValueProjection.init(.{ .arg_indices = arg_indices, .value = function_value }, self.allocator);

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

    fn run(self: *Self) !*Value {
        while (true) {
            self.frame = &self.frames[self.frame_count - 1];
            if (comptime debug_mod.debug_trace_execution) {
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
                .op_concat => try self.opConcat(),
                .op_flip => try self.opFlip(),
                .op_add => try self.opAdd(),
                .op_negate => try self.opNegate(),
                .op_subtract => try self.opSubtract(),
                .op_first => try self.opFirst(),
                .op_multiply => try self.opMultiply(),
                .op_sqrt => try self.opSqrt(),
                .op_divide => try self.opDivide(),
                .op_key => try self.opKey(),
                .op_dict => try self.opDict(),
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
                .op_not => try self.opNot(),
                .op_match => try self.opMatch(),
                .op_enlist => try self.opEnlist(),
                .op_merge => try self.opMerge(),
                .op_null => try self.opNull(),
                .op_fill => try self.opFill(),
                .op_length => try self.opLength(),
                .op_take => try self.opTake(),
                .op_floor => try self.opFloor(),
                .op_drop => try self.opDrop(),
                .op_string => try self.opString(),
                .op_cast => try self.opCast(),
                .op_unique => try self.opUnique(),
                .op_find => try self.opFind(),
                .op_type => try self.opType(),
                .op_apply_1 => try self.opApply1(),
                .op_value => try self.opValue(),
                .op_apply_n => try self.opApplyN(),
                .op_call => try self.opCall(),
                .op_return => if (try self.opReturn()) |value| return value,
            }
        }
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
            .boolean => switch (y.as) {
                .boolean => self.initValue(.{ .boolean_list = self.concat(x, y) }),
                else => self.initValue(.{ .list = self.concat(x, y) }),
            },
            .int => switch (y.as) {
                .int => self.initValue(.{ .int_list = self.concat(x, y) }),
                else => self.initValue(.{ .list = self.concat(x, y) }),
            },
            .float => switch (y.as) {
                .float => self.initValue(.{ .float_list = self.concat(x, y) }),
                else => self.initValue(.{ .list = self.concat(x, y) }),
            },
            .char => switch (y.as) {
                .char => self.initValue(.{ .char_list = self.concat(x, y) }),
                else => self.initValue(.{ .list = self.concat(x, y) }),
            },
            .symbol => switch (y.as) {
                .symbol => self.initValue(.{ .symbol_list = self.concat(x, y) }),
                else => self.initValue(.{ .list = self.concat(x, y) }),
            },
            .dictionary => |dict_x| switch (y.as) {
                .dictionary => |dict_y| blk: {
                    if (dict_x.key.as != .symbol_list or dict_x.key.as != .symbol_list or !dict_x.key.eql(dict_y.key)) break :blk self.initValue(.{ .list = self.concat(x, y) });

                    const columns = dict_x.key.ref();
                    const values = self.initValue(.{ .list = self.concat(dict_x.value, dict_y.value) });
                    const table = ValueTable.init(.{ .columns = columns, .values = values }, self.allocator);
                    break :blk self.initValue(.{ .table = table });
                },
                else => self.initValue(.{ .list = self.concat(x, y) }),
            },
            .nil,
            .list,
            .boolean_list,
            .int_list,
            .float_list,
            .char_list,
            .symbol_list,
            .table,
            .function,
            .projection,
            => self.initValue(.{ .list = self.concat(x, y) }),
        };
        try self.push(value);
    }

    fn opFlip(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);

        const value = try verbs.flip(self, x);
        try self.push(value);
    }

    fn opAdd(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);
        const y = self.pop();
        defer y.deref(self.allocator);

        const value = try verbs.add(self, x, y);
        try self.push(value);
    }

    fn opNegate(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);

        const value = try verbs.negate(self, x);
        try self.push(value);
    }

    fn opSubtract(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);
        const y = self.pop();
        defer y.deref(self.allocator);

        const value = try verbs.subtract(self, x, y);
        try self.push(value);
    }

    fn opFirst(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);

        const value = verbs.first(self, x);
        try self.push(value);
    }

    fn opMultiply(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);
        const y = self.pop();
        defer y.deref(self.allocator);

        const value = try verbs.multiply(self, x, y);
        try self.push(value);
    }

    fn opSqrt(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);

        const value = try verbs.sqrt(self, x);
        try self.push(value);
    }

    fn opDivide(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);
        const y = self.pop();
        defer y.deref(self.allocator);

        const value = try verbs.divide(self, x, y);
        try self.push(value);
    }

    fn opKey(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);

        const value = switch (x.as) {
            .int => try verbs.til(self, x),
            .dictionary => |dict| dict.key.ref(),
            else => unreachable,
        };
        try self.push(value);
    }

    fn opDict(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);

        const y = self.pop();
        defer y.deref(self.allocator);

        const value = try verbs.dict(self, x, y);
        try self.push(value);
    }

    fn opWhere(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);

        const value = try verbs.where(self, x);
        try self.push(value);
    }

    fn opMin(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);
        const y = self.pop();
        defer y.deref(self.allocator);

        const value = try verbs.min(self, x, y);
        try self.push(value);
    }

    fn opReverse(self: *Self) !void {
        return self.monadicVerb();
    }

    fn opMax(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);
        const y = self.pop();
        defer y.deref(self.allocator);

        const value = try verbs.max(self, x, y);
        try self.push(value);
    }

    fn opAscend(self: *Self) !void {
        return self.monadicVerb();
    }

    fn opLess(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);
        const y = self.pop();
        defer y.deref(self.allocator);

        const value = try verbs.less(self, x, y);
        try self.push(value);
    }

    fn opDescend(self: *Self) !void {
        return self.monadicVerb();
    }

    fn opMore(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);
        const y = self.pop();
        defer y.deref(self.allocator);

        const value = try verbs.more(self, x, y);
        try self.push(value);
    }

    fn opGroup(self: *Self) !void {
        return self.monadicVerb();
    }

    fn opEqual(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);
        const y = self.pop();
        defer y.deref(self.allocator);

        const value = try verbs.equal(self, x, y);
        try self.push(value);
    }

    fn opNot(self: *Self) !void {
        return self.monadicVerb();
    }

    fn opMatch(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);
        const y = self.pop();
        defer y.deref(self.allocator);

        const value = try verbs.match(self, x, y);
        try self.push(value);
    }

    fn opEnlist(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);

        const value = try verbs.enlist(self, x);
        try self.push(value);
    }

    fn opMerge(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);
        const y = self.pop();
        defer y.deref(self.allocator);

        const value = try verbs.merge(self, x, y);
        try self.push(value);
    }

    fn opNull(self: *Self) !void {
        return self.monadicVerb();
    }

    fn opFill(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);
        const y = self.pop();
        defer y.deref(self.allocator);

        const value = try verbs.fill(self, x, y);
        try self.push(value);
    }

    fn opLength(self: *Self) !void {
        return self.monadicVerb();
    }

    fn opTake(self: *Self) !void {
        return self.dyadicVerb();
    }

    fn opFloor(self: *Self) !void {
        return self.monadicVerb();
    }

    fn opDrop(self: *Self) !void {
        return self.dyadicVerb();
    }

    fn opString(self: *Self) !void {
        return self.monadicVerb();
    }

    fn opCast(self: *Self) !void {
        return self.dyadicVerb();
    }

    fn opUnique(self: *Self) !void {
        return self.monadicVerb();
    }

    fn opFind(self: *Self) !void {
        return self.dyadicVerb();
    }

    fn opType(self: *Self) !void {
        return self.monadicVerb();
    }

    fn opApply1(self: *Self) !void {
        var x = self.pop();
        errdefer x.deref(self.allocator);
        if (x.as == .symbol) {
            const global = self.globals.get(x.as.symbol) orelse return self.runtimeError("Undefined variable '{s}'", .{x.as.symbol});
            x.deref(self.allocator);
            x = global.ref();
        }

        if (x.as == .function or x.as == .projection) {
            try self.callValue(x, std.bit_set.IntegerBitSet(8){ .mask = 1 });
            return;
        }

        const y = self.pop();
        defer y.deref(self.allocator);

        const value = try verbs.index(self, x, y);
        x.deref(self.allocator);
        try self.push(value);
    }

    fn opValue(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);

        const value = switch (x.as) {
            .dictionary => |dict| dict.value.ref(),
            else => unreachable,
        };
        try self.push(value);
    }

    fn opApplyN(self: *Self) !void {
        var x = self.pop();
        errdefer x.deref(self.allocator);
        if (x.as == .symbol) {
            const global = self.globals.get(x.as.symbol) orelse return self.runtimeError("Undefined variable '{s}'", .{x.as.symbol});
            x.deref(self.allocator);
            x = global.ref();
        }

        const y = self.pop();
        defer y.deref(self.allocator);

        if (x.as == .function or x.as == .projection) {
            switch (y.as) {
                .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list| {
                    const arity = switch (x.as) {
                        .function => |func| func.arity,
                        .projection => |proj| proj.value.as.function.arity - proj.arg_indices.count(),
                        else => unreachable,
                    };
                    if (arity < list.len) return self.runtimeError("Too many arguments", .{});

                    var arg_indices = std.bit_set.IntegerBitSet(8).initEmpty();
                    arg_indices.setRangeValue(.{ .start = 0, .end = list.len }, true);
                    var i: usize = list.len;
                    while (i > 0) : (i -= 1) {
                        try self.push(list[i - 1].ref());
                    }
                    try self.callValue(x, arg_indices);
                },
                else => return self.runtimeError("Can only apply list arguments", .{}),
            }
            return;
        }

        const value = try verbs.index(self, x, y);
        x.deref(self.allocator);
        try self.push(value);
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

    fn monadicVerb(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);

        try self.push(self.initValue(.nil));
    }

    fn dyadicVerb(self: *Self) !void {
        const x = self.pop();
        defer x.deref(self.allocator);
        const y = self.pop();
        defer y.deref(self.allocator);

        try self.push(self.initValue(.nil));
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

        self.reset();

        return error.interpret_runtime_error;
    }
};
