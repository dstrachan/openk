const std = @import("std");

const utils_mod = @import("../utils.zig");
const print = utils_mod.print;

const value_mod = @import("../value.zig");
const Value = value_mod.Value;
const ValueDictionary = value_mod.ValueDictionary;
const ValueTable = value_mod.ValueTable;
const ValueType = value_mod.ValueType;

const vm_mod = @import("../vm.zig");
const VM = vm_mod.VM;

pub const LessError = error{
    incompatible_types,
    length_mismatch,
};

fn runtimeError(comptime err: LessError) LessError!*Value {
    switch (err) {
        LessError.incompatible_types => print("Incompatible types.\n", .{}),
        LessError.length_mismatch => print("List lengths must match.\n", .{}),
    }
    return err;
}

fn lessInt(x: i64, y: i64) bool {
    return x < y;
}

fn lessFloat(x: f64, y: f64) bool {
    if (std.math.isNan(x)) return !std.math.isNan(y);
    return x < y;
}

pub fn less(vm: *VM, x: *Value, y: *Value) LessError!*Value {
    return switch (x.as) {
        .boolean => |bool_x| switch (y.as) {
            .boolean => |bool_y| vm.initValue(.{ .boolean = lessInt(@boolToInt(bool_x), @boolToInt(bool_y)) }),
            .int => |int_y| vm.initValue(.{ .boolean = lessInt(@boolToInt(bool_x), int_y) }),
            .float => |float_y| vm.initValue(.{ .boolean = lessFloat(if (bool_x) 1 else 0, float_y) }),
            .list, .boolean_list, .int_list, .float_list => |list_y| blk: {
                if (list_y.len == 0) break :blk vm.initList(&[_]*Value{}, @intToEnum(ValueType, std.math.min(@enumToInt(ValueType.boolean_list), @enumToInt(y.as))));

                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                for (list_y, 0..) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try less(vm, x, value);
                }
                break :blk vm.initValue(.{ .boolean_list = list });
            },
            .dictionary => |dict_y| blk: {
                const value = try less(vm, x, dict_y.value);
                const dictionary = ValueDictionary.init(.{ .key = dict_y.key.ref(), .value = value }, vm.allocator);
                break :blk vm.initValue(.{ .dictionary = dictionary });
            },
            .table => |table_y| blk: {
                const values = try less(vm, x, table_y.values);
                const table = ValueTable.init(.{ .columns = table_y.columns.ref(), .values = values }, vm.allocator);
                break :blk vm.initValue(.{ .table = table });
            },
            else => runtimeError(LessError.incompatible_types),
        },
        .int => |int_x| switch (y.as) {
            .boolean => |bool_y| vm.initValue(.{ .boolean = lessInt(int_x, @boolToInt(bool_y)) }),
            .int => |int_y| vm.initValue(.{ .boolean = lessInt(int_x, int_y) }),
            .float => |float_y| vm.initValue(.{ .boolean = lessFloat(utils_mod.intToFloat(int_x), float_y) }),
            .list, .boolean_list, .int_list, .float_list => |list_y| blk: {
                if (list_y.len == 0) break :blk vm.initList(&[_]*Value{}, @intToEnum(ValueType, std.math.min(@enumToInt(ValueType.boolean_list), @enumToInt(y.as))));

                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                for (list_y, 0..) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try less(vm, x, value);
                }
                break :blk vm.initValue(.{ .boolean_list = list });
            },
            .dictionary => |dict_y| blk: {
                const value = try less(vm, x, dict_y.value);
                const dictionary = ValueDictionary.init(.{ .key = dict_y.key.ref(), .value = value }, vm.allocator);
                break :blk vm.initValue(.{ .dictionary = dictionary });
            },
            .table => |table_y| blk: {
                const values = try less(vm, x, table_y.values);
                const table = ValueTable.init(.{ .columns = table_y.columns.ref(), .values = values }, vm.allocator);
                break :blk vm.initValue(.{ .table = table });
            },
            else => runtimeError(LessError.incompatible_types),
        },
        .float => |float_x| switch (y.as) {
            .boolean => |bool_y| vm.initValue(.{ .boolean = lessFloat(float_x, if (bool_y) 1 else 0) }),
            .int => |int_y| vm.initValue(.{ .boolean = lessFloat(float_x, utils_mod.intToFloat(int_y)) }),
            .float => |float_y| vm.initValue(.{ .boolean = lessFloat(float_x, float_y) }),
            .list, .boolean_list, .int_list, .float_list => |list_y| blk: {
                if (list_y.len == 0) break :blk vm.initList(&[_]*Value{}, @intToEnum(ValueType, std.math.min(@enumToInt(ValueType.boolean_list), @enumToInt(y.as))));

                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                for (list_y, 0..) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try less(vm, x, value);
                }
                break :blk vm.initValue(.{ .boolean_list = list });
            },
            .dictionary => |dict_y| blk: {
                const value = try less(vm, x, dict_y.value);
                const dictionary = ValueDictionary.init(.{ .key = dict_y.key.ref(), .value = value }, vm.allocator);
                break :blk vm.initValue(.{ .dictionary = dictionary });
            },
            .table => |table_y| blk: {
                const values = try less(vm, x, table_y.values);
                const table = ValueTable.init(.{ .columns = table_y.columns.ref(), .values = values }, vm.allocator);
                break :blk vm.initValue(.{ .table = table });
            },
            else => runtimeError(LessError.incompatible_types),
        },
        .list, .boolean_list, .int_list, .float_list => |list_x| switch (y.as) {
            .boolean, .int, .float => blk: {
                if (list_x.len == 0) break :blk vm.initList(&[_]*Value{}, @intToEnum(ValueType, std.math.min(@enumToInt(ValueType.boolean_list), @enumToInt(x.as))));

                const list = vm.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                for (list_x, 0..) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try less(vm, value, y);
                }
                break :blk vm.initValue(.{ .boolean_list = list });
            },
            .list, .boolean_list, .int_list, .float_list => |list_y| blk: {
                if (list_x.len != list_y.len) break :blk runtimeError(LessError.length_mismatch);
                if (list_x.len == 0) break :blk vm.initList(&[_]*Value{}, @intToEnum(ValueType, std.math.min(@enumToInt(x.as), @enumToInt(y.as))));

                const list = vm.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ValueType = .boolean_list;
                for (list_x, list_y, 0..) |value_x, value_y, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try less(vm, value_x, value_y);
                    if (list_type != .list and @as(ValueType, list[0].as) != list[i].as) list_type = .list;
                }
                break :blk vm.initList(list, list_type);
            },
            .dictionary => |dict_y| blk: {
                const value = try less(vm, x, dict_y.value);
                const dictionary = ValueDictionary.init(.{ .key = dict_y.key.ref(), .value = value }, vm.allocator);
                break :blk vm.initValue(.{ .dictionary = dictionary });
            },
            else => runtimeError(LessError.incompatible_types),
        },
        .dictionary => |dict_x| switch (y.as) {
            .boolean, .int, .float, .list, .boolean_list, .int_list, .float_list => blk: {
                const value = try less(vm, dict_x.value, y);
                const dictionary = ValueDictionary.init(.{ .key = dict_x.key.ref(), .value = value }, vm.allocator);
                break :blk vm.initValue(.{ .dictionary = dictionary });
            },
            .dictionary => |dict_y| blk: {
                var key = dict_x.key.asArrayList(vm.allocator);
                errdefer key.deinit();
                errdefer for (key.items) |v| v.deref(vm.allocator);
                var key_list_type: ValueType = dict_x.key.as;
                var value = dict_x.value.asArrayList(vm.allocator);
                errdefer value.deinit();
                errdefer for (value.items) |v| v.deref(vm.allocator);
                for (dict_y.key.asList(), 0..) |k_y, i_y| loop: {
                    for (key.items, 0..) |k_x, i_x| {
                        if (k_x.eql(k_y)) {
                            value.items[i_x].deref(vm.allocator);
                            value.items[i_x] = try less(vm, value.items[i_x], dict_y.value.asList()[i_y]);
                            break :loop;
                        }
                    }
                    key.append(k_y.ref()) catch std.debug.panic("Failed to append item.", .{});
                    if (key_list_type != .list and @as(ValueType, key.items[0].as) != key.items[key.items.len - 1].as) key_list_type = .list;
                    value.append(vm.initValue(.{ .boolean = true })) catch std.debug.panic("Failed to append item.", .{});
                }
                const key_list = key.toOwnedSlice() catch std.debug.panic("Failed to create list.", .{});
                const new_key = vm.initList(key_list, key_list_type);
                const value_list = value.toOwnedSlice() catch std.debug.panic("Failed to create list.", .{});
                const new_value = vm.initList(value_list, .boolean);
                const dictionary = ValueDictionary.init(.{ .key = new_key, .value = new_value }, vm.allocator);
                break :blk vm.initValue(.{ .dictionary = dictionary });
            },
            else => runtimeError(LessError.incompatible_types),
        },
        .table => |table_x| switch (y.as) {
            .boolean, .int, .float => blk: {
                const list = vm.allocator.alloc(*Value, table_x.values.asList().len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                for (table_x.values.asList(), 0..) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try less(vm, value, y);
                }
                const values = vm.initValue(.{ .list = list });
                const table = ValueTable.init(.{ .columns = table_x.columns.ref(), .values = values }, vm.allocator);
                break :blk vm.initValue(.{ .table = table });
            },
            .table => |table_y| blk: {
                var columns = table_x.columns.asArrayList(vm.allocator);
                errdefer columns.deinit();
                errdefer for (columns.items) |v| v.deref(vm.allocator);
                var values = table_x.values.asArrayList(vm.allocator);
                errdefer values.deinit();
                errdefer for (values.items) |v| v.deref(vm.allocator);
                for (table_y.columns.asList(), 0..) |c_y, i_y| loop: {
                    for (columns.items, 0..) |c_x, i_x| {
                        if (c_x.eql(c_y)) {
                            values.items[i_x].deref(vm.allocator);
                            values.items[i_x] = try less(vm, values.items[i_x], table_y.values.asList()[i_y]);
                            break :loop;
                        }
                    }
                    columns.append(c_y.ref()) catch std.debug.panic("Failed to append item.", .{});
                    // TODO: This should be a list of true booleans
                    values.append(vm.initValue(.{ .boolean = true })) catch std.debug.panic("Failed to append item.", .{});
                }
                const columns_list = columns.toOwnedSlice() catch std.debug.panic("Failed to create list.", .{});
                const new_columns = vm.initValue(.{ .symbol_list = columns_list });
                const values_list = values.toOwnedSlice() catch std.debug.panic("Failed to create list.", .{});
                const new_values = vm.initValue(.{ .list = values_list });
                const table = ValueTable.init(.{ .columns = new_columns, .values = new_values }, vm.allocator);
                break :blk vm.initValue(.{ .table = table });
            },
            else => runtimeError(LessError.incompatible_types),
        },
        else => runtimeError(LessError.incompatible_types),
    };
}
