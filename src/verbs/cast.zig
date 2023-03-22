const std = @import("std");

const utils_mod = @import("../utils.zig");
const print = utils_mod.print;

const value_mod = @import("../value.zig");
const Value = value_mod.Value;
const ValueType = value_mod.ValueType;

const vm_mod = @import("../vm.zig");
const VM = vm_mod.VM;

pub const CastError = error{
    invalid_type,
};

fn runtimeError(comptime err: CastError) CastError!*Value {
    switch (err) {
        CastError.invalid_type => print("NYI", .{}),
    }
    return err;
}

pub fn cast(vm: *VM, x: *Value, y: *Value) CastError!*Value {
    return switch (x.as) {
        .symbol => switch (y.as) {
            .char_list => |list_y| blk: {
                const list = vm.allocator.alloc(u8, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (list, list_y) |*char, y_value| {
                    char.* = y_value.as.char;
                }
                break :blk vm.takeSymbol(list);
            },
            else => runtimeError(CastError.invalid_type),
        },
        else => runtimeError(CastError.invalid_type),
    };
}
