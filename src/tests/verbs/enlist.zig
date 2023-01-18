const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;
const TestValue = vm_mod.TestValue;

test "enlist" {
    try runTest(",1", .{ .int_list = &[_]TestValue{.{ .int = 1 }} });
    try runTest(",,1", .{ .list = &[_]TestValue{.{ .int_list = &[_]TestValue{.{ .int = 1 }} }} });
}
