const std = @import("std");

const utils_mod = @import("../utils.zig");
const print = utils_mod.print;

const value_mod = @import("../value.zig");
const Value = value_mod.Value;
const ValueDictionary = value_mod.ValueDictionary;
const ValueType = value_mod.ValueType;
const ValueUnion = value_mod.ValueUnion;

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
            else => runtimeError(MergeError.incompatible_types),
        },
        .dictionary => |dict_x| switch (y.as) {
            .list => |list_y| if (list_y.len == 0) x.ref() else runtimeError(MergeError.incompatible_types),
            .dictionary => |dict_y| blk: {
                var key = dupeAsArrayList(dict_x.key, vm.allocator);
                var key_list_type: ValueType = dict_x.key.as;
                var value = dupeAsArrayList(dict_x.value, vm.allocator);
                var value_list_type: ValueType = dict_x.value.as;
                for (asList(dict_y.key), 0..) |k_y, i_y| loop: {
                    for (key.items, 0..) |k_x, i_x| {
                        if (k_x.eql(k_y)) {
                            value.items[i_x].deref(vm.allocator);
                            value.items[i_x] = asList(dict_y.value)[i_y].ref();
                            if (value_list_type != .list and @as(ValueType, value.items[0].as) != value.items[i_x].as) value_list_type = .list;
                            break :loop;
                        }
                    }
                    key.append(k_y.ref()) catch std.debug.panic("Failed to append item.", .{});
                    if (key_list_type != .list and @as(ValueType, key.items[0].as) != key.items[key.items.len - 1].as) key_list_type = .list;
                    value.append(asList(dict_y.value)[i_y].ref()) catch std.debug.panic("Failed to append item.", .{});
                    if (value_list_type != .list and @as(ValueType, value.items[0].as) != value.items[value.items.len - 1].as) value_list_type = .list;
                }
                const key_list = key.toOwnedSlice() catch std.debug.panic("Failed to create list.", .{});
                const new_key = vm.initValue(initList(key_list_type, key_list));
                const value_list = value.toOwnedSlice() catch std.debug.panic("Failed to create list.", .{});
                const new_value = vm.initValue(initList(value_list_type, value_list));
                const dictionary = ValueDictionary.init(.{ .key = new_key, .value = new_value }, vm.allocator);
                break :blk vm.initValue(.{ .dictionary = dictionary });
            },
            else => runtimeError(MergeError.incompatible_types),
        },
        else => runtimeError(MergeError.incompatible_types),
    };
}

fn dupeAsArrayList(value: *Value, allocator: std.mem.Allocator) std.ArrayList(*Value) {
    return switch (value.as) {
        .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list| blk: {
            var array_list = std.ArrayList(*Value).initCapacity(allocator, list.len) catch std.debug.panic("Failed to create list.", .{});
            errdefer array_list.deinit();
            for (list) |v| {
                array_list.append(v.ref()) catch std.debug.panic("Failed to append value.", .{});
            }
            break :blk array_list;
        },
        else => unreachable,
    };
}

fn asList(value: *Value) []*Value {
    return switch (value.as) {
        .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list| list,
        else => unreachable,
    };
}

fn initList(list_type: ValueType, list: []*Value) ValueUnion {
    return switch (list_type) {
        .list => .{ .list = list },
        .boolean_list => .{ .boolean_list = list },
        .int_list => .{ .int_list = list },
        .float_list => .{ .float_list = list },
        .char_list => .{ .char_list = list },
        .symbol_list => .{ .symbol_list = list },
        else => unreachable,
    };
}
