const std = @import("std");

const utils_mod = @import("../utils.zig");
const print = utils_mod.print;

const value_mod = @import("../value.zig");
const Value = value_mod.Value;
const ValueType = value_mod.ValueType;

const vm_mod = @import("../vm.zig");
const VM = vm_mod.VM;

pub const ReciprocalError = error{
    invalid_type,
};

fn runtimeError(comptime err: ReciprocalError) ReciprocalError!*Value {
    switch (err) {
        ReciprocalError.invalid_type => print("Can only get the reciprocal of numeric values.", .{}),
    }
    return err;
}

fn reciprocalFloat(x: f64) f64 {
    return 1 / x;
}

pub fn reciprocal(vm: *VM, x: *Value) ReciprocalError!*Value {
    return switch (x.as) {
        .boolean => |bool_x| vm.initValue(.{ .float = if (bool_x) 1 else Value.inf_float }),
        .int => |int_x| vm.initValue(.{ .float = reciprocalFloat(utils_mod.intToFloat(int_x)) }),
        .float => |float_x| vm.initValue(.{ .float = reciprocalFloat(float_x) }),
        .list, .boolean_list, .int_list, .float_list => |list_x| blk: {
            if (list_x.len == 0) break :blk vm.initList(&.{}, if (x.as == .list) .list else .float_list);

            const list = vm.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
            errdefer vm.allocator.free(list);
            var list_type: ValueType = .float;
            for (list, list_x, 0..) |*value, x_value, i| {
                errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                value.* = try reciprocal(vm, x_value);
                if (list_type != .list and value.*.as != .float) list_type = .list;
            }
            break :blk vm.initList(list, list_type);
        },
        .dictionary => |dict_x| blk: {
            const values = try reciprocal(vm, dict_x.values);
            break :blk vm.initDictionary(.{ .keys = dict_x.keys.ref(), .values = values });
        },
        .table => |table_x| blk: {
            const values = try reciprocal(vm, table_x.values);
            break :blk vm.initTable(.{ .columns = table_x.columns.ref(), .values = values });
        },
        else => runtimeError(ReciprocalError.invalid_type),
    };
}
