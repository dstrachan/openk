const std = @import("std");

const chunk_mod = @import("chunk.zig");
const Chunk = chunk_mod.Chunk;

const utils_mod = @import("utils.zig");
const print = utils_mod.print;

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
            .int => |int| try writer.print("{d}", .{int}),
            .float => |float| try writer.print("{d}f", .{float}),
            .char => |char| {
                try writer.writeAll("\"");
                try printChar(writer, char);
                try writer.writeAll("\"");
            },
            .symbol => |symbol| try writer.print("`{s}", .{symbol}),
            .list => |list| {
                if (list.len == 1) {
                    try writer.print(",{}", .{list[0].as});
                } else {
                    try writer.writeAll("(");
                    for (list[0 .. list.len - 1]) |value| try writer.print("{};", .{value.as});
                    try writer.print("{})", .{list[list.len - 1].as});
                }
            },
            .boolean_list => |list| {
                if (list.len == 1) try writer.writeAll(",");
                for (list) |value| try writer.writeAll(if (value.as.boolean) "1" else "0");
                try writer.writeAll("b");
            },
            .int_list => |list| {
                if (list.len == 1) try writer.writeAll(",");
                for (list[0 .. list.len - 1]) |value| try writer.print("{d} ", .{value.as.int});
                try writer.print("{d}", .{list[list.len - 1].as.int});
            },
            .float_list => |list| {
                if (list.len == 1) try writer.writeAll(",");
                for (list[0 .. list.len - 1]) |value| try writer.print("{d} ", .{value.as.float});
                try writer.print("{d}f", .{list[list.len - 1].as.float});
            },
            .char_list => |list| {
                if (list.len == 1) try writer.writeAll(",");
                try writer.writeAll("\"");
                for (list) |value| try printChar(writer, value.as.char);
                try writer.writeAll("\"");
            },
            .symbol_list => |list| {
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
