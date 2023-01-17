const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;
const TestValue = vm_mod.TestValue;

// TODO: Negate mixed list
test "negate" {
    try runTest("- 1", .{ .int = -1 });

    try runTest("- 1 2 3", .{
        .int_list = &[_]TestValue{
            .{ .int = -1 },
            .{ .int = -2 },
            .{ .int = -3 },
        },
    });
}
