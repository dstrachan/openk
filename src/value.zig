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
};

pub const ValueUnion = union(ValueType) {
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
};

pub const Value = struct {
    const Self = @This();

    reference_count: u32,
    data: ValueUnion,

    pub fn init(data: ValueUnion, allocator: std.mem.Allocator) *Self {
        const self = allocator.create(Self) catch std.debug.panic("Failed to create value", .{});
        self.* = Self{
            .reference_count = 1,
            .data = data,
        };
        print("init value ({})\n", .{self});
        return self;
    }

    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        print("{d} => {d} ({})\n", .{ self.reference_count, self.reference_count - 1, self });
        self.reference_count -= 1;
        if (self.reference_count == 0) {
            switch (self.data) {
                .nil,
                .boolean,
                .int,
                .float,
                .char,
                => {},
                .symbol => |symbol| allocator.free(symbol), // TODO: Symbol table
                .function => |function| function.deinit(allocator),
                .list,
                .boolean_list,
                .int_list,
                .float_list,
                .char_list,
                .symbol_list,
                => |list| {
                    for (list) |value| value.deinit(allocator);
                    allocator.free(list);
                },
            }
            allocator.destroy(self);
        }
    }

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        switch (self.data) {
            .list => |list| {
                try writer.writeAll("(");
                for (list) |value| try writer.print("{}", .{value});
                try writer.writeAll(")");
            },
            .nil => {},
            .boolean => |boolean| try writer.writeAll(if (boolean) "1b" else "0b"),
            .boolean_list => |list| {
                for (list) |value| try writer.writeAll(if (value.data.boolean) "1" else "0");
                try writer.writeAll("b");
            },
            .int => |int| try writer.print("{d}", .{int}),
            .int_list => |list| {
                for (list[0 .. list.len - 1]) |value| try writer.print("{d} ", .{value.data.int});
                try writer.print("{d}", .{list[list.len - 1].data.int});
            },
            .float => |float| try writer.print("{d}f", .{float}),
            .float_list => |list| {
                for (list[0 .. list.len - 1]) |value| try writer.print("{d} ", .{value.data.float});
                try writer.print("{d}f", .{list[list.len - 1].data.float});
            },
            .char => |char| try writer.print("\"{c}\"", .{char}),
            .char_list => |list| {
                try writer.writeAll("\"");
                for (list) |value| try writer.print("{c}", .{value.data.char});
                try writer.writeAll("\"");
            },
            .symbol => |symbol| try writer.print("`{s}", .{symbol}),
            .symbol_list => |list| {
                for (list) |value| try writer.print("`{s}", .{value.data.symbol});
            },
            .function => try writer.writeAll("{[]NYI}"),
        }
    }
};

pub const ValueFunction = struct {
    const Self = @This();

    arity: u8,
    local_count: u8,
    chunk: *Chunk,
    name: ?[]const u8,

    pub fn init(allocator: std.mem.Allocator) *ValueFunction {
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
        self.chunk.deinit();
        allocator.destroy(self);
    }
};
