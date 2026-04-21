const k = @import("../../root.zig");
const Vm = k.Vm;
const Value = k.Value;

pub fn match(vm: *Vm, x: *Value, y: *Value) !*Value {
    return .create(.boolean, vm.gpa, x.match(y));
}
