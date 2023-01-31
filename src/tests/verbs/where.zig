const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;
const runTestError = vm_mod.runTestError;
const TestValue = vm_mod.TestValue;

const WhereError = @import("../../verbs/where.zig").WhereError;

test "where" {
    try runTest("&101b", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 2 },
        },
    });
    try runTest("&!5", .{
        .int_list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 2 },
            .{ .int = 2 },
            .{ .int = 3 },
            .{ .int = 3 },
            .{ .int = 3 },
            .{ .int = 4 },
            .{ .int = 4 },
            .{ .int = 4 },
            .{ .int = 4 },
        },
    });

    try runTestError("&1b", WhereError.invalid_type);
    try runTestError("&1", WhereError.invalid_type);
    try runTestError("&(0b;1)", WhereError.invalid_type);
    try runTestError("&1 0 -3", WhereError.negative_number);
}
