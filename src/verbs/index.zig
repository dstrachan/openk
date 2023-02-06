const std = @import("std");

const utils_mod = @import("../utils.zig");
const print = utils_mod.print;

const value_mod = @import("../value.zig");
const Value = value_mod.Value;
const ValueDictionary = value_mod.ValueDictionary;
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
        .list => |list_x| switch (y.as) {
            .boolean => |bool_y| if (list_x.len <= @boolToInt(bool_y)) list_x[0].copyNull(vm) else list_x[@boolToInt(bool_y)].ref(),
            .int => |int_y| if (int_y < 0 or list_x.len <= int_y) list_x[0].copyNull(vm) else list_x[@intCast(usize, int_y)].ref(),
            .list, .boolean_list, .int_list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = if (list_y.len == 0) .list else null;
                for (list_y) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try index(vm, x, value);
                    if (list_type == null and @as(ValueType, list[0].as) != list[i].as) list_type = .list;
                }
                break :blk vm.initValue(switch (if (list_type) |list_value_type| list_value_type else @as(ValueType, list[0].as)) {
                    .boolean => .{ .boolean_list = list },
                    .int => .{ .int_list = list },
                    .float => .{ .float_list = list },
                    .char => .{ .char_list = list },
                    .symbol => .{ .symbol_list = list },
                    else => .{ .list = list },
                });
            },
            else => runtimeError(ApplyError.incompatible_types),
        },
        .boolean_list => |bool_list_x| switch (y.as) {
            .boolean => |bool_y| vm.initValue(.{ .boolean = if (bool_list_x.len <= @boolToInt(bool_y)) false else bool_list_x[@boolToInt(bool_y)].as.boolean }),
            .int => |int_y| vm.initValue(.{ .boolean = if (int_y < 0 or bool_list_x.len <= int_y) false else bool_list_x[@intCast(usize, int_y)].as.boolean }),
            .list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = if (list_y.len == 0) .list else null;
                for (list_y) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try index(vm, x, value);
                    if (list_type == null and @as(ValueType, list[0].as) != list[i].as) list_type = .list;
                }
                break :blk vm.initValue(switch (if (list_type) |list_value_type| list_value_type else @as(ValueType, list[0].as)) {
                    .boolean => .{ .boolean_list = list },
                    else => .{ .list = list },
                });
            },
            .boolean_list => |bool_list_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .boolean = if (bool_list_x.len <= @boolToInt(value.as.boolean)) false else bool_list_x[@boolToInt(value.as.boolean)].as.boolean });
                }
                break :blk vm.initValue(.{ .boolean_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .boolean = if (value.as.int < 0 or bool_list_x.len <= value.as.int) false else bool_list_x[@intCast(usize, value.as.int)].as.boolean });
                }
                break :blk vm.initValue(.{ .boolean_list = list });
            },
            else => runtimeError(ApplyError.incompatible_types),
        },
        .int_list => |int_list_x| switch (y.as) {
            .boolean => |bool_y| vm.initValue(.{ .int = if (int_list_x.len <= @boolToInt(bool_y)) Value.null_int else int_list_x[@boolToInt(bool_y)].as.int }),
            .int => |int_y| vm.initValue(.{ .int = if (int_y < 0 or int_list_x.len <= int_y) Value.null_int else int_list_x[@intCast(usize, int_y)].as.int }),
            .list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = if (list_y.len == 0) .list else null;
                for (list_y) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try index(vm, x, value);
                    if (list_type == null and @as(ValueType, list[0].as) != list[i].as) list_type = .list;
                }
                break :blk vm.initValue(switch (if (list_type) |list_value_type| list_value_type else @as(ValueType, list[0].as)) {
                    .int => .{ .int_list = list },
                    else => .{ .list = list },
                });
            },
            .boolean_list => |bool_list_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .int = if (int_list_x.len <= @boolToInt(value.as.boolean)) Value.null_int else int_list_x[@boolToInt(value.as.boolean)].as.int });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .int = if (value.as.int < 0 or int_list_x.len <= value.as.int) Value.null_int else int_list_x[@intCast(usize, value.as.int)].as.int });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            else => runtimeError(ApplyError.incompatible_types),
        },
        .float_list => |float_list_x| switch (y.as) {
            .boolean => |bool_y| vm.initValue(.{ .float = if (float_list_x.len <= @boolToInt(bool_y)) Value.null_float else float_list_x[@boolToInt(bool_y)].as.float }),
            .int => |int_y| vm.initValue(.{ .float = if (int_y < 0 or float_list_x.len <= int_y) Value.null_float else float_list_x[@intCast(usize, int_y)].as.float }),
            .list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = if (list_y.len == 0) .list else null;
                for (list_y) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try index(vm, x, value);
                    if (list_type == null and @as(ValueType, list[0].as) != list[i].as) list_type = .list;
                }
                break :blk vm.initValue(switch (if (list_type) |list_value_type| list_value_type else @as(ValueType, list[0].as)) {
                    .float => .{ .float_list = list },
                    else => .{ .list = list },
                });
            },
            .boolean_list => |bool_list_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .float = if (float_list_x.len <= @boolToInt(value.as.boolean)) Value.null_float else float_list_x[@boolToInt(value.as.boolean)].as.float });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .float = if (value.as.int < 0 or float_list_x.len <= value.as.int) Value.null_int else float_list_x[@intCast(usize, value.as.int)].as.float });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            else => runtimeError(ApplyError.incompatible_types),
        },
        .char_list => |char_list_x| switch (y.as) {
            .boolean => |bool_y| vm.initValue(.{ .char = if (char_list_x.len <= @boolToInt(bool_y)) ' ' else char_list_x[@boolToInt(bool_y)].as.char }),
            .int => |int_y| vm.initValue(.{ .char = if (int_y < 0 or char_list_x.len <= int_y) ' ' else char_list_x[@intCast(usize, int_y)].as.char }),
            .list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = if (list_y.len == 0) .list else null;
                for (list_y) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try index(vm, x, value);
                    if (list_type == null and @as(ValueType, list[0].as) != list[i].as) list_type = .list;
                }
                break :blk vm.initValue(switch (if (list_type) |list_value_type| list_value_type else @as(ValueType, list[0].as)) {
                    .char => .{ .char_list = list },
                    else => .{ .list = list },
                });
            },
            .boolean_list => |bool_list_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .char = if (char_list_x.len <= @boolToInt(value.as.boolean)) ' ' else char_list_x[@boolToInt(value.as.boolean)].as.char });
                }
                break :blk vm.initValue(.{ .char_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .char = if (value.as.int < 0 or char_list_x.len <= value.as.int) ' ' else char_list_x[@intCast(usize, value.as.int)].as.char });
                }
                break :blk vm.initValue(.{ .char_list = list });
            },
            else => runtimeError(ApplyError.incompatible_types),
        },
        .symbol_list => |symbol_list_x| switch (y.as) {
            .boolean => |bool_y| vm.copySymbol(if (symbol_list_x.len <= @boolToInt(bool_y)) "" else symbol_list_x[@boolToInt(bool_y)].as.symbol),
            .int => |int_y| vm.copySymbol(if (int_y < 0 or symbol_list_x.len <= int_y) "" else symbol_list_x[@intCast(usize, int_y)].as.symbol),
            .list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = if (list_y.len == 0) .list else null;
                for (list_y) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try index(vm, x, value);
                    if (list_type == null and @as(ValueType, list[0].as) != list[i].as) list_type = .list;
                }
                break :blk vm.initValue(switch (if (list_type) |list_value_type| list_value_type else @as(ValueType, list[0].as)) {
                    .symbol => .{ .symbol_list = list },
                    else => .{ .list = list },
                });
            },
            .boolean_list => |bool_list_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_y) |value, i| {
                    list[i] = vm.copySymbol(if (symbol_list_x.len <= @boolToInt(value.as.boolean)) "" else symbol_list_x[@boolToInt(value.as.boolean)].as.symbol);
                }
                break :blk vm.initValue(.{ .symbol_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_y) |value, i| {
                    list[i] = vm.copySymbol(if (value.as.int < 0 or symbol_list_x.len <= value.as.int) "" else symbol_list_x[@intCast(usize, value.as.int)].as.symbol);
                }
                break :blk vm.initValue(.{ .char_list = list });
            },
            else => runtimeError(ApplyError.incompatible_types),
        },
        .dictionary => |dict_x| switch (y.as) {
            .boolean, .int, .float, .char, .symbol => switch (dict_x.key.as) {
                .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |keys| switch (dict_x.value.as) {
                    .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |values| blk: {
                        for (keys) |value, i| {
                            if (value.eql(y)) break :blk values[i].ref();
                        }
                        break :blk vm.initNull(switch (dict_x.value.as) {
                            .boolean_list => .boolean,
                            .int_list => .int,
                            .float_list => .float,
                            .char_list => .char,
                            .symbol_list => .symbol,
                            else => dict_x.value.as,
                        });
                    },
                    else => unreachable,
                },
                else => unreachable,
            },
            .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list_y| switch (dict_x.key.as) {
                .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |keys| switch (dict_x.value.as) {
                    .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |values| blk: {
                        const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                        if (values.len > 0) {
                            for (list_y) |lookup, i| outer_loop: {
                                for (keys) |value, j| {
                                    if (value.eql(lookup)) {
                                        list[i] = values[j].ref();
                                        break :outer_loop;
                                    }
                                }
                                list[i] = if (values.len > 0) values[0].copyNull(vm) else vm.initNull(switch (dict_x.value.as) {
                                    .boolean_list => .boolean,
                                    .int_list => .int,
                                    .float_list => .float,
                                    .char_list => .char,
                                    .symbol_list => .symbol,
                                    else => dict_x.value.as,
                                });
                            }
                        } else {
                            const value_type: ValueType = switch (dict_x.value.as) {
                                .boolean_list => .boolean,
                                .int_list => .int,
                                .float_list => .float,
                                .char_list => .char,
                                .symbol_list => .symbol,
                                else => dict_x.value.as,
                            };
                            for (list) |*value| {
                                value.* = vm.initNull(value_type);
                            }
                        }

                        break :blk vm.initValue(switch (dict_x.value.as) {
                            .list => .{ .list = list },
                            .boolean_list => .{ .boolean_list = list },
                            .int_list => .{ .int_list = list },
                            .float_list => .{ .float_list = list },
                            .char_list => .{ .char_list = list },
                            .symbol_list => .{ .symbol_list = list },
                            else => unreachable,
                        });
                    },
                    else => unreachable,
                },
                else => unreachable,
            },
            else => runtimeError(ApplyError.incompatible_types),
        },
        .function => unreachable,
        .projection => unreachable,
        else => runtimeError(ApplyError.incompatible_types),
    };
}
