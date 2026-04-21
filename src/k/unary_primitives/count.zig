const k = @import("../../root.zig");
const Vm = k.Vm;
const Value = k.Value;

pub fn count(vm: *Vm, x: *Value) !*Value {
    return .create(.long, vm.gpa, @intCast(x.count()));
}
