const std = @import("std");

const utils_mod = @import("../utils.zig");
const print = utils_mod.print;

const value_mod = @import("../value.zig");
const Value = value_mod.Value;
const ValueType = value_mod.ValueType;

const vm_mod = @import("../vm.zig");
const VM = vm_mod.VM;

pub const NotError = error{
    invalid_type,
};

fn runtimeError(comptime err: NotError) NotError!*Value {
    switch (err) {
        NotError.invalid_type => print("Can only not numeric values.", .{}),
    }
    return err;
}

pub fn not(vm: *VM, x: *Value) NotError!*Value {
    _ = vm;
    return switch (x.as) {
        else => runtimeError(NotError.invalid_type),
    };
}
