const std = @import("std");

const value_mod = @import("../value.zig");
const Value = value_mod.Value;
const ValueDictionary = value_mod.ValueDictionary;
const ValueType = value_mod.ValueType;

const vm_mod = @import("../vm.zig");
const VM = vm_mod.VM;

pub fn first(vm: *VM, x: *Value) *Value {
    return switch (x.as) {
        .nil, .boolean, .int, .float, .char, .symbol, .function, .projection => x.ref(),
        .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list_x| if (list_x.len == 0) vm.initNull(x.as) else list_x[0].ref(),
        .dictionary => |dict_x| first(vm, dict_x.values),
        .table => |table_x| blk: {
            const list = vm.allocator.alloc(*Value, table_x.columns.as.symbol_list.len) catch std.debug.panic("Failed to create list.", .{});
            var list_type: ?ValueType = null;
            for (table_x.values.asList(), 0..) |v, i| {
                list[i] = first(vm, v);
                if (list_type == null and @as(ValueType, list[0].as) != list[i].as) list_type = .list;
            }
            const value = vm.initListAtoms(list, list_type);
            const dictionary = ValueDictionary.init(.{ .keys = table_x.columns.ref(), .values = value }, vm);
            break :blk vm.initValue(.{ .dictionary = dictionary });
        },
    };
}
