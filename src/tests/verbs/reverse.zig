const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;
const runTestError = vm_mod.runTestError;

const ReverseError = @import("../../verbs/reverse.zig").ReverseError;

test "reverse boolean" {
    try runTest("|0b", .{ .boolean = false });
    try runTest("|`boolean$()", .{ .boolean_list = &.{} });
    try runTest("|01b", .{
        .boolean_list = &.{
            .{ .boolean = true },
            .{ .boolean = false },
        },
    });
}

test "reverse int" {
    try runTest("|0", .{ .int = 0 });
    try runTest("|`int$()", .{ .int_list = &.{} });
    try runTest("|0 1", .{
        .int_list = &.{
            .{ .int = 1 },
            .{ .int = 0 },
        },
    });
}

test "reverse float" {
    try runTest("|0f", .{ .float = 0 });
    try runTest("|`float$()", .{ .float_list = &.{} });
    try runTest("|0 1f", .{
        .float_list = &.{
            .{ .float = 1 },
            .{ .float = 0 },
        },
    });
}

test "reverse char" {
    try runTest("|\"a\"", .{ .char = 'a' });
    try runTest("|\"\"", .{ .char_list = &.{} });
    try runTest("|\"abcde\"", .{
        .char_list = &.{
            .{ .char = 'e' },
            .{ .char = 'd' },
            .{ .char = 'c' },
            .{ .char = 'b' },
            .{ .char = 'a' },
        },
    });
}

test "reverse symbol" {
    try runTest("|`symbol", .{ .symbol = "symbol" });
    try runTest("|`$()", .{ .symbol_list = &.{} });
    try runTest("|`a`b`c`d`e", .{
        .symbol_list = &.{
            .{ .symbol = "e" },
            .{ .symbol = "d" },
            .{ .symbol = "c" },
            .{ .symbol = "b" },
            .{ .symbol = "a" },
        },
    });
}

test "reverse list" {
    try runTest("|()", .{ .list = &.{} });
    try runTest("|(0b;1;2f)", .{
        .list = &.{
            .{ .float = 2 },
            .{ .int = 1 },
            .{ .boolean = false },
        },
    });

    try runTest("|(0 1;2 3)", .{
        .list = &.{
            .{ .int_list = &.{
                .{ .int = 2 },
                .{ .int = 3 },
            } },
            .{ .int_list = &.{
                .{ .int = 0 },
                .{ .int = 1 },
            } },
        },
    });
    try runTest("|(`a`b;`c`d)", .{
        .list = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "c" },
                .{ .symbol = "d" },
            } },
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
        },
    });
    try runTest("|(\"ab\";\"cd\")", .{
        .list = &.{
            .{ .char_list = &.{
                .{ .char = 'c' },
                .{ .char = 'd' },
            } },
            .{ .char_list = &.{
                .{ .char = 'a' },
                .{ .char = 'b' },
            } },
        },
    });
    try runTest("|(`a;1;\"ab\";\"cd\")", .{
        .list = &.{
            .{ .char_list = &.{
                .{ .char = 'c' },
                .{ .char = 'd' },
            } },
            .{ .char_list = &.{
                .{ .char = 'a' },
                .{ .char = 'b' },
            } },
            .{ .int = 1 },
            .{ .symbol = "a" },
        },
    });

    try runTest("|(``;(`a`b;`symbol))", .{
        .list = &.{
            .{ .list = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .symbol = "symbol" },
            } },
            .{ .symbol_list = &.{
                .{ .symbol = "" },
                .{ .symbol = "" },
            } },
        },
    });
}

test "reverse dictionary" {
    try runTest("|()!()", .{
        .dictionary = &.{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("|`a`b!1 2", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "b" },
                .{ .symbol = "a" },
            } },
            .{ .int_list = &.{
                .{ .int = 2 },
                .{ .int = 1 },
            } },
        },
    });
    try runTest("|`a`b!(();())", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "b" },
                .{ .symbol = "a" },
            } },
            .{ .list = &.{
                .{ .list = &.{} },
                .{ .list = &.{} },
            } },
        },
    });
    try runTest("|`a`b!(`int$();`float$())", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "b" },
                .{ .symbol = "a" },
            } },
            .{ .list = &.{
                .{ .float_list = &.{} },
                .{ .int_list = &.{} },
            } },
        },
    });
    try runTest("|`a`b!(,1;,2)", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "b" },
                .{ .symbol = "a" },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 2 },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                } },
            } },
        },
    });
    try runTest("|`a`b!(1 2;3 4)", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "b" },
                .{ .symbol = "a" },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 3 },
                    .{ .int = 4 },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
            } },
        },
    });
    try runTest("|`a`b!(1;2 3)", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "b" },
                .{ .symbol = "a" },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 2 },
                    .{ .int = 3 },
                } },
                .{ .int = 1 },
            } },
        },
    });
    try runTest("|1 2!3 4", .{
        .dictionary = &.{
            .{ .int_list = &.{
                .{ .int = 2 },
                .{ .int = 1 },
            } },
            .{ .int_list = &.{
                .{ .int = 4 },
                .{ .int = 3 },
            } },
        },
    });
}

test "reverse table" {
    try runTest("|+`a`b!()", .{
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
    try runTest("|+`a`b!(`int$();`float$())", .{
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
    try runTest("|+`a`b!(,1;,2)", .{
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
    try runTest("|+`a`b!(1 2;3 4)", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 2 },
                    .{ .int = 1 },
                } },
                .{ .int_list = &.{
                    .{ .int = 4 },
                    .{ .int = 3 },
                } },
            } },
        },
    });
    try runTest("|+`a`b!(1;2 3)", .{
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
                    .{ .int = 3 },
                    .{ .int = 2 },
                } },
            } },
        },
    });
}
