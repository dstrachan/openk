const k = @import("../../root.zig");
const Vm = k.Vm;
const Value = k.Value;

pub fn count(vm: *Vm, x: *Value) !*Value {
    return .long(vm.gpa, switch (x.as) {
        inline .list,
        .boolean_list,
        .byte_list,
        .short_list,
        .int_list,
        .long_list,
        .real_list,
        .float_list,
        .char_list,
        .symbol_list,
        => |list| @intCast(list.len),
        else => 1,
    });
}
