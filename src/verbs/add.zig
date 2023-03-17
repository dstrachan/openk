const std = @import("std");

const utils_mod = @import("../utils.zig");
const print = utils_mod.print;

const value_mod = @import("../value.zig");
const Value = value_mod.Value;
const ValueDictionary = value_mod.ValueDictionary;
const ValueHashMapContext = value_mod.ValueHashMapContext;
const ValueTable = value_mod.ValueTable;
const ValueType = value_mod.ValueType;

const vm_mod = @import("../vm.zig");
const VM = vm_mod.VM;

pub const AddError = error{
    incompatible_types,
    length_mismatch,
};

fn runtimeError(comptime err: AddError) AddError!*Value {
    switch (err) {
        AddError.incompatible_types => print("Incompatible types.\n", .{}),
        AddError.length_mismatch => print("List lengths must match.\n", .{}),
    }
    return err;
}

fn addInt(x: i64, y: i64) i64 {
    if (x == Value.null_int or y == Value.null_int) return Value.null_int;
    return x +% y;
}

fn addFloat(x: f64, y: f64) f64 {
    return x + y;
}

pub fn add(vm: *VM, x: *Value, y: *Value) AddError!*Value {
    return switch (x.as) {
        .boolean => |bool_x| switch (y.as) {
            .boolean => |bool_y| vm.initValue(.{ .int = addInt(@boolToInt(bool_x), @boolToInt(bool_y)) }),
            .int => |int_y| vm.initValue(.{ .int = addInt(@boolToInt(bool_x), int_y) }),
            .float => |float_y| vm.initValue(.{ .float = addFloat(if (bool_x) 1 else 0, float_y) }),
            .list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = if (list_y.len == 0) .list else null;
                for (list_y, 0..) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try add(vm, x, value);
                    if (list_type == null and @as(ValueType, list[0].as) != list[i].as) list_type = .list;
                }
                break :blk vm.initListAtoms(list, list_type);
            },
            .boolean_list => |bool_list_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .int = addInt(@boolToInt(bool_x), @boolToInt(value.as.boolean)) });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .int = addInt(@boolToInt(bool_x), value.as.int) });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .float_list => |float_list_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = addFloat(if (bool_x) 1 else 0, value.as.float) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .dictionary => |dict_y| blk: {
                if (dict_y.values.asList().len == 0) break :blk y.ref();

                const value = try add(vm, x, dict_y.values);
                const dictionary = ValueDictionary.init(.{ .keys = dict_y.keys.ref(), .values = value }, vm.allocator);
                break :blk vm.initValue(.{ .dictionary = dictionary });
            },
            .table => |table_y| blk: {
                const values = try add(vm, x, table_y.values);
                const table = ValueTable.init(.{ .columns = table_y.columns.ref(), .values = values }, vm.allocator);
                break :blk vm.initValue(.{ .table = table });
            },
            else => runtimeError(AddError.incompatible_types),
        },
        .int => |int_x| switch (y.as) {
            .boolean => |bool_y| vm.initValue(.{ .int = addInt(int_x, @boolToInt(bool_y)) }),
            .int => |int_y| vm.initValue(.{ .int = addInt(int_x, int_y) }),
            .float => |float_y| vm.initValue(.{ .float = addFloat(utils_mod.intToFloat(int_x), float_y) }),
            .list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = if (list_y.len == 0) .list else null;
                for (list_y, 0..) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try add(vm, x, value);
                    if (list_type == null and @as(ValueType, list[0].as) != list[i].as) list_type = .list;
                }
                break :blk vm.initListAtoms(list, list_type);
            },
            .boolean_list => |bool_list_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .int = addInt(int_x, @boolToInt(value.as.boolean)) });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .int = addInt(int_x, value.as.int) });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .float_list => |float_list_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = addFloat(utils_mod.intToFloat(int_x), value.as.float) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .dictionary => |dict_y| blk: {
                if (dict_y.values.asList().len == 0) break :blk y.ref();

                const value = try add(vm, x, dict_y.values);
                const dictionary = ValueDictionary.init(.{ .keys = dict_y.keys.ref(), .values = value }, vm.allocator);
                break :blk vm.initValue(.{ .dictionary = dictionary });
            },
            .table => |table_y| blk: {
                const values = try add(vm, x, table_y.values);
                const table = ValueTable.init(.{ .columns = table_y.columns.ref(), .values = values }, vm.allocator);
                break :blk vm.initValue(.{ .table = table });
            },
            else => runtimeError(AddError.incompatible_types),
        },
        .float => |float_x| switch (y.as) {
            .boolean => |bool_y| vm.initValue(.{ .float = addFloat(float_x, if (bool_y) 1 else 0) }),
            .int => |int_y| vm.initValue(.{ .float = addFloat(float_x, utils_mod.intToFloat(int_y)) }),
            .float => |float_y| vm.initValue(.{ .float = addFloat(float_x, float_y) }),
            .list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = if (list_y.len == 0) .list else null;
                for (list_y, 0..) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try add(vm, x, value);
                    if (list_type == null and @as(ValueType, list[0].as) != list[i].as) list_type = .list;
                }
                break :blk vm.initListAtoms(list, list_type);
            },
            .boolean_list => |bool_list_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = addFloat(float_x, if (value.as.boolean) 1 else 0) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = addFloat(float_x, utils_mod.intToFloat(value.as.int)) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .float_list => |float_list_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = addFloat(float_x, value.as.float) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .dictionary => |dict_y| blk: {
                if (dict_y.values.asList().len == 0) break :blk y.ref();

                const value = try add(vm, x, dict_y.values);
                const dictionary = ValueDictionary.init(.{ .keys = dict_y.keys.ref(), .values = value }, vm.allocator);
                break :blk vm.initValue(.{ .dictionary = dictionary });
            },
            .table => |table_y| blk: {
                const values = try add(vm, x, table_y.values);
                const table = ValueTable.init(.{ .columns = table_y.columns.ref(), .values = values }, vm.allocator);
                break :blk vm.initValue(.{ .table = table });
            },
            else => runtimeError(AddError.incompatible_types),
        },
        .list => |list_x| switch (y.as) {
            .boolean, .int, .float => blk: {
                const list = vm.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = if (list_x.len == 0) .list else null;
                for (list_x, 0..) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try add(vm, value, y);
                    if (list_type == null and @as(ValueType, list[0].as) != list[i].as) list_type = .list;
                }
                break :blk vm.initListAtoms(list, list_type);
            },
            .list, .boolean_list, .int_list, .float_list => |list_y| blk: {
                if (list_x.len != list_y.len) return runtimeError(AddError.length_mismatch);

                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = if (list_y.len == 0) .list else null;
                for (list_y, 0..) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try add(vm, list_x[i], value);
                    if (list_type == null and @as(ValueType, list[0].as) != list[i].as) list_type = .list;
                }
                break :blk vm.initListAtoms(list, list_type);
            },
            .dictionary => |dict_y| blk: {
                if (dict_y.values.asList().len == 0) break :blk y.ref();

                const value = try add(vm, x, dict_y.values);
                const dictionary = ValueDictionary.init(.{ .keys = dict_y.keys.ref(), .values = value }, vm.allocator);
                break :blk vm.initValue(.{ .dictionary = dictionary });
            },
            else => runtimeError(AddError.incompatible_types),
        },
        .boolean_list => |bool_list_x| switch (y.as) {
            .boolean => |bool_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_x, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .int = addInt(@boolToInt(value.as.boolean), @boolToInt(bool_y)) });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .int => |int_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_x, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .int = addInt(@boolToInt(value.as.boolean), int_y) });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .float => |float_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_x, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = addFloat(if (value.as.boolean) 1 else 0, float_y) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .list => |list_y| blk: {
                if (bool_list_x.len != list_y.len) return runtimeError(AddError.length_mismatch);

                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = if (list_y.len == 0) .list else null;
                for (list_y, 0..) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try add(vm, bool_list_x[i], value);
                    if (list_type == null and @as(ValueType, list[0].as) != list[i].as) list_type = .list;
                }
                break :blk vm.initListAtoms(list, list_type);
            },
            .boolean_list => |bool_list_y| blk: {
                if (bool_list_x.len != bool_list_y.len) return runtimeError(AddError.length_mismatch);

                const list = vm.allocator.alloc(*Value, bool_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .int = addInt(@boolToInt(bool_list_x[i].as.boolean), @boolToInt(value.as.boolean)) });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .int_list => |int_list_y| blk: {
                if (bool_list_x.len != int_list_y.len) return runtimeError(AddError.length_mismatch);

                const list = vm.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .int = addInt(@boolToInt(bool_list_x[i].as.boolean), value.as.int) });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .float_list => |float_list_y| blk: {
                if (bool_list_x.len != float_list_y.len) return runtimeError(AddError.length_mismatch);

                const list = vm.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = addFloat(if (bool_list_x[i].as.boolean) 1 else 0, value.as.float) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .dictionary => |dict_y| blk: {
                if (dict_y.values.asList().len == 0) break :blk y.ref();

                const value = try add(vm, x, dict_y.values);
                const dictionary = ValueDictionary.init(.{ .keys = dict_y.keys.ref(), .values = value }, vm.allocator);
                break :blk vm.initValue(.{ .dictionary = dictionary });
            },
            else => runtimeError(AddError.incompatible_types),
        },
        .int_list => |int_list_x| switch (y.as) {
            .boolean => |bool_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_x, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .int = addInt(value.as.int, @boolToInt(bool_y)) });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .int => |int_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_x, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .int = addInt(value.as.int, int_y) });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .float => |float_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_x, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = addFloat(utils_mod.intToFloat(value.as.int), float_y) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .list => |list_y| blk: {
                if (int_list_x.len != list_y.len) return runtimeError(AddError.length_mismatch);

                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = if (list_y.len == 0) .list else null;
                for (list_y, 0..) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try add(vm, int_list_x[i], value);
                    if (list_type == null and @as(ValueType, list[0].as) != list[i].as) list_type = .list;
                }
                break :blk vm.initListAtoms(list, list_type);
            },
            .boolean_list => |bool_list_y| blk: {
                if (int_list_x.len != bool_list_y.len) return runtimeError(AddError.length_mismatch);

                const list = vm.allocator.alloc(*Value, bool_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .int = addInt(int_list_x[i].as.int, @boolToInt(value.as.boolean)) });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .int_list => |int_list_y| blk: {
                if (int_list_x.len != int_list_y.len) return runtimeError(AddError.length_mismatch);

                const list = vm.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .int = addInt(int_list_x[i].as.int, value.as.int) });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .float_list => |float_list_y| blk: {
                if (int_list_x.len != float_list_y.len) return runtimeError(AddError.length_mismatch);

                const list = vm.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = addFloat(utils_mod.intToFloat(int_list_x[i].as.int), value.as.float) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .dictionary => |dict_y| blk: {
                if (dict_y.values.asList().len == 0) break :blk y.ref();

                const value = try add(vm, x, dict_y.values);
                const dictionary = ValueDictionary.init(.{ .keys = dict_y.keys.ref(), .values = value }, vm.allocator);
                break :blk vm.initValue(.{ .dictionary = dictionary });
            },
            else => runtimeError(AddError.incompatible_types),
        },
        .float_list => |float_list_x| switch (y.as) {
            .boolean => |bool_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_x, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = addFloat(value.as.float, if (bool_y) 1 else 0) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .int => |int_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_x, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = addFloat(value.as.float, utils_mod.intToFloat(int_y)) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .float => |float_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_x, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = addFloat(value.as.float, float_y) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .list => |list_y| blk: {
                if (float_list_x.len != list_y.len) return runtimeError(AddError.length_mismatch);

                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                for (list_y, 0..) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try add(vm, float_list_x[i], value);
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .boolean_list => |bool_list_y| blk: {
                if (float_list_x.len != bool_list_y.len) return runtimeError(AddError.length_mismatch);

                const list = vm.allocator.alloc(*Value, bool_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = addFloat(float_list_x[i].as.float, if (value.as.boolean) 1 else 0) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .int_list => |int_list_y| blk: {
                if (float_list_x.len != int_list_y.len) return runtimeError(AddError.length_mismatch);

                const list = vm.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = addFloat(float_list_x[i].as.float, utils_mod.intToFloat(value.as.int)) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .float_list => |float_list_y| blk: {
                if (float_list_x.len != float_list_y.len) return runtimeError(AddError.length_mismatch);

                const list = vm.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_y, 0..) |value, i| {
                    list[i] = vm.initValue(.{ .float = addFloat(float_list_x[i].as.float, value.as.float) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .dictionary => |dict_y| blk: {
                if (dict_y.values.asList().len == 0) break :blk y.ref();

                const value = try add(vm, x, dict_y.values);
                const dictionary = ValueDictionary.init(.{ .keys = dict_y.keys.ref(), .values = value }, vm.allocator);
                break :blk vm.initValue(.{ .dictionary = dictionary });
            },
            else => runtimeError(AddError.incompatible_types),
        },
        .dictionary => |dict_x| switch (y.as) {
            .boolean, .int, .float, .char, .symbol, .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => blk: {
                const value = try add(vm, dict_x.values, y);
                const dictionary = ValueDictionary.init(.{ .keys = dict_x.keys.ref(), .values = value }, vm.allocator);
                break :blk vm.initValue(.{ .dictionary = dictionary });
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
                            v_x.* = try add(vm, v_x.*, v_y);
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
                const dictionary = ValueDictionary.init(.{ .keys = key, .values = value }, vm.allocator);
                break :blk vm.initValue(.{ .dictionary = dictionary });
            },
            else => runtimeError(AddError.incompatible_types),
        },
        .table => |table_x| switch (y.as) {
            .boolean, .int, .float => blk: {
                const values = try add(vm, table_x.values, y);
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
                            values.items[i_x] = try add(vm, values.items[i_x], table_y.values.asList()[i_y]);
                            break :loop;
                        }
                    }
                    columns.append(c_y.ref()) catch std.debug.panic("Failed to append item.", .{});
                    values.append(table_y.values.asList()[i_y].ref()) catch std.debug.panic("Failed to append item.", .{});
                }
                const columns_list = columns.toOwnedSlice() catch std.debug.panic("Failed to create list.", .{});
                const new_columns = vm.initValue(.{ .symbol_list = columns_list });
                const values_list = values.toOwnedSlice() catch std.debug.panic("Failed to create list.", .{});
                const new_values = vm.initValue(.{ .list = values_list });
                const table = ValueTable.init(.{ .columns = new_columns, .values = new_values }, vm.allocator);
                break :blk vm.initValue(.{ .table = table });
            },
            else => runtimeError(AddError.incompatible_types),
        },
        else => runtimeError(AddError.incompatible_types),
    };
}
