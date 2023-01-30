const std = @import("std");

const chunk_mod = @import("chunk.zig");
const Chunk = chunk_mod.Chunk;

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

    pub const null_int = -9223372036854775808;
    pub const inf_int = 9223372036854775807;

    pub const null_float = std.math.nan(f64);
    pub const inf_float = std.math.inf(f64);

    reference_count: u32,
    as: ValueUnion,

    pub fn init(data: ValueUnion, allocator: std.mem.Allocator) *Self {
        const self = allocator.create(Self) catch std.debug.panic("Failed to create value", .{});
        self.* = Self{
            .reference_count = 1,
            .as = data,
        };
        print("init value {}\n", .{self});
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
            .boolean_list => vm.initValue(.{ .boolean_list = &[_]*Value{} }),
            .int_list => vm.initValue(.{ .int_list = &[_]*Value{} }),
            .float_list => vm.initValue(.{ .float_list = &[_]*Value{} }),
            .char_list => vm.initValue(.{ .char_list = &[_]*Value{} }),
            .symbol_list => vm.initValue(.{ .symbol_list = &[_]*Value{} }),
            .function => unreachable,
            .projection => unreachable,
        };
    }

    pub fn ref(self: *Self) *Self {
        print("{} => [{d}]\n", .{ self, self.reference_count + 1 });
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
        }
        return self;
    }

    pub fn deref(self: *Self, allocator: std.mem.Allocator) void {
        print("{} => [{d}]\n", .{ self, self.reference_count - 1 });
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
                .function => |function| function.deinit(allocator),
                .projection => |projection| projection.deinit(allocator),
                .list,
                .boolean_list,
                .int_list,
                .float_list,
                .char_list,
                .symbol_list,
                => |list| allocator.free(list),
            }
            allocator.destroy(self);
        }
    }

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("{} [{d}]", .{ self.as, self.reference_count });
    }

    pub fn eql(x: *Self, y: *Self) bool {
        return switch (x.as) {
            .nil => y.as == .nil,
            .boolean => |bool_x| y.as == .boolean and bool_x == y.as.boolean,
            .int => |int_x| y.as == .int and int_x == y.as.int,
            .float => |float_x| y.as == .float and (std.math.isNan(float_x) and std.math.isNan(y.as.float) or float_x == y.as.float),
            .char => |char_x| y.as == .char and char_x == y.as.char,
            .symbol => |symbol_x| y.as == .symbol and std.mem.eql(u8, symbol_x, y.as.symbol),
            .list => |list_x| switch (y.as) {
                .list => |list_y| {
                    if (list_x.len != list_y.len) return false;
                    for (list_x) |value, i| {
                        if (!value.eql(list_y[i])) return false;
                    }
                    return true;
                },
                else => false,
            },
            .boolean_list => |list_x| switch (y.as) {
                .boolean_list => |list_y| {
                    if (list_x.len != list_y.len) return false;
                    for (list_x) |value, i| {
                        if (!value.eql(list_y[i])) return false;
                    }
                    return true;
                },
                else => false,
            },
            .int_list => |list_x| switch (y.as) {
                .int_list => |list_y| {
                    if (list_x.len != list_y.len) return false;
                    for (list_x) |value, i| {
                        if (!value.eql(list_y[i])) return false;
                    }
                    return true;
                },
                else => false,
            },
            .float_list => |list_x| switch (y.as) {
                .float_list => |list_y| {
                    if (list_x.len != list_y.len) return false;
                    for (list_x) |value, i| {
                        if (!value.eql(list_y[i])) return false;
                    }
                    return true;
                },
                else => false,
            },
            .char_list => |list_x| switch (y.as) {
                .char_list => |list_y| {
                    if (list_x.len != list_y.len) return false;
                    for (list_x) |value, i| {
                        if (!value.eql(list_y[i])) return false;
                    }
                    return true;
                },
                else => false,
            },
            .symbol_list => |list_x| switch (y.as) {
                .symbol_list => |list_y| {
                    if (list_x.len != list_y.len) return false;
                    for (list_x) |value, i| {
                        if (!value.eql(list_y[i])) return false;
                    }
                    return true;
                },
                else => false,
            },
            else => false,
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
        const self = allocator.create(Self) catch std.debug.panic("Failed to create function", .{});
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
        const self = allocator.create(Self) catch std.debug.panic("Failed to create projection", .{});
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
