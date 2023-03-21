const value_mod = @import("../value.zig");
const Value = value_mod.Value;

const vm_mod = @import("../vm.zig");
const VM = vm_mod.VM;

pub fn match(vm: *VM, x: *Value, y: *Value) *Value {
    return vm.initValue(.{ .boolean = x.eql(y) });
}
