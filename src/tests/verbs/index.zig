const value_mod = @import("../../value.zig");
const Value = value_mod.Value;

const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;
const TestValue = vm_mod.TestValue;

test "index" {
    try runTest("(!10)@2", .{ .int = 2 });

    try runTest("(`a`b`c!1 2 3)`a", .{ .int = 1 });
    try runTest("(`a`b`c!1 2 3)`d", .{ .int = Value.null_int });
    try runTest("(`a`b`c!1 2 3)`a`b", .{
        .int_list = &.{
            .{ .int = 1 },
            .{ .int = 2 },
        },
    });
    try runTest("(`a`b`c!1 2 3)`a`d", .{
        .int_list = &.{
            .{ .int = 1 },
            .{ .int = Value.null_int },
        },
    });
    try runTest("(`a`b`c!1 2 3)`d`a", .{
        .int_list = &.{
            .{ .int = Value.null_int },
            .{ .int = 1 },
        },
    });
    try runTest("(`a`b`c!1 2 3)`d`e", .{
        .int_list = &.{
            .{ .int = Value.null_int },
            .{ .int = Value.null_int },
        },
    });
}
