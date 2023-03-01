const std = @import("std");

const utils_mod = @import("../utils.zig");
const print = utils_mod.print;

const value_mod = @import("../value.zig");
const Value = value_mod.Value;
const ValueType = value_mod.ValueType;

const vm_mod = @import("../vm.zig");
const VM = vm_mod.VM;

pub const MoreError = error{
    incompatible_types,
    length_mismatch,
};

fn runtimeError(comptime err: MoreError) MoreError!*Value {
    switch (err) {
        MoreError.incompatible_types => print("Incompatible types.\n", .{}),
        MoreError.length_mismatch => print("List lengths must match.\n", .{}),
    }
    return err;
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

pub fn more(vm: *VM, x: *Value, y: *Value) MoreError!*Value {
    return switch (x.as) {
        .boolean => |bool_x| switch (y.as) {
            .boolean => |bool_y| vm.initValue(.{ .boolean = moreBool(bool_x, bool_y) }),
            .int => |int_y| vm.initValue(.{ .boolean = moreInt(@boolToInt(bool_x), int_y) }),
            .float => |float_y| vm.initValue(.{ .boolean = moreFloat(if (bool_x) 1 else 0, float_y) }),
            .list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ?ValueType = null;
                for (list_y, 0..) |value, i| {
                    list[i] = try more(vm, x, value);
                    if (list_type == null and @as(ValueType, list[0].as) != @as(ValueType, list[i].as)) list_type = .list;
                }
                break :blk vm.initValue(switch (if (list_type) |list_type_value| list_type_value else @as(ValueType, list[0].as)) {
                    .boolean => .{ .boolean_list = list },
                    else => .{ .list = list },
                });
            },
            .boolean_list => |bool_list_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .boolean = moreBool(bool_x, value.as.boolean) });
                }
                break :blk vm.initValue(.{ .boolean_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .boolean = moreInt(@boolToInt(bool_x), value.as.int) });
                }
                break :blk vm.initValue(.{ .boolean_list = list });
            },
            .float_list => |float_list_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .boolean = moreFloat(if (bool_x) 1 else 0, value.as.float) });
                }
                break :blk vm.initValue(.{ .boolean_list = list });
            },
            else => unreachable,
        },
        .int => |int_x| switch (y.as) {
            .boolean => |bool_y| vm.initValue(.{ .boolean = moreInt(int_x, @boolToInt(bool_y)) }),
            .int => |int_y| vm.initValue(.{ .boolean = moreInt(int_x, int_y) }),
            .float => |float_y| vm.initValue(.{ .boolean = moreFloat(utils_mod.intToFloat(int_x), float_y) }),
            .list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ?ValueType = null;
                for (list_y, 0..) |value, i| {
                    list[i] = try more(vm, x, value);
                    if (list_type == null and @as(ValueType, list[0].as) != @as(ValueType, list[i].as)) list_type = .list;
                }
                break :blk vm.initValue(switch (if (list_type) |list_type_value| list_type_value else @as(ValueType, list[0].as)) {
                    .boolean => .{ .boolean_list = list },
                    else => .{ .list = list },
                });
            },
            .boolean_list => |bool_list_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .boolean = moreInt(int_x, @boolToInt(value.as.boolean)) });
                }
                break :blk vm.initValue(.{ .boolean_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .boolean = moreInt(int_x, value.as.int) });
                }
                break :blk vm.initValue(.{ .boolean_list = list });
            },
            .float_list => |float_list_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .boolean = moreFloat(utils_mod.intToFloat(int_x), value.as.float) });
                }
                break :blk vm.initValue(.{ .boolean_list = list });
            },
            else => unreachable,
        },
        .float => |float_x| switch (y.as) {
            .boolean => |bool_y| vm.initValue(.{ .boolean = moreFloat(float_x, if (bool_y) 1 else 0) }),
            .int => |int_y| vm.initValue(.{ .boolean = moreFloat(float_x, utils_mod.intToFloat(int_y)) }),
            .float => |float_y| vm.initValue(.{ .boolean = moreFloat(float_x, float_y) }),
            .list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ?ValueType = null;
                for (list_y, 0..) |value, i| {
                    list[i] = try more(vm, x, value);
                    if (list_type == null and @as(ValueType, list[0].as) != @as(ValueType, list[i].as)) list_type = .list;
                }
                break :blk vm.initValue(switch (if (list_type) |list_type_value| list_type_value else @as(ValueType, list[0].as)) {
                    .boolean => .{ .boolean_list = list },
                    else => .{ .list = list },
                });
            },
            .boolean_list => |bool_list_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .boolean = moreFloat(float_x, if (value.as.boolean) 1 else 0) });
                }
                break :blk vm.initValue(.{ .boolean_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .boolean = moreFloat(float_x, utils_mod.intToFloat(value.as.int)) });
                }
                break :blk vm.initValue(.{ .boolean_list = list });
            },
            .float_list => |float_list_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .boolean = moreFloat(float_x, value.as.float) });
                }
                break :blk vm.initValue(.{ .boolean_list = list });
            },
            else => unreachable,
        },
        .list => |list_x| switch (y.as) {
            .boolean, .int, .float => blk: {
                const list = vm.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ?ValueType = null;
                for (list_x, 0..) |value, i| {
                    list[i] = try more(vm, value, y);
                    if (list_type == null and @as(ValueType, list[0].as) != @as(ValueType, list[i].as)) list_type = .list;
                }
                break :blk vm.initValue(switch (if (list_type) |list_type_value| list_type_value else @as(ValueType, list[0].as)) {
                    .boolean => .{ .boolean_list = list },
                    else => .{ .list = list },
                });
            },
            .list, .boolean_list, .int_list, .float_list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ?ValueType = null;
                for (list_x, 0..) |value, i| {
                    list[i] = try more(vm, value, list_y[i]);
                    if (list_type == null and @as(ValueType, list[0].as) != @as(ValueType, list[i].as)) list_type = .list;
                }
                break :blk vm.initValue(switch (if (list_type) |list_type_value| list_type_value else @as(ValueType, list[0].as)) {
                    .boolean => .{ .boolean_list = list },
                    else => .{ .list = list },
                });
            },
            else => unreachable,
        },
        .boolean_list => |bool_list_x| switch (y.as) {
            .boolean => |bool_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_x, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .boolean = moreBool(value.as.boolean, bool_y) });
                }
                break :blk vm.initValue(.{ .boolean_list = list });
            },
            .int => |int_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_x, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .boolean = moreInt(@boolToInt(value.as.boolean), int_y) });
                }
                break :blk vm.initValue(.{ .boolean_list = list });
            },
            .float => |float_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_x, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .boolean = moreFloat(if (value.as.boolean) 1 else 0, float_y) });
                }
                break :blk vm.initValue(.{ .boolean_list = list });
            },
            .list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ?ValueType = null;
                for (bool_list_x, 0..) |value, i| {
                    list[i] = try more(vm, value, list_y[i]);
                    if (list_type == null and @as(ValueType, list[0].as) != @as(ValueType, list[i].as)) list_type = .list;
                }
                break :blk vm.initValue(switch (if (list_type) |list_type_value| list_type_value else @as(ValueType, list[0].as)) {
                    .boolean => .{ .boolean_list = list },
                    else => .{ .list = list },
                });
            },
            .boolean_list => |bool_list_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_x, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .boolean = moreBool(value.as.boolean, bool_list_y[i].as.boolean) });
                }
                break :blk vm.initValue(.{ .boolean_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_x, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .boolean = moreInt(@boolToInt(value.as.boolean), int_list_y[i].as.int) });
                }
                break :blk vm.initValue(.{ .boolean_list = list });
            },
            .float_list => |float_list_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_x, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .boolean = moreFloat(if (value.as.boolean) 1 else 0, float_list_y[i].as.float) });
                }
                break :blk vm.initValue(.{ .boolean_list = list });
            },
            else => unreachable,
        },
        .int_list => |int_list_x| switch (y.as) {
            .boolean => |bool_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_x, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .boolean = moreInt(value.as.int, @boolToInt(bool_y)) });
                }
                break :blk vm.initValue(.{ .boolean_list = list });
            },
            .int => |int_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_x, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .boolean = moreInt(value.as.int, int_y) });
                }
                break :blk vm.initValue(.{ .boolean_list = list });
            },
            .float => |float_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_x, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .boolean = moreFloat(utils_mod.intToFloat(value.as.int), float_y) });
                }
                break :blk vm.initValue(.{ .boolean_list = list });
            },
            .list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ?ValueType = null;
                for (int_list_x, 0..) |value, i| {
                    list[i] = try more(vm, value, list_y[i]);
                    if (list_type == null and @as(ValueType, list[0].as) != @as(ValueType, list[i].as)) list_type = .list;
                }
                break :blk vm.initValue(switch (if (list_type) |list_type_value| list_type_value else @as(ValueType, list[0].as)) {
                    .boolean => .{ .boolean_list = list },
                    else => .{ .list = list },
                });
            },
            .boolean_list => |bool_list_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_x, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .boolean = moreInt(value.as.int, @boolToInt(bool_list_y[i].as.boolean)) });
                }
                break :blk vm.initValue(.{ .boolean_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_x, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .boolean = moreInt(value.as.int, int_list_y[i].as.int) });
                }
                break :blk vm.initValue(.{ .boolean_list = list });
            },
            .float_list => |float_list_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_x, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .boolean = moreFloat(utils_mod.intToFloat(value.as.int), float_list_y[i].as.float) });
                }
                break :blk vm.initValue(.{ .boolean_list = list });
            },
            else => unreachable,
        },
        .float_list => |float_list_x| switch (y.as) {
            .boolean => |bool_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_x, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .boolean = moreFloat(value.as.float, if (bool_y) 1 else 0) });
                }
                break :blk vm.initValue(.{ .boolean_list = list });
            },
            .int => |int_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_x, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .boolean = moreFloat(value.as.float, utils_mod.intToFloat(int_y)) });
                }
                break :blk vm.initValue(.{ .boolean_list = list });
            },
            .float => |float_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_x, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .boolean = moreFloat(value.as.float, float_y) });
                }
                break :blk vm.initValue(.{ .boolean_list = list });
            },
            .list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ?ValueType = null;
                for (float_list_x, 0..) |value, i| {
                    list[i] = try more(vm, value, list_y[i]);
                    if (list_type == null and @as(ValueType, list[0].as) != @as(ValueType, list[i].as)) list_type = .list;
                }
                break :blk vm.initValue(switch (if (list_type) |list_type_value| list_type_value else @as(ValueType, list[0].as)) {
                    .boolean => .{ .boolean_list = list },
                    else => .{ .list = list },
                });
            },
            .boolean_list => |bool_list_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_x, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .boolean = moreFloat(value.as.float, if (bool_list_y[i].as.boolean) 1 else 0) });
                }
                break :blk vm.initValue(.{ .boolean_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_x, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .boolean = moreFloat(value.as.float, utils_mod.intToFloat(int_list_y[i].as.int)) });
                }
                break :blk vm.initValue(.{ .boolean_list = list });
            },
            .float_list => |float_list_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_x, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .boolean = moreFloat(value.as.float, float_list_y[i].as.float) });
                }
                break :blk vm.initValue(.{ .boolean_list = list });
            },
            else => unreachable,
        },
        else => unreachable,
    };
}
