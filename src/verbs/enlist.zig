const std = @import("std");

const utils_mod = @import("../utils.zig");
const print = utils_mod.print;

const value_mod = @import("../value.zig");
const Value = value_mod.Value;
const ValueType = value_mod.ValueType;

const vm_mod = @import("../vm.zig");
const VM = vm_mod.VM;

pub const EnlistError = error{
    length_mismatch,
    invalid_type,
};

fn runtimeError(comptime err: EnlistError) EnlistError!*Value {
    switch (err) {
        EnlistError.length_mismatch => print("Can only enlist values of equal length.\n", .{}),
        EnlistError.invalid_type => print("Can only enlist list values.", .{}),
    }
    return err;
}

pub fn enlist(vm: *VM, x: *Value) EnlistError!*Value {
    const list = vm.allocator.alloc(*Value, 1) catch std.debug.panic("Failed to create list.", .{});
    list[0] = x.ref();
    return vm.initValue(switch (x.as) {
        .boolean => .{ .boolean_list = list },
        .int => .{ .int_list = list },
        .float => .{ .float_list = list },
        .char => .{ .char_list = list },
        .symbol => .{ .symbol_list = list },
        else => .{ .list = list },
    });
}
