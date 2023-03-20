const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;
const TestValue = vm_mod.TestValue;

test "enlist" {
    try runTest(",1", .{ .int_list = &.{.{ .int = 1 }} });
    try runTest(",,1", .{ .list = &.{.{ .int_list = &.{.{ .int = 1 }} }} });
    try runTest(",`a`b!1 2", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 1 },
                } },
                .{ .int_list = &.{
                    .{ .int = 2 },
                } },
            } },
        },
    });
}
