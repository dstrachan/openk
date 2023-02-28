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
    try runTest("+()", .{ .list = &[_]TestValue{} });
    try runTestError("+(0b;1;2f)", FlipError.length_mismatch);

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

    try runTestError("+(1;2f)", FlipError.length_mismatch);
    try runTestError("+(1;2 3;4 5 6)", FlipError.length_mismatch);
    try runTestError("+(1;2 3;())", FlipError.length_mismatch);
}

test "flip dictionary" {
    try runTest("+`a`b!(();())", .{
        .table = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .list = &[_]TestValue{} },
                .{ .list = &[_]TestValue{} },
            } },
        },
    });
    try runTest("+`a`b!(`int$();`float$())", .{
        .table = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{} },
                .{ .float_list = &[_]TestValue{} },
            } },
        },
    });
    try runTest("+`a`b!(,1;,2)", .{
        .table = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 2 },
                } },
            } },
        },
    });
    try runTest("+`a`b!(1 1;2 2)", .{
        .table = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                    .{ .int = 1 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 2 },
                    .{ .int = 2 },
                } },
            } },
        },
    });
    try runTest("+`a`b!(1;2 2)", .{
        .table = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                    .{ .int = 1 },
                } },
                .{ .int_list = &[_]TestValue{
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
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .list = &[_]TestValue{} },
                .{ .list = &[_]TestValue{} },
            } },
        },
    });
    try runTest("++`a`b!(`int$();`float$())", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{} },
                .{ .float_list = &[_]TestValue{} },
            } },
        },
    });
    try runTest("++`a`b!(,1;,2)", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 2 },
                } },
            } },
        },
    });
    try runTest("++`a`b!(1 1;2 2)", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                    .{ .int = 1 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 2 },
                    .{ .int = 2 },
                } },
            } },
        },
    });
    try runTest("++`a`b!(1;2 2)", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                    .{ .int = 1 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 2 },
                    .{ .int = 2 },
                } },
            } },
        },
    });
}
