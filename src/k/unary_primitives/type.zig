const k = @import("../../root.zig");
const Vm = k.Vm;
const Value = k.Value;

pub fn @"type"(vm: *Vm, x: *Value) !*Value {
    return .create(.short, vm.gpa, @intFromEnum(x.as));
}
