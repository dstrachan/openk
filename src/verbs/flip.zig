const std = @import("std");

const utils_mod = @import("../utils.zig");
const print = utils_mod.print;

const value_mod = @import("../value.zig");
const Value = value_mod.Value;
const ValueType = value_mod.ValueType;

const vm_mod = @import("../vm.zig");
const VM = vm_mod.VM;

pub const FlipError = error{
    length_mismatch,
    invalid_type,
};

fn runtimeError(comptime err: FlipError) FlipError!*Value {
    switch (err) {
        FlipError.length_mismatch => print("Can only flip list values of equal length.\n", .{}),
        FlipError.invalid_type => print("Can only flip nested lists.", .{}),
    }
    return err;
}

pub fn flip(vm: *VM, x: *Value) FlipError!*Value {
    return switch (x.as) {
        .list => |list_x| blk: {
            var len: ?usize = null;
            for (list_x) |value| {
                switch (value.as) {
                    .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list| {
                        if (len == null) {
                            len = list.len;
                        } else if (list.len != len.?) {
                            return runtimeError(FlipError.length_mismatch);
                        }
                    },
                    else => continue,
                }
            }
            if (len == null) return runtimeError(FlipError.invalid_type);

            const list = vm.allocator.alloc(*Value, len.?) catch std.debug.panic("Failed to create list.", .{});
            var i: usize = 0;
            while (i < len.?) : (i += 1) {
                var list_type: ?ValueType = if (len.? == 0) .list else null;
                const inner_list = vm.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
                for (list_x) |value, j| {
                    inner_list[j] = switch (value.as) {
                        .nil, .boolean, .int, .float, .char, .symbol, .function, .projection => value.ref(),
                        .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list_value| list_value[i].ref(),
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
        else => return runtimeError(FlipError.invalid_type),
    };
}
