const std = @import("std");

const utils_mod = @import("../utils.zig");
const print = utils_mod.print;

const value_mod = @import("../value.zig");
const Value = value_mod.Value;

const vm_mod = @import("../vm.zig");
const VM = vm_mod.VM;

pub const KeyError = error{
    invalid_type,
    enum_range,
    nyi,
};

fn runtimeError(comptime err: KeyError) KeyError!*Value {
    switch (err) {
        KeyError.invalid_type => print("Can only key dictionaries with symbol keys.", .{}),
        KeyError.enum_range => print("Can only enumerate positive numbers.", .{}),
        KeyError.nyi => print("NYI", .{}),
    }
    return err;
}

pub fn key(vm: *VM, x: *Value) KeyError!*Value {
    return switch (x.as) {
        .boolean => |bool_x| blk: {
            if (bool_x) {
                const list = vm.allocator.alloc(*Value, 1) catch std.debug.panic("Failed to create list.", .{});
                list[0] = vm.initValue(.{ .int = 0 });
                break :blk vm.initValue(.{ .int_list = list });
            } else {
                break :blk vm.initValue(.{ .int_list = &.{} });
            }
        },
        .int => |int_x| blk: {
            if (int_x < 0) break :blk runtimeError(KeyError.enum_range);

            const list = vm.allocator.alloc(*Value, @intCast(usize, int_x)) catch std.debug.panic("Failed to create list.", .{});
            for (list, 0..) |*value, i| {
                value.* = vm.initValue(.{ .int = @intCast(i64, i) });
            }
            break :blk vm.initValue(.{ .int_list = list });
        },
        .symbol => runtimeError(KeyError.nyi),
        .boolean_list => vm.copySymbol("boolean"),
        .int_list => vm.copySymbol("int"),
        .float_list => vm.copySymbol("float"),
        .char_list => vm.copySymbol("char"),
        .symbol_list => vm.copySymbol("symbol"),
        .dictionary => |dict_x| dict_x.keys.ref(),
        else => runtimeError(KeyError.invalid_type),
    };
}
