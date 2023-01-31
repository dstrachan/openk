const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;
const runTestError = vm_mod.runTestError;
const TestValue = vm_mod.TestValue;

const FlipError = @import("../../verbs/flip.zig").FlipError;

test "flip" {
    try runTest("+(0 1;2 3)", .{
        .list = &[_]TestValue{
            .{ .int_list = &[_]TestValue{
                .{ .int = 0 },
                .{ .int = 2 },
            } },
            .{ .int_list = &[_]TestValue{
                .{ .int = 1 },
                .{ .int = 3 },
            } },
        },
    });
    try runTest("+(`a`b;`c`d)", .{
        .list = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "c" },
            } },
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "b" },
                .{ .symbol = "d" },
            } },
        },
    });
    try runTest("+(\"ab\";\"cd\")", .{
        .list = &[_]TestValue{
            .{ .char_list = &[_]TestValue{
                .{ .char = 'a' },
                .{ .char = 'c' },
            } },
            .{ .char_list = &[_]TestValue{
                .{ .char = 'b' },
                .{ .char = 'd' },
            } },
        },
    });
    try runTest("+(`a;1;\"ab\";\"cd\")", .{
        .list = &[_]TestValue{
            .{ .list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .int = 1 },
                .{ .char = 'a' },
                .{ .char = 'c' },
            } },
            .{ .list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .int = 1 },
                .{ .char = 'b' },
                .{ .char = 'd' },
            } },
        },
    });

    try runTest("+(2f;1;`int$())", .{ .list = &[_]TestValue{} });

    try runTest("+(1 2;3;4 5)", .{
        .list = &[_]TestValue{
            .{ .int_list = &[_]TestValue{
                .{ .int = 1 },
                .{ .int = 3 },
                .{ .int = 4 },
            } },
            .{ .int_list = &[_]TestValue{
                .{ .int = 2 },
                .{ .int = 3 },
                .{ .int = 5 },
            } },
        },
    });

    try runTest("+(``;(`a`b;`symbol))", .{
        .list = &[_]TestValue{
            .{ .list = &[_]TestValue{
                .{ .symbol = "" },
                .{ .symbol_list = &[_]TestValue{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
            } },
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "" },
                .{ .symbol = "symbol" },
            } },
        },
    });

    try runTestError("+1", FlipError.invalid_type);
    try runTestError("+(1;2f)", FlipError.invalid_type);
    try runTestError("+(1;2 3;4 5 6)", FlipError.length_mismatch);
    try runTestError("+(1;2 3;())", FlipError.length_mismatch);
}
