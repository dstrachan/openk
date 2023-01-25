const std = @import("std");

const value_mod = @import("../value.zig");
const Value = value_mod.Value;

const vm_mod = @import("../vm.zig");
const VM = vm_mod.VM;

pub fn mergeAtoms(vm: *VM, x: *Value, y: *Value) []*Value {
    const list = vm.allocator.alloc(*Value, 2) catch std.debug.panic("Failed to create list.", .{});
    list[0] = x.ref();
    list[1] = y.ref();
    return list;
}

fn mergeAtomList(vm: *VM, x: *Value, y: []*Value) []*Value {
    const list = vm.allocator.alloc(*Value, y.len + 1) catch std.debug.panic("Failed to create list.", .{});
    list[0] = x.ref();
    for (y) |value| _ = value.ref();
    std.mem.copy(*Value, list[1..], y);
    return list;
}

fn mergeListAtom(vm: *VM, x: []*Value, y: *Value) []*Value {
    const list = vm.allocator.alloc(*Value, x.len + 1) catch std.debug.panic("Failed to create list.", .{});
    for (x) |value| _ = value.ref();
    std.mem.copy(*Value, list, x);
    list[list.len - 1] = y.ref();
    return list;
}

fn mergeLists(vm: *VM, x: []*Value, y: []*Value) []*Value {
    const list = vm.allocator.alloc(*Value, x.len + y.len) catch std.debug.panic("Failed to create list.", .{});
    for (x) |value| _ = value.ref();
    std.mem.copy(*Value, list, x);
    for (y) |value| _ = value.ref();
    std.mem.copy(*Value, list[x.len..], y);
    return list;
}

pub fn merge(vm: *VM, x: *Value, y: *Value) !*Value {
    return switch (x.as) {
        .nil => switch (y.as) {
            .nil, .boolean, .int, .float, .char, .symbol, .function, .projection => vm.initValue(.{ .list = mergeAtoms(vm, x, y) }),
            .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list_y| vm.initValue(.{ .list = mergeAtomList(vm, x, list_y) }),
        },
        .boolean => switch (y.as) {
            .boolean => vm.initValue(.{ .boolean_list = mergeAtoms(vm, x, y) }),
            .boolean_list => |list_y| vm.initValue(.{ .boolean_list = mergeAtomList(vm, x, list_y) }),
            .nil, .int, .float, .char, .symbol, .function, .projection => vm.initValue(.{ .list = mergeAtoms(vm, x, y) }),
            .list, .int_list, .float_list, .char_list, .symbol_list => |list_y| vm.initValue(.{ .list = mergeAtomList(vm, x, list_y) }),
        },
        .int => switch (y.as) {
            .int => vm.initValue(.{ .int_list = mergeAtoms(vm, x, y) }),
            .int_list => |list_y| vm.initValue(.{ .int_list = mergeAtomList(vm, x, list_y) }),
            .nil, .boolean, .float, .char, .symbol, .function, .projection => vm.initValue(.{ .list = mergeAtoms(vm, x, y) }),
            .list, .boolean_list, .float_list, .char_list, .symbol_list => |list_y| vm.initValue(.{ .list = mergeAtomList(vm, x, list_y) }),
        },
        .float => switch (y.as) {
            .float => vm.initValue(.{ .float_list = mergeAtoms(vm, x, y) }),
            .float_list => |list_y| vm.initValue(.{ .float_list = mergeAtomList(vm, x, list_y) }),
            .nil, .boolean, .int, .char, .symbol, .function, .projection => vm.initValue(.{ .list = mergeAtoms(vm, x, y) }),
            .list, .boolean_list, .int_list, .char_list, .symbol_list => |list_y| vm.initValue(.{ .list = mergeAtomList(vm, x, list_y) }),
        },
        .char => switch (y.as) {
            .char => vm.initValue(.{ .char_list = mergeAtoms(vm, x, y) }),
            .char_list => |list_y| vm.initValue(.{ .char_list = mergeAtomList(vm, x, list_y) }),
            .nil, .boolean, .int, .float, .symbol, .function, .projection => vm.initValue(.{ .list = mergeAtoms(vm, x, y) }),
            .list, .boolean_list, .int_list, .float_list, .symbol_list => |list_y| vm.initValue(.{ .list = mergeAtomList(vm, x, list_y) }),
        },
        .symbol => switch (y.as) {
            .symbol => vm.initValue(.{ .symbol_list = mergeAtoms(vm, x, y) }),
            .symbol_list => |list_y| vm.initValue(.{ .symbol_list = mergeAtomList(vm, x, list_y) }),
            .nil, .boolean, .int, .float, .char, .function, .projection => vm.initValue(.{ .list = mergeAtoms(vm, x, y) }),
            .list, .boolean_list, .int_list, .float_list, .char_list => |list_y| vm.initValue(.{ .list = mergeAtomList(vm, x, list_y) }),
        },
        .function => switch (y.as) {
            .nil, .boolean, .int, .float, .char, .symbol, .function, .projection => vm.initValue(.{ .list = mergeAtoms(vm, x, y) }),
            .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list_y| vm.initValue(.{ .list = mergeAtomList(vm, x, list_y) }),
        },
        .projection => switch (y.as) {
            .nil, .boolean, .int, .float, .char, .symbol, .function, .projection => vm.initValue(.{ .list = mergeAtoms(vm, x, y) }),
            .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list_y| vm.initValue(.{ .list = mergeAtomList(vm, x, list_y) }),
        },
        .list => |list_x| switch (y.as) {
            .nil, .boolean, .int, .float, .char, .symbol, .function, .projection => vm.initValue(.{ .list = mergeListAtom(vm, list_x, y) }),
            .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list_y| vm.initValue(.{ .list = mergeLists(vm, list_x, list_y) }),
        },
        .boolean_list => |list_x| switch (y.as) {
            .boolean => vm.initValue(.{ .boolean_list = mergeListAtom(vm, list_x, y) }),
            .boolean_list => |list_y| vm.initValue(.{ .boolean_list = mergeLists(vm, list_x, list_y) }),
            .nil, .int, .float, .char, .symbol, .function, .projection => vm.initValue(.{ .list = mergeListAtom(vm, list_x, y) }),
            .list, .int_list, .float_list, .char_list, .symbol_list => |list_y| vm.initValue(.{ .list = mergeLists(vm, list_x, list_y) }),
        },
        .int_list => |list_x| switch (y.as) {
            .int => vm.initValue(.{ .int_list = mergeListAtom(vm, list_x, y) }),
            .int_list => |list_y| vm.initValue(.{ .int_list = mergeLists(vm, list_x, list_y) }),
            .nil, .boolean, .float, .char, .symbol, .function, .projection => vm.initValue(.{ .list = mergeListAtom(vm, list_x, y) }),
            .list, .boolean_list, .float_list, .char_list, .symbol_list => |list_y| vm.initValue(.{ .list = mergeLists(vm, list_x, list_y) }),
        },
        .float_list => |list_x| switch (y.as) {
            .float => vm.initValue(.{ .float_list = mergeListAtom(vm, list_x, y) }),
            .float_list => |list_y| vm.initValue(.{ .float_list = mergeLists(vm, list_x, list_y) }),
            .nil, .boolean, .int, .char, .symbol, .function, .projection => vm.initValue(.{ .list = mergeListAtom(vm, list_x, y) }),
            .list, .boolean_list, .int_list, .char_list, .symbol_list => |list_y| vm.initValue(.{ .list = mergeLists(vm, list_x, list_y) }),
        },
        .char_list => |list_x| switch (y.as) {
            .char => vm.initValue(.{ .char_list = mergeListAtom(vm, list_x, y) }),
            .char_list => |list_y| vm.initValue(.{ .char_list = mergeLists(vm, list_x, list_y) }),
            .nil, .boolean, .int, .float, .symbol, .function, .projection => vm.initValue(.{ .list = mergeListAtom(vm, list_x, y) }),
            .list, .boolean_list, .int_list, .float_list, .symbol_list => |list_y| vm.initValue(.{ .list = mergeLists(vm, list_x, list_y) }),
        },
        .symbol_list => |list_x| switch (y.as) {
            .symbol => vm.initValue(.{ .symbol_list = mergeListAtom(vm, list_x, y) }),
            .symbol_list => |list_y| vm.initValue(.{ .symbol_list = mergeLists(vm, list_x, list_y) }),
            .nil, .boolean, .int, .float, .char, .function, .projection => vm.initValue(.{ .list = mergeListAtom(vm, list_x, y) }),
            .list, .boolean_list, .int_list, .float_list, .char_list => |list_y| vm.initValue(.{ .list = mergeLists(vm, list_x, list_y) }),
        },
    };
}
