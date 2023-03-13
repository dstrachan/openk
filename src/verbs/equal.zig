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
                    const list_type = @intToEnum(ValueType, std.math.min(@enumToInt(ValueType.boolean_list), @enumToInt(y.as)));
                    break :blk vm.initList(&[_]*Value{}, list_type);
                }

                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ValueType = .boolean;
                errdefer vm.allocator.free(list);
                for (list, 0..) |*value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    value.* = try equal(vm, x, list_y[i]);
                    if (list_type != .list and value.*.as != .boolean) list_type = .list;
                }
                break :blk vm.initList(list, list_type);
            },
            else => runtimeError(EqualError.incompatible_types),
        },
        .int => |int_x| switch (y.as) {
            .boolean => |bool_y| vm.initValue(.{ .boolean = int_x == @boolToInt(bool_y) }),
            .int => |int_y| vm.initValue(.{ .boolean = int_x == int_y }),
            .float => |float_y| vm.initValue(.{ .boolean = equalFloat(utils_mod.intToFloat(int_x), float_y) }),
            .list, .boolean_list, .int_list, .float_list => |list_y| blk: {
                if (list_y.len == 0) {
                    const list_type = @intToEnum(ValueType, std.math.min(@enumToInt(ValueType.boolean_list), @enumToInt(y.as)));
                    break :blk vm.initList(&[_]*Value{}, list_type);
                }

                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ValueType = .boolean;
                errdefer vm.allocator.free(list);
                for (list, 0..) |*value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    value.* = try equal(vm, x, list_y[i]);
                    if (list_type != .list and value.*.as != .boolean) list_type = .list;
                }
                break :blk vm.initList(list, list_type);
            },
            else => runtimeError(EqualError.incompatible_types),
        },
        .float => |float_x| switch (y.as) {
            .boolean => |bool_y| vm.initValue(.{ .boolean = equalFloat(float_x, if (bool_y) 1 else 0) }),
            .int => |int_y| vm.initValue(.{ .boolean = equalFloat(float_x, utils_mod.intToFloat(int_y)) }),
            .float => |float_y| vm.initValue(.{ .boolean = equalFloat(float_x, float_y) }),
            .list, .boolean_list, .int_list, .float_list => |list_y| blk: {
                if (list_y.len == 0) {
                    const list_type = @intToEnum(ValueType, std.math.min(@enumToInt(ValueType.boolean_list), @enumToInt(y.as)));
                    break :blk vm.initList(&[_]*Value{}, list_type);
                }

                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ValueType = .boolean;
                errdefer vm.allocator.free(list);
                for (list, 0..) |*value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    value.* = try equal(vm, x, list_y[i]);
                    if (list_type != .list and value.*.as != .boolean) list_type = .list;
                }
                break :blk vm.initList(list, list_type);
            },
            else => runtimeError(EqualError.incompatible_types),
        },
        .list, .boolean_list, .int_list, .float_list => |list_x| switch (y.as) {
            .boolean, .int, .float => blk: {
                if (list_x.len == 0) break :blk x.ref();

                const list = vm.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ValueType = .boolean;
                errdefer vm.allocator.free(list);
                for (list, 0..) |*value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    value.* = try equal(vm, list_x[i], y);
                    if (list_type != .list and value.*.as != .boolean) list_type = .list;
                }
                break :blk vm.initList(list, list_type);
            },
            .list, .boolean_list, .int_list, .float_list => |list_y| blk: {
                if (list_x.len != list_y.len) break :blk runtimeError(EqualError.length_mismatch);
                if (list_x.len == 0) break :blk x.ref();

                const list = vm.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ValueType = .boolean;
                errdefer vm.allocator.free(list);
                for (list, 0..) |*value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    value.* = try equal(vm, list_x[i], list_y[i]);
                    if (list_type != .list and value.*.as != .boolean) list_type = .list;
                }
                break :blk vm.initList(list, list_type);
            },
            else => runtimeError(EqualError.incompatible_types),
        },
        .dictionary => |dict_x| switch (y.as) {
            .boolean, .int, .float => blk: {
                if (dict_x.key.asList().len == 0) {
                    const value = vm.initList(&[_]*Value{}, if (dict_x.value.as == .list) .list else .boolean_list);
                    const dictionary = ValueDictionary.init(.{ .key = dict_x.key.ref(), .value = value }, vm.allocator);
                    break :blk vm.initValue(.{ .dictionary = dictionary });
                }

                const value = try equal(vm, dict_x.value, y);
                const dictionary = ValueDictionary.init(.{ .key = dict_x.key.ref(), .value = value }, vm.allocator);
                break :blk vm.initValue(.{ .dictionary = dictionary });
            },
            .list, .boolean_list, .int_list, .float_list => |list_y| blk: {
                if (dict_x.key.asList().len != list_y.len) break :blk runtimeError(EqualError.length_mismatch);
                if (dict_x.key.asList().len == 0) {
                    const value = vm.initList(&[_]*Value{}, if (dict_x.value.as == .list) .list else .boolean_list);
                    const dictionary = ValueDictionary.init(.{ .key = dict_x.key.ref(), .value = value }, vm.allocator);
                    break :blk vm.initValue(.{ .dictionary = dictionary });
                }

                const value = try equal(vm, dict_x.value, y);
                const dictionary = ValueDictionary.init(.{ .key = dict_x.key.ref(), .value = value }, vm.allocator);
                break :blk vm.initValue(.{ .dictionary = dictionary });
            },
            else => runtimeError(EqualError.incompatible_types),
        },
        .table => |table_x| switch (y.as) {
            .boolean, .int, .float => blk: {
                if (table_x.values.as.list[0].asList().len == 0) {
                    const list = vm.allocator.alloc(*Value, table_x.columns.as.symbol_list.len) catch std.debug.panic("Failed to create list.", .{});
                    for (list, table_x.values.as.list) |*value, column| {
                        const list_type = @intToEnum(ValueType, std.math.min(@enumToInt(ValueType.boolean_list), @enumToInt(column.as)));
                        value.* = vm.initList(&[_]*Value{}, list_type);
                    }
                    const values = vm.initValue(.{ .list = list });
                    const table = ValueTable.init(.{ .columns = table_x.columns.ref(), .values = values }, vm.allocator);
                    break :blk vm.initValue(.{ .table = table });
                }

                const list = vm.allocator.alloc(*Value, table_x.columns.as.symbol_list.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                for (list, table_x.values.as.list, 0..) |*value, column, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    value.* = try equal(vm, column, y);
                }
                const values = vm.initValue(.{ .list = list });
                const table = ValueTable.init(.{ .columns = table_x.columns.ref(), .values = values }, vm.allocator);
                break :blk vm.initValue(.{ .table = table });
            },
            else => runtimeError(EqualError.incompatible_types),
        },
        else => runtimeError(EqualError.incompatible_types),
    };
}
