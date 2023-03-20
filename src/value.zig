const std = @import("std");

const chunk_mod = @import("chunk.zig");
const Chunk = chunk_mod.Chunk;

const debug_mod = @import("debug.zig");

const utils_mod = @import("utils.zig");
const print = utils_mod.print;

const vm_mod = @import("vm.zig");
const VM = vm_mod.VM;

pub const ValueType = enum {
    nil,
    list,
    boolean,
    boolean_list,
    int,
    int_list,
    float,
    float_list,
    char,
    char_list,
    symbol,
    symbol_list,
    dictionary,
    table,
    function,
    projection,
};

pub const ValueUnion = union(ValueType) {
    const Self = @This();

    nil,
    boolean: bool,
    int: i64,
    float: f64,
    char: u8,
    symbol: []const u8,

    list: []*Value,

    boolean_list: []*Value,
    int_list: []*Value,
    float_list: []*Value,
    char_list: []*Value,
    symbol_list: []*Value,

    dictionary: *ValueDictionary,
    table: *ValueTable,

    function: *ValueFunction,
    projection: *ValueProjection,

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        switch (self) {
            .nil => try writer.writeAll("(::)"),
            .boolean => |boolean| try writer.writeAll(if (boolean) "1b" else "0b"),
            .int => |int| try printInt(writer, int),
            .float => |float| if (try printFloat(writer, float)) try writer.writeAll("f"),
            .char => |char| {
                try writer.writeAll("\"");
                try printChar(writer, char);
                try writer.writeAll("\"");
            },
            .symbol => |symbol| try writer.print("`{s}", .{symbol}),
            .list => |list| {
                if (list.len == 0) {
                    try writer.writeAll("()");
                } else if (list.len == 1) {
                    try writer.print(",{}", .{list[0].as});
                } else {
                    try writer.writeAll("(");
                    for (list[0 .. list.len - 1]) |value| try writer.print("{};", .{value.as});
                    try writer.print("{})", .{list[list.len - 1].as});
                }
            },
            .boolean_list => |list| {
                if (list.len == 0) {
                    try writer.writeAll("`boolean$()");
                    return;
                }
                if (list.len == 1) try writer.writeAll(",");
                for (list) |value| try writer.writeAll(if (value.as.boolean) "1" else "0");
                try writer.writeAll("b");
            },
            .int_list => |list| {
                if (list.len == 0) {
                    try writer.writeAll("`int$()");
                    return;
                }
                if (list.len == 1) try writer.writeAll(",");
                for (list[0 .. list.len - 1]) |value| {
                    try printInt(writer, value.as.int);
                    try writer.writeAll(" ");
                }
                try printInt(writer, list[list.len - 1].as.int);
            },
            .float_list => |list| {
                if (list.len == 0) {
                    try writer.writeAll("`float$()");
                    return;
                }
                var needs_suffix = true;
                if (list.len == 1) try writer.writeAll(",");
                for (list[0 .. list.len - 1]) |value| {
                    if (!try printFloat(writer, value.as.float)) needs_suffix = false;
                    try writer.writeAll(" ");
                }
                if (try printFloat(writer, list[list.len - 1].as.float) and needs_suffix) try writer.writeAll("f");
            },
            .char_list => |list| {
                if (list.len == 1) try writer.writeAll(",");
                try writer.writeAll("\"");
                for (list) |value| try printChar(writer, value.as.char);
                try writer.writeAll("\"");
            },
            .symbol_list => |list| {
                if (list.len == 0) {
                    try writer.writeAll("`symbol$()");
                    return;
                }
                if (list.len == 1) try writer.writeAll(",");
                for (list) |value| try writer.print("`{s}", .{value.as.symbol});
            },
            .dictionary => |dict| try writer.print("{}!{}", .{ dict.keys.as, dict.values.as }),
            .table => |table| try writer.print("+{}!{}", .{ table.columns.as, table.values.as }),
            .function => |function| if (function.name) |name| try writer.print("{s}", .{name}) else try writer.writeAll("script"),
            .projection => |projection| {
                const function = projection.value.as.function;
                try writer.print("{s}[", .{function.name.?});

                var i: u8 = 0;
                while (i < function.arity - 1) : (i += 1) {
                    if (projection.arg_indices.isSet(i)) {
                        try writer.print("{};", .{projection.arguments[i].as});
                    } else {
                        try writer.writeAll(";");
                    }
                }

                if (projection.arg_indices.isSet(i)) {
                    try writer.print("{}]", .{projection.arguments[i].as});
                } else {
                    try writer.writeAll("]");
                }
            },
        }
    }

    fn printInt(writer: anytype, int: i64) !void {
        if (int == Value.null_int) {
            try writer.writeAll("0N");
        } else if (int == -Value.inf_int) {
            try writer.writeAll("-0W");
        } else if (int == Value.inf_int) {
            try writer.writeAll("0W");
        } else {
            try writer.print("{d}", .{int});
        }
    }

    fn printFloat(writer: anytype, float: f64) !bool {
        if (std.math.isNan(float)) {
            try writer.writeAll("0n");
            return false;
        } else if (float == -Value.inf_float) {
            try writer.writeAll("-0w");
            return false;
        } else if (float == Value.inf_float) {
            try writer.writeAll("0w");
            return false;
        } else {
            try writer.print("{d}", .{float});
            return true;
        }
    }

    fn printChar(writer: anytype, char: u8) !void {
        switch (char) {
            '\\' => try writer.writeAll("\\\\"),
            '"' => try writer.writeAll("\\\""),
            else => try writer.print("{c}", .{char}),
        }
    }
};

pub const Value = struct {
    const Self = @This();

    const Config = struct {
        reference_count: u32 = 1,
        data: ValueUnion,
    };

    pub const null_int = -9223372036854775808;
    pub const inf_int = 9223372036854775807;

    pub const null_float = std.math.nan(f64);
    pub const inf_float = std.math.inf(f64);

    reference_count: u32,
    as: ValueUnion,

    pub fn init(config: Config, allocator: std.mem.Allocator) *Self {
        const self = allocator.create(Self) catch std.debug.panic("Failed to create value.", .{});
        self.* = Self{
            .reference_count = config.reference_count,
            .as = config.data,
        };
        if (debug_mod.debug_show_memory_allocations) print("init value {}\n", .{self});
        return self;
    }

    pub fn copyNull(self: *Self, vm: *VM) *Self {
        return switch (self.as) {
            .nil => vm.initValue(.nil),
            .boolean => vm.initValue(.{ .boolean = false }),
            .int => vm.initValue(.{ .int = Value.null_int }),
            .float => vm.initValue(.{ .float = Value.null_float }),
            .char => vm.initValue(.{ .char = ' ' }),
            .symbol => vm.copySymbol(""),
            .list => |list_self| blk: {
                const list = vm.allocator.alloc(*Value, 1) catch std.debug.panic("Failed to create list.", .{});
                list[0] = list_self[0].copyNull(vm);
                break :blk vm.initValue(.{ .list = list });
            },
            .boolean_list => vm.initValue(.{ .boolean_list = &.{} }),
            .int_list => vm.initValue(.{ .int_list = &.{} }),
            .float_list => vm.initValue(.{ .float_list = &.{} }),
            .char_list => vm.initValue(.{ .char_list = &.{} }),
            .symbol_list => vm.initValue(.{ .symbol_list = &.{} }),
            .dictionary => |dict| dict.values.copyNull(vm),
            .table => unreachable,
            .function => unreachable,
            .projection => unreachable,
        };
    }

    pub fn ref(self: *Self) *Self {
        if (debug_mod.debug_show_memory_allocations) print("{} => [{d}]\n", .{ self, self.reference_count + 1 });
        self.reference_count += 1;
        switch (self.as) {
            .nil,
            .boolean,
            .int,
            .float,
            .char,
            .symbol,
            .function,
            .projection,
            => {},
            .list,
            .boolean_list,
            .int_list,
            .float_list,
            .char_list,
            .symbol_list,
            => |list| {
                for (list) |value| _ = value.ref();
            },
            .dictionary => |dict| {
                _ = dict.keys.ref();
                _ = dict.values.ref();
            },
            .table => |table| {
                _ = table.columns.ref();
                _ = table.values.ref();
            },
        }
        return self;
    }

    pub fn deref(self: *Self, allocator: std.mem.Allocator) void {
        if (debug_mod.debug_show_memory_allocations) print("{} => [{d}]\n", .{ self, self.reference_count - 1 });
        self.reference_count -= 1;
        switch (self.as) {
            .nil,
            .boolean,
            .int,
            .float,
            .char,
            .symbol,
            .function,
            .projection,
            => {},
            .list,
            .boolean_list,
            .int_list,
            .float_list,
            .char_list,
            .symbol_list,
            => |list| for (list) |value| value.deref(allocator),
            .dictionary => |dict| {
                dict.keys.deref(allocator);
                dict.values.deref(allocator);
            },
            .table => |table| {
                table.columns.deref(allocator);
                table.values.deref(allocator);
            },
        }
        if (self.reference_count == 0) {
            switch (self.as) {
                .nil,
                .boolean,
                .int,
                .float,
                .char,
                => {},
                .symbol => |symbol| allocator.free(symbol),
                .list,
                .boolean_list,
                .int_list,
                .float_list,
                .char_list,
                .symbol_list,
                => |list| allocator.free(list),
                .dictionary => |dict| dict.deinit(allocator),
                .table => |table| table.deinit(allocator),
                .function => |function| function.deinit(allocator),
                .projection => |projection| projection.deinit(allocator),
            }
            allocator.destroy(self);
        }
    }

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("{} [{d}]", .{ self.as, self.reference_count });
    }

    pub fn eql(x: *Self, y: *Self) bool {
        if (x == y) return true;
        if (@as(ValueType, x.as) != y.as) return false;
        return switch (x.as) {
            .nil => true,
            .boolean => |bool_x| bool_x == y.as.boolean,
            .int => |int_x| int_x == y.as.int,
            .float => |float_x| std.math.isNan(float_x) and std.math.isNan(y.as.float) or float_x == y.as.float,
            .char => |char_x| char_x == y.as.char,
            .symbol => |symbol_x| std.mem.eql(u8, symbol_x, y.as.symbol),
            .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list_x| switch (y.as) {
                .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list_y| blk: {
                    if (list_x.len != list_y.len) break :blk false;
                    for (list_x, list_y) |value_x, value_y| {
                        if (!value_x.eql(value_y)) break :blk false;
                    }
                    break :blk true;
                },
                else => unreachable,
            },
            .dictionary => |dict_x| dict_x.keys.eql(y.as.dictionary.keys) and dict_x.values.eql(y.as.dictionary.values),
            .table => |table_x| table_x.columns.eql(y.as.table.columns) and table_x.values.eql(y.as.table.values),
            .function => |func_x| switch (y.as) {
                .function => |func_y| blk: {
                    if (func_x.arity != func_y.arity) break :blk false;
                    if (func_x.local_count != func_y.local_count) break :blk false;
                    if (!std.mem.eql(u8, func_x.chunk.code.items, func_y.chunk.code.items)) break :blk false;
                    break :blk true;
                },
                else => unreachable,
            },
            .projection => |proj_x| switch (y.as) {
                .projection => |proj_y| blk: {
                    if (!proj_x.value.eql(proj_y.value)) break :blk false;
                    if (!proj_x.arg_indices.eql(proj_y.arg_indices)) break :blk false;
                    var it = proj_x.arg_indices.iterator(.{});
                    while (it.next()) |i| {
                        if (!proj_x.arguments[i].eql(proj_y.arguments[i])) break :blk false;
                    }
                    break :blk true;
                },
                else => unreachable,
            },
        };
    }

    pub fn asList(self: *Self) []*Self {
        return switch (self.as) {
            .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list| list,
            else => unreachable,
        };
    }

    pub fn dupeAsList(self: *Self, allocator: std.mem.Allocator) []*Self {
        const list = allocator.alloc(*Self, self.asList().len) catch std.debug.panic("Failed to create list.", .{});
        for (self.asList(), 0..) |v, i| list[i] = v.ref();
        return list;
    }

    pub fn asArrayList(self: *Self, allocator: std.mem.Allocator) std.ArrayList(*Self) {
        var array_list = std.ArrayList(*Self).initCapacity(allocator, self.asList().len) catch std.debug.panic("Failed to create list.", .{});
        for (self.asList()) |v| {
            array_list.append(v.ref()) catch std.debug.panic("Failed to append item.", .{});
        }
        return array_list;
    }

    pub fn getListType(self: *Self) ValueType {
        return switch (self.as) {
            .boolean => .boolean_list,
            .int => .int_list,
            .float => .float_list,
            .char => .char_list,
            .symbol => .symbol_list,
            else => .list,
        };
    }

    pub fn isNull(self: *Self) bool {
        return switch (self.as) {
            .nil => true,
            .boolean => false,
            .int => |i| i == Value.null_int,
            .float => |f| std.math.isNan(f),
            .char => |c| c == ' ',
            .symbol => |s| s.len == 0,
            else => unreachable,
        };
    }
};

pub const ValueFunction = struct {
    const Self = @This();

    arity: u8,
    local_count: u8,
    chunk: *Chunk,
    name: ?[]const u8,

    pub fn init(allocator: std.mem.Allocator) *Self {
        const self = allocator.create(Self) catch std.debug.panic("Failed to create function.", .{});
        self.* = Self{
            .arity = 0,
            .local_count = 0,
            .chunk = Chunk.init(allocator),
            .name = null,
        };
        return self;
    }

    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        if (self.name) |name| allocator.free(name);
        self.chunk.deinit();
        allocator.destroy(self);
    }
};

pub const ValueProjection = struct {
    const Self = @This();

    pub const Config = struct {
        arg_indices: std.bit_set.IntegerBitSet(8),
        value: *Value,
    };

    arg_indices: std.bit_set.IntegerBitSet(8),
    arguments: [8]*Value,
    value: *Value,

    pub fn init(config: Config, allocator: std.mem.Allocator) *Self {
        const self = allocator.create(Self) catch std.debug.panic("Failed to create projection.", .{});
        self.* = Self{
            .arg_indices = config.arg_indices,
            .arguments = undefined,
            .value = config.value,
        };
        return self;
    }

    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        var it = self.arg_indices.iterator(.{});
        while (it.next()) |i| self.arguments[i].deref(allocator);
        self.value.deref(allocator);
        allocator.destroy(self);
    }
};

pub const ValueDictionary = struct {
    const Self = @This();

    pub const Config = struct {
        keys: *Value,
        values: *Value,
    };

    keys: *Value,
    values: *Value,
    hash_map: ValueHashMap,

    pub fn init(config: Config, vm: *VM) *Self {
        const self = vm.allocator.create(Self) catch std.debug.panic("Failed to create dictionary.", .{});
        self.* = Self{
            .keys = config.keys,
            .values = config.values,
            .hash_map = switch (config.keys.as) {
                .table => |table| blk: {
                    var hash_map = ValueHashMap.init(vm.allocator);
                    const table_count = table.values.as.list[0].asList().len;
                    hash_map.ensureTotalCapacity(table_count) catch std.debug.panic("Failed to create dictionary.", .{});
                    for (config.values.asList(), 0..) |v, i| {
                        const list = vm.allocator.alloc(*Value, table.columns.as.symbol_list.len) catch std.debug.panic("Failed to create list.", .{});
                        var list_type: ?ValueType = null;
                        for (list, table.values.as.list) |*value, column| {
                            value.* = column.asList()[i].ref();
                            if (list_type == null and @as(ValueType, list[0].as) != value.*.as) list_type = .list;
                        }
                        const k = vm.initList(list, list_type);
                        defer k.deref(vm.allocator); // This is most likely wrong, need some more tests to figure out correct cleanup approach
                        const result = hash_map.getOrPutAssumeCapacity(k);
                        if (!result.found_existing) {
                            result.value_ptr.* = v;
                        }
                    }
                    break :blk hash_map;
                },
                .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list| blk: {
                    var hash_map = ValueHashMap.init(vm.allocator);
                    hash_map.ensureTotalCapacity(list.len) catch std.debug.panic("Failed to create dictionary.", .{});
                    for (list, config.values.asList()) |k, v| {
                        const result = hash_map.getOrPutAssumeCapacity(k);
                        if (!result.found_existing) {
                            result.value_ptr.* = v;
                        }
                    }
                    break :blk hash_map;
                },
                else => unreachable,
            },
        };
        return self;
    }

    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        self.hash_map.deinit();
        allocator.destroy(self);
    }
};

pub const ValueTable = struct {
    const Self = @This();

    pub const Config = struct {
        columns: *Value,
        values: *Value,
    };

    columns: *Value,
    values: *Value,
    hash_map: ValueHashMap,

    pub fn init(config: Config, allocator: std.mem.Allocator) *Self {
        const self = allocator.create(Self) catch std.debug.panic("Failed to create table.", .{});
        var hash_map = ValueHashMap.init(allocator);
        hash_map.ensureTotalCapacity(config.columns.as.symbol_list.len) catch std.debug.panic("Failed to create table.", .{});
        for (config.columns.as.symbol_list, config.values.as.list) |c, v| {
            const result = hash_map.getOrPutAssumeCapacity(c);
            if (!result.found_existing) result.value_ptr.* = v;
        }
        self.* = Self{
            .columns = config.columns,
            .values = config.values,
            .hash_map = hash_map,
        };
        return self;
    }

    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        self.hash_map.deinit();
        allocator.destroy(self);
    }
};

pub const ValueHashMap = std.ArrayHashMap(*Value, *Value, ValueHashMapContext, false);

pub const ValueHashMapContext = struct {
    const Self = @This();

    pub fn hash(self: Self, value: *Value) u32 {
        _ = self;
        _ = value;
        unreachable;
    }

    pub fn eql(self: Self, a: *Value, b: *Value, b_index: usize) bool {
        _ = self;
        _ = b_index;
        return a.eql(b);
    }
};

pub const ValueSliceHashMapContext = struct {
    const Self = @This();

    // TODO: Needs implementation
    pub fn hash(self: Self, value: []*Value) u32 {
        _ = self;
        _ = value;
        unreachable;
    }

    pub fn eql(self: Self, a: []*Value, b: []*Value, b_index: usize) bool {
        _ = self;
        _ = b_index;
        if (a.len != b.len) return false;
        for (a, b) |a_value, b_value| {
            if (!a_value.eql(b_value)) return false;
        }
        return true;
    }
};
