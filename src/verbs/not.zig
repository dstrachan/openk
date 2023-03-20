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
    return switch (x.as) {
        .boolean => |bool_x| vm.initValue(.{ .boolean = bool_x == false }),
        .int => |int_x| vm.initValue(.{ .boolean = int_x == 0 }),
        .float => |float_x| vm.initValue(.{ .boolean = float_x == 0 }),
        .list, .boolean_list, .int_list, .float_list => |list_x| blk: {
            if (list_x.len == 0) break :blk vm.initList(&.{}, utils_mod.minType(&.{ .boolean_list, x.as }));

            const list = vm.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
            errdefer vm.allocator.free(list);
            var list_type: ValueType = .boolean;
            for (list, list_x, 0..) |*value, x_value, i| {
                errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                value.* = try not(vm, x_value);
                if (list_type != .list and value.*.as != .boolean) list_type = .list;
            }
            break :blk vm.initList(list, list_type);
        },
        .dictionary => |dict_x| blk: {
            const values = try not(vm, dict_x.values);
            break :blk vm.initDictionary(.{ .keys = dict_x.keys.ref(), .values = values });
        },
        .table => |table_x| blk: {
            const values = try not(vm, table_x.values);
            break :blk vm.initTable(.{ .columns = table_x.columns.ref(), .values = values });
        },
        else => runtimeError(NotError.invalid_type),
    };
}
