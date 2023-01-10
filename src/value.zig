const std = @import("std");

const chunk_mod = @import("chunk.zig");
const Chunk = chunk_mod.Chunk;

const utils_mod = @import("utils.zig");
const print = utils_mod.print;

pub const ValueType = enum {
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
};

const ValueUnion = union(ValueType) {
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
};

pub const Value = struct {
    const Self = @This();

    reference_count: u32,
    data: ValueUnion,

    pub fn init(data: ValueUnion, allocator: std.mem.Allocator) !*Self {
        const self = try allocator.create(Self);
        self.reference_count = 1;
        self.data = data;
        return self;
    }

    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        self.reference_count -= 1;
        if (self.reference_count == 0) {
            print("RC = 0\n", .{});
            switch (self.data) {
                .boolean,
                .int,
                .float,
                .char,
                => {},
                .symbol => |symbol| allocator.free(symbol), // TODO: Symbol table
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
        }
    }
};
