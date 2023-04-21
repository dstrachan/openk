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

pub const EqualError = error{
    incompatible_types,
    length_mismatch,
};

fn runtimeError(comptime err: EqualError) EqualError!*Value {
    switch (err) {
        EqualError.incompatible_types => print("Incompatible types.\n", .{}),
        EqualError.length_mismatch => print("List lengths must match.\n", .{}),
    }
    return err;
}

fn equalFloat(x: f64, y: f64) bool {
    if (std.math.isNan(x) and std.math.isNan(y)) return true;
    return x == y;
}

pub fn equal(vm: *VM, x: *Value, y: *Value) EqualError!*Value {
    return switch (x.as) {
        .boolean => |bool_x| switch (y.as) {
            .boolean => |bool_y| vm.initValue(.{ .boolean = bool_x == bool_y }),
            .int => |int_y| vm.initValue(.{ .boolean = @boolToInt(bool_x) == int_y }),
            .float => |float_y| vm.initValue(.{ .boolean = equalFloat(if (bool_x) 1 else 0, float_y) }),
            .list, .boolean_list, .int_list, .float_list => |list_y| blk: {
                if (list_y.len == 0) {
                    const list_type = utils_mod.minType(&.{ .boolean_list, y.as });
                    break :blk vm.initList(&.{}, list_type);
                }

                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ValueType = .boolean;
                errdefer vm.allocator.free(list);
                for (list, list_y, 0..) |*value, y_value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    value.* = try equal(vm, x, y_value);
                    if (list_type != .list and value.*.as != .boolean) list_type = .list;
                }
                break :blk vm.initList(list, list_type);
            },
            .dictionary => |dict_y| blk: {
                const values = try equal(vm, x, dict_y.values);
                break :blk vm.initDictionary(.{ .keys = dict_y.keys.ref(), .values = values });
            },
            .table => |table_y| blk: {
                const values = try equal(vm, x, table_y.values);
                break :blk vm.initTable(.{ .columns = table_y.columns.ref(), .values = values });
            },
            else => runtimeError(EqualError.incompatible_types),
        },
        .int => |int_x| switch (y.as) {
            .boolean => |bool_y| vm.initValue(.{ .boolean = int_x == @boolToInt(bool_y) }),
            .int => |int_y| vm.initValue(.{ .boolean = int_x == int_y }),
            .float => |float_y| vm.initValue(.{ .boolean = equalFloat(utils_mod.intToFloat(int_x), float_y) }),
            .list, .boolean_list, .int_list, .float_list => |list_y| blk: {
                if (list_y.len == 0) {
                    const list_type = utils_mod.minType(&.{ .boolean_list, y.as });
                    break :blk vm.initList(&.{}, list_type);
                }

                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ValueType = .boolean;
                errdefer vm.allocator.free(list);
                for (list, list_y, 0..) |*value, y_value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    value.* = try equal(vm, x, y_value);
                    if (list_type != .list and value.*.as != .boolean) list_type = .list;
                }
                break :blk vm.initList(list, list_type);
            },
            .dictionary => |dict_y| blk: {
                const values = try equal(vm, x, dict_y.values);
                break :blk vm.initDictionary(.{ .keys = dict_y.keys.ref(), .values = values });
            },
            .table => |table_y| blk: {
                const values = try equal(vm, x, table_y.values);
                break :blk vm.initTable(.{ .columns = table_y.columns.ref(), .values = values });
            },
            else => runtimeError(EqualError.incompatible_types),
        },
        .float => |float_x| switch (y.as) {
            .boolean => |bool_y| vm.initValue(.{ .boolean = equalFloat(float_x, if (bool_y) 1 else 0) }),
            .int => |int_y| vm.initValue(.{ .boolean = equalFloat(float_x, utils_mod.intToFloat(int_y)) }),
            .float => |float_y| vm.initValue(.{ .boolean = equalFloat(float_x, float_y) }),
            .list, .boolean_list, .int_list, .float_list => |list_y| blk: {
                if (list_y.len == 0) {
                    const list_type = utils_mod.minType(&.{ .boolean_list, y.as });
                    break :blk vm.initList(&.{}, list_type);
                }

                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ValueType = .boolean;
                errdefer vm.allocator.free(list);
                for (list, list_y, 0..) |*value, y_value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    value.* = try equal(vm, x, y_value);
                    if (list_type != .list and value.*.as != .boolean) list_type = .list;
                }
                break :blk vm.initList(list, list_type);
            },
            .dictionary => |dict_y| blk: {
                const values = try equal(vm, x, dict_y.values);
                break :blk vm.initDictionary(.{ .keys = dict_y.keys.ref(), .values = values });
            },
            .table => |table_y| blk: {
                const values = try equal(vm, x, table_y.values);
                break :blk vm.initTable(.{ .columns = table_y.columns.ref(), .values = values });
            },
            else => runtimeError(EqualError.incompatible_types),
        },
        .list, .boolean_list, .int_list, .float_list => |list_x| switch (y.as) {
            .boolean, .int, .float => blk: {
                if (list_x.len == 0) {
                    const list_type = utils_mod.minType(&.{ x.as, .boolean_list });
                    break :blk vm.initList(&.{}, list_type);
                }

                const list = vm.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ValueType = .boolean;
                errdefer vm.allocator.free(list);
                for (list, list_x, 0..) |*value, x_value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    value.* = try equal(vm, x_value, y);
                    if (list_type != .list and value.*.as != .boolean) list_type = .list;
                }
                break :blk vm.initList(list, list_type);
            },
            .list, .boolean_list, .int_list, .float_list => |list_y| blk: {
                if (list_x.len != list_y.len) break :blk runtimeError(EqualError.length_mismatch);
                if (list_x.len == 0) {
                    const list_type = utils_mod.minType(&.{ .boolean_list, x.as, y.as });
                    break :blk vm.initList(&.{}, list_type);
                }

                const list = vm.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ValueType = .boolean;
                errdefer vm.allocator.free(list);
                for (list, list_x, list_y, 0..) |*value, x_value, y_value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    value.* = try equal(vm, x_value, y_value);
                    if (list_type != .list and value.*.as != .boolean) list_type = .list;
                }
                break :blk vm.initList(list, list_type);
            },
            .dictionary => |dict_y| blk: {
                const values = try equal(vm, x, dict_y.values);
                break :blk vm.initDictionary(.{ .keys = dict_y.keys.ref(), .values = values });
            },
            else => runtimeError(EqualError.incompatible_types),
        },
        .dictionary => |dict_x| switch (y.as) {
            .boolean, .int, .float, .list, .boolean_list, .int_list, .float_list => blk: {
                const values = try equal(vm, dict_x.values, y);
                break :blk vm.initDictionary(.{ .keys = dict_x.keys.ref(), .values = values });
            },
            .dictionary => |dict_y| blk: {
                if (dict_x.values.asList().len != dict_y.values.asList().len) break :blk runtimeError(EqualError.length_mismatch);
                if (dict_x.values.asList().len == 0) {
                    const keys = vm.initList(&.{}, utils_mod.maxType(&.{ dict_x.keys.as, dict_y.keys.as }));
                    const values = vm.initList(&.{}, utils_mod.minType(&.{ .boolean_list, dict_x.values.as, dict_y.values.as }));
                    break :blk vm.initDictionary(.{ .keys = keys, .values = values });
                }

                var key_list = dict_x.keys.asArrayList(vm.allocator);
                errdefer key_list.deinit();
                errdefer for (key_list.items) |v| v.deref(vm.allocator);
                var key_list_type: ValueType = dict_x.keys.as;

                var value_list = dict_x.values.asArrayList(vm.allocator);
                errdefer value_list.deinit();
                errdefer for (value_list.items) |v| v.deref(vm.allocator);

                for (key_list.items, value_list.items) |k_x, *v_x| {
                    if (!dict_y.hash_map.contains(k_x)) {
                        const old_x = v_x.*;
                        defer old_x.deref(vm.allocator);
                        v_x.* = vm.initValue(.{ .boolean = old_x.isNull() });
                    }
                }

                for (dict_y.keys.asList(), dict_y.values.asList()) |k_y, v_y| loop: {
                    if (dict_x.hash_map.getIndex(k_y)) |i| {
                        const old_x = value_list.items[i];
                        defer old_x.deref(vm.allocator);
                        value_list.items[i] = try equal(vm, old_x, v_y);
                        break :loop;
                    }

                    key_list.append(k_y.ref()) catch std.debug.panic("Failed to append item.", .{});
                    if (key_list_type != .list and @as(ValueType, key_list.items[0].as) != key_list.items[key_list.items.len - 1].as) key_list_type = .list;
                    value_list.append(vm.initValue(.{ .boolean = v_y.isNull() })) catch std.debug.panic("Failed to append item.", .{});
                }

                const key_slice = key_list.toOwnedSlice() catch std.debug.panic("Failed to create list.", .{});
                const value_slice = value_list.toOwnedSlice() catch std.debug.panic("Failed to create list.", .{});
                const key = vm.initList(key_slice, key_list_type);
                const value = vm.initListIter(value_slice);
                break :blk vm.initDictionary(.{ .keys = key, .values = value });
            },
            else => runtimeError(EqualError.incompatible_types),
        },
        .table => |table_x| switch (y.as) {
            .boolean, .int, .float => blk: {
                const values = try equal(vm, table_x.values, y);
                break :blk vm.initTable(.{ .columns = table_x.columns.ref(), .values = values });
            },
            .table => |table_y| blk: {
                if (!utils_mod.hasSameKeys(table_x, table_y)) break :blk runtimeError(EqualError.length_mismatch);

                const list = vm.allocator.alloc(*Value, table_x.columns.as.symbol_list.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                for (list, table_x.columns.as.symbol_list, table_x.values.as.list, 0..) |*value, column_name, column_x, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    const column_y = table_y.hash_map.get(column_name).?;
                    value.* = try equal(vm, column_x, column_y);
                }
                const values = vm.initValue(.{ .list = list });
                break :blk vm.initTable(.{ .columns = table_x.columns.ref(), .values = values });
            },
            else => runtimeError(EqualError.incompatible_types),
        },
        else => runtimeError(EqualError.incompatible_types),
    };
}
