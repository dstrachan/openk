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

pub const NegateError = error{
    invalid_type,
};

fn runtimeError(comptime err: NegateError) NegateError!*Value {
    switch (err) {
        NegateError.invalid_type => print("Can only negate numeric values.", .{}),
    }
    return err;
}

fn negateInt(x: i64) i64 {
    return if (x == Value.null_int) Value.null_int else -x;
}

pub fn negate(vm: *VM, x: *Value) NegateError!*Value {
    return switch (x.as) {
        .boolean => |bool_x| vm.initValue(.{ .int = if (bool_x) -1 else 0 }),
        .int => |int_x| vm.initValue(.{ .int = negateInt(int_x) }),
        .float => |float_x| vm.initValue(.{ .float = -float_x }),
        .list => |list_x| blk: {
            const list = vm.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
            errdefer vm.allocator.free(list);
            var list_type: ?ValueType = if (list_x.len == 0) .list else null;
            for (list_x, 0..) |value, i| {
                errdefer for (list[0..i]) |v| v.deref(vm.allocator);
                list[i] = try negate(vm, value);
                if (list_type == null and @as(ValueType, list[0].as) != list[i].as) list_type = .list;
            }
            break :blk vm.initListAtoms(list, list_type);
        },
        .boolean_list => |bool_list_x| blk: {
            const list = vm.allocator.alloc(*Value, bool_list_x.len) catch std.debug.panic("Failed to create list.", .{});
            for (bool_list_x, 0..) |value, i| {
                list[i] = vm.initValue(.{ .int = if (value.as.boolean) -1 else 0 });
            }
            break :blk vm.initValue(.{ .int_list = list });
        },
        .int_list => |int_list_x| blk: {
            const list = vm.allocator.alloc(*Value, int_list_x.len) catch std.debug.panic("Failed to create list.", .{});
            for (int_list_x, 0..) |value, i| {
                list[i] = vm.initValue(.{ .int = negateInt(value.as.int) });
            }
            break :blk vm.initValue(.{ .int_list = list });
        },
        .float_list => |float_list_x| blk: {
            const list = vm.allocator.alloc(*Value, float_list_x.len) catch std.debug.panic("Failed to create list.", .{});
            for (float_list_x, 0..) |value, i| {
                list[i] = vm.initValue(.{ .float = -value.as.float });
            }
            break :blk vm.initValue(.{ .float_list = list });
        },
        .dictionary => |dict_x| blk: {
            const value = try negate(vm, dict_x.value);
            const dictionary = ValueDictionary.init(.{ .key = dict_x.key.ref(), .value = value }, vm.allocator);
            break :blk vm.initValue(.{ .dictionary = dictionary });
        },
        .table => |table_x| blk: {
            const values = try negate(vm, table_x.values);
            const table = ValueTable.init(.{ .columns = table_x.columns.ref(), .values = values }, vm.allocator);
            break :blk vm.initValue(.{ .table = table });
        },
        else => return runtimeError(NegateError.invalid_type),
    };
}
