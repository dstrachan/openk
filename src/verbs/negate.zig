const std = @import("std");

const utils_mod = @import("../utils.zig");
const print = utils_mod.print;

const value_mod = @import("../value.zig");
const Value = value_mod.Value;
const ValueType = value_mod.ValueType;

const vm_mod = @import("../vm.zig");
const VM = vm_mod.VM;

pub const NegateError = error{
    invalid_type,
};

fn runtimeError(comptime err: NegateError) NegateError!*Value {
    switch (err) {
        NegateError.invalid_type => print("Can only flip list values.", .{}),
    }
    return err;
}

pub fn negate(vm: *VM, x: *Value) NegateError!*Value {
    return switch (x.as) {
        .boolean => |bool_x| vm.initValue(.{ .int = if (bool_x) -1 else 0 }),
        .int => |int_x| vm.initValue(.{ .int = -int_x }),
        .float => |float_x| vm.initValue(.{ .float = -float_x }),
        .boolean_list => |bool_list_x| blk: {
            const list = vm.allocator.alloc(*Value, bool_list_x.len) catch std.debug.panic("Failed to create list.", .{});
            for (bool_list_x) |value, i| {
                list[i] = vm.initValue(.{ .int = if (value.as.boolean) -1 else 0 });
            }
            break :blk vm.initValue(.{ .int_list = list });
        },
        .int_list => |int_list_x| blk: {
            const list = vm.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
            for (int_list_x) |value, i| {
                list[i] = vm.initValue(.{ .int = -value.as.int });
            }
            break :blk vm.initValue(.{ .int_list = list });
        },
        .float_list => |float_list_x| blk: {
            const list = vm.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
            for (float_list_x) |value, i| {
                list[i] = vm.initValue(.{ .float = -value.as.float });
            }
            break :blk vm.initValue(.{ .int_list = list });
        },
        else => return runtimeError(NegateError.invalid_type),
    };
}
