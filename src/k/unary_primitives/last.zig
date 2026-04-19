const k = @import("../../root.zig");
const Vm = k.Vm;
const Value = k.Value;

pub fn last(vm: *Vm, x: *Value) !*Value {
    const len = x.count();
    return x.index(vm.gpa, len - 1);
}
