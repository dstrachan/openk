const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;
const TestValue = vm_mod.TestValue;

test "sqrt" {
    try runTest("%25", .{ .float = 5 });
}
