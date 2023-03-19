const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;
const runTestError = vm_mod.runTestError;
const TestValue = vm_mod.TestValue;

const FlipError = @import("../../verbs/flip.zig").FlipError;

test "flip boolean" {
    try runTestError("+0b", FlipError.invalid_type);
    try runTestError("+`boolean$()", FlipError.invalid_type);
    try runTestError("+01b", FlipError.invalid_type);
}

test "flip int" {
    try runTestError("+0", FlipError.invalid_type);
    try runTestError("+`int$()", FlipError.invalid_type);
    try runTestError("+0 1 0N 0W -0W", FlipError.invalid_type);
}

test "flip float" {
    try runTestError("+0f", FlipError.invalid_type);
    try runTestError("+`float$()", FlipError.invalid_type);
    try runTestError("+0 1 0n 0w -0w", FlipError.invalid_type);
}

test "flip char" {
    try runTestError("+\"a\"", FlipError.invalid_type);
    try runTestError("+\"\"", FlipError.invalid_type);
    try runTestError("+\"abcde\"", FlipError.invalid_type);
}

test "flip symbol" {
    try runTestError("+`symbol", FlipError.invalid_type);
    try runTestError("+`$()", FlipError.invalid_type);
    try runTestError("+`a`b`c`d`e", FlipError.invalid_type);
}

test "flip list" {
    try runTest("+()", .{ .list = &.{} });
    try runTestError("+(0b;1;2f)", FlipError.length_mismatch);

    try runTest("+(0 1;2 3)", .{
        .list = &.{
            .{ .int_list = &.{
                .{ .int = 0 },
                .{ .int = 2 },
            } },
            .{ .int_list = &.{
                .{ .int = 1 },
                .{ .int = 3 },
            } },
        },
    });
    try runTest("+(`a`b;`c`d)", .{
        .list = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "c" },
            } },
            .{ .symbol_list = &.{
                .{ .symbol = "b" },
                .{ .symbol = "d" },
            } },
        },
    });
    try runTest("+(\"ab\";\"cd\")", .{
        .list = &.{
            .{ .char_list = &.{
                .{ .char = 'a' },
                .{ .char = 'c' },
            } },
            .{ .char_list = &.{
                .{ .char = 'b' },
                .{ .char = 'd' },
            } },
        },
    });
    try runTest("+(`a;1;\"ab\";\"cd\")", .{
        .list = &.{
            .{ .list = &.{
                .{ .symbol = "a" },
                .{ .int = 1 },
                .{ .char = 'a' },
                .{ .char = 'c' },
            } },
            .{ .list = &.{
                .{ .symbol = "a" },
                .{ .int = 1 },
                .{ .char = 'b' },
                .{ .char = 'd' },
            } },
        },
    });

    try runTest("+(2f;1;`int$())", .{ .list = &.{} });

    try runTest("+(1 2;3;4 5)", .{
        .list = &.{
            .{ .int_list = &.{
                .{ .int = 1 },
                .{ .int = 3 },
                .{ .int = 4 },
            } },
            .{ .int_list = &.{
                .{ .int = 2 },
                .{ .int = 3 },
                .{ .int = 5 },
            } },
        },
    });

    try runTest("+(``;(`a`b;`symbol))", .{
        .list = &.{
            .{ .list = &.{
                .{ .symbol = "" },
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
            } },
            .{ .symbol_list = &.{
                .{ .symbol = "" },
                .{ .symbol = "symbol" },
            } },
        },
    });

    try runTestError("+(1;2f)", FlipError.length_mismatch);
    try runTestError("+(1;2 3;4 5 6)", FlipError.length_mismatch);
    try runTestError("+(1;2 3;())", FlipError.length_mismatch);
}

test "flip dictionary" {
    try runTestError("+()!()", FlipError.invalid_column_type);
    try runTest("+`a`b!(();())", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .list = &.{} },
                .{ .list = &.{} },
            } },
        },
    });
    try runTest("+`a`b!(`int$();`float$())", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .int_list = &.{} },
                .{ .float_list = &.{} },
            } },
        },
    });
    try runTest("+`a`b!(,1;,2)", .{
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
    try runTest("+`a`b!(1 1;2 2)", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 1 },
                    .{ .int = 1 },
                } },
                .{ .int_list = &.{
                    .{ .int = 2 },
                    .{ .int = 2 },
                } },
            } },
        },
    });
    try runTest("+`a`b!(1;2 2)", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 1 },
                    .{ .int = 1 },
                } },
                .{ .int_list = &.{
                    .{ .int = 2 },
                    .{ .int = 2 },
                } },
            } },
        },
    });
    try runTestError("+1 2!1 2", FlipError.invalid_column_type);
    try runTestError("+`a`b!1 2", FlipError.invalid_value_type);
}

test "flip table" {
    try runTest("++`a`b!(();())", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .list = &.{} },
                .{ .list = &.{} },
            } },
        },
    });
    try runTest("++`a`b!(`int$();`float$())", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .int_list = &.{} },
                .{ .float_list = &.{} },
            } },
        },
    });
    try runTest("++`a`b!(,1;,2)", .{
        .dictionary = &.{
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
    try runTest("++`a`b!(1 1;2 2)", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 1 },
                    .{ .int = 1 },
                } },
                .{ .int_list = &.{
                    .{ .int = 2 },
                    .{ .int = 2 },
                } },
            } },
        },
    });
    try runTest("++`a`b!(1;2 2)", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 1 },
                    .{ .int = 1 },
                } },
                .{ .int_list = &.{
                    .{ .int = 2 },
                    .{ .int = 2 },
                } },
            } },
        },
    });
}
