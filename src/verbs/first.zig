const std = @import("std");

const value_mod = @import("../value.zig");
const Value = value_mod.Value;
const ValueDictionary = value_mod.ValueDictionary;
const ValueType = value_mod.ValueType;

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
            var list_type: ?ValueType = null;
            for (table.values.asList(), 0..) |v, i| {
                list[i] = v.asList()[0].ref();
                if (list_type == null and @as(ValueType, list[0].as) != list[i].as) list_type = .list;
            }
            const value = vm.initList(list, list_type);
            const dictionary = ValueDictionary.init(.{ .key = table.columns.ref(), .value = value }, vm.allocator);
            break :blk vm.initValue(.{ .dictionary = dictionary });
        },
    };
}
