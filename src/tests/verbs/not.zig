const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;
const runTestError = vm_mod.runTestError;
const TestValue = vm_mod.TestValue;

const NotError = @import("../../verbs/not.zig").NotError;

test "not boolean" {
    try runTest("~0b", .{ .boolean = true });
    try runTest("~`boolean$()", .{ .boolean_list = &.{} });
    try runTest("~01b", .{
        .boolean_list = &.{
            .{ .boolean = true },
            .{ .boolean = false },
        },
    });
}

test "not int" {
    try runTest("~0", .{ .boolean = true });
    try runTest("~`int$()", .{ .boolean_list = &.{} });
    try runTest("~0 1 0N 0W -0W", .{
        .boolean_list = &.{
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
}

test "not float" {
    try runTest("~0f", .{ .boolean = true });
    try runTest("~`float$()", .{ .boolean_list = &.{} });
    try runTest("~0 1 0n 0w -0w", .{
        .boolean_list = &.{
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
}

test "not char" {
    try runTestError("~\"a\"", NotError.invalid_type);
    try runTestError("~\"\"", NotError.invalid_type);
    try runTestError("~\"abcde\"", NotError.invalid_type);
}

test "not symbol" {
    try runTestError("~`symbol", NotError.invalid_type);
    try runTestError("~`$()", NotError.invalid_type);
    try runTestError("~`a`b`c`d`e", NotError.invalid_type);
}

test "not list" {
    try runTest("~()", .{ .list = &.{} });
    try runTest("~(0b;1;2f)", .{
        .boolean_list = &.{
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });

    try runTest("~(0 1;2 3)", .{
        .list = &.{
            .{ .boolean_list = &.{
                .{ .boolean = true },
                .{ .boolean = false },
            } },
            .{ .boolean_list = &.{
                .{ .boolean = false },
                .{ .boolean = false },
            } },
        },
    });

    try runTest("~(2f;1;`int$())", .{ .list = &.{
        .{ .boolean = false },
        .{ .boolean = false },
        .{ .boolean_list = &.{} },
    } });

    try runTest("~(1 2;3;4 5)", .{
        .list = &.{
            .{ .boolean_list = &.{
                .{ .boolean = false },
                .{ .boolean = false },
            } },
            .{ .boolean = false },
            .{ .boolean_list = &.{
                .{ .boolean = false },
                .{ .boolean = false },
            } },
        },
    });

    try runTestError("~(0b;1;2f;`three)", NotError.invalid_type);
    try runTestError("~(`three;2f;1;0b)", NotError.invalid_type);
}

test "not dictionary" {
    try runTest("~()!()", .{
        .dictionary = &.{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("~()!`float$()", .{
        .dictionary = &.{
            .{ .list = &.{} },
            .{ .boolean_list = &.{} },
        },
    });
    try runTest("~(`int$())!()", .{
        .dictionary = &.{
            .{ .int_list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("~(`int$())!`float$()", .{
        .dictionary = &.{
            .{ .int_list = &.{} },
            .{ .boolean_list = &.{} },
        },
    });
    try runTest("~`a`b!(();())", .{
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
    try runTest("~`a`b!(`int$();`float$())", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .boolean_list = &.{} },
                .{ .boolean_list = &.{} },
            } },
        },
    });
    try runTest("~`a`b!(,1;,2)", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .boolean_list = &.{
                    .{ .boolean = false },
                } },
                .{ .boolean_list = &.{
                    .{ .boolean = false },
                } },
            } },
        },
    });
    try runTest("~`a`b!(1 1;2 2)", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .boolean_list = &.{
                    .{ .boolean = false },
                    .{ .boolean = false },
                } },
                .{ .boolean_list = &.{
                    .{ .boolean = false },
                    .{ .boolean = false },
                } },
            } },
        },
    });
    try runTest("~`a`b!(1;2 2)", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .boolean = false },
                .{ .boolean_list = &.{
                    .{ .boolean = false },
                    .{ .boolean = false },
                } },
            } },
        },
    });
}

test "not table" {
    try runTest("~+`a`b!(();())", .{
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
    try runTest("~+`a`b!(`int$();`float$())", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .boolean_list = &.{} },
                .{ .boolean_list = &.{} },
            } },
        },
    });
    try runTest("~+`a`b!(,1;,2)", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .boolean_list = &.{
                    .{ .boolean = false },
                } },
                .{ .boolean_list = &.{
                    .{ .boolean = false },
                } },
            } },
        },
    });
    try runTest("~+`a`b!(1 1;2 2)", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .boolean_list = &.{
                    .{ .boolean = false },
                    .{ .boolean = false },
                } },
                .{ .boolean_list = &.{
                    .{ .boolean = false },
                    .{ .boolean = false },
                } },
            } },
        },
    });
    try runTest("~+`a`b!(1;2 2)", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .boolean_list = &.{
                    .{ .boolean = false },
                    .{ .boolean = false },
                } },
                .{ .boolean_list = &.{
                    .{ .boolean = false },
                    .{ .boolean = false },
                } },
            } },
        },
    });
}
