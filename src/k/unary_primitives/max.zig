const k = @import("../../root.zig");
const Vm = k.Vm;
const Value = k.Value;

pub fn max(vm: *Vm, x: *Value) !*Value {
    return vm.runtimeError("nyi: {s}[{t}]", .{ @src().fn_name, x.as });
}
