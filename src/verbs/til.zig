const std = @import("std");

const utils_mod = @import("../utils.zig");
const print = utils_mod.print;

const value_mod = @import("../value.zig");
const Value = value_mod.Value;
const ValueType = value_mod.ValueType;

const vm_mod = @import("../vm.zig");
const VM = vm_mod.VM;

pub const TilError = error{
    length_mismatch,
    invalid_type,
};

fn runtimeError(comptime err: TilError) !*Value {
    switch (err) {
        TilError.length_mismatch => print("Can only flip values of equal length.\n", .{}),
        TilError.invalid_type => print("Can only flip list values.", .{}),
    }
    return err;
}

pub fn til(vm: *VM, x: *Value) TilError!*Value {
    return switch (x.as) {
        .int => |int_x| blk: {
            const list = vm.allocator.alloc(*Value, std.math.absCast(int_x)) catch std.debug.panic("Failed to create list.", .{});
            if (int_x < 0) {
                for (list) |_, i| {
                    list[i] = vm.initValue(.{ .int = int_x + @intCast(i64, i) });
                }
            } else {
                for (list) |_, i| {
                    list[i] = vm.initValue(.{ .int = @intCast(i64, i) });
                }
            }
            break :blk vm.initValue(.{ .int_list = list });
        },
        else => unreachable,
    };
}
