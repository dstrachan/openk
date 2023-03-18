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

pub const ApplyError = error{
    incompatible_types,
};

fn runtimeError(comptime err: ApplyError) ApplyError!*Value {
    switch (err) {
        ApplyError.incompatible_types => print("Incompatible types.\n", .{}),
    }
    return err;
}

pub fn index(vm: *VM, x: *Value, y: *Value) ApplyError!*Value {
    return switch (x.as) {
        .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list_x| switch (y.as) {
            .boolean => |bool_y| if (list_x.len <= @boolToInt(bool_y)) vm.initNull(x.as) else list_x[@boolToInt(bool_y)].ref(),
            .int => |int_y| if (int_y < 0 or list_x.len <= int_y) vm.initNull(x.as) else list_x[@intCast(usize, int_y)].ref(),
            .list, .boolean_list, .int_list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = if (list_y.len == 0) .list else null;
                for (list_y, 0..) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try index(vm, x, value);
                    if (list_type == null and @as(ValueType, list[0].as) != list[i].as) list_type = .list;
                }
                break :blk vm.initList(list, list_type);
            },
            else => runtimeError(ApplyError.incompatible_types),
        },
        .dictionary => |dict_x| switch (y.as) {
            .boolean, .int, .float, .char, .symbol => if (dict_x.hash_map.get(y)) |v| v.ref() else vm.initNull(dict_x.values.as),
            .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (list_y, 0..) |lookup, i| {
                    list[i] = if (dict_x.hash_map.get(lookup)) |v| v.ref() else vm.initNull(dict_x.values.as);
                }
                break :blk vm.initList(list, dict_x.values.as);
            },
            else => runtimeError(ApplyError.incompatible_types),
        },
        .table => |table_x| switch (y.as) {
            .boolean, .int => blk: {
                const list = vm.allocator.alloc(*Value, table_x.columns.as.symbol_list.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = null;
                for (list, table_x.values.as.list, 0..) |*value, column, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    value.* = try index(vm, column, y);
                    if (list_type == null and @as(ValueType, list[0].as) != value.*.as) list_type = .list;
                }
                const values = vm.initList(list, list_type);
                const dictionary = ValueDictionary.init(.{ .keys = table_x.columns.ref(), .values = values }, vm);
                break :blk vm.initValue(.{ .dictionary = dictionary });
            },
            .symbol => if (table_x.hash_map.get(y)) |v| v.ref() else vm.initList(&.{}, table_x.values.as.list[0].as),
            .list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = null;
                for (list, list_y, 0..) |*value, y_value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    value.* = try index(vm, x, y_value);
                    if (list_type == null and @as(ValueType, list[0].as) != value.*.as) list_type = .list;
                }
                break :blk vm.initList(list, list_type);
            },
            .boolean_list, .int_list => blk: {
                const list = vm.allocator.alloc(*Value, table_x.columns.as.symbol_list.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                for (list, table_x.values.as.list, 0..) |*value, column, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    value.* = try index(vm, column, y);
                }
                const values = vm.initValue(.{ .list = list });
                const table = ValueTable.init(.{ .columns = table_x.columns.ref(), .values = values }, vm.allocator);
                break :blk vm.initValue(.{ .table = table });
            },
            .symbol_list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (list, list_y) |*value, y_value| {
                    value.* = if (table_x.hash_map.get(y_value)) |v| v.ref() else vm.initList(&.{}, table_x.values.as.list[0].as);
                }
                break :blk vm.initValue(.{ .list = list });
            },
            else => runtimeError(ApplyError.incompatible_types),
        },
        .function => unreachable,
        .projection => unreachable,
        else => runtimeError(ApplyError.incompatible_types),
    };
}
