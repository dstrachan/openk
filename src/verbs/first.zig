const value_mod = @import("../value.zig");
const Value = value_mod.Value;

const vm_mod = @import("../vm.zig");
const VM = vm_mod.VM;

pub fn first(_: *VM, x: *Value) !*Value {
    return switch (x.as) {
        .nil, .boolean, .int, .float, .char, .symbol, .function, .projection => x.ref(),
        .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list| list[0].ref(),
        .dictionary => |dict| switch (dict.value.as) {
            .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list| list[0].ref(),
            else => unreachable,
        },
    };
}
