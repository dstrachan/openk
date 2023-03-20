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

pub const MoreError = error{
    incompatible_types,
    length_mismatch,
};

fn runtimeError(comptime err: MoreError) MoreError!*Value {
    switch (err) {
        MoreError.incompatible_types => print("Incompatible types.\n", .{}),
        MoreError.length_mismatch => print("List lengths must match.\n", .{}),
    }
    return err;
}

fn moreInt(x: i64, y: i64) bool {
    return x > y;
}

fn moreFloat(x: f64, y: f64) bool {
    if (std.math.isNan(y)) return !std.math.isNan(x);
    return x > y;
}

pub fn more(vm: *VM, x: *Value, y: *Value) MoreError!*Value {
    return switch (x.as) {
        .boolean => |bool_x| switch (y.as) {
            .boolean => |bool_y| vm.initValue(.{ .boolean = moreInt(@boolToInt(bool_x), @boolToInt(bool_y)) }),
            .int => |int_y| vm.initValue(.{ .boolean = moreInt(@boolToInt(bool_x), int_y) }),
            .float => |float_y| vm.initValue(.{ .boolean = moreFloat(if (bool_x) 1 else 0, float_y) }),
            .list, .boolean_list, .int_list, .float_list => |list_y| blk: {
                if (list_y.len == 0) break :blk vm.initList(&.{}, @intToEnum(ValueType, std.math.min(@enumToInt(ValueType.boolean_list), @enumToInt(y.as))));

                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = null;
                for (list_y, 0..) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try more(vm, x, value);
                    if (list_type == null and @as(ValueType, list[0].as) != list[i].as) list_type = .list;
                }
                break :blk vm.initListAtoms(list, list_type);
            },
            .dictionary => |dict_y| blk: {
                const value = try more(vm, x, dict_y.values);
                break :blk vm.initDictionary(.{ .keys = dict_y.keys.ref(), .values = value });
            },
            .table => |table_y| blk: {
                const values = try more(vm, x, table_y.values);
                break :blk vm.initTable(.{ .columns = table_y.columns.ref(), .values = values });
            },
            else => runtimeError(MoreError.incompatible_types),
        },
        .int => |int_x| switch (y.as) {
            .boolean => |bool_y| vm.initValue(.{ .boolean = moreInt(int_x, @boolToInt(bool_y)) }),
            .int => |int_y| vm.initValue(.{ .boolean = moreInt(int_x, int_y) }),
            .float => |float_y| vm.initValue(.{ .boolean = moreFloat(utils_mod.intToFloat(int_x), float_y) }),
            .list, .boolean_list, .int_list, .float_list => |list_y| blk: {
                if (list_y.len == 0) break :blk vm.initList(&.{}, @intToEnum(ValueType, std.math.min(@enumToInt(ValueType.boolean_list), @enumToInt(y.as))));

                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = null;
                for (list_y, 0..) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try more(vm, x, value);
                    if (list_type == null and @as(ValueType, list[0].as) != list[i].as) list_type = .list;
                }
                break :blk vm.initListAtoms(list, list_type);
            },
            .dictionary => |dict_y| blk: {
                const value = try more(vm, x, dict_y.values);
                break :blk vm.initDictionary(.{ .keys = dict_y.keys.ref(), .values = value });
            },
            .table => |table_y| blk: {
                const values = try more(vm, x, table_y.values);
                break :blk vm.initTable(.{ .columns = table_y.columns.ref(), .values = values });
            },
            else => runtimeError(MoreError.incompatible_types),
        },
        .float => |float_x| switch (y.as) {
            .boolean => |bool_y| vm.initValue(.{ .boolean = moreFloat(float_x, if (bool_y) 1 else 0) }),
            .int => |int_y| vm.initValue(.{ .boolean = moreFloat(float_x, utils_mod.intToFloat(int_y)) }),
            .float => |float_y| vm.initValue(.{ .boolean = moreFloat(float_x, float_y) }),
            .list, .boolean_list, .int_list, .float_list => |list_y| blk: {
                if (list_y.len == 0) break :blk vm.initList(&.{}, @intToEnum(ValueType, std.math.min(@enumToInt(ValueType.boolean_list), @enumToInt(y.as))));

                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = null;
                for (list_y, 0..) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try more(vm, x, value);
                    if (list_type == null and @as(ValueType, list[0].as) != list[i].as) list_type = .list;
                }
                break :blk vm.initListAtoms(list, list_type);
            },
            .dictionary => |dict_y| blk: {
                const value = try more(vm, x, dict_y.values);
                break :blk vm.initDictionary(.{ .keys = dict_y.keys.ref(), .values = value });
            },
            .table => |table_y| blk: {
                const values = try more(vm, x, table_y.values);
                break :blk vm.initTable(.{ .columns = table_y.columns.ref(), .values = values });
            },
            else => runtimeError(MoreError.incompatible_types),
        },
        .list, .boolean_list, .int_list, .float_list => |list_x| switch (y.as) {
            .boolean, .int, .float => blk: {
                if (list_x.len == 0) break :blk vm.initList(&.{}, @intToEnum(ValueType, std.math.min(@enumToInt(ValueType.boolean_list), @enumToInt(x.as))));

                const list = vm.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = null;
                for (list_x, 0..) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try more(vm, value, y);
                    if (list_type == null and @as(ValueType, list[0].as) != list[i].as) list_type = .list;
                }
                break :blk vm.initListAtoms(list, list_type);
            },
            .list, .boolean_list, .int_list, .float_list => |list_y| blk: {
                if (list_x.len != list_y.len) break :blk runtimeError(MoreError.length_mismatch);
                if (list_x.len == 0) break :blk vm.initList(&.{}, @intToEnum(ValueType, std.math.min(@enumToInt(x.as), @enumToInt(y.as))));

                const list = vm.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ValueType = .boolean_list;
                for (list_x, list_y, 0..) |value_x, value_y, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try more(vm, value_x, value_y);
                    if (list_type != .list and @as(ValueType, list[0].as) != list[i].as) list_type = .list;
                }
                break :blk vm.initList(list, list_type);
            },
            .dictionary => |dict_y| blk: {
                const value = try more(vm, x, dict_y.values);
                break :blk vm.initDictionary(.{ .keys = dict_y.keys.ref(), .values = value });
            },
            else => runtimeError(MoreError.incompatible_types),
        },
        .dictionary => |dict_x| switch (y.as) {
            .boolean, .int, .float, .list, .boolean_list, .int_list, .float_list => blk: {
                const value = try more(vm, dict_x.values, y);
                break :blk vm.initDictionary(.{ .keys = dict_x.keys.ref(), .values = value });
            },
            .dictionary => |dict_y| blk: {
                if (dict_x.keys.asList().len == 0) {
                    const list = vm.allocator.alloc(*Value, dict_y.keys.asList().len) catch std.debug.panic("Failed to create list.", .{});
                    for (list) |*v| {
                        v.* = vm.initValue(.{ .list = &.{} });
                    }
                    const value = vm.initValue(.{ .list = list });
                    break :blk vm.initDictionary(.{ .keys = dict_y.keys.ref(), .values = value });
                }
                if (dict_y.keys.asList().len == 0) {
                    const list = vm.allocator.alloc(*Value, dict_x.keys.asList().len) catch std.debug.panic("Failed to create list.", .{});
                    for (list) |*v| {
                        v.* = vm.initValue(.{ .list = &.{} });
                    }
                    const value = vm.initValue(.{ .list = list });
                    break :blk vm.initDictionary(.{ .keys = dict_x.keys.ref(), .values = value });
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
                        v_x.* = vm.initValue(.{ .boolean = !old_x.isNull() });
                    }
                }

                for (dict_y.keys.asList(), dict_y.values.asList()) |k_y, v_y| loop: {
                    for (key_list.items, value_list.items) |k_x, *v_x| {
                        if (k_x.eql(k_y)) {
                            const old_x = v_x.*;
                            defer old_x.deref(vm.allocator);
                            v_x.* = try more(vm, old_x, v_y);
                            break :loop;
                        }
                    }

                    key_list.append(k_y.ref()) catch std.debug.panic("Failed to append item.", .{});
                    if (key_list_type != .list and @as(ValueType, key_list.items[0].as) != key_list.items[key_list.items.len - 1].as) key_list_type = .list;
                    value_list.append(vm.initValue(.{ .boolean = false })) catch std.debug.panic("Failed to append item.", .{});
                }

                const key_slice = key_list.toOwnedSlice() catch std.debug.panic("Failed to create list.", .{});
                const value_slice = value_list.toOwnedSlice() catch std.debug.panic("Failed to create list.", .{});
                const key = vm.initList(key_slice, key_list_type);
                const value = vm.initListIter(value_slice);
                break :blk vm.initDictionary(.{ .keys = key, .values = value });
            },
            else => runtimeError(MoreError.incompatible_types),
        },
        .table => |table_x| switch (y.as) {
            .boolean, .int, .float => blk: {
                const list = vm.allocator.alloc(*Value, table_x.values.asList().len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                for (table_x.values.asList(), 0..) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try more(vm, value, y);
                }
                const values = vm.initValue(.{ .list = list });
                break :blk vm.initTable(.{ .columns = table_x.columns.ref(), .values = values });
            },
            .table => |table_y| blk: {
                if (!utils_mod.hasSameKeys(table_x, table_y)) break :blk runtimeError(MoreError.length_mismatch);

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
                            values.items[i_x] = try more(vm, values.items[i_x], table_y.values.asList()[i_y]);
                            break :loop;
                        }
                    }
                }
                const columns_list = columns.toOwnedSlice() catch std.debug.panic("Failed to create list.", .{});
                const new_columns = vm.initValue(.{ .symbol_list = columns_list });
                const values_list = values.toOwnedSlice() catch std.debug.panic("Failed to create list.", .{});
                const new_values = vm.initValue(.{ .list = values_list });
                break :blk vm.initTable(.{ .columns = new_columns, .values = new_values });
            },
            else => runtimeError(MoreError.incompatible_types),
        },
        else => runtimeError(MoreError.incompatible_types),
    };
}
