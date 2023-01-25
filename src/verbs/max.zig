const std = @import("std");

const utils_mod = @import("../utils.zig");
const print = utils_mod.print;

const value_mod = @import("../value.zig");
const Value = value_mod.Value;
const ValueType = value_mod.ValueType;

const vm_mod = @import("../vm.zig");
const VM = vm_mod.VM;

pub const MinError = error{
    incompatible_types,
    length_mismatch,
};

fn runtimeError(comptime err: MinError) MinError!*Value {
    switch (err) {
        MinError.incompatible_types => print("Incompatible types.\n", .{}),
        MinError.length_mismatch => print("List lengths must match.\n", .{}),
    }
    return err;
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

pub fn max(vm: *VM, x: *Value, y: *Value) MinError!*Value {
    return switch (x.as) {
        .boolean => |bool_x| switch (y.as) {
            .boolean => |bool_y| vm.initValue(.{ .boolean = maxBool(bool_x, bool_y) }),
            .int => |int_y| vm.initValue(.{ .int = maxInt(@boolToInt(bool_x), int_y) }),
            .float => |float_y| vm.initValue(.{ .float = maxFloat(utils_mod.intToFloat(@boolToInt(bool_x)), float_y) }),
            .list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ?ValueType = null;
                for (list_y) |value, i| {
                    list[i] = try max(vm, x, value);
                    if (list_type == null and @as(ValueType, list[0].as) != @as(ValueType, list[i].as)) list_type = .list;
                }
                break :blk vm.initValue(switch (if (list_type) |list_type_value| list_type_value else @as(ValueType, list[0].as)) {
                    .int => .{ .int_list = list },
                    .float => .{ .float_list = list },
                    else => .{ .list = list },
                });
            },
            .boolean_list => |bool_list_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .boolean = maxBool(bool_x, value.as.boolean) });
                }
                break :blk vm.initValue(.{ .boolean_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .int = maxInt(@boolToInt(bool_x), value.as.int) });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .float_list => |float_list_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .float = maxFloat(utils_mod.intToFloat(@boolToInt(bool_x)), value.as.float) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            else => unreachable,
        },
        .int => |int_x| switch (y.as) {
            .boolean => |bool_y| vm.initValue(.{ .int = maxInt(int_x, @boolToInt(bool_y)) }),
            .int => |int_y| vm.initValue(.{ .int = maxInt(int_x, int_y) }),
            .float => |float_y| vm.initValue(.{ .float = maxFloat(utils_mod.intToFloat(int_x), float_y) }),
            .list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ?ValueType = null;
                for (list_y) |value, i| {
                    list[i] = try max(vm, x, value);
                    if (list_type == null and @as(ValueType, list[0].as) != @as(ValueType, list[i].as)) list_type = .list;
                }
                break :blk vm.initValue(switch (if (list_type) |list_type_value| list_type_value else @as(ValueType, list[0].as)) {
                    .int => .{ .int_list = list },
                    .float => .{ .float_list = list },
                    else => .{ .list = list },
                });
            },
            .boolean_list => |bool_list_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .int = maxInt(int_x, @boolToInt(value.as.boolean)) });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .int = maxInt(int_x, value.as.int) });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .float_list => |float_list_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .float = maxFloat(utils_mod.intToFloat(int_x), value.as.float) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            else => unreachable,
        },
        .float => |float_x| switch (y.as) {
            .boolean => |bool_y| vm.initValue(.{ .float = maxFloat(float_x, utils_mod.intToFloat(@boolToInt(bool_y))) }),
            .int => |int_y| vm.initValue(.{ .float = maxFloat(float_x, utils_mod.intToFloat(int_y)) }),
            .float => |float_y| vm.initValue(.{ .float = maxFloat(float_x, float_y) }),
            .list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ?ValueType = null;
                for (list_y) |value, i| {
                    list[i] = try max(vm, x, value);
                    if (list_type == null and @as(ValueType, list[0].as) != @as(ValueType, list[i].as)) list_type = .list;
                }
                break :blk vm.initValue(switch (if (list_type) |list_type_value| list_type_value else @as(ValueType, list[0].as)) {
                    .float => .{ .float_list = list },
                    else => .{ .list = list },
                });
            },
            .boolean_list => |bool_list_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .float = maxFloat(float_x, utils_mod.intToFloat(@boolToInt(value.as.boolean))) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .float = maxFloat(float_x, utils_mod.intToFloat(value.as.int)) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .float_list => |float_list_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .float = maxFloat(float_x, value.as.float) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            else => unreachable,
        },
        .list => |list_x| switch (y.as) {
            .boolean, .int, .float => blk: {
                const list = vm.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ?ValueType = null;
                for (list_x) |value, i| {
                    list[i] = try max(vm, value, y);
                    if (list_type == null and @as(ValueType, list[0].as) != @as(ValueType, list[i].as)) list_type = .list;
                }
                break :blk vm.initValue(switch (if (list_type) |list_type_value| list_type_value else @as(ValueType, list[0].as)) {
                    .int => .{ .int_list = list },
                    .float => .{ .float_list = list },
                    else => .{ .list = list },
                });
            },
            .list, .boolean_list, .int_list, .float_list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ?ValueType = null;
                for (list_x) |value, i| {
                    list[i] = try max(vm, value, list_y[i]);
                    if (list_type == null and @as(ValueType, list[0].as) != @as(ValueType, list[i].as)) list_type = .list;
                }
                break :blk vm.initValue(switch (if (list_type) |list_type_value| list_type_value else @as(ValueType, list[0].as)) {
                    .int => .{ .int_list = list },
                    .float => .{ .float_list = list },
                    else => .{ .list = list },
                });
            },
            else => unreachable,
        },
        .boolean_list => |bool_list_x| switch (y.as) {
            .boolean => |bool_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_x) |value, i| {
                    list[i] = vm.initValue(.{ .boolean = maxBool(value.as.boolean, bool_y) });
                }
                break :blk vm.initValue(.{ .boolean_list = list });
            },
            .int => |int_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_x) |value, i| {
                    list[i] = vm.initValue(.{ .int = maxInt(@boolToInt(value.as.boolean), int_y) });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .float => |float_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_x) |value, i| {
                    list[i] = vm.initValue(.{ .float = maxFloat(utils_mod.intToFloat(@boolToInt(value.as.boolean)), float_y) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ?ValueType = null;
                for (bool_list_x) |value, i| {
                    list[i] = try max(vm, value, list_y[i]);
                    if (list_type == null and @as(ValueType, list[0].as) != @as(ValueType, list[i].as)) list_type = .list;
                }
                break :blk vm.initValue(switch (if (list_type) |list_type_value| list_type_value else @as(ValueType, list[0].as)) {
                    .int => .{ .int_list = list },
                    .float => .{ .float_list = list },
                    else => .{ .list = list },
                });
            },
            .boolean_list => |bool_list_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_x) |value, i| {
                    list[i] = vm.initValue(.{ .boolean = maxBool(value.as.boolean, bool_list_y[i].as.boolean) });
                }
                break :blk vm.initValue(.{ .boolean_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_x) |value, i| {
                    list[i] = vm.initValue(.{ .int = maxInt(@boolToInt(value.as.boolean), int_list_y[i].as.int) });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .float_list => |float_list_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_x) |value, i| {
                    list[i] = vm.initValue(.{ .float = maxFloat(utils_mod.intToFloat(@boolToInt(value.as.boolean)), float_list_y[i].as.float) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            else => unreachable,
        },
        .int_list => |int_list_x| switch (y.as) {
            .boolean => |bool_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_x) |value, i| {
                    list[i] = vm.initValue(.{ .int = maxInt(value.as.int, @boolToInt(bool_y)) });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .int => |int_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_x) |value, i| {
                    list[i] = vm.initValue(.{ .int = maxInt(value.as.int, int_y) });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .float => |float_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_x) |value, i| {
                    list[i] = vm.initValue(.{ .float = maxFloat(utils_mod.intToFloat(value.as.int), float_y) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ?ValueType = null;
                for (int_list_x) |value, i| {
                    list[i] = try max(vm, value, list_y[i]);
                    if (list_type == null and @as(ValueType, list[0].as) != @as(ValueType, list[i].as)) list_type = .list;
                }
                break :blk vm.initValue(switch (if (list_type) |list_type_value| list_type_value else @as(ValueType, list[0].as)) {
                    .int => .{ .int_list = list },
                    .float => .{ .float_list = list },
                    else => .{ .list = list },
                });
            },
            .boolean_list => |bool_list_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_x) |value, i| {
                    list[i] = vm.initValue(.{ .int = maxInt(value.as.int, @boolToInt(bool_list_y[i].as.boolean)) });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_x) |value, i| {
                    list[i] = vm.initValue(.{ .int = maxInt(value.as.int, int_list_y[i].as.int) });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .float_list => |float_list_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_x) |value, i| {
                    list[i] = vm.initValue(.{ .float = maxFloat(utils_mod.intToFloat(value.as.int), float_list_y[i].as.float) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            else => unreachable,
        },
        .float_list => |float_list_x| switch (y.as) {
            .boolean => |bool_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_x) |value, i| {
                    list[i] = vm.initValue(.{ .float = maxFloat(value.as.float, utils_mod.intToFloat(@boolToInt(bool_y))) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .int => |int_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_x) |value, i| {
                    list[i] = vm.initValue(.{ .float = maxFloat(value.as.float, utils_mod.intToFloat(int_y)) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .float => |float_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_x) |value, i| {
                    list[i] = vm.initValue(.{ .float = maxFloat(value.as.float, float_y) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ?ValueType = null;
                for (float_list_x) |value, i| {
                    list[i] = try max(vm, value, list_y[i]);
                    if (list_type == null and @as(ValueType, list[0].as) != @as(ValueType, list[i].as)) list_type = .list;
                }
                break :blk vm.initValue(switch (if (list_type) |list_type_value| list_type_value else @as(ValueType, list[0].as)) {
                    .int => .{ .int_list = list },
                    .float => .{ .float_list = list },
                    else => .{ .list = list },
                });
            },
            .boolean_list => |bool_list_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_x) |value, i| {
                    list[i] = vm.initValue(.{ .float = maxFloat(value.as.float, utils_mod.intToFloat(@boolToInt(bool_list_y[i].as.boolean))) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_x) |value, i| {
                    list[i] = vm.initValue(.{ .float = maxFloat(value.as.float, utils_mod.intToFloat(int_list_y[i].as.int)) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .float_list => |float_list_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_x) |value, i| {
                    list[i] = vm.initValue(.{ .float = maxFloat(value.as.float, float_list_y[i].as.float) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            else => unreachable,
        },
        else => unreachable,
    };
}
