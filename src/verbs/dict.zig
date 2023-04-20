const std = @import("std");

const utils_mod = @import("../utils.zig");
const print = utils_mod.print;

const value_mod = @import("../value.zig");
const Value = value_mod.Value;

const vm_mod = @import("../vm.zig");
const VM = vm_mod.VM;

pub const DictError = error{
    incompatible_types,
    length_mismatch,
};

fn runtimeError(comptime err: DictError) DictError!*Value {
    switch (err) {
        DictError.incompatible_types => print("Incompatible types.\n", .{}),
        DictError.length_mismatch => print("List lengths must match.\n", .{}),
    }
    return err;
}

pub fn dict(vm: *VM, x: *Value, y: *Value) DictError!*Value {
    return switch (x.as) {
        .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list_x| switch (y.as) {
            .list => |list_y| blk: {
                if (list_y.len > 0) {
                    if (list_x.len != list_y.len) return runtimeError(DictError.length_mismatch);

                    break :blk vm.initDictionary(.{ .keys = x.ref(), .values = y.ref() });
                }

                const list = vm.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
                var i: usize = 0;
                while (i < list_x.len) : (i += 1) {
                    list[i] = y.ref();
                }
                const values = vm.initValue(.{ .list = list });
                break :blk vm.initDictionary(.{ .keys = x.ref(), .values = values });
            },
            .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list_y| blk: {
                if (list_x.len != list_y.len) return runtimeError(DictError.length_mismatch);

                break :blk vm.initDictionary(.{ .keys = x.ref(), .values = y.ref() });
            },
            else => runtimeError(DictError.incompatible_types),
        },
        else => runtimeError(DictError.incompatible_types),
    };
}
