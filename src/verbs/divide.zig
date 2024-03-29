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

pub const DivideError = error{
    incompatible_types,
    length_mismatch,
};

fn runtimeError(comptime err: DivideError) DivideError!*Value {
    switch (err) {
        DivideError.incompatible_types => print("Incompatible types.\n", .{}),
        DivideError.length_mismatch => print("List lengths must match.\n", .{}),
    }
    return err;
}

fn divideFloat(x: f64, y: f64) f64 {
    return if (std.math.isNan(x) or std.math.isNan(y)) Value.null_float else x / y;
}

pub fn divide(vm: *VM, x: *Value, y: *Value) DivideError!*Value {
    return switch (x.as) {
        .boolean => |bool_x| switch (y.as) {
            .boolean => |bool_y| vm.initValue(.{ .float = divideFloat(if (bool_x) 1 else 0, if (bool_y) 1 else 0) }),
            .int => |int_y| vm.initValue(.{ .float = divideFloat(if (bool_x) 1 else 0, utils_mod.intToFloat(int_y)) }),
            .float => |float_y| vm.initValue(.{ .float = divideFloat(if (bool_x) 1 else 0, float_y) }),
            .list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = if (list_y.len == 0) .list else null;
                for (list_y, 0..) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try divide(vm, x, value);
                    if (list_type == null and @as(ValueType, list[0].as) != list[i].as) list_type = .list;
                }
                break :blk vm.initListAtoms(list, list_type);
            },
            .boolean_list => |bool_list_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = divideFloat(if (bool_x) 1 else 0, if (value.as.boolean) 1 else 0) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = divideFloat(if (bool_x) 1 else 0, utils_mod.intToFloat(value.as.int)) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .float_list => |float_list_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = divideFloat(if (bool_x) 1 else 0, value.as.float) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .dictionary => |dict_y| blk: {
                if (dict_y.values.asList().len == 0) break :blk y.ref();

                const value = try divide(vm, x, dict_y.values);
                break :blk vm.initDictionary(.{ .keys = dict_y.keys.ref(), .values = value });
            },
            .table => |table_y| blk: {
                const values = try divide(vm, x, table_y.values);
                break :blk vm.initTable(.{ .columns = table_y.columns.ref(), .values = values });
            },
            else => runtimeError(DivideError.incompatible_types),
        },
        .int => |int_x| switch (y.as) {
            .boolean => |bool_y| vm.initValue(.{ .float = divideFloat(utils_mod.intToFloat(int_x), if (bool_y) 1 else 0) }),
            .int => |int_y| vm.initValue(.{ .float = divideFloat(utils_mod.intToFloat(int_x), utils_mod.intToFloat(int_y)) }),
            .float => |float_y| vm.initValue(.{ .float = divideFloat(utils_mod.intToFloat(int_x), float_y) }),
            .list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = if (list_y.len == 0) .list else null;
                for (list_y, 0..) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try divide(vm, x, value);
                    if (list_type == null and @as(ValueType, list[0].as) != list[i].as) list_type = .list;
                }
                break :blk vm.initListAtoms(list, list_type);
            },
            .boolean_list => |bool_list_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = divideFloat(utils_mod.intToFloat(int_x), if (value.as.boolean) 1 else 0) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = divideFloat(utils_mod.intToFloat(int_x), utils_mod.intToFloat(value.as.int)) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .float_list => |float_list_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = divideFloat(utils_mod.intToFloat(int_x), value.as.float) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .dictionary => |dict_y| blk: {
                if (dict_y.values.asList().len == 0) break :blk y.ref();

                const value = try divide(vm, x, dict_y.values);
                break :blk vm.initDictionary(.{ .keys = dict_y.keys.ref(), .values = value });
            },
            .table => |table_y| blk: {
                const values = try divide(vm, x, table_y.values);
                break :blk vm.initTable(.{ .columns = table_y.columns.ref(), .values = values });
            },
            else => runtimeError(DivideError.incompatible_types),
        },
        .float => |float_x| switch (y.as) {
            .boolean => |bool_y| vm.initValue(.{ .float = divideFloat(float_x, if (bool_y) 1 else 0) }),
            .int => |int_y| vm.initValue(.{ .float = divideFloat(float_x, utils_mod.intToFloat(int_y)) }),
            .float => |float_y| vm.initValue(.{ .float = divideFloat(float_x, float_y) }),
            .list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = if (list_y.len == 0) .list else null;
                for (list_y, 0..) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try divide(vm, x, value);
                    if (list_type == null and @as(ValueType, list[0].as) != list[i].as) list_type = .list;
                }
                break :blk vm.initListAtoms(list, list_type);
            },
            .boolean_list => |bool_list_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = divideFloat(float_x, if (value.as.boolean) 1 else 0) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = divideFloat(float_x, utils_mod.intToFloat(value.as.int)) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .float_list => |float_list_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = divideFloat(float_x, value.as.float) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .dictionary => |dict_y| blk: {
                if (dict_y.values.asList().len == 0) break :blk y.ref();

                const value = try divide(vm, x, dict_y.values);
                break :blk vm.initDictionary(.{ .keys = dict_y.keys.ref(), .values = value });
            },
            .table => |table_y| blk: {
                const values = try divide(vm, x, table_y.values);
                break :blk vm.initTable(.{ .columns = table_y.columns.ref(), .values = values });
            },
            else => runtimeError(DivideError.incompatible_types),
        },
        .list => |list_x| switch (y.as) {
            .boolean, .int, .float => blk: {
                const list = vm.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = if (list_x.len == 0) .list else null;
                for (list_x, 0..) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try divide(vm, value, y);
                    if (list_type == null and @as(ValueType, list[0].as) != list[i].as) list_type = .list;
                }
                break :blk vm.initListAtoms(list, list_type);
            },
            .list, .boolean_list, .int_list, .float_list => |list_y| blk: {
                if (list_x.len != list_y.len) return runtimeError(DivideError.length_mismatch);

                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = if (list_y.len == 0) .list else null;
                for (list_y, 0..) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try divide(vm, list_x[i], value);
                    if (list_type == null and @as(ValueType, list[0].as) != list[i].as) list_type = .list;
                }
                break :blk vm.initListAtoms(list, list_type);
            },
            .dictionary => |dict_y| blk: {
                if (dict_y.values.asList().len == 0) break :blk y.ref();

                const value = try divide(vm, x, dict_y.values);
                break :blk vm.initDictionary(.{ .keys = dict_y.keys.ref(), .values = value });
            },
            else => runtimeError(DivideError.incompatible_types),
        },
        .boolean_list => |bool_list_x| switch (y.as) {
            .boolean => |bool_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_x, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = divideFloat(if (value.as.boolean) 1 else 0, if (bool_y) 1 else 0) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .int => |int_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_x, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = divideFloat(if (value.as.boolean) 1 else 0, utils_mod.intToFloat(int_y)) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .float => |float_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_x, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = divideFloat(if (value.as.boolean) 1 else 0, float_y) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .list => |list_y| blk: {
                if (bool_list_x.len != list_y.len) return runtimeError(DivideError.length_mismatch);

                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = if (list_y.len == 0) .list else null;
                for (list_y, 0..) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try divide(vm, bool_list_x[i], value);
                    if (list_type == null and @as(ValueType, list[0].as) != list[i].as) list_type = .list;
                }
                break :blk vm.initListAtoms(list, list_type);
            },
            .boolean_list => |bool_list_y| blk: {
                if (bool_list_x.len != bool_list_y.len) return runtimeError(DivideError.length_mismatch);

                const list = vm.allocator.alloc(*Value, bool_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = divideFloat(if (bool_list_x[i].as.boolean) 1 else 0, if (value.as.boolean) 1 else 0) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .int_list => |int_list_y| blk: {
                if (bool_list_x.len != int_list_y.len) return runtimeError(DivideError.length_mismatch);

                const list = vm.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = divideFloat(if (bool_list_x[i].as.boolean) 1 else 0, utils_mod.intToFloat(value.as.int)) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .float_list => |float_list_y| blk: {
                if (bool_list_x.len != float_list_y.len) return runtimeError(DivideError.length_mismatch);

                const list = vm.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = divideFloat(if (bool_list_x[i].as.boolean) 1 else 0, value.as.float) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .dictionary => |dict_y| blk: {
                if (dict_y.values.asList().len == 0) break :blk y.ref();

                const value = try divide(vm, x, dict_y.values);
                break :blk vm.initDictionary(.{ .keys = dict_y.keys.ref(), .values = value });
            },
            else => runtimeError(DivideError.incompatible_types),
        },
        .int_list => |int_list_x| switch (y.as) {
            .boolean => |bool_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_x, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = divideFloat(utils_mod.intToFloat(value.as.int), if (bool_y) 1 else 0) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .int => |int_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_x, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = divideFloat(utils_mod.intToFloat(value.as.int), utils_mod.intToFloat(int_y)) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .float => |float_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_x, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = divideFloat(utils_mod.intToFloat(value.as.int), float_y) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .list => |list_y| blk: {
                if (int_list_x.len != list_y.len) return runtimeError(DivideError.length_mismatch);

                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = if (list_y.len == 0) .list else null;
                for (list_y, 0..) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try divide(vm, int_list_x[i], value);
                    if (list_type == null and @as(ValueType, list[0].as) != list[i].as) list_type = .list;
                }
                break :blk vm.initListAtoms(list, list_type);
            },
            .boolean_list => |bool_list_y| blk: {
                if (int_list_x.len != bool_list_y.len) return runtimeError(DivideError.length_mismatch);

                const list = vm.allocator.alloc(*Value, bool_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = divideFloat(utils_mod.intToFloat(int_list_x[i].as.int), if (value.as.boolean) 1 else 0) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .int_list => |int_list_y| blk: {
                if (int_list_x.len != int_list_y.len) return runtimeError(DivideError.length_mismatch);

                const list = vm.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = divideFloat(utils_mod.intToFloat(int_list_x[i].as.int), utils_mod.intToFloat(value.as.int)) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .float_list => |float_list_y| blk: {
                if (int_list_x.len != float_list_y.len) return runtimeError(DivideError.length_mismatch);

                const list = vm.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = divideFloat(utils_mod.intToFloat(int_list_x[i].as.int), value.as.float) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .dictionary => |dict_y| blk: {
                if (dict_y.values.asList().len == 0) break :blk y.ref();

                const value = try divide(vm, x, dict_y.values);
                break :blk vm.initDictionary(.{ .keys = dict_y.keys.ref(), .values = value });
            },
            else => runtimeError(DivideError.incompatible_types),
        },
        .float_list => |float_list_x| switch (y.as) {
            .boolean => |bool_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_x, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = divideFloat(value.as.float, if (bool_y) 1 else 0) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .int => |int_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_x, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = divideFloat(value.as.float, utils_mod.intToFloat(int_y)) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .float => |float_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_x, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = divideFloat(value.as.float, float_y) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .list => |list_y| blk: {
                if (float_list_x.len != list_y.len) return runtimeError(DivideError.length_mismatch);

                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                for (list_y, 0..) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try divide(vm, float_list_x[i], value);
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .boolean_list => |bool_list_y| blk: {
                if (float_list_x.len != bool_list_y.len) return runtimeError(DivideError.length_mismatch);

                const list = vm.allocator.alloc(*Value, bool_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = divideFloat(float_list_x[i].as.float, if (value.as.boolean) 1 else 0) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .int_list => |int_list_y| blk: {
                if (float_list_x.len != int_list_y.len) return runtimeError(DivideError.length_mismatch);

                const list = vm.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = divideFloat(float_list_x[i].as.float, utils_mod.intToFloat(value.as.int)) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .float_list => |float_list_y| blk: {
                if (float_list_x.len != float_list_y.len) return runtimeError(DivideError.length_mismatch);

                const list = vm.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = divideFloat(float_list_x[i].as.float, value.as.float) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .dictionary => |dict_y| blk: {
                if (dict_y.values.asList().len == 0) break :blk y.ref();

                const value = try divide(vm, x, dict_y.values);
                break :blk vm.initDictionary(.{ .keys = dict_y.keys.ref(), .values = value });
            },
            else => runtimeError(DivideError.incompatible_types),
        },
        .dictionary => |dict_x| switch (y.as) {
            .boolean, .int, .float, .char, .symbol, .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => blk: {
                const value = try divide(vm, dict_x.values, y);
                break :blk vm.initDictionary(.{ .keys = dict_x.keys.ref(), .values = value });
            },
            .dictionary => |dict_y| blk: {
                if (dict_x.keys.asList().len == 0) break :blk y.ref();
                if (dict_y.keys.asList().len == 0) break :blk x.ref();

                var key_list = dict_x.keys.asArrayList(vm.allocator);
                errdefer key_list.deinit();
                errdefer for (key_list.items) |v| v.deref(vm.allocator);
                var key_list_type: ValueType = dict_x.keys.as;

                var value_list = dict_x.values.asArrayList(vm.allocator);
                errdefer value_list.deinit();
                errdefer for (value_list.items) |v| v.deref(vm.allocator);

                for (dict_y.keys.asList(), dict_y.values.asList()) |k_y, v_y| loop: {
                    for (key_list.items, value_list.items) |k_x, *v_x| {
                        if (k_x.eql(k_y)) {
                            v_x.*.deref(vm.allocator);
                            v_x.* = try divide(vm, v_x.*, v_y);
                            break :loop;
                        }
                    }

                    key_list.append(k_y.ref()) catch std.debug.panic("Failed to append item.", .{});
                    if (key_list_type != .list and @as(ValueType, key_list.items[0].as) != key_list.items[key_list.items.len - 1].as) key_list_type = .list;
                    value_list.append(v_y.ref()) catch std.debug.panic("Failed to append item.", .{});
                }

                const key_slice = key_list.toOwnedSlice() catch std.debug.panic("Failed to create list.", .{});
                const value_slice = value_list.toOwnedSlice() catch std.debug.panic("Failed to create list.", .{});
                const key = vm.initList(key_slice, key_list_type);
                const value = vm.initListIter(value_slice);
                break :blk vm.initDictionary(.{ .keys = key, .values = value });
            },
            else => runtimeError(DivideError.incompatible_types),
        },
        .table => |table_x| switch (y.as) {
            .boolean, .int, .float => blk: {
                const values = try divide(vm, table_x.values, y);
                break :blk vm.initTable(.{ .columns = table_x.columns.ref(), .values = values });
            },
            .table => |table_y| blk: {
                var columns = table_x.columns.asArrayList(vm.allocator);
                errdefer columns.deinit();
                errdefer for (columns.items) |v| v.deref(vm.allocator);
                var values = table_x.values.asArrayList(vm.allocator);
                errdefer values.deinit();
                errdefer for (values.items) |v| v.deref(vm.allocator);
                for (table_y.columns.as.symbol_list, 0..) |c_y, i_y| loop: {
                    for (columns.items, 0..) |c_x, i_x| {
                        if (c_x.eql(c_y)) {
                            values.items[i_x].deref(vm.allocator);
                            values.items[i_x] = try divide(vm, values.items[i_x], table_y.values.as.list[i_y]);
                            break :loop;
                        }
                    }
                    columns.append(c_y.ref()) catch std.debug.panic("Failed to append item.", .{});
                    values.append(table_y.values.as.list[i_y].ref()) catch std.debug.panic("Failed to append item.", .{});
                }
                const columns_list = columns.toOwnedSlice() catch std.debug.panic("Failed to create list.", .{});
                const new_columns = vm.initValue(.{ .symbol_list = columns_list });
                const values_list = values.toOwnedSlice() catch std.debug.panic("Failed to create list.", .{});
                const new_values = vm.initValue(.{ .list = values_list });
                break :blk vm.initTable(.{ .columns = new_columns, .values = new_values });
            },
            else => runtimeError(DivideError.incompatible_types),
        },
        else => runtimeError(DivideError.incompatible_types),
    };
}
