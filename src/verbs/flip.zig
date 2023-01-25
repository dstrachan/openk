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
        FlipError.length_mismatch => print("Can only flip values of equal length.\n", .{}),
        FlipError.invalid_type => print("Can only flip list values.", .{}),
    }
    return err;
}

pub fn flip(vm: *VM, x: *Value) FlipError!*Value {
    return switch (x.as) {
        .list => |list_x| blk: {
            var has_list = false;
            var list_len: usize = 0;
            for (list_x) |value| {
                switch (value.as) {
                    .list,
                    .boolean_list,
                    .int_list,
                    .float_list,
                    .char_list,
                    .symbol_list,
                    => |inner_list| {
                        if (has_list) {
                            if (list_len != inner_list.len) return runtimeError(FlipError.length_mismatch);
                        } else {
                            has_list = true;
                            list_len = inner_list.len;
                        }
                    },
                    else => {},
                }
            }
            if (!has_list) return runtimeError(FlipError.invalid_type);
            const value = vm.allocator.alloc(*Value, list_len) catch std.debug.panic("Failed to create list.", .{});
            var i: usize = 0;
            while (i < list_len) : (i += 1) {
                const inner_list = vm.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
                var list_type: ValueType = switch (list_x[0].as) {
                    .boolean_list => .boolean,
                    .int_list => .int,
                    .float_list => .float,
                    .char_list => .char,
                    .symbol_list => .symbol,
                    else => .list,
                };
                for (list_x) |list_value, j| {
                    inner_list[j] = switch (list_value.as) {
                        .nil,
                        .boolean,
                        .int,
                        .float,
                        .char,
                        .symbol,
                        .function,
                        .projection,
                        => list_value.ref(),
                        .list,
                        .boolean_list,
                        .int_list,
                        .float_list,
                        .char_list,
                        .symbol_list,
                        => |inner_list_value| inner_list_value[i].ref(),
                    };
                    if (list_type != .list and list_type != inner_list[j].as) {
                        list_type = .list;
                    }
                }
                value[i] = switch (list_type) {
                    .boolean => vm.initValue(.{ .boolean_list = inner_list }),
                    .int => vm.initValue(.{ .int_list = inner_list }),
                    .float => vm.initValue(.{ .float_list = inner_list }),
                    .char => vm.initValue(.{ .char_list = inner_list }),
                    .symbol => vm.initValue(.{ .symbol_list = inner_list }),
                    else => vm.initValue(.{ .list = inner_list }),
                };
            }
            break :blk vm.initValue(.{ .list = value });
        },
        else => return runtimeError(FlipError.invalid_type),
    };
}
