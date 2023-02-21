const std = @import("std");

const utils_mod = @import("../utils.zig");
const print = utils_mod.print;

const value_mod = @import("../value.zig");
const Value = value_mod.Value;
const ValueType = value_mod.ValueType;

const vm_mod = @import("../vm.zig");
const VM = vm_mod.VM;

pub const SqrtError = error{
    length_mismatch,
    invalid_type,
};

fn runtimeError(comptime err: SqrtError) SqrtError!*Value {
    switch (err) {
        SqrtError.length_mismatch => print("Can only sqrt values of equal length.\n", .{}),
        SqrtError.invalid_type => print("Can only sqrt list values.", .{}),
    }
    return err;
}

pub fn sqrt(vm: *VM, x: *Value) SqrtError!*Value {
    return switch (x.as) {
        .boolean => |bool_x| vm.initValue(.{ .float = if (bool_x) 1 else std.math.inf(f64) }),
        .int => |int_x| vm.initValue(.{ .float = std.math.sqrt(utils_mod.intToFloat(int_x)) }),
        .float => |float_x| vm.initValue(.{ .float = std.math.sqrt(float_x) }),
        .list => |list_x| blk: {
            const list = vm.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
            var list_type = ValueType.float_list;
            for (list_x, 0..) |value, i| {
                list[i] = try sqrt(vm, value);
                if (list_type != .list and @as(ValueType, list[i].as) != .float) list_type = .list;
            }
            break :blk vm.initValue(if (list_type == .float_list) .{ .float_list = list } else .{ .list = list });
        },
        .boolean_list => |boolean_list_x| blk: {
            const list = vm.allocator.alloc(*Value, boolean_list_x.len) catch std.debug.panic("Failed to create list.", .{});
            for (boolean_list_x, 0..) |value, i| {
                list[i] = vm.initValue(.{ .float = if (value.as.boolean) 1 else std.math.inf(f64) });
            }
            break :blk vm.initValue(.{ .float_list = list });
        },
        .int_list => |int_list_x| blk: {
            const list = vm.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
            for (int_list_x, 0..) |value, i| {
                list[i] = vm.initValue(.{ .float = std.math.sqrt(utils_mod.intToFloat(value.as.int)) });
            }
            break :blk vm.initValue(.{ .float_list = list });
        },
        .float_list => |float_list_x| blk: {
            const list = vm.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
            for (float_list_x, 0..) |value, i| {
                list[i] = vm.initValue(.{ .float = std.math.sqrt(value.as.float) });
            }
            break :blk vm.initValue(.{ .float_list = list });
        },
        else => unreachable,
    };
}
