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

pub fn reverse(vm: *VM, x: *Value) *Value {
    return switch (x.as) {
        .nil, .boolean, .int, .float, .char, .symbol, .function, .projection => x.ref(),
        .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list_x| blk: {
            if (list_x.len == 0) break :blk x.ref();

            const list = vm.allocator.alloc(*Value, list_x.len) catch std.debug.panic("Failed to create list.", .{});
            var j: usize = list_x.len;
            for (list) |*v| {
                v.* = list_x[j - 1].ref();
                j -= 1;
            }
            break :blk vm.initList(list, x.as);
        },
        .dictionary => |dict_x| blk: {
            const key = reverse(vm, dict_x.keys);
            const value = reverse(vm, dict_x.values);
            break :blk vm.initDictionary(.{ .keys = key, .values = value });
        },
        .table => |table_x| blk: {
            const list = vm.allocator.alloc(*Value, table_x.values.asList().len) catch std.debug.panic("Failed to create list.", .{});
            for (list, 0..) |*v, i| {
                v.* = reverse(vm, table_x.values.asList()[i]);
            }
            const values = vm.initValue(.{ .list = list });
            break :blk vm.initTable(.{ .columns = table_x.columns.ref(), .values = values });
        },
    };
}
