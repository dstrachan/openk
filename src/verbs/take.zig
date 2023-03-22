const std = @import("std");

const utils_mod = @import("../utils.zig");
const print = utils_mod.print;

const value_mod = @import("../value.zig");
const Value = value_mod.Value;
const ValueType = value_mod.ValueType;

const vm_mod = @import("../vm.zig");
const VM = vm_mod.VM;

pub const TakeError = error{
    invalid_type,
};

fn runtimeError(comptime err: TakeError) TakeError!*Value {
    switch (err) {
        TakeError.invalid_type => print("NYI", .{}),
    }
    return err;
}

pub fn take(vm: *VM, x: *Value, y: *Value) TakeError!*Value {
    return switch (x.as) {
        .int => |int_x| switch (y.as) {
            .char => blk: {
                const list = vm.allocator.alloc(*Value, @intCast(usize, int_x)) catch std.debug.panic("Failed to create list.", .{});
                for (list) |*value| {
                    value.* = y.ref();
                }
                break :blk vm.initValue(.{ .char_list = list });
            },
            else => runtimeError(TakeError.invalid_type),
        },
        else => runtimeError(TakeError.invalid_type),
    };
}
