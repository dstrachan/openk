const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;
const runTestError = vm_mod.runTestError;
const TestValue = vm_mod.TestValue;

const ReverseError = @import("../../verbs/reverse.zig").ReverseError;

test "reverse boolean" {
    try runTest("|0b", .{ .boolean = false });
    try runTest("|`boolean$()", .{ .boolean_list = &[_]TestValue{} });
    try runTest("|01b", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = false },
        },
    });
}

test "reverse int" {
    try runTest("|0", .{ .int = 0 });
    try runTest("|`int$()", .{ .int_list = &[_]TestValue{} });
    try runTest("|0 1", .{
        .int_list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 0 },
        },
    });
}

test "reverse float" {
    try runTest("|0f", .{ .float = 0 });
    try runTest("|`float$()", .{ .float_list = &[_]TestValue{} });
    try runTest("|0 1f", .{
        .float_list = &[_]TestValue{
            .{ .float = 1 },
            .{ .float = 0 },
        },
    });
}

test "reverse char" {
    try runTest("|\"a\"", .{ .char = 'a' });
    try runTest("|\"\"", .{ .char_list = &[_]TestValue{} });
    try runTest("|\"abcde\"", .{
        .char_list = &[_]TestValue{
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
    try runTest("|`$()", .{ .symbol_list = &[_]TestValue{} });
    try runTest("|`a`b`c`d`e", .{
        .symbol_list = &[_]TestValue{
            .{ .symbol = "e" },
            .{ .symbol = "d" },
            .{ .symbol = "c" },
            .{ .symbol = "b" },
            .{ .symbol = "a" },
        },
    });
}

test "reverse list" {
    try runTest("|()", .{ .list = &[_]TestValue{} });
    try runTest("|(0b;1;2f)", .{
        .list = &[_]TestValue{
            .{ .float = 2 },
            .{ .int = 1 },
            .{ .boolean = false },
        },
    });

    try runTest("|(0 1;2 3)", .{
        .list = &[_]TestValue{
            .{ .int_list = &[_]TestValue{
                .{ .int = 2 },
                .{ .int = 3 },
            } },
            .{ .int_list = &[_]TestValue{
                .{ .int = 0 },
                .{ .int = 1 },
            } },
        },
    });
    try runTest("|(`a`b;`c`d)", .{
        .list = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "c" },
                .{ .symbol = "d" },
            } },
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
        },
    });
    try runTest("|(\"ab\";\"cd\")", .{
        .list = &[_]TestValue{
            .{ .char_list = &[_]TestValue{
                .{ .char = 'c' },
                .{ .char = 'd' },
            } },
            .{ .char_list = &[_]TestValue{
                .{ .char = 'a' },
                .{ .char = 'b' },
            } },
        },
    });
    try runTest("|(`a;1;\"ab\";\"cd\")", .{
        .list = &[_]TestValue{
            .{ .char_list = &[_]TestValue{
                .{ .char = 'c' },
                .{ .char = 'd' },
            } },
            .{ .char_list = &[_]TestValue{
                .{ .char = 'a' },
                .{ .char = 'b' },
            } },
            .{ .int = 1 },
            .{ .symbol = "a" },
        },
    });

    try runTest("|(``;(`a`b;`symbol))", .{
        .list = &[_]TestValue{
            .{ .list = &[_]TestValue{
                .{ .symbol_list = &[_]TestValue{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .symbol = "symbol" },
            } },
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "" },
                .{ .symbol = "" },
            } },
        },
    });
}

test "reverse dictionary" {
    try runTest("|()!()", .{
        .dictionary = &[_]TestValue{
            .{ .list = &[_]TestValue{} },
            .{ .list = &[_]TestValue{} },
        },
    });
    try runTest("|`a`b!1 2", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "b" },
                .{ .symbol = "a" },
            } },
            .{ .int_list = &[_]TestValue{
                .{ .int = 2 },
                .{ .int = 1 },
            } },
        },
    });
    try runTest("|`a`b!(();())", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "b" },
                .{ .symbol = "a" },
            } },
            .{ .list = &[_]TestValue{
                .{ .list = &[_]TestValue{} },
                .{ .list = &[_]TestValue{} },
            } },
        },
    });
    try runTest("|`a`b!(`int$();`float$())", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "b" },
                .{ .symbol = "a" },
            } },
            .{ .list = &[_]TestValue{
                .{ .float_list = &[_]TestValue{} },
                .{ .int_list = &[_]TestValue{} },
            } },
        },
    });
    try runTest("|`a`b!(,1;,2)", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "b" },
                .{ .symbol = "a" },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = 2 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                } },
            } },
        },
    });
    try runTest("|`a`b!(1 2;3 4)", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "b" },
                .{ .symbol = "a" },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = 3 },
                    .{ .int = 4 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
            } },
        },
    });
    try runTest("|`a`b!(1;2 3)", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "b" },
                .{ .symbol = "a" },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = 2 },
                    .{ .int = 3 },
                } },
                .{ .int = 1 },
            } },
        },
    });
    try runTest("|1 2!3 4", .{
        .dictionary = &[_]TestValue{
            .{ .int_list = &[_]TestValue{
                .{ .int = 2 },
                .{ .int = 1 },
            } },
            .{ .int_list = &[_]TestValue{
                .{ .int = 4 },
                .{ .int = 3 },
            } },
        },
    });
}

test "reverse table" {
    try runTest("|+`a`b!(();())", .{
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
    try runTest("|+`a`b!(`int$();`float$())", .{
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
    try runTest("|+`a`b!(,1;,2)", .{
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
    try runTest("|+`a`b!(1 2;3 4)", .{
        .table = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = 2 },
                    .{ .int = 1 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 4 },
                    .{ .int = 3 },
                } },
            } },
        },
    });
    try runTest("|+`a`b!(1;2 3)", .{
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
                    .{ .int = 3 },
                    .{ .int = 2 },
                } },
            } },
        },
    });
}
