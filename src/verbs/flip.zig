const std = @import("std");

const utils_mod = @import("../utils.zig");
const print = utils_mod.print;

const value_mod = @import("../value.zig");
const Value = value_mod.Value;
const ValueTable = value_mod.ValueTable;
const ValueType = value_mod.ValueType;

const vm_mod = @import("../vm.zig");
const VM = vm_mod.VM;

pub const FlipError = error{
    length_mismatch,
    invalid_type,
    invalid_column_type,
    invalid_value_type,
};

fn runtimeError(comptime T: type, comptime err: FlipError) FlipError!T {
    switch (err) {
        FlipError.length_mismatch => print("Can only flip list values of equal length.\n", .{}),
        FlipError.invalid_type => print("Can only flip nested lists.\n", .{}),
        FlipError.invalid_column_type => print("Can only flip dictionary with symbol keys.\n", .{}),
        FlipError.invalid_value_type => print("Can only flip dictionary with list values.\n", .{}),
    }
    return err;
}

pub fn flip(vm: *VM, x: *Value) FlipError!*Value {
    return switch (x.as) {
        .list => |list_x| blk: {
            const len = try validateListLen(list_x);
            const list = vm.allocator.alloc(*Value, len) catch std.debug.panic("Failed to create list.", .{});
            var i: usize = 0;
            while (i < len) : (i += 1) {
                var list_type: ?ValueType = if (len == 0) .list else null;
                const inner_list = vm.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (list_x) |value, j| {
                    inner_list[j] = switch (value.as) {
                        .nil, .boolean, .int, .float, .char, .symbol, .function, .projection => value.ref(),
                        .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list_value| list_value[i].ref(),
                        .dictionary => unreachable,
                        .table => unreachable,
                    };
                    if (list_type == null and @as(ValueType, inner_list[0].as) != @as(ValueType, inner_list[j].as)) list_type = .list;
                }
                list[i] = vm.initValue(switch (if (list_type) |list_type_value| list_type_value else @as(ValueType, inner_list[0].as)) {
                    .boolean => .{ .boolean_list = inner_list },
                    .int => .{ .int_list = inner_list },
                    .float => .{ .float_list = inner_list },
                    .char => .{ .char_list = inner_list },
                    .symbol => .{ .symbol_list = inner_list },
                    else => .{ .list = inner_list },
                });
            }
            break :blk vm.initValue(.{ .list = list });
        },
        .dictionary => |dict_x| blk: {
            if (dict_x.key.as != .symbol_list) return runtimeError(*Value, FlipError.invalid_column_type);
            if (dict_x.value.as != .list) return runtimeError(*Value, FlipError.invalid_value_type);

            const column_count = dict_x.key.as.symbol_list.len;
            const table_len = try validateListLen(dict_x.value.as.list);

            const value_list = vm.allocator.alloc(*Value, column_count) catch std.debug.panic("Failed to create list.", .{});

            var i: usize = 0;
            while (i < column_count) : (i += 1) {
                value_list[i] = switch (dict_x.value.as.list[i].as) {
                    .boolean => inner_blk: {
                        const inner_list = vm.allocator.alloc(*Value, table_len) catch std.debug.panic("Failed to create list.", .{});
                        for (inner_list) |*inner_list_value| {
                            inner_list_value.* = dict_x.value.as.list[i].ref();
                        }
                        break :inner_blk vm.initValue(.{ .boolean_list = inner_list });
                    },
                    .int => inner_blk: {
                        const inner_list = vm.allocator.alloc(*Value, table_len) catch std.debug.panic("Failed to create list.", .{});
                        for (inner_list) |*inner_list_value| {
                            inner_list_value.* = dict_x.value.as.list[i].ref();
                        }
                        break :inner_blk vm.initValue(.{ .int_list = inner_list });
                    },
                    .float => inner_blk: {
                        const inner_list = vm.allocator.alloc(*Value, table_len) catch std.debug.panic("Failed to create list.", .{});
                        for (inner_list) |*inner_list_value| {
                            inner_list_value.* = dict_x.value.as.list[i].ref();
                        }
                        break :inner_blk vm.initValue(.{ .float_list = inner_list });
                    },
                    .char => inner_blk: {
                        const inner_list = vm.allocator.alloc(*Value, table_len) catch std.debug.panic("Failed to create list.", .{});
                        for (inner_list) |*inner_list_value| {
                            inner_list_value.* = dict_x.value.as.list[i].ref();
                        }
                        break :inner_blk vm.initValue(.{ .char_list = inner_list });
                    },
                    .symbol => inner_blk: {
                        const inner_list = vm.allocator.alloc(*Value, table_len) catch std.debug.panic("Failed to create list.", .{});
                        for (inner_list) |*inner_list_value| {
                            inner_list_value.* = dict_x.value.as.list[i].ref();
                        }
                        break :inner_blk vm.initValue(.{ .symbol_list = inner_list });
                    },
                    .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => dict_x.value.as.list[i].ref(),
                    else => unreachable,
                };
            }

            const values = vm.initValue(.{ .list = value_list });
            const table = ValueTable.init(.{ .columns = dict_x.key.ref(), .values = values }, vm.allocator);

            break :blk vm.initValue(.{ .table = table });
        },
        else => return runtimeError(*Value, FlipError.invalid_type),
    };
}

fn validateListLen(values: []*Value) FlipError!usize {
    var len: ?usize = null;
    for (values) |value| switch (value.as) {
        .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list| {
            if (len == null) {
                len = list.len;
            } else if (list.len != len.?) {
                return runtimeError(usize, FlipError.length_mismatch);
            }
        },
        else => continue,
    };
    if (len == null) return runtimeError(usize, FlipError.invalid_type);
    return len.?;
}
