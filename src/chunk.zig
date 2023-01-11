const std = @import("std");

const value_mod = @import("value.zig");
const Value = value_mod.Value;

pub const OpCode = enum {
    op_constant,
    op_pop,
    op_get_global,
    op_set_global,
    op_add,
    op_return,
};

pub const Chunk = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    code: std.ArrayList(u8),
    constants: std.ArrayList(*Value),
    lines: std.ArrayList(usize),

    pub fn init(allocator: std.mem.Allocator) *Self {
        var self = allocator.create(Self) catch std.debug.panic("Failed to create chunk", .{});
        self.* = Self{
            .allocator = allocator,
            .code = std.ArrayList(u8).init(allocator),
            .constants = std.ArrayList(*Value).init(allocator),
            .lines = std.ArrayList(usize).init(allocator),
        };
        return self;
    }

    pub fn deinit(self: *Self) void {
        self.code.deinit();
        for (self.constants.items) |value| value.deinit(self.allocator);
        self.constants.deinit();
        self.lines.deinit();
        self.allocator.destroy(self);
    }

    pub fn write(self: *Self, byte: u8, line: usize) void {
        self.code.append(byte) catch std.debug.panic("Not enough memory", .{});
        self.lines.append(line) catch std.debug.panic("Not enough memory", .{});
    }

    pub fn writeOpCode(self: *Self, op_code: OpCode, line: usize) void {
        self.write(@enumToInt(op_code), line);
    }

    pub fn addConstant(self: *Self, value: *Value) usize {
        self.constants.append(value) catch std.debug.panic("Not enough memory", .{});
        return self.constants.items.len - 1;
    }
};
