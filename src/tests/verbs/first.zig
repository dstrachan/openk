const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;
const TestValue = vm_mod.TestValue;

test "first" {
    try runTest("*`a`b", .{ .symbol = "a" });

    try runTest("*(0 1;\"cd\")", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 1 },
        },
    });
}
