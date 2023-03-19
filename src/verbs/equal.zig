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
                for (list, 0..) |*value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    value.* = try equal(vm, x, list_y[i]);
                    if (list_type != .list and value.*.as != .boolean) list_type = .list;
                }
                break :blk vm.initList(list, list_type);
            },
            .dictionary => |dict_y| blk: {
                if (dict_y.values.asList().len == 0) {
                    const values = vm.initList(&.{}, utils_mod.minType(&.{ .boolean_list, dict_y.values.as }));
                    break :blk vm.initDictionary(.{ .keys = dict_y.keys.ref(), .values = values });
                }

                const list = vm.allocator.alloc(*Value, dict_y.values.asList().len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = null;
                for (list, dict_y.values.asList(), 0..) |*value, y_value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    value.* = try equal(vm, x, y_value);
                    if (list_type == null and value.*.as != .boolean) list_type = .list;
                }

                const values = vm.initList(list, list_type);
                break :blk vm.initDictionary(.{ .keys = dict_y.keys.ref(), .values = values });
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
                for (list, 0..) |*value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    value.* = try equal(vm, x, list_y[i]);
                    if (list_type != .list and value.*.as != .boolean) list_type = .list;
                }
                break :blk vm.initList(list, list_type);
            },
            .dictionary => |dict_y| blk: {
                if (dict_y.values.asList().len == 0) {
                    const values = vm.initList(&.{}, utils_mod.minType(&.{ .boolean_list, dict_y.values.as }));
                    break :blk vm.initDictionary(.{ .keys = dict_y.keys.ref(), .values = values });
                }

                const list = vm.allocator.alloc(*Value, dict_y.values.asList().len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = null;
                for (list, dict_y.values.asList(), 0..) |*value, y_value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    value.* = try equal(vm, x, y_value);
                    if (list_type == null and value.*.as != .boolean) list_type = .list;
                }

                const values = vm.initList(list, list_type);
                break :blk vm.initDictionary(.{ .keys = dict_y.keys.ref(), .values = values });
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
                for (list, 0..) |*value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    value.* = try equal(vm, x, list_y[i]);
                    if (list_type != .list and value.*.as != .boolean) list_type = .list;
                }
                break :blk vm.initList(list, list_type);
            },
            .dictionary => |dict_y| blk: {
                if (dict_y.values.asList().len == 0) {
                    const values = vm.initList(&.{}, utils_mod.minType(&.{ .boolean_list, dict_y.values.as }));
                    break :blk vm.initDictionary(.{ .keys = dict_y.keys.ref(), .values = values });
                }

                const list = vm.allocator.alloc(*Value, dict_y.values.asList().len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = null;
                for (list, dict_y.values.asList(), 0..) |*value, y_value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    value.* = try equal(vm, x, y_value);
                    if (list_type == null and value.*.as != .boolean) list_type = .list;
                }

                const values = vm.initList(list, list_type);
                break :blk vm.initDictionary(.{ .keys = dict_y.keys.ref(), .values = values });
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
                for (list, 0..) |*value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    value.* = try equal(vm, list_x[i], y);
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
                for (list, 0..) |*value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    value.* = try equal(vm, list_x[i], list_y[i]);
                    if (list_type != .list and value.*.as != .boolean) list_type = .list;
                }
                break :blk vm.initList(list, list_type);
            },
            .dictionary => |dict_y| blk: {
                if (list_x.len != dict_y.values.asList().len) break :blk runtimeError(EqualError.length_mismatch);
                if (list_x.len == 0) {
                    const values = vm.initList(&.{}, utils_mod.minType(&.{ .boolean_list, dict_y.values.as }));
                    break :blk vm.initDictionary(.{ .keys = dict_y.keys.ref(), .values = values });
                }

                const list = vm.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = null;
                for (list, list_x, dict_y.values.asList(), 0..) |*value, x_value, y_value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    value.* = try equal(vm, x_value, y_value);
                    if (list_type == null and value.*.as != .boolean) list_type = .list;
                }

                const values = vm.initList(list, list_type);
                break :blk vm.initDictionary(.{ .keys = dict_y.keys.ref(), .values = values });
            },
            else => runtimeError(EqualError.incompatible_types),
        },
        .dictionary => |dict_x| switch (y.as) {
            .boolean, .int, .float => blk: {
                const values = switch (dict_x.keys.asList().len == 0) {
                    true => vm.initList(&.{}, @intToEnum(ValueType, std.math.min(@enumToInt(ValueType.boolean_list), @enumToInt(dict_x.keys.as)))),
                    false => try equal(vm, dict_x.values, y),
                };
                break :blk vm.initDictionary(.{ .keys = dict_x.keys.ref(), .values = values });
            },
            .list, .boolean_list, .int_list, .float_list => |list_y| blk: {
                if (dict_x.keys.asList().len != list_y.len) break :blk runtimeError(EqualError.length_mismatch);
                if (dict_x.keys.asList().len == 0) {
                    const list_type = @intToEnum(ValueType, std.math.min(@enumToInt(ValueType.boolean_list), @enumToInt(dict_x.values.as)));
                    const values = vm.initList(&.{}, list_type);
                    break :blk vm.initDictionary(.{ .keys = dict_x.keys.ref(), .values = values });
                }

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

                // TODO: Build hash_map for: (`a`b!1 2)=`c`d!1 2

                const list = vm.allocator.alloc(*Value, dict_x.values.asList().len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = null;
                for (list, dict_x.keys.asList(), dict_x.values.asList(), 0..) |*value, x_key, x_value, i| {
                    if (dict_y.hash_map.get(x_key)) |y_value| {
                        errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                        value.* = try equal(vm, x_value, y_value);
                        if (list_type == null and value.*.as != .boolean) list_type = .list;
                    } else {
                        value.* = vm.initValue(.{ .boolean = false });
                    }
                }

                const values = vm.initList(list, list_type);
                break :blk vm.initDictionary(.{ .keys = dict_x.keys.ref(), .values = values });
            },
            else => runtimeError(EqualError.incompatible_types),
        },
        .table => |table_x| switch (y.as) {
            .boolean, .int, .float => blk: {
                if (table_x.values.as.list[0].asList().len == 0) {
                    const list = vm.allocator.alloc(*Value, table_x.columns.as.symbol_list.len) catch std.debug.panic("Failed to create list.", .{});
                    for (list, table_x.values.as.list) |*value, column| {
                        const list_type = @intToEnum(ValueType, std.math.min(@enumToInt(ValueType.boolean_list), @enumToInt(column.as)));
                        value.* = vm.initList(&.{}, list_type);
                    }
                    const values = vm.initValue(.{ .list = list });
                    break :blk vm.initTable(.{ .columns = table_x.columns.ref(), .values = values });
                }

                const list = vm.allocator.alloc(*Value, table_x.columns.as.symbol_list.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                for (list, table_x.values.as.list, 0..) |*value, column, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    value.* = try equal(vm, column, y);
                }
                const values = vm.initValue(.{ .list = list });
                break :blk vm.initTable(.{ .columns = table_x.columns.ref(), .values = values });
            },
            else => runtimeError(EqualError.incompatible_types),
        },
        else => runtimeError(EqualError.incompatible_types),
    };
}
