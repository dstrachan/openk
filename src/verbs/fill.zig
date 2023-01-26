const std = @import("std");

const utils_mod = @import("../utils.zig");
const print = utils_mod.print;

const value_mod = @import("../value.zig");
const Value = value_mod.Value;
const ValueType = value_mod.ValueType;

const vm_mod = @import("../vm.zig");
const VM = vm_mod.VM;

pub const FillError = error{
    incompatible_types,
    length_mismatch,
};

fn runtimeError(comptime err: FillError) FillError!*Value {
    switch (err) {
        FillError.incompatible_types => print("Incompatible types.\n", .{}),
        FillError.length_mismatch => print("List lengths must match.\n", .{}),
    }
    return err;
}

pub fn fill(vm: *VM, x: *Value, y: *Value) FillError!*Value {
    return switch (x.as) {
        .boolean => |bool_x| switch (y.as) {
            .boolean => |bool_y| vm.initValue(.{ .boolean = bool_y }),
            .int => |int_y| vm.initValue(.{ .int = if (int_y == Value.null_int) if (bool_x) 1 else 0 else int_y }),
            .float => |float_y| vm.initValue(.{ .float = if (std.math.isNan(float_y)) if (bool_x) 1 else 0 else float_y }),
            .char => |char_y| vm.initValue(.{ .char = if (char_y == ' ') if (bool_x) 1 else 0 else char_y }),
            .list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                for (list_y) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try fill(vm, x, value);
                }
                break :blk vm.initValue(.{ .list = list });
            },
            .boolean_list => |bool_list_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .boolean = value.as.boolean });
                }
                break :blk vm.initValue(.{ .boolean_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .int = if (value.as.int == Value.null_int) if (bool_x) 1 else 0 else value.as.int });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .float_list => |float_list_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .float = if (std.math.isNan(value.as.float)) if (bool_x) 1 else 0 else value.as.float });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .char_list => |char_list_y| blk: {
                const list = vm.allocator.alloc(*Value, char_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (char_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .char = if (value.as.char == ' ') if (bool_x) 1 else 0 else value.as.char });
                }
                break :blk vm.initValue(.{ .char_list = list });
            },
            else => return runtimeError(FillError.incompatible_types),
        },
        .int => |int_x| switch (y.as) {
            .boolean => |bool_y| vm.initValue(.{ .int = if (bool_y) 1 else 0 }),
            .int => |int_y| vm.initValue(.{ .int = if (int_y == Value.null_int) int_x else int_y }),
            .float => |float_y| vm.initValue(.{ .float = if (std.math.isNan(float_y)) utils_mod.intToFloat(int_x) else float_y }),
            .char => |char_y| vm.initValue(.{ .char = if (char_y == ' ') @intCast(u8, @mod(int_x, 256)) else char_y }),
            .list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = null;
                for (list_y) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try fill(vm, x, value);
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
                    list[i] = vm.initValue(.{ .int = if (value.as.boolean) 1 else 0 });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .int = if (value.as.int == Value.null_int) int_x else value.as.int });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .float_list => |float_list_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .float = if (std.math.isNan(value.as.float)) utils_mod.intToFloat(int_x) else value.as.float });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .char_list => |char_list_y| blk: {
                const list = vm.allocator.alloc(*Value, char_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (char_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .char = if (value.as.char == ' ') @intCast(u8, @mod(int_x, 256)) else value.as.char });
                }
                break :blk vm.initValue(.{ .char_list = list });
            },
            else => return runtimeError(FillError.incompatible_types),
        },
        .float => |float_x| switch (y.as) {
            .boolean => |bool_y| vm.initValue(.{ .float = if (bool_y) 1 else 0 }),
            .int => |int_y| vm.initValue(.{ .float = if (int_y == Value.null_int) float_x else utils_mod.intToFloat(int_y) }),
            .float => |float_y| vm.initValue(.{ .float = if (std.math.isNan(float_y)) float_x else float_y }),
            .char => |char_y| vm.initValue(.{ .char = if (char_y == ' ') @floatToInt(u8, @mod(@round(float_x), 256)) else char_y }),
            .list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = null;
                for (list_y) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try fill(vm, x, value);
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
                    list[i] = vm.initValue(.{ .float = if (value.as.boolean) 1 else 0 });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .float = if (value.as.int == Value.null_int) float_x else utils_mod.intToFloat(value.as.int) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .float_list => |float_list_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .float = if (std.math.isNan(value.as.float)) float_x else value.as.float });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .char_list => |char_list_y| blk: {
                const list = vm.allocator.alloc(*Value, char_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (char_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .char = if (value.as.char == ' ') @floatToInt(u8, @mod(@round(float_x), 256)) else value.as.char });
                }
                break :blk vm.initValue(.{ .char_list = list });
            },
            else => return runtimeError(FillError.incompatible_types),
        },
        .char => |char_x| switch (y.as) {
            .boolean => |bool_y| vm.initValue(.{ .char = if (bool_y) 1 else 0 }),
            .int => |int_y| vm.initValue(.{ .char = if (int_y == Value.null_int) 0 else @intCast(u8, @mod(int_y, 256)) }),
            .float => |float_y| vm.initValue(.{ .char = if (std.math.isNan(float_y)) 0 else @floatToInt(u8, @mod(@round(float_y), 256)) }),
            .char => |char_y| vm.initValue(.{ .char = if (char_y == ' ') char_x else char_y }),
            .list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                for (list_y) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try fill(vm, x, value);
                }
                break :blk vm.initValue(.{ .list = list });
            },
            .boolean_list => |bool_list_y| blk: {
                const list = vm.allocator.alloc(*Value, bool_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .char = if (value.as.boolean) 1 else 0 });
                }
                break :blk vm.initValue(.{ .char_list = list });
            },
            .int_list => |int_list_y| blk: {
                const list = vm.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .char = if (value.as.int == Value.null_int) 0 else @intCast(u8, @mod(value.as.int, 256)) });
                }
                break :blk vm.initValue(.{ .char_list = list });
            },
            .float_list => |float_list_y| blk: {
                const list = vm.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .char = if (std.math.isNan(value.as.float)) 0 else @floatToInt(u8, @mod(@round(value.as.float), 256)) });
                }
                break :blk vm.initValue(.{ .char_list = list });
            },
            .char_list => |char_list_y| blk: {
                const list = vm.allocator.alloc(*Value, char_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (char_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .char = if (value.as.char == ' ') char_x else value.as.char });
                }
                break :blk vm.initValue(.{ .char_list = list });
            },
            else => return runtimeError(FillError.incompatible_types),
        },
        .symbol => |symbol_x| switch (y.as) {
            .symbol => |symbol_y| if (symbol_y.len == 0) vm.copySymbol(symbol_x) else vm.copySymbol(symbol_y),
            .list => |list_y| blk: {
                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                for (list_y) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try fill(vm, x, value);
                }
                break :blk vm.initValue(.{ .list = list });
            },
            .symbol_list => |symbol_list_y| blk: {
                const list = vm.allocator.alloc(*Value, symbol_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (symbol_list_y) |value, i| {
                    list[i] = if (value.as.symbol.len == 0) vm.copySymbol(symbol_x) else vm.copySymbol(value.as.symbol);
                }
                break :blk vm.initValue(.{ .symbol_list = list });
            },
            else => return runtimeError(FillError.incompatible_types),
        },
        .list => |list_x| switch (y.as) {
            .list => |list_y| blk: {
                if (list_x.len != list_y.len) return runtimeError(FillError.length_mismatch);

                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = if (list_y.len == 0) .list else null;
                for (list_y) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try fill(vm, list_x[i], value);
                    if (list_type == null and @as(ValueType, list[0].as) != list[i].as) list_type = .list;
                }
                break :blk vm.initValue(switch (if (list_type) |list_value_type| list_value_type else @as(ValueType, list[0].as)) {
                    .float => .{ .float_list = list },
                    else => .{ .list = list },
                });
            },
            .boolean_list => |bool_list_y| blk: {
                if (list_x.len != bool_list_y.len) return runtimeError(FillError.length_mismatch);

                const list = vm.allocator.alloc(*Value, bool_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                for (bool_list_y) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try fill(vm, list_x[i], value);
                }
                break :blk vm.initValue(.{ .list = list });
            },
            .int_list => |int_list_y| blk: {
                if (list_x.len != int_list_y.len) return runtimeError(FillError.length_mismatch);

                const list = vm.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = null;
                for (int_list_y) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try fill(vm, list_x[i], value);
                    if (list_type == null and @as(ValueType, list[0].as) != list[i].as) list_type = .list;
                }
                break :blk vm.initValue(switch (if (list_type) |list_value_type| list_value_type else @as(ValueType, list[0].as)) {
                    .int => .{ .int_list = list },
                    else => .{ .list = list },
                });
            },
            .float_list => |float_list_y| blk: {
                if (list_x.len != float_list_y.len) return runtimeError(FillError.length_mismatch);

                const list = vm.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = null;
                for (float_list_y) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try fill(vm, list_x[i], value);
                    if (list_type == null and @as(ValueType, list[0].as) != list[i].as) list_type = .list;
                }
                break :blk vm.initValue(switch (if (list_type) |list_value_type| list_value_type else @as(ValueType, list[0].as)) {
                    .float => .{ .float_list = list },
                    else => .{ .list = list },
                });
            },
            .char_list => |char_list_y| blk: {
                if (list_x.len != char_list_y.len) return runtimeError(FillError.length_mismatch);

                const list = vm.allocator.alloc(*Value, char_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                for (char_list_y) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try fill(vm, list_x[i], value);
                }
                break :blk vm.initValue(.{ .char_list = list });
            },
            else => return runtimeError(FillError.incompatible_types),
        },
        .boolean_list => |bool_list_x| switch (y.as) {
            .list => |list_y| blk: {
                if (bool_list_x.len != list_y.len) return runtimeError(FillError.length_mismatch);

                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                for (list_y) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try fill(vm, bool_list_x[i], value);
                }
                break :blk vm.initValue(.{ .list = list });
            },
            .boolean_list => |bool_list_y| blk: {
                if (bool_list_x.len != bool_list_y.len) return runtimeError(FillError.length_mismatch);

                const list = vm.allocator.alloc(*Value, bool_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .boolean = value.as.boolean });
                }
                break :blk vm.initValue(.{ .boolean_list = list });
            },
            .int_list => |int_list_y| blk: {
                if (bool_list_x.len != int_list_y.len) return runtimeError(FillError.length_mismatch);

                const list = vm.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .int = if (value.as.int == Value.null_int) if (bool_list_x[i].as.boolean) 1 else 0 else value.as.int });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .float_list => |float_list_y| blk: {
                if (bool_list_x.len != float_list_y.len) return runtimeError(FillError.length_mismatch);

                const list = vm.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .float = if (std.math.isNan(value.as.float)) if (bool_list_x[i].as.boolean) 1 else 0 else value.as.float });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .char_list => |char_list_y| blk: {
                if (bool_list_x.len != char_list_y.len) return runtimeError(FillError.length_mismatch);

                const list = vm.allocator.alloc(*Value, char_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (char_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .char = if (value.as.char == ' ') if (bool_list_x[i].as.boolean) 1 else 0 else value.as.char });
                }
                break :blk vm.initValue(.{ .char_list = list });
            },
            else => return runtimeError(FillError.incompatible_types),
        },
        .int_list => |int_list_x| switch (y.as) {
            .list => |int_list_y| blk: {
                if (int_list_x.len != int_list_y.len) return runtimeError(FillError.length_mismatch);

                const list = vm.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                var list_type: ?ValueType = null;
                for (int_list_y) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try fill(vm, int_list_x[i], value);
                    if (list_type == null and @as(ValueType, list[0].as) != list[i].as) list_type = .list;
                }
                break :blk vm.initValue(switch (if (list_type) |list_value_type| list_value_type else @as(ValueType, list[0].as)) {
                    .int => .{ .int_list = list },
                    else => .{ .list = list },
                });
            },
            .boolean_list => |bool_list_y| blk: {
                if (int_list_x.len != bool_list_y.len) return runtimeError(FillError.length_mismatch);

                const list = vm.allocator.alloc(*Value, bool_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .int = if (value.as.boolean) 1 else 0 });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .int_list => |int_list_y| blk: {
                if (int_list_x.len != int_list_y.len) return runtimeError(FillError.length_mismatch);

                const list = vm.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .int = if (value.as.int == Value.null_int) int_list_x[i].as.int else value.as.int });
                }
                break :blk vm.initValue(.{ .int_list = list });
            },
            .float_list => |float_list_y| blk: {
                if (int_list_x.len != float_list_y.len) return runtimeError(FillError.length_mismatch);

                const list = vm.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .float = if (std.math.isNan(value.as.float)) utils_mod.intToFloat(int_list_x[i].as.int) else value.as.float });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .char_list => |char_list_y| blk: {
                if (int_list_x.len != char_list_y.len) return runtimeError(FillError.length_mismatch);

                const list = vm.allocator.alloc(*Value, char_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (char_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .char = if (value.as.char == ' ') @intCast(u8, @mod(int_list_x[i].as.int, 256)) else value.as.char });
                }
                break :blk vm.initValue(.{ .char_list = list });
            },
            else => return runtimeError(FillError.incompatible_types),
        },
        .float_list => |float_list_x| switch (y.as) {
            .list => |list_y| blk: {
                if (float_list_x.len != list_y.len) return runtimeError(FillError.length_mismatch);

                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                for (list_y) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try fill(vm, float_list_x[i], value);
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .boolean_list => |bool_list_y| blk: {
                if (float_list_x.len != bool_list_y.len) return runtimeError(FillError.length_mismatch);

                const list = vm.allocator.alloc(*Value, bool_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .float = if (value.as.boolean) 1 else 0 });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .int_list => |int_list_y| blk: {
                if (float_list_x.len != int_list_y.len) return runtimeError(FillError.length_mismatch);

                const list = vm.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .float = if (value.as.int == Value.null_int) float_list_x[i].as.float else utils_mod.intToFloat(value.as.int) });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .float_list => |float_list_y| blk: {
                if (float_list_x.len != float_list_y.len) return runtimeError(FillError.length_mismatch);

                const list = vm.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .float = if (std.math.isNan(value.as.float)) float_list_x[i].as.float else value.as.float });
                }
                break :blk vm.initValue(.{ .float_list = list });
            },
            .char_list => |char_list_y| blk: {
                if (float_list_x.len != char_list_y.len) return runtimeError(FillError.length_mismatch);

                const list = vm.allocator.alloc(*Value, char_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (char_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .char = if (value.as.char == ' ') @floatToInt(u8, @mod(@round(float_list_x[i].as.float), 256)) else value.as.char });
                }
                break :blk vm.initValue(.{ .char_list = list });
            },
            else => return runtimeError(FillError.incompatible_types),
        },
        .char_list => |char_list_x| switch (y.as) {
            .list => |list_y| blk: {
                if (char_list_x.len != list_y.len) return runtimeError(FillError.length_mismatch);

                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                for (list_y) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try fill(vm, char_list_x[i], value);
                }
                break :blk vm.initValue(.{ .list = list });
            },
            .boolean_list => |bool_list_y| blk: {
                if (char_list_x.len != bool_list_y.len) return runtimeError(FillError.length_mismatch);

                const list = vm.allocator.alloc(*Value, bool_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (bool_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .char = if (value.as.boolean) 1 else 0 });
                }
                break :blk vm.initValue(.{ .char_list = list });
            },
            .int_list => |int_list_y| blk: {
                if (char_list_x.len != int_list_y.len) return runtimeError(FillError.length_mismatch);

                const list = vm.allocator.alloc(*Value, int_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (int_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .char = if (value.as.int == Value.null_int) 0 else @intCast(u8, @mod(value.as.int, 256)) });
                }
                break :blk vm.initValue(.{ .char_list = list });
            },
            .float_list => |float_list_y| blk: {
                if (char_list_x.len != float_list_y.len) return runtimeError(FillError.length_mismatch);

                const list = vm.allocator.alloc(*Value, float_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (float_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .char = if (std.math.isNan(value.as.float)) 0 else @floatToInt(u8, @mod(@round(value.as.float), 256)) });
                }
                break :blk vm.initValue(.{ .char_list = list });
            },
            .char_list => |char_list_y| blk: {
                if (char_list_x.len != char_list_y.len) return runtimeError(FillError.length_mismatch);

                const list = vm.allocator.alloc(*Value, char_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (char_list_y) |value, i| {
                    list[i] = vm.initValue(.{ .char = if (value.as.char == ' ') char_list_x[i].as.char else value.as.char });
                }
                break :blk vm.initValue(.{ .char_list = list });
            },
            else => return runtimeError(FillError.incompatible_types),
        },
        .symbol_list => |symbol_list_x| switch (y.as) {
            .list => |list_y| blk: {
                if (symbol_list_x.len != list_y.len) return runtimeError(FillError.length_mismatch);

                const list = vm.allocator.alloc(*Value, list_y.len) catch std.debug.panic("Failed to create list.", .{});
                errdefer vm.allocator.free(list);
                for (list_y) |value, i| {
                    errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                    list[i] = try fill(vm, symbol_list_x[i], value);
                }
                break :blk vm.initValue(.{ .list = list });
            },
            .symbol_list => |symbol_list_y| blk: {
                if (symbol_list_x.len != symbol_list_y.len) return runtimeError(FillError.length_mismatch);

                const list = vm.allocator.alloc(*Value, symbol_list_y.len) catch std.debug.panic("Failed to create list.", .{});
                for (symbol_list_y) |value, i| {
                    list[i] = if (value.as.symbol.len == 0) vm.copySymbol(symbol_list_x[i].as.symbol) else vm.copySymbol(value.as.symbol);
                }
                break :blk vm.initValue(.{ .symbol_list = list });
            },
            else => return runtimeError(FillError.incompatible_types),
        },
        else => return runtimeError(FillError.incompatible_types),
    };
}
