const std = @import("std");

const utils_mod = @import("../utils.zig");
const print = utils_mod.print;

const value_mod = @import("../value.zig");
const Value = value_mod.Value;
const ValueType = value_mod.ValueType;

const vm_mod = @import("../vm.zig");
const VM = vm_mod.VM;

pub const WhereError = error{
    invalid_type,
    negative_number,
};

fn runtimeError(comptime err: WhereError) WhereError!*Value {
    switch (err) {
        WhereError.invalid_type => print("Invalid type.\n", .{}),
        WhereError.negative_number => print("Cannot generate list from negative input.\n", .{}),
    }
    return err;
}

pub fn where(vm: *VM, x: *Value) WhereError!*Value {
    return switch (x.as) {
        .boolean_list => |bool_list_x| blk: {
            var list = std.ArrayList(*Value).init(vm.allocator);
            for (bool_list_x) |value, i| {
                if (value.as.boolean) list.append(vm.initValue(.{ .int = @intCast(i64, i) })) catch std.debug.panic("Failed to append item.", .{});
            }
            break :blk vm.initValue(.{ .int_list = list.toOwnedSlice() catch std.debug.panic("Failed to create list.", .{}) });
        },
        .int_list => |int_list_x| blk: {
            var list = std.ArrayList(*Value).init(vm.allocator);
            errdefer list.deinit();
            for (int_list_x) |value, i| {
                errdefer for (list.items) |v| v.deref(vm.allocator);
                if (value.as.int < 0) return runtimeError(WhereError.negative_number);
                if (value.as.int > 0) list.appendNTimes(vm.initValue(.{ .int = @intCast(i64, i) }), @intCast(usize, value.as.int)) catch std.debug.panic("Failed to append item.", .{});
            }
            break :blk vm.initValue(.{ .int_list = list.toOwnedSlice() catch std.debug.panic("Failed to create list.", .{}) });
        },
        else => runtimeError(WhereError.invalid_type),
    };
}
