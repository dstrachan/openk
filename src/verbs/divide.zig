const std = @import("std");

const utils_mod = @import("../utils.zig");
const print = utils_mod.print;

const value_mod = @import("../value.zig");
const Value = value_mod.Value;
const ValueType = value_mod.ValueType;

const vm_mod = @import("../vm.zig");
const VM = vm_mod.VM;

pub const DivideError = error{
    incompatible_types,
    length_mismatch,
};

fn runtimeError(comptime err: DivideError) !*Value {
    switch (err) {
        DivideError.incompatible_types => print("Incompatible types.\n", .{}),
        DivideError.length_mismatch => print("List lengths must match.\n", .{}),
    }
    return err;
}

fn divideFloat(x: f64, y: f64) f64 {
    return if (std.math.isNan(x) or std.math.isNan(y)) Value.null_float else x / y;
}

pub fn divide(self: *VM, x: *Value, y: *Value) *Value {
    return switch (x.as) {
        .boolean => |bool_x| switch (y.as) {
            .boolean => |bool_y| self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(@boolToInt(bool_x)), utils_mod.intToFloat(@boolToInt(bool_y))) }),
            .int => |int_y| self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(@boolToInt(bool_x)), utils_mod.intToFloat(int_y)) }),
            .float => |float_y| self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(@boolToInt(bool_x)), float_y) }),
            .list => |list_y| blk: {
                const list = self.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ValueType = switch (list_y[0].as) {
                    .boolean, .int, .float => .float,
                    else => .list,
                };
                for (list_y) |value, i| {
                    list[i] = divide(self, x, value);
                    if (list_type != .list and list_type != list[i].as) list_type = .list;
                }
                break :blk self.initValue(switch (list_type) {
                    .float => .{ .float_list = list },
                    else => .{ .list = list },
                });
            },
            .boolean_list => |boolean_list_y| blk: {
                const list = self.allocator.alloc(*Value, boolean_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (boolean_list_y) |value, i| {
                    list[i] = self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(@boolToInt(bool_x)), utils_mod.intToFloat(@boolToInt(value.as.boolean))) });
                }
                break :blk self.initValue(.{ .float_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = self.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_y) |value, i| {
                    list[i] = self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(@boolToInt(bool_x)), utils_mod.intToFloat(value.as.int)) });
                }
                break :blk self.initValue(.{ .float_list = list });
            },
            .float_list => |float_list_y| blk: {
                const list = self.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_y) |value, i| {
                    list[i] = self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(@boolToInt(bool_x)), value.as.float) });
                }
                break :blk self.initValue(.{ .float_list = list });
            },
            else => unreachable,
        },
        .int => |int_x| switch (y.as) {
            .boolean => |bool_y| self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(int_x), utils_mod.intToFloat(@boolToInt(bool_y))) }),
            .int => |int_y| self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(int_x), utils_mod.intToFloat(int_y)) }),
            .float => |float_y| self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(int_x), float_y) }),
            .list => |list_y| blk: {
                const list = self.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ValueType = switch (list_y[0].as) {
                    .boolean, .int, .float => .float,
                    else => .list,
                };
                for (list_y) |value, i| {
                    list[i] = divide(self, x, value);
                    if (list_type != .list and list_type != list[i].as) list_type = .list;
                }
                break :blk self.initValue(switch (list_type) {
                    .float => .{ .float_list = list },
                    else => .{ .list = list },
                });
            },
            .boolean_list => |boolean_list_y| blk: {
                const list = self.allocator.alloc(*Value, boolean_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (boolean_list_y) |value, i| {
                    list[i] = self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(int_x), utils_mod.intToFloat(@boolToInt(value.as.boolean))) });
                }
                break :blk self.initValue(.{ .float_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = self.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_y) |value, i| {
                    list[i] = self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(int_x), utils_mod.intToFloat(value.as.int)) });
                }
                break :blk self.initValue(.{ .float_list = list });
            },
            .float_list => |float_list_y| blk: {
                const list = self.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_y) |value, i| {
                    list[i] = self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(int_x), value.as.float) });
                }
                break :blk self.initValue(.{ .float_list = list });
            },
            else => unreachable,
        },
        .float => |float_x| switch (y.as) {
            .boolean => |bool_y| self.initValue(.{ .float = divideFloat(float_x, utils_mod.intToFloat(@boolToInt(bool_y))) }),
            .int => |int_y| self.initValue(.{ .float = divideFloat(float_x, utils_mod.intToFloat(int_y)) }),
            .float => |float_y| self.initValue(.{ .float = divideFloat(float_x, float_y) }),
            .list => |list_y| blk: {
                const list = self.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ValueType = switch (list_y[0].as) {
                    .boolean, .int, .float => .float,
                    else => .list,
                };
                for (list_y) |value, i| {
                    list[i] = divide(self, x, value);
                    if (list_type != .list and list_type != list[i].as) list_type = .list;
                }
                break :blk self.initValue(switch (list_type) {
                    .float => .{ .float_list = list },
                    else => .{ .list = list },
                });
            },
            .boolean_list => |boolean_list_y| blk: {
                const list = self.allocator.alloc(*Value, boolean_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (boolean_list_y) |value, i| {
                    list[i] = self.initValue(.{ .float = divideFloat(float_x, utils_mod.intToFloat(@boolToInt(value.as.boolean))) });
                }
                break :blk self.initValue(.{ .float_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = self.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_y) |value, i| {
                    list[i] = self.initValue(.{ .float = divideFloat(float_x, utils_mod.intToFloat(value.as.int)) });
                }
                break :blk self.initValue(.{ .float_list = list });
            },
            .float_list => |float_list_y| blk: {
                const list = self.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_y) |value, i| {
                    list[i] = self.initValue(.{ .float = divideFloat(float_x, value.as.float) });
                }
                break :blk self.initValue(.{ .float_list = list });
            },
            else => unreachable,
        },
        .list => |list_x| switch (y.as) {
            .boolean, .int => blk: {
                const list = self.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ValueType = switch (list_x[0].as) {
                    .boolean, .int, .float => .float,
                    else => .list,
                };
                for (list_x) |value, i| {
                    list[i] = divide(self, value, y);
                    if (list_type != .list and list_type != list[i].as) list_type = .list;
                }
                break :blk self.initValue(switch (list_type) {
                    .float => .{ .float_list = list },
                    else => .{ .list = list },
                });
            },
            .float => blk: {
                const list = self.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ValueType = switch (list_x[0].as) {
                    .boolean, .int, .float => .float,
                    else => .list,
                };
                for (list_x) |value, i| {
                    list[i] = divide(self, value, y);
                    if (list_type != .list and list_type != list[i].as) list_type = .list;
                }
                break :blk self.initValue(switch (list_type) {
                    .float => .{ .float_list = list },
                    else => .{ .list = list },
                });
            },
            .list,
            .boolean_list,
            .int_list,
            .float_list,
            => |list_y| blk: {
                const list = self.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ?ValueType = null;
                for (list_x) |value, i| {
                    list[i] = divide(self, value, list_y[i]);
                    if (list_type == null and @as(ValueType, list[0].as) != @as(ValueType, list[i].as)) list_type = .list;
                }
                break :blk self.initValue(switch (if (list_type) |value_type| value_type else @as(ValueType, list[0].as)) {
                    .float => .{ .float_list = list },
                    else => .{ .list = list },
                });
            },
            else => unreachable,
        },
        .boolean_list => |boolean_list_x| switch (y.as) {
            .boolean => |bool_y| blk: {
                const list = self.allocator.alloc(*Value, boolean_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (boolean_list_x) |value, i| {
                    list[i] = self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(@boolToInt(value.as.boolean)), utils_mod.intToFloat(@boolToInt(bool_y))) });
                }
                break :blk self.initValue(.{ .float_list = list });
            },
            .int => |int_y| blk: {
                const list = self.allocator.alloc(*Value, boolean_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (boolean_list_x) |value, i| {
                    list[i] = self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(@boolToInt(value.as.boolean)), utils_mod.intToFloat(int_y)) });
                }
                break :blk self.initValue(.{ .float_list = list });
            },
            .float => |float_y| blk: {
                const list = self.allocator.alloc(*Value, boolean_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (boolean_list_x) |value, i| {
                    list[i] = self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(@boolToInt(value.as.boolean)), float_y) });
                }
                break :blk self.initValue(.{ .float_list = list });
            },
            .list => |list_y| blk: {
                const list = self.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ValueType = switch (list_y[0].as) {
                    .boolean, .int, .float => .float,
                    else => .list,
                };
                for (boolean_list_x) |value, i| {
                    list[i] = divide(self, value, list_y[i]);
                    if (list_type != .list and list_type != list[i].as) list_type = .list;
                }
                break :blk self.initValue(switch (list_type) {
                    .float => .{ .float_list = list },
                    else => .{ .list = list },
                });
            },
            .boolean_list => |boolean_list_y| blk: {
                const list = self.allocator.alloc(*Value, boolean_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (boolean_list_x) |value, i| {
                    list[i] = self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(@boolToInt(value.as.boolean)), utils_mod.intToFloat(@boolToInt(boolean_list_y[i].as.boolean))) });
                }
                break :blk self.initValue(.{ .float_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = self.allocator.alloc(*Value, boolean_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (boolean_list_x) |value, i| {
                    list[i] = self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(@boolToInt(value.as.boolean)), utils_mod.intToFloat(int_list_y[i].as.int)) });
                }
                break :blk self.initValue(.{ .float_list = list });
            },
            .float_list => |float_list_y| blk: {
                const list = self.allocator.alloc(*Value, boolean_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (boolean_list_x) |value, i| {
                    list[i] = self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(@boolToInt(value.as.boolean)), float_list_y[i].as.float) });
                }
                break :blk self.initValue(.{ .float_list = list });
            },
            else => unreachable,
        },
        .int_list => |int_list_x| switch (y.as) {
            .boolean => |bool_y| blk: {
                const list = self.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_x) |value, i| {
                    list[i] = self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(value.as.int), utils_mod.intToFloat(@boolToInt(bool_y))) });
                }
                break :blk self.initValue(.{ .float_list = list });
            },
            .int => |int_y| blk: {
                const list = self.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_x) |value, i| {
                    list[i] = self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(value.as.int), utils_mod.intToFloat(int_y)) });
                }
                break :blk self.initValue(.{ .float_list = list });
            },
            .float => |float_y| blk: {
                const list = self.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_x) |value, i| {
                    list[i] = self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(value.as.int), float_y) });
                }
                break :blk self.initValue(.{ .float_list = list });
            },
            .list => |list_y| blk: {
                const list = self.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ValueType = switch (list_y[0].as) {
                    .boolean, .int, .float => .float,
                    else => .list,
                };
                for (int_list_x) |value, i| {
                    list[i] = divide(self, value, list_y[i]);
                    if (list_type != .list and list_type != list[i].as) list_type = .list;
                }
                break :blk self.initValue(switch (list_type) {
                    .float => .{ .float_list = list },
                    else => .{ .list = list },
                });
            },
            .boolean_list => |boolean_list_y| blk: {
                const list = self.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_x) |value, i| {
                    list[i] = self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(value.as.int), utils_mod.intToFloat(@boolToInt(boolean_list_y[i].as.boolean))) });
                }
                break :blk self.initValue(.{ .float_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = self.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_x) |value, i| {
                    list[i] = self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(value.as.int), utils_mod.intToFloat(int_list_y[i].as.int)) });
                }
                break :blk self.initValue(.{ .float_list = list });
            },
            .float_list => |float_list_y| blk: {
                const list = self.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_x) |value, i| {
                    list[i] = self.initValue(.{ .float = divideFloat(utils_mod.intToFloat(value.as.int), float_list_y[i].as.float) });
                }
                break :blk self.initValue(.{ .float_list = list });
            },
            else => unreachable,
        },
        .float_list => |float_list_x| switch (y.as) {
            .boolean => |bool_y| blk: {
                const list = self.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_x) |value, i| {
                    list[i] = self.initValue(.{ .float = divideFloat(value.as.float, utils_mod.intToFloat(@boolToInt(bool_y))) });
                }
                break :blk self.initValue(.{ .float_list = list });
            },
            .int => |int_y| blk: {
                const list = self.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_x) |value, i| {
                    list[i] = self.initValue(.{ .float = divideFloat(value.as.float, utils_mod.intToFloat(int_y)) });
                }
                break :blk self.initValue(.{ .float_list = list });
            },
            .float => |float_y| blk: {
                const list = self.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_x) |value, i| {
                    list[i] = self.initValue(.{ .float = divideFloat(value.as.float, float_y) });
                }
                break :blk self.initValue(.{ .float_list = list });
            },
            .list => |list_y| blk: {
                const list = self.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ValueType = switch (list_y[0].as) {
                    .boolean, .int, .float => .float,
                    else => .list,
                };
                for (float_list_x) |value, i| {
                    list[i] = divide(self, value, list_y[i]);
                    if (list_type != .list and list_type != list[i].as) list_type = .list;
                }
                break :blk self.initValue(switch (list_type) {
                    .float => .{ .float_list = list },
                    else => .{ .list = list },
                });
            },
            .boolean_list => |boolean_list_y| blk: {
                const list = self.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_x) |value, i| {
                    list[i] = self.initValue(.{ .float = divideFloat(value.as.float, utils_mod.intToFloat(@boolToInt(boolean_list_y[i].as.boolean))) });
                }
                break :blk self.initValue(.{ .float_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = self.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_x) |value, i| {
                    list[i] = self.initValue(.{ .float = divideFloat(value.as.float, utils_mod.intToFloat(int_list_y[i].as.int)) });
                }
                break :blk self.initValue(.{ .float_list = list });
            },
            .float_list => |float_list_y| blk: {
                const list = self.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_x) |value, i| {
                    list[i] = self.initValue(.{ .float = divideFloat(value.as.float, float_list_y[i].as.float) });
                }
                break :blk self.initValue(.{ .float_list = list });
            },
            else => unreachable,
        },
        else => unreachable,
    };
}
