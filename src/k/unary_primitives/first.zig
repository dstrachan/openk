const k = @import("../../root.zig");
const Vm = k.Vm;
const Value = k.Value;

pub fn first(vm: *Vm, x: *Value) !*Value {
    return x.index(vm.gpa, 0);
}
