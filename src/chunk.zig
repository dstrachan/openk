const std = @import("std");

const scanner_mod = @import("scanner.zig");
const Token = scanner_mod.Token;

const value_mod = @import("value.zig");
const Value = value_mod.Value;

pub const OpCode = enum {
    op_nil,
    op_constant,
    op_pop,
    op_get_local,
    op_set_local,
    op_get_global,
    op_set_global,
    op_concat,
    op_flip,
    op_add,
    op_negate,
    op_subtract,
    op_first,
    op_multiply,
    op_reciprocal,
    op_divide,
    op_key,
    op_dict,
    op_where,
    op_min,
    op_reverse,
    op_max,
    op_ascend,
    op_less,
    op_descend,
    op_more,
    op_group,
    op_equal,
    op_not,
    op_match,
    op_enlist,
    op_merge,
    op_null,
    op_fill,
    op_length,
    op_take,
    op_floor,
    op_drop,
    op_string,
    op_cast,
    op_unique,
    op_find,
    op_type,
    op_apply_1,
    op_value,
    op_apply_n,
    op_call,
    op_return,
};

pub const Chunk = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    code: std.ArrayList(u8),
    constants: std.ArrayList(*Value),
    tokens: std.ArrayList(Token),

    pub fn init(allocator: std.mem.Allocator) *Self {
        var self = allocator.create(Self) catch std.debug.panic("Failed to create chunk.", .{});
        self.* = Self{
            .allocator = allocator,
            .code = std.ArrayList(u8).init(allocator),
            .constants = std.ArrayList(*Value).init(allocator),
            .tokens = std.ArrayList(Token).init(allocator),
        };
        return self;
    }

    pub fn deinit(self: *Self) void {
        self.code.deinit();
        for (self.constants.items) |value| value.deref(self.allocator);
        self.constants.deinit();
        self.tokens.deinit();
        self.allocator.destroy(self);
    }

    pub fn write(self: *Self, byte: u8, token: Token) void {
        self.code.append(byte) catch std.debug.panic("Not enough memory", .{});
        self.tokens.append(token) catch std.debug.panic("Not enough memory", .{});
    }

    pub fn writeOpCode(self: *Self, op_code: OpCode, token: Token) void {
        self.write(@enumToInt(op_code), token);
    }

    pub fn addConstant(self: *Self, value: *Value) usize {
        self.constants.append(value) catch std.debug.panic("Not enough memory", .{});
        return self.constants.items.len - 1;
    }
};
