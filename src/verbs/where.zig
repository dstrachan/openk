const std = @import("std");

const utils_mod = @import("../utils.zig");
const print = utils_mod.print;

const value_mod = @import("../value.zig");
const Value = value_mod.Value;
const ValueType = value_mod.ValueType;

const vm_mod = @import("../vm.zig");
const VM = vm_mod.VM;

const index = @import("index.zig").index;

pub const WhereError = error{
    invalid_type,
    negative_number,
    list_limit,
};

fn runtimeError(comptime err: WhereError) WhereError!*Value {
    switch (err) {
        WhereError.invalid_type => print("Invalid type.\n", .{}),
        WhereError.negative_number => print("Cannot generate list from negative input.\n", .{}),
        WhereError.list_limit => print("Cannot generate a list longer than 10,085,382,816 elements.\n", .{}),
    }
    return err;
}

pub fn where(vm: *VM, x: *Value) WhereError!*Value {
    return switch (x.as) {
        .list => |list_x| if (list_x.len == 0) vm.initValue(.{ .int_list = &[_]*Value{} }) else runtimeError(WhereError.invalid_type),
        .boolean_list => |bool_list_x| blk: {
            var list = std.ArrayList(*Value).init(vm.allocator);
            for (bool_list_x, 0..) |value, i| {
                if (value.as.boolean) list.append(vm.initValue(.{ .int = @intCast(i64, i) })) catch std.debug.panic("Failed to append item.", .{});
            }
            break :blk vm.initValue(.{ .int_list = list.toOwnedSlice() catch std.debug.panic("Failed to create list.", .{}) });
        },
        .int_list => |int_list_x| blk: {
            var len: i64 = 0;
            for (int_list_x) |value| {
                if (value.as.int < 0) return runtimeError(WhereError.negative_number);
                len = std.math.add(i64, len, value.as.int) catch return runtimeError(WhereError.list_limit);
            }

            const list = vm.allocator.alloc(*Value, @intCast(usize, len)) catch return runtimeError(WhereError.list_limit);
            var i: usize = 0;
            for (int_list_x, 0..) |value, j| {
                if (value.as.int > 0) {
                    const v = vm.initValueWithRefCount(0, .{ .int = @intCast(i64, j) });
                    for (i..i + @intCast(usize, value.as.int)) |idx| list[idx] = v.ref();
                    i += @intCast(usize, value.as.int);
                }
            }

            break :blk vm.initValue(.{ .int_list = list });
        },
        .dictionary => |dict_x| blk: {
            const indices = try where(vm, dict_x.values);
            defer indices.deref(vm.allocator);
            break :blk index(vm, dict_x.keys, indices) catch runtimeError(WhereError.invalid_type);
        },
        else => runtimeError(WhereError.invalid_type),
    };
}
