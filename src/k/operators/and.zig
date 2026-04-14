const k = @import("../../root.zig");
const Vm = k.Vm;
const Value = k.Value;

pub fn @"and"(vm: *Vm, x: *Value, y: *Value) !*Value {
    return vm.runtimeError("nyi: {s}[{t};{t}]", .{ @src().fn_name, x.as, y.as });
}
