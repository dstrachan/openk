const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;
const TestValue = vm_mod.TestValue;

test "enum" {
    try runTest("!10", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = 2 },
            .{ .int = 3 },
            .{ .int = 4 },
            .{ .int = 5 },
            .{ .int = 6 },
            .{ .int = 7 },
            .{ .int = 8 },
            .{ .int = 9 },
        },
    });

    try runTest("!-3", .{
        .int_list = &[_]TestValue{
            .{ .int = -3 },
            .{ .int = -2 },
            .{ .int = -1 },
        },
    });

    try runTest("!0", .{ .int_list = &[_]TestValue{} });
}
