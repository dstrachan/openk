const std = @import("std");

const utils_mod = @import("../utils.zig");
const print = utils_mod.print;

const value_mod = @import("../value.zig");
const Value = value_mod.Value;
const ValueType = value_mod.ValueType;

const vm_mod = @import("../vm.zig");
const VM = vm_mod.VM;

pub const EnlistError = error{
    invalid_type,
};

fn runtimeError(comptime err: EnlistError) EnlistError!*Value {
    switch (err) {
        EnlistError.invalid_type => print("Can only enlist dictionaries with symbol keys.", .{}),
    }
    return err;
}

pub fn enlist(vm: *VM, x: *Value) EnlistError!*Value {
    return switch (x.as) {
        .dictionary => |dict_x| blk: {
            if (dict_x.keys.as != .symbol_list) break :blk runtimeError(EnlistError.invalid_type);

            const list = vm.allocator.alloc(*Value, dict_x.keys.as.symbol_list.len) catch std.debug.panic("Failed to create list.", .{});
            errdefer vm.allocator.free(list);
            for (list, dict_x.values.asList(), 0..) |*value, x_value, i| {
                errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                value.* = try enlist(vm, x_value);
            }
            const values = vm.initValue(.{ .list = list });
            break :blk vm.initTable(.{ .columns = dict_x.keys.ref(), .values = values });
        },
        else => blk: {
            const list = vm.allocator.alloc(*Value, 1) catch std.debug.panic("Failed to create list.", .{});
            list[0] = x.ref();
            break :blk vm.initListAtoms(list, x.as);
        },
    };
}
