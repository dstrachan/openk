const std = @import("std");

const utils_mod = @import("../utils.zig");
const print = utils_mod.print;

const value_mod = @import("../value.zig");
const Value = value_mod.Value;
const ValueDictionary = value_mod.ValueDictionary;
const ValueType = value_mod.ValueType;

const vm_mod = @import("../vm.zig");
const VM = vm_mod.VM;

pub const ApplyError = error{
    incompatible_types,
};

fn runtimeError(comptime err: ApplyError) ApplyError!*Value {
    switch (err) {
        ApplyError.incompatible_types => print("Incompatible types.\n", .{}),
    }
    return err;
}

pub fn index(vm: *VM, x: *Value, y: *Value) ApplyError!*Value {
    return switch (x.as) {
        .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list_x| switch (y.as) {
            .boolean => |bool_y| if (list_x.len <= @boolToInt(bool_y)) list_x[0].copyNull(vm) else list_x[@boolToInt(bool_y)].ref(),
            .int => |int_y| if (int_y < 0 or list_x.len <= int_y) list_x[0].copyNull(vm) else list_x[@intCast(usize, int_y)].ref(),
            .list, .boolean_list, .int_list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = if (list_y.len == 0) .list else null;
                for (list_y, 0..) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try index(vm, x, value);
                    if (list_type == null and @as(ValueType, list[0].as) != list[i].as) list_type = .list;
                }
                break :blk vm.initList(list, list_type);
            },
            else => runtimeError(ApplyError.incompatible_types),
        },
        .dictionary => |dict_x| switch (y.as) {
            .boolean, .int, .float, .char, .symbol => if (dict_x.hash_map.?.get(y)) |v| v.ref() else vm.initNull(dict_x.values.as),
            .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (list_y, 0..) |lookup, i| {
                    list[i] = if (dict_x.hash_map.?.get(lookup)) |v| v.ref() else vm.initNull(dict_x.values.as);
                }
                break :blk vm.initList(list, dict_x.values.as);
            },
            else => runtimeError(ApplyError.incompatible_types),
        },
        .function => unreachable,
        .projection => unreachable,
        else => runtimeError(ApplyError.incompatible_types),
    };
}
