const k = @import("../../root.zig");
const Vm = k.Vm;
const Value = k.Value;

pub fn count(vm: *Vm, x: *Value) !*Value {
    return .long(vm.gpa, @intCast(x.count()));
}
