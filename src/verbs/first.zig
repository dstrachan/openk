const std = @import("std");

const value_mod = @import("../value.zig");
const Value = value_mod.Value;
const ValueTable = value_mod.ValueTable;

const vm_mod = @import("../vm.zig");
const VM = vm_mod.VM;

pub fn first(vm: *VM, x: *Value) !*Value {
    return switch (x.as) {
        .nil, .boolean, .int, .float, .char, .symbol, .function, .projection => x.ref(),
        .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list| list[0].ref(),
        .dictionary => |dict| switch (dict.value.as) {
            .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list| list[0].ref(),
            else => unreachable,
        },
        .table => |table| blk: {
            const list = vm.allocator.alloc(*Value, table.columns.as.symbol_list.len) catch std.debug.panic("Failed to create list.", .{});
            const values_list = switch (table.values.as) {
                .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |l| l,
                else => unreachable,
            };
            var i: usize = 0;
            while (i < list.len) : (i += 1) {
                list[i] = try first(vm, values_list[i]);
            }

            const values = vm.initValue(.{ .list = list });
            const value = ValueTable.init(.{ .columns = table.columns.ref(), .values = values }, vm.allocator);
            break :blk vm.initValue(.{ .table = value });
        },
    };
}
