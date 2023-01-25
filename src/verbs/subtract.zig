const std = @import("std");

const utils_mod = @import("../utils.zig");
const print = utils_mod.print;

const value_mod = @import("../value.zig");
const Value = value_mod.Value;
const ValueType = value_mod.ValueType;

const vm_mod = @import("../vm.zig");
const VM = vm_mod.VM;

pub const SubtractError = error{
    incompatible_types,
    length_mismatch,
};

fn runtimeError(comptime err: SubtractError) !*Value {
    switch (err) {
        SubtractError.incompatible_types => print("Incompatible types.\n", .{}),
        SubtractError.length_mismatch => print("List lengths must match.\n", .{}),
    }
    return err;
}

// TODO: Add tests to implement these functions inline
fn subtractInt(x: i64, y: i64) i64 {
    if (x == Value.null_int or y == Value.null_int) return Value.null_int;
    return x -% y;
}

fn subtractFloat(x: f64, y: f64) f64 {
    return x - y;
}

pub fn subtract(vm: *VM, x: *Value, y: *Value) SubtractError!*Value {
    return switch (x.as) {
        .boolean => |bool_x| switch (y.as) {
            .boolean => |bool_y| vm.initValue(.{ .int = @boolToInt(bool_x) - @as(i64, @boolToInt(bool_y)) }),
            .int => |int_y| vm.initValue(.{ .int = @boolToInt(bool_x) - int_y }),
            .float => |float_y| vm.initValue(.{ .float = utils_mod.intToFloat(@boolToInt(bool_x)) - float_y }),
            .list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ValueType = switch (list_y[0].as) {
                    .boolean => .int,
                    .int => .int,
                    .float => .float,
                    else => .list,
                };
                for (list_y) |value, i| {
                    list[i] = try subtract(vm, x, value);
                    if (list_type != .list and list_type != list[i].as) list_type = .list;
                }
                break :blk vm.initValue(switch (list_type) {
                    .int => .{ .int_list = list },
                    .float => .{ .float_list = list },
                    else => .{ .list = list },
                });
            },
            .boolean_list => |boolean_list_y| blk: {
                const list = vm.allocator.alloc(*Value, boolean_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (boolean_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .int = @boolToInt(bool_x) - @as(i64, @boolToInt(value.as.boolean)) });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .int = @boolToInt(bool_x) - value.as.int });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .float_list => |float_list_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .float = utils_mod.intToFloat(@boolToInt(bool_x)) - value.as.float });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            else => unreachable,
        },
        .int => |int_x| switch (y.as) {
            .boolean => |bool_y| vm.initValue(.{ .int = int_x - @boolToInt(bool_y) }),
            .int => |int_y| vm.initValue(.{ .int = int_x - int_y }),
            .float => |float_y| vm.initValue(.{ .float = utils_mod.intToFloat(int_x) - float_y }),
            .list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ValueType = switch (list_y[0].as) {
                    .boolean => .int,
                    .int => .int,
                    .float => .float,
                    else => .list,
                };
                for (list_y) |value, i| {
                    list[i] = try subtract(vm, x, value);
                    if (list_type != .list and list_type != list[i].as) list_type = .list;
                }
                break :blk vm.initValue(switch (list_type) {
                    .int => .{ .int_list = list },
                    .float => .{ .float_list = list },
                    else => .{ .list = list },
                });
            },
            .boolean_list => |boolean_list_y| blk: {
                const list = vm.allocator.alloc(*Value, boolean_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (boolean_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .int = int_x - @boolToInt(value.as.boolean) });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .int = int_x - value.as.int });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .float_list => |float_list_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .float = utils_mod.intToFloat(int_x) - value.as.float });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            else => unreachable,
        },
        .float => |float_x| switch (y.as) {
            .boolean => |bool_y| vm.initValue(.{ .float = float_x - utils_mod.intToFloat(@boolToInt(bool_y)) }),
            .int => |int_y| vm.initValue(.{ .float = float_x - utils_mod.intToFloat(int_y) }),
            .float => |float_y| vm.initValue(.{ .float = float_x - float_y }),
            .list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ValueType = switch (list_y[0].as) {
                    .boolean => .float,
                    .int => .float,
                    .float => .float,
                    else => .list,
                };
                for (list_y) |value, i| {
                    list[i] = try subtract(vm, x, value);
                    if (list_type != .list and list_type != list[i].as) list_type = .list;
                }
                break :blk vm.initValue(switch (list_type) {
                    .float => .{ .float_list = list },
                    else => .{ .list = list },
                });
            },
            .boolean_list => |boolean_list_y| blk: {
                const list = vm.allocator.alloc(*Value, boolean_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (boolean_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .float = float_x - utils_mod.intToFloat(@boolToInt(value.as.boolean)) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .float = float_x - utils_mod.intToFloat(value.as.int) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .float_list => |float_list_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .float = float_x - value.as.float });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            else => unreachable,
        },
        .list => |list_x| switch (y.as) {
            .boolean, .int => blk: {
                const list = vm.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ValueType = switch (list_x[0].as) {
                    .boolean => .int,
                    .int => .int,
                    .float => .float,
                    else => .list,
                };
                for (list_x) |value, i| {
                    list[i] = try subtract(vm, value, y);
                    if (list_type != .list and list_type != list[i].as) list_type = .list;
                }
                break :blk vm.initValue(switch (list_type) {
                    .int => .{ .int_list = list },
                    .float => .{ .float_list = list },
                    else => .{ .list = list },
                });
            },
            .float => blk: {
                const list = vm.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ValueType = switch (list_x[0].as) {
                    .boolean => .float,
                    .int => .float,
                    .float => .float,
                    else => .list,
                };
                for (list_x) |value, i| {
                    list[i] = try subtract(vm, value, y);
                    if (list_type != .list and list_type != list[i].as) list_type = .list;
                }
                break :blk vm.initValue(switch (list_type) {
                    .float => .{ .float_list = list },
                    else => .{ .list = list },
                });
            },
            .list,
            .boolean_list,
            .int_list,
            .float_list,
            => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ?ValueType = null;
                for (list_x) |value, i| {
                    list[i] = try subtract(vm, value, list_y[i]);
                    if (list_type == null and @as(ValueType, list[0].as) != @as(ValueType, list[i].as)) list_type = .list;
                }
                break :blk vm.initValue(switch (if (list_type) |value_type| value_type else @as(ValueType, list[0].as)) {
                    .int => .{ .int_list = list },
                    .float => .{ .float_list = list },
                    else => .{ .list = list },
                });
            },
            else => unreachable,
        },
        .boolean_list => |boolean_list_x| switch (y.as) {
            .boolean => |bool_y| blk: {
                const list = vm.allocator.alloc(*Value, boolean_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (boolean_list_x) |value, i| {
                    list[i] = vm.initValue(.{ .int = @boolToInt(value.as.boolean) - @as(i64, @boolToInt(bool_y)) });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .int => |int_y| blk: {
                const list = vm.allocator.alloc(*Value, boolean_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (boolean_list_x) |value, i| {
                    list[i] = vm.initValue(.{ .int = @boolToInt(value.as.boolean) - int_y });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .float => |float_y| blk: {
                const list = vm.allocator.alloc(*Value, boolean_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (boolean_list_x) |value, i| {
                    list[i] = vm.initValue(.{ .float = utils_mod.intToFloat(@boolToInt(value.as.boolean)) - float_y });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ValueType = switch (list_y[0].as) {
                    .boolean => .int,
                    .int => .int,
                    .float => .float,
                    else => .list,
                };
                for (boolean_list_x) |value, i| {
                    list[i] = try subtract(vm, value, list_y[i]);
                    if (list_type != .list and list_type != list[i].as) list_type = .list;
                }
                break :blk vm.initValue(switch (list_type) {
                    .int => .{ .int_list = list },
                    .float => .{ .float_list = list },
                    else => .{ .list = list },
                });
            },
            .boolean_list => |boolean_list_y| blk: {
                const list = vm.allocator.alloc(*Value, boolean_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (boolean_list_x) |value, i| {
                    list[i] = vm.initValue(.{ .int = @boolToInt(value.as.boolean) - @as(i64, @boolToInt(boolean_list_y[i].as.boolean)) });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = vm.allocator.alloc(*Value, boolean_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (boolean_list_x) |value, i| {
                    list[i] = vm.initValue(.{ .int = @boolToInt(value.as.boolean) - int_list_y[i].as.int });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .float_list => |float_list_y| blk: {
                const list = vm.allocator.alloc(*Value, boolean_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (boolean_list_x) |value, i| {
                    list[i] = vm.initValue(.{ .float = utils_mod.intToFloat(@boolToInt(value.as.boolean)) - float_list_y[i].as.float });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            else => unreachable,
        },
        .int_list => |int_list_x| switch (y.as) {
            .boolean => |bool_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_x) |value, i| {
                    list[i] = vm.initValue(.{ .int = value.as.int - @boolToInt(bool_y) });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .int => |int_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_x) |value, i| {
                    list[i] = vm.initValue(.{ .int = value.as.int - int_y });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .float => |float_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_x) |value, i| {
                    list[i] = vm.initValue(.{ .float = utils_mod.intToFloat(value.as.int) - float_y });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ValueType = switch (list_y[0].as) {
                    .boolean => .int,
                    .int => .int,
                    .float => .float,
                    else => .list,
                };
                for (int_list_x) |value, i| {
                    list[i] = try subtract(vm, value, list_y[i]);
                    if (list_type != .list and list_type != list[i].as) list_type = .list;
                }
                break :blk vm.initValue(switch (list_type) {
                    .int => .{ .int_list = list },
                    .float => .{ .float_list = list },
                    else => .{ .list = list },
                });
            },
            .boolean_list => |boolean_list_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_x) |value, i| {
                    list[i] = vm.initValue(.{ .int = value.as.int - @boolToInt(boolean_list_y[i].as.boolean) });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_x) |value, i| {
                    list[i] = vm.initValue(.{ .int = value.as.int - int_list_y[i].as.int });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .float_list => |float_list_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_x) |value, i| {
                    list[i] = vm.initValue(.{ .float = utils_mod.intToFloat(value.as.int) - float_list_y[i].as.float });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            else => unreachable,
        },
        .float_list => |float_list_x| switch (y.as) {
            .boolean => |bool_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_x) |value, i| {
                    list[i] = vm.initValue(.{ .float = value.as.float - utils_mod.intToFloat(@boolToInt(bool_y)) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .int => |int_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_x) |value, i| {
                    list[i] = vm.initValue(.{ .float = value.as.float - utils_mod.intToFloat(int_y) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .float => |float_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_x) |value, i| {
                    list[i] = vm.initValue(.{ .float = value.as.float - float_y });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ValueType = switch (list_y[0].as) {
                    .boolean => .float,
                    .int => .float,
                    .float => .float,
                    else => .list,
                };
                for (float_list_x) |value, i| {
                    list[i] = try subtract(vm, value, list_y[i]);
                    if (list_type != .list and list_type != list[i].as) list_type = .list;
                }
                break :blk vm.initValue(switch (list_type) {
                    .float => .{ .float_list = list },
                    else => .{ .list = list },
                });
            },
            .boolean_list => |boolean_list_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_x) |value, i| {
                    list[i] = vm.initValue(.{ .float = value.as.float - utils_mod.intToFloat(@boolToInt(boolean_list_y[i].as.boolean)) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_x) |value, i| {
                    list[i] = vm.initValue(.{ .float = value.as.float - utils_mod.intToFloat(int_list_y[i].as.int) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .float_list => |float_list_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_x) |value, i| {
                    list[i] = vm.initValue(.{ .float = value.as.float - float_list_y[i].as.float });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            else => unreachable,
        },
        else => unreachable,
    };
}
