const std = @import("std");

const utils_mod = @import("../utils.zig");
const print = utils_mod.print;

const value_mod = @import("../value.zig");
const Value = value_mod.Value;
const ValueDictionary = value_mod.ValueDictionary;
const ValueTable = value_mod.ValueTable;
const ValueType = value_mod.ValueType;
const ValueUnion = value_mod.ValueUnion;

const first = @import("first.zig").first;

const vm_mod = @import("../vm.zig");
const VM = vm_mod.VM;

pub const MergeError = error{
    incompatible_types,
};

fn runtimeError(comptime err: MergeError) MergeError!*Value {
    switch (err) {
        MergeError.incompatible_types => print("Incompatible types.\n", .{}),
    }
    return err;
}

fn mergeAtoms(vm: *VM, x: *Value, y: *Value) []*Value {
    const list = vm.allocator.alloc(*Value, 2) catch std.debug.panic("Failed to create list.", .{});
    list[0] = x.ref();
    list[1] = y.ref();
    return list;
}

fn mergeAtomList(vm: *VM, x: *Value, y: []*Value) []*Value {
    const list = vm.allocator.alloc(*Value, y.len + 1) catch std.debug.panic("Failed to create list.", .{});
    list[0] = x.ref();
    if (y.len > 0) {
        for (y) |v| _ = v.ref();
        std.mem.copy(*Value, list[1..], y);
    }
    return list;
}

fn mergeListAtom(vm: *VM, x: []*Value, y: *Value) []*Value {
    const list = vm.allocator.alloc(*Value, x.len + 1) catch std.debug.panic("Failed to create list.", .{});
    if (x.len > 0) {
        for (x) |v| _ = v.ref();
        std.mem.copy(*Value, list, x);
    }
    list[x.len] = y.ref();
    return list;
}

fn mergeLists(vm: *VM, x: []*Value, y: []*Value) []*Value {
    const list = vm.allocator.alloc(*Value, x.len + y.len) catch std.debug.panic("Failed to create list.", .{});
    if (x.len > 0) {
        for (x) |v| _ = v.ref();
        std.mem.copy(*Value, list, x);
    }
    if (y.len > 0) {
        for (y) |v| _ = v.ref();
        std.mem.copy(*Value, list[x.len..], y);
    }
    return list;
}

pub fn merge(vm: *VM, x: *Value, y: *Value) MergeError!*Value {
    return switch (x.as) {
        .boolean => switch (y.as) {
            .boolean => vm.initValue(.{ .boolean_list = mergeAtoms(vm, x, y) }),
            .int, .float, .char, .symbol => vm.initValue(.{ .list = mergeAtoms(vm, x, y) }),
            .boolean_list => |bool_list_y| vm.initValue(.{ .boolean_list = mergeAtomList(vm, x, bool_list_y) }),
            .list,
            .int_list,
            .float_list,
            .char_list,
            .symbol_list,
            => |list_y| vm.initValue(if (list_y.len == 0) .{ .boolean_list = mergeAtomList(vm, x, list_y) } else .{ .list = mergeAtomList(vm, x, list_y) }),
            .table => blk: {
                const list = vm.allocator.alloc(*Value, 2) catch std.debug.panic("Failed to create list.", .{});
                list[0] = x.ref();
                list[1] = first(vm, y);
                break :blk vm.initValue(.{ .list = list });
            },
            else => runtimeError(MergeError.incompatible_types),
        },
        .int => switch (y.as) {
            .int => vm.initValue(.{ .int_list = mergeAtoms(vm, x, y) }),
            .boolean, .float, .char, .symbol => vm.initValue(.{ .list = mergeAtoms(vm, x, y) }),
            .int_list => |int_list_y| vm.initValue(.{ .int_list = mergeAtomList(vm, x, int_list_y) }),
            .list,
            .boolean_list,
            .float_list,
            .char_list,
            .symbol_list,
            => |list_y| vm.initValue(if (list_y.len == 0) .{ .int_list = mergeAtomList(vm, x, list_y) } else .{ .list = mergeAtomList(vm, x, list_y) }),
            .table => blk: {
                const list = vm.allocator.alloc(*Value, 2) catch std.debug.panic("Failed to create list.", .{});
                list[0] = x.ref();
                list[1] = first(vm, y);
                break :blk vm.initValue(.{ .list = list });
            },
            else => runtimeError(MergeError.incompatible_types),
        },
        .float => switch (y.as) {
            .float => vm.initValue(.{ .float_list = mergeAtoms(vm, x, y) }),
            .boolean, .int, .char, .symbol => vm.initValue(.{ .list = mergeAtoms(vm, x, y) }),
            .float_list => |int_list_y| vm.initValue(.{ .float_list = mergeAtomList(vm, x, int_list_y) }),
            .list,
            .boolean_list,
            .int_list,
            .char_list,
            .symbol_list,
            => |list_y| vm.initValue(if (list_y.len == 0) .{ .float_list = mergeAtomList(vm, x, list_y) } else .{ .list = mergeAtomList(vm, x, list_y) }),
            .table => blk: {
                const list = vm.allocator.alloc(*Value, 2) catch std.debug.panic("Failed to create list.", .{});
                list[0] = x.ref();
                list[1] = first(vm, y);
                break :blk vm.initValue(.{ .list = list });
            },
            else => runtimeError(MergeError.incompatible_types),
        },
        .char => switch (y.as) {
            .char => vm.initValue(.{ .char_list = mergeAtoms(vm, x, y) }),
            .boolean, .int, .float, .symbol => vm.initValue(.{ .list = mergeAtoms(vm, x, y) }),
            .char_list => |int_list_y| vm.initValue(.{ .char_list = mergeAtomList(vm, x, int_list_y) }),
            .list,
            .boolean_list,
            .int_list,
            .float_list,
            .symbol_list,
            => |list_y| vm.initValue(if (list_y.len == 0) .{ .char_list = mergeAtomList(vm, x, list_y) } else .{ .list = mergeAtomList(vm, x, list_y) }),
            .table => blk: {
                const list = vm.allocator.alloc(*Value, 2) catch std.debug.panic("Failed to create list.", .{});
                list[0] = x.ref();
                list[1] = first(vm, y);
                break :blk vm.initValue(.{ .list = list });
            },
            else => runtimeError(MergeError.incompatible_types),
        },
        .symbol => switch (y.as) {
            .symbol => vm.initValue(.{ .symbol_list = mergeAtoms(vm, x, y) }),
            .boolean, .int, .float, .char => vm.initValue(.{ .list = mergeAtoms(vm, x, y) }),
            .symbol_list => |int_list_y| vm.initValue(.{ .symbol_list = mergeAtomList(vm, x, int_list_y) }),
            .list,
            .boolean_list,
            .int_list,
            .float_list,
            .char_list,
            => |list_y| vm.initValue(if (list_y.len == 0) .{ .symbol_list = mergeAtomList(vm, x, list_y) } else .{ .list = mergeAtomList(vm, x, list_y) }),
            .table => blk: {
                const list = vm.allocator.alloc(*Value, 2) catch std.debug.panic("Failed to create list.", .{});
                list[0] = x.ref();
                list[1] = first(vm, y);
                break :blk vm.initValue(.{ .list = list });
            },
            else => runtimeError(MergeError.incompatible_types),
        },
        .list => |list_x| switch (y.as) {
            .boolean => vm.initValue(if (list_x.len == 0) .{ .boolean_list = mergeListAtom(vm, list_x, y) } else .{ .list = mergeListAtom(vm, list_x, y) }),
            .int => vm.initValue(if (list_x.len == 0) .{ .int_list = mergeListAtom(vm, list_x, y) } else .{ .list = mergeListAtom(vm, list_x, y) }),
            .float => vm.initValue(if (list_x.len == 0) .{ .float_list = mergeListAtom(vm, list_x, y) } else .{ .list = mergeListAtom(vm, list_x, y) }),
            .char => vm.initValue(if (list_x.len == 0) .{ .char_list = mergeListAtom(vm, list_x, y) } else .{ .list = mergeListAtom(vm, list_x, y) }),
            .symbol => vm.initValue(if (list_x.len == 0) .{ .symbol_list = mergeListAtom(vm, list_x, y) } else .{ .list = mergeListAtom(vm, list_x, y) }),
            .list,
            .boolean_list,
            .int_list,
            .float_list,
            .char_list,
            .symbol_list,
            => |list_y| if (list_x.len == 0) y.ref() else if (list_y.len == 0) x.ref() else vm.initValue(.{ .list = mergeLists(vm, list_x, list_y) }),
            .dictionary => if (list_x.len == 0) y.ref() else runtimeError(MergeError.incompatible_types),
            .table => blk: {
                if (list_x.len == 0) break :blk y.ref();
                const list = vm.allocator.alloc(*Value, list_x.len + 1) catch std.debug.panic("Failed to create list.", .{});
                for (list_x, 0..) |v, i| {
                    list[i] = v.ref();
                }
                list[list_x.len] = first(vm, y);
                break :blk vm.initValue(.{ .list = list });
            },
            else => runtimeError(MergeError.incompatible_types),
        },
        .boolean_list => |bool_list_x| switch (y.as) {
            .boolean => vm.initValue(.{ .boolean_list = mergeListAtom(vm, bool_list_x, y) }),
            .int, .float, .char, .symbol => vm.initValue(.{ .list = mergeListAtom(vm, bool_list_x, y) }),
            .boolean_list => |bool_list_y| vm.initValue(.{ .boolean_list = mergeLists(vm, bool_list_x, bool_list_y) }),
            .list,
            .int_list,
            .float_list,
            .char_list,
            .symbol_list,
            => |list_y| if (bool_list_x.len == 0) y.ref() else if (list_y.len == 0) x.ref() else vm.initValue(.{ .list = mergeLists(vm, bool_list_x, list_y) }),
            .table => blk: {
                if (bool_list_x.len == 0) break :blk y.ref();
                const list = vm.allocator.alloc(*Value, bool_list_x.len + 1) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_x, 0..) |v, i| {
                    list[i] = v.ref();
                }
                list[bool_list_x.len] = first(vm, y);
                break :blk vm.initValue(.{ .list = list });
            },
            else => runtimeError(MergeError.incompatible_types),
        },
        .int_list => |int_list_x| switch (y.as) {
            .int => vm.initValue(.{ .int_list = mergeListAtom(vm, int_list_x, y) }),
            .boolean, .float, .char, .symbol => vm.initValue(.{ .list = mergeListAtom(vm, int_list_x, y) }),
            .int_list => |int_list_y| vm.initValue(.{ .int_list = mergeLists(vm, int_list_x, int_list_y) }),
            .list,
            .boolean_list,
            .float_list,
            .char_list,
            .symbol_list,
            => |list_y| if (int_list_x.len == 0) y.ref() else if (list_y.len == 0) x.ref() else vm.initValue(.{ .list = mergeLists(vm, int_list_x, list_y) }),
            .table => blk: {
                if (int_list_x.len == 0) break :blk y.ref();
                const list = vm.allocator.alloc(*Value, int_list_x.len + 1) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_x, 0..) |v, i| {
                    list[i] = v.ref();
                }
                list[int_list_x.len] = first(vm, y);
                break :blk vm.initValue(.{ .list = list });
            },
            else => runtimeError(MergeError.incompatible_types),
        },
        .float_list => |float_list_x| switch (y.as) {
            .float => vm.initValue(.{ .float_list = mergeListAtom(vm, float_list_x, y) }),
            .boolean, .int, .char, .symbol => vm.initValue(.{ .list = mergeListAtom(vm, float_list_x, y) }),
            .float_list => |float_list_y| vm.initValue(.{ .float_list = mergeLists(vm, float_list_x, float_list_y) }),
            .list,
            .boolean_list,
            .int_list,
            .char_list,
            .symbol_list,
            => |list_y| if (float_list_x.len == 0) y.ref() else if (list_y.len == 0) x.ref() else vm.initValue(.{ .list = mergeLists(vm, float_list_x, list_y) }),
            .table => blk: {
                if (float_list_x.len == 0) break :blk y.ref();
                const list = vm.allocator.alloc(*Value, float_list_x.len + 1) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_x, 0..) |v, i| {
                    list[i] = v.ref();
                }
                list[float_list_x.len] = first(vm, y);
                break :blk vm.initValue(.{ .list = list });
            },
            else => runtimeError(MergeError.incompatible_types),
        },
        .char_list => |char_list_x| switch (y.as) {
            .char => vm.initValue(.{ .char_list = mergeListAtom(vm, char_list_x, y) }),
            .boolean, .int, .float, .symbol => vm.initValue(.{ .list = mergeListAtom(vm, char_list_x, y) }),
            .char_list => |char_list_y| vm.initValue(.{ .char_list = mergeLists(vm, char_list_x, char_list_y) }),
            .list,
            .boolean_list,
            .int_list,
            .float_list,
            .symbol_list,
            => |list_y| if (char_list_x.len == 0) y.ref() else if (list_y.len == 0) x.ref() else vm.initValue(.{ .list = mergeLists(vm, char_list_x, list_y) }),
            .table => blk: {
                if (char_list_x.len == 0) break :blk y.ref();
                const list = vm.allocator.alloc(*Value, char_list_x.len + 1) catch std.debug.panic("Failed to create list.", .{});
                for (char_list_x, 0..) |v, i| {
                    list[i] = v.ref();
                }
                list[char_list_x.len] = first(vm, y);
                break :blk vm.initValue(.{ .list = list });
            },
            else => runtimeError(MergeError.incompatible_types),
        },
        .symbol_list => |symbol_list_x| switch (y.as) {
            .symbol => vm.initValue(.{ .symbol_list = mergeListAtom(vm, symbol_list_x, y) }),
            .boolean, .int, .float, .char => vm.initValue(.{ .list = mergeListAtom(vm, symbol_list_x, y) }),
            .symbol_list => |symbol_list_y| vm.initValue(.{ .symbol_list = mergeLists(vm, symbol_list_x, symbol_list_y) }),
            .list,
            .boolean_list,
            .int_list,
            .float_list,
            .char_list,
            => |list_y| if (symbol_list_x.len == 0) y.ref() else if (list_y.len == 0) x.ref() else vm.initValue(.{ .list = mergeLists(vm, symbol_list_x, list_y) }),
            .table => blk: {
                if (symbol_list_x.len == 0) break :blk y.ref();
                const list = vm.allocator.alloc(*Value, symbol_list_x.len + 1) catch std.debug.panic("Failed to create list.", .{});
                for (symbol_list_x, 0..) |v, i| {
                    list[i] = v.ref();
                }
                list[symbol_list_x.len] = first(vm, y);
                break :blk vm.initValue(.{ .list = list });
            },
            else => runtimeError(MergeError.incompatible_types),
        },
        .dictionary => |dict_x| switch (y.as) {
            .list => |list_y| if (list_y.len == 0) x.ref() else runtimeError(MergeError.incompatible_types),
            .dictionary => |dict_y| blk: {
                var key = dict_x.keys.asArrayList(vm.allocator);
                var key_list_type: ValueType = dict_x.keys.as;
                var value = dict_x.values.asArrayList(vm.allocator);
                var value_list_type: ValueType = dict_x.values.as;
                for (dict_y.keys.asList(), 0..) |k_y, i_y| loop: {
                    for (key.items, 0..) |k_x, i_x| {
                        if (k_x.eql(k_y)) {
                            value.items[i_x].deref(vm.allocator);
                            value.items[i_x] = dict_y.values.asList()[i_y].ref();
                            if (value_list_type != .list and @as(ValueType, value.items[0].as) != value.items[i_x].as) value_list_type = .list;
                            break :loop;
                        }
                    }
                    key.append(k_y.ref()) catch std.debug.panic("Failed to append item.", .{});
                    if (key_list_type != .list and @as(ValueType, key.items[0].as) != key.items[key.items.len - 1].as) key_list_type = .list;
                    value.append(dict_y.values.asList()[i_y].ref()) catch std.debug.panic("Failed to append item.", .{});
                    if (value_list_type != .list and @as(ValueType, value.items[0].as) != value.items[value.items.len - 1].as) value_list_type = .list;
                }
                const key_list = key.toOwnedSlice() catch std.debug.panic("Failed to create list.", .{});
                const new_key = vm.initList(key_list, key_list_type);
                const value_list = value.toOwnedSlice() catch std.debug.panic("Failed to create list.", .{});
                const new_value = vm.initList(value_list, value_list_type);
                break :blk vm.initDictionary(.{ .keys = new_key, .values = new_value });
            },
            .table => |table_y| blk: {
                if (!utils_mod.hasSameKeys(dict_x, table_y)) return runtimeError(MergeError.incompatible_types);

                const list = vm.allocator.alloc(*Value, dict_x.keys.as.symbol_list.len) catch std.debug.panic("Failed to create list.", .{});
                for (list, dict_x.keys.as.symbol_list, dict_x.values.asList()) |*value, k_x, v_x| {
                    const column = table_y.hash_map.get(k_x).?;
                    const y_list = column.asList();
                    const value_list = vm.allocator.alloc(*Value, y_list.len + 1) catch std.debug.panic("Failed to create list.", .{});
                    value_list[0] = v_x.ref();
                    for (y_list, 0..) |v, i| {
                        value_list[i + 1] = v.ref();
                    }
                    const value_list_type: ValueType = if (@as(ValueType, dict_x.values.as) == column.as) dict_x.values.as else .list;
                    value.* = vm.initList(value_list, value_list_type);
                }
                const values = vm.initValue(.{ .list = list });
                break :blk vm.initTable(.{ .columns = dict_x.keys.ref(), .values = values });
            },
            else => runtimeError(MergeError.incompatible_types),
        },
        .table => |table_x| switch (y.as) {
            .boolean, .int, .float, .char, .symbol => blk: {
                const list = vm.allocator.alloc(*Value, 2) catch std.debug.panic("Failed to create list.", .{});
                list[0] = first(vm, x);
                list[1] = y.ref();
                break :blk vm.initValue(.{ .list = list });
            },
            .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list_y| blk: {
                if (list_y.len == 0) break :blk x.ref();
                const list = vm.allocator.alloc(*Value, list_y.len + 1) catch std.debug.panic("Failed to create list.", .{});
                list[0] = first(vm, x);
                for (list_y, 0..) |v, i| {
                    list[i + 1] = v.ref();
                }
                break :blk vm.initValue(.{ .list = list });
            },
            .dictionary => |dict_y| blk: {
                if (!utils_mod.hasSameKeys(table_x, dict_y)) return runtimeError(MergeError.incompatible_types);

                const list = vm.allocator.alloc(*Value, table_x.columns.as.symbol_list.len) catch std.debug.panic("Failed to create list.", .{});
                for (list, table_x.columns.as.symbol_list) |*value, k_x| {
                    const x_column = table_x.hash_map.get(k_x).?;
                    const x_list = x_column.asList();
                    const value_list = vm.allocator.alloc(*Value, x_list.len + 1) catch std.debug.panic("Failed to create list.", .{});
                    for (x_list, 0..) |v, i| {
                        value_list[i] = v.ref();
                    }
                    value_list[value_list.len - 1] = dict_y.hash_map.get(k_x).?.ref();
                    const value_list_type: ValueType = if (@as(ValueType, dict_y.values.as) == x_column.as) dict_y.values.as else .list;
                    value.* = vm.initList(value_list, value_list_type);
                }
                const values = vm.initValue(.{ .list = list });
                break :blk vm.initTable(.{ .columns = table_x.columns.ref(), .values = values });
            },
            .table => |table_y| blk: {
                if (!utils_mod.hasSameKeys(table_x, table_y)) return runtimeError(MergeError.incompatible_types);

                const list = vm.allocator.alloc(*Value, table_x.columns.as.symbol_list.len) catch std.debug.panic("Failed to create list.", .{});
                for (list, table_x.columns.as.symbol_list) |*value, k_x| {
                    const x_column = table_x.hash_map.get(k_x).?;
                    const x_list = x_column.asList();
                    const y_column = table_y.hash_map.get(k_x).?;
                    const y_list = y_column.asList();
                    const value_list = vm.allocator.alloc(*Value, x_list.len + y_list.len) catch std.debug.panic("Failed to create list.", .{});
                    for (x_list, 0..) |v, i| {
                        value_list[i] = v.ref();
                    }
                    for (y_list, 0..) |v, i| {
                        value_list[i + x_list.len] = v.ref();
                    }
                    const value_list_type: ValueType = if (@as(ValueType, x_column.as) == y_column.as) x_column.as else .list;
                    value.* = vm.initList(value_list, value_list_type);
                }
                const values = vm.initValue(.{ .list = list });
                break :blk vm.initTable(.{ .columns = table_x.columns.ref(), .values = values });
            },
            else => runtimeError(MergeError.incompatible_types),
        },
        else => runtimeError(MergeError.incompatible_types),
    };
}
