const value_mod = @import("../../value.zig");
const Value = value_mod.Value;

const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;
const runTestError = vm_mod.runTestError;
const TestValue = vm_mod.TestValue;

const MergeError = @import("../../verbs/merge.zig").MergeError;

test "merge boolean" {
    try runTest("1b,0b", .{
        .boolean_list = &.{
            .{ .boolean = true },
            .{ .boolean = false },
        },
    });
    try runTest("1b,`boolean$()", .{
        .boolean_list = &.{
            .{ .boolean = true },
        },
    });
    try runTest("1b,00000b", .{
        .boolean_list = &.{
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });

    try runTest("1,0b", .{
        .list = &.{
            .{ .int = 1 },
            .{ .boolean = false },
        },
    });
    try runTest("1,`boolean$()", .{
        .int_list = &.{
            .{ .int = 1 },
        },
    });
    try runTest("1,00000b", .{
        .list = &.{
            .{ .int = 1 },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });

    try runTest("1f,0b", .{
        .list = &.{
            .{ .float = 1 },
            .{ .boolean = false },
        },
    });
    try runTest("1f,`boolean$()", .{
        .float_list = &.{
            .{ .float = 1 },
        },
    });
    try runTest("1f,00000b", .{
        .list = &.{
            .{ .float = 1 },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });

    try runTest("\"a\",0b", .{
        .list = &.{
            .{ .char = 'a' },
            .{ .boolean = false },
        },
    });
    try runTest("\"a\",`boolean$()", .{
        .char_list = &.{
            .{ .char = 'a' },
        },
    });
    try runTest("\"a\",00000b", .{
        .list = &.{
            .{ .char = 'a' },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });

    try runTest("`symbol,0b", .{
        .list = &.{
            .{ .symbol = "symbol" },
            .{ .boolean = false },
        },
    });
    try runTest("`symbol,`boolean$()", .{
        .symbol_list = &.{
            .{ .symbol = "symbol" },
        },
    });
    try runTest("`symbol,00000b", .{
        .list = &.{
            .{ .symbol = "symbol" },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });

    try runTest("(),0b", .{
        .boolean_list = &.{
            .{ .boolean = false },
        },
    });
    try runTest("(1b;2),0b", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .boolean = false },
        },
    });
    try runTest("(1b;2;3f),0b", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .boolean = false },
        },
    });
    try runTest("(1b;2;3f;`symbol),0b", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .symbol = "symbol" },
            .{ .boolean = false },
        },
    });
    try runTest("(),`boolean$()", .{ .boolean_list = &.{} });
    try runTest("(),010b", .{
        .boolean_list = &.{
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
        },
    });
    try runTest("(1b;2),`boolean$()", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 2 },
        },
    });
    try runTest("(1b;2),01b", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .boolean = false },
            .{ .boolean = true },
        },
    });
    try runTest("(1b;2;3f),010b", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
        },
    });
    try runTest("(1b;2;3f),0101b", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = true },
        },
    });
    try runTest("(1b;2;3f;\"a\"),0101b", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .char = 'a' },
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = true },
        },
    });
    try runTest("(1b;2;3f;`symbol),0101b", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .symbol = "symbol" },
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = true },
        },
    });

    try runTest("11111b,0b", .{
        .boolean_list = &.{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = false },
        },
    });
    try runTest("11111b,`boolean$()", .{
        .boolean_list = &.{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTest("11111b,00000b", .{
        .boolean_list = &.{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTest("11111b,000000b", .{
        .boolean_list = &.{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });

    try runTest("5 4 3 2 1,0b", .{
        .list = &.{
            .{ .int = 5 },
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = 2 },
            .{ .int = 1 },
            .{ .boolean = false },
        },
    });
    try runTest("5 4 3 2 1,`boolean$()", .{
        .int_list = &.{
            .{ .int = 5 },
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = 2 },
            .{ .int = 1 },
        },
    });
    try runTest("5 4 3 2 1,00000b", .{
        .list = &.{
            .{ .int = 5 },
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = 2 },
            .{ .int = 1 },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTest("5 4 3 2 1,000000b", .{
        .list = &.{
            .{ .int = 5 },
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = 2 },
            .{ .int = 1 },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });

    try runTest("5 4 3 2 1f,0b", .{
        .list = &.{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
            .{ .boolean = false },
        },
    });
    try runTest("5 4 3 2 1f,`boolean$()", .{
        .float_list = &.{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
        },
    });
    try runTest("5 4 3 2 1f,00000b", .{
        .list = &.{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTest("5 4 3 2 1f,000000b", .{
        .list = &.{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });

    try runTest("\"abcde\",0b", .{
        .list = &.{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
            .{ .boolean = false },
        },
    });
    try runTest("\"abcde\",`boolean$()", .{
        .char_list = &.{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });
    try runTest("\"abcde\",00000b", .{
        .list = &.{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTest("\"abcde\",000000b", .{
        .list = &.{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });

    try runTest("`a`b`c`d`e,0b", .{
        .list = &.{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
            .{ .boolean = false },
        },
    });
    try runTest("`a`b`c`d`e,`boolean$()", .{
        .symbol_list = &.{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
        },
    });
    try runTest("`a`b`c`d`e,00000b", .{
        .list = &.{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTest("`a`b`c`d`e,000000b", .{
        .list = &.{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });

    try runTestError("(`a`b!1 2),0b", MergeError.incompatible_types);
    try runTestError("(`a`b!1 2),`boolean$()", MergeError.incompatible_types);
    try runTestError("(`a`b!1 2),00000b", MergeError.incompatible_types);

    try runTest("(+`a`b!(,1;,2)),0b", .{
        .list = &.{
            .{ .dictionary = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
            } },
            .{ .boolean = false },
        },
    });
    try runTest("(+`a`b!(,1;,2)),`boolean$()", .{
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
    try runTest("(+`a`b!(,1;,2)),00000b", .{
        .list = &.{
            .{ .dictionary = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
            } },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
}

test "merge int" {
    try runTest("1b,0", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 0 },
        },
    });
    try runTest("1b,`int$()", .{
        .boolean_list = &.{
            .{ .boolean = true },
        },
    });
    try runTest("1b,0 1 0N 0W -0W", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
        },
    });

    try runTest("1,0", .{
        .int_list = &.{
            .{ .int = 1 },
            .{ .int = 0 },
        },
    });
    try runTest("1,`int$()", .{
        .int_list = &.{
            .{ .int = 1 },
        },
    });
    try runTest("1,0 1 0N 0W -0W", .{
        .int_list = &.{
            .{ .int = 1 },
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
        },
    });

    try runTest("1f,0", .{
        .list = &.{
            .{ .float = 1 },
            .{ .int = 0 },
        },
    });
    try runTest("1f,`int$()", .{
        .float_list = &.{
            .{ .float = 1 },
        },
    });
    try runTest("1f,0 1 0N 0W -0W", .{
        .list = &.{
            .{ .float = 1 },
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
        },
    });

    try runTest("\"a\",0", .{
        .list = &.{
            .{ .char = 'a' },
            .{ .int = 0 },
        },
    });
    try runTest("\"a\",`int$()", .{
        .char_list = &.{
            .{ .char = 'a' },
        },
    });
    try runTest("\"a\",0 1 0N 0W -0W", .{
        .list = &.{
            .{ .char = 'a' },
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
        },
    });

    try runTest("`symbol,0", .{
        .list = &.{
            .{ .symbol = "symbol" },
            .{ .int = 0 },
        },
    });
    try runTest("`symbol,`int$()", .{
        .symbol_list = &.{
            .{ .symbol = "symbol" },
        },
    });
    try runTest("`symbol,0 1 0N 0W -0W", .{
        .list = &.{
            .{ .symbol = "symbol" },
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
        },
    });

    try runTest("(),0", .{
        .int_list = &.{
            .{ .int = 0 },
        },
    });
    try runTest("(1b;2),0", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .int = 0 },
        },
    });
    try runTest("(1b;2;3f),0", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .int = 0 },
        },
    });
    try runTest("(1b;2;3f;`symbol),0", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .symbol = "symbol" },
            .{ .int = 0 },
        },
    });
    try runTest("(),`int$()", .{ .int_list = &.{} });
    try runTest("(),0 1 0N 0W -0W", .{
        .int_list = &.{
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
        },
    });
    try runTest("(1b;2;3;4;5),`int$()", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .int = 3 },
            .{ .int = 4 },
            .{ .int = 5 },
        },
    });
    try runTest("(1b;2;3;4;5),0 1 0N 0W -0W", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .int = 3 },
            .{ .int = 4 },
            .{ .int = 5 },
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
        },
    });
    try runTest("(1b;2;3f;4;5),0 1 0N 0W -0W", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .int = 4 },
            .{ .int = 5 },
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
        },
    });
    try runTest("(1b;2;3f;4),0 1 0N 0W -0W", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .int = 4 },
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
        },
    });
    try runTest("(1b;2;3f;4;\"a\"),0 1 0N 0W -0W", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .int = 4 },
            .{ .char = 'a' },
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
        },
    });
    try runTest("(1b;2;3f;4;`symbol),0 1 0N 0W -0W", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .int = 4 },
            .{ .symbol = "symbol" },
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
        },
    });

    try runTest("11111b,0", .{
        .list = &.{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .int = 0 },
        },
    });
    try runTest("11111b,`int$()", .{
        .boolean_list = &.{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTest("11111b,0 1 0N 0W -0W", .{
        .list = &.{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
        },
    });
    try runTest("11111b,0 1 0N 0W -0W 2", .{
        .list = &.{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
            .{ .int = 2 },
        },
    });

    try runTest("5 4 3 2 1,0", .{
        .int_list = &.{
            .{ .int = 5 },
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = 2 },
            .{ .int = 1 },
            .{ .int = 0 },
        },
    });
    try runTest("5 4 3 2 1,`int$()", .{
        .int_list = &.{
            .{ .int = 5 },
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = 2 },
            .{ .int = 1 },
        },
    });
    try runTest("5 4 3 2 1,0 1 0N 0W -0W", .{
        .int_list = &.{
            .{ .int = 5 },
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = 2 },
            .{ .int = 1 },
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
        },
    });
    try runTest("5 4 3 2 1,0 1 0N 0W -0W 2", .{
        .int_list = &.{
            .{ .int = 5 },
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = 2 },
            .{ .int = 1 },
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
            .{ .int = 2 },
        },
    });

    try runTest("5 4 3 2 1f,0", .{
        .list = &.{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
            .{ .int = 0 },
        },
    });
    try runTest("5 4 3 2 1f,`int$()", .{
        .float_list = &.{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
        },
    });
    try runTest("5 4 3 2 1f,0 1 0N 0W -0W", .{
        .list = &.{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
        },
    });
    try runTest("5 4 3 2 1f,0 1 0N 0W -0W 2", .{
        .list = &.{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
            .{ .int = 2 },
        },
    });

    try runTest("\"abcde\",0", .{
        .list = &.{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
            .{ .int = 0 },
        },
    });
    try runTest("\"abcde\",`int$()", .{
        .char_list = &.{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });
    try runTest("\"abcde\",0 1 0N 0W -0W", .{
        .list = &.{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
        },
    });
    try runTest("\"abcde\",0 1 0N 0W -0W 2", .{
        .list = &.{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
            .{ .int = 2 },
        },
    });

    try runTest("`a`b`c`d`e,0", .{
        .list = &.{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
            .{ .int = 0 },
        },
    });
    try runTest("`a`b`c`d`e,`int$()", .{
        .symbol_list = &.{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
        },
    });
    try runTest("`a`b`c`d`e,0 1 0N 0W -0W", .{
        .list = &.{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
        },
    });
    try runTest("`a`b`c`d`e,0 1 0N 0W -0W 2", .{
        .list = &.{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
            .{ .int = 2 },
        },
    });

    try runTestError("(`a`b!1 2),0", MergeError.incompatible_types);
    try runTestError("(`a`b!1 2),`int$()", MergeError.incompatible_types);
    try runTestError("(`a`b!1 2),0 1 0N 0W -0W", MergeError.incompatible_types);
    try runTestError("(`a`b!1 2),0 1 0N 0W -0W 2", MergeError.incompatible_types);

    try runTest("(+`a`b!(,1;,2)),0", .{
        .list = &.{
            .{ .dictionary = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
            } },
            .{ .int = 0 },
        },
    });
    try runTest("(+`a`b!(,1;,2)),`int$()", .{
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
    try runTest("(+`a`b!(,1;,2)),0 1 0N 0W -0W", .{
        .list = &.{
            .{ .dictionary = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
            } },
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
        },
    });
}

test "merge float" {
    try runTest("1b,0f", .{
        .list = &.{
            .{ .boolean = true },
            .{ .float = 0 },
        },
    });
    try runTest("1b,`float$()", .{
        .boolean_list = &.{
            .{ .boolean = true },
        },
    });
    try runTest("1b,0 1 0n 0w -0w", .{
        .list = &.{
            .{ .boolean = true },
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
        },
    });

    try runTest("1,0f", .{
        .list = &.{
            .{ .int = 1 },
            .{ .float = 0 },
        },
    });
    try runTest("1,`float$()", .{
        .int_list = &.{
            .{ .int = 1 },
        },
    });
    try runTest("1,0 1 0n 0w -0w", .{
        .list = &.{
            .{ .int = 1 },
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
        },
    });

    try runTest("1f,0f", .{
        .float_list = &.{
            .{ .float = 1 },
            .{ .float = 0 },
        },
    });
    try runTest("1f,`float$()", .{
        .float_list = &.{
            .{ .float = 1 },
        },
    });
    try runTest("1f,0 1 0n 0w -0w", .{
        .float_list = &.{
            .{ .float = 1 },
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
        },
    });

    try runTest("\"a\",0f", .{
        .list = &.{
            .{ .char = 'a' },
            .{ .float = 0 },
        },
    });
    try runTest("\"a\",`float$()", .{
        .char_list = &.{
            .{ .char = 'a' },
        },
    });
    try runTest("\"a\",0 1 0n 0w -0w", .{
        .list = &.{
            .{ .char = 'a' },
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
        },
    });

    try runTest("`symbol,0f", .{
        .list = &.{
            .{ .symbol = "symbol" },
            .{ .float = 0 },
        },
    });
    try runTest("`symbol,`float$()", .{
        .symbol_list = &.{
            .{ .symbol = "symbol" },
        },
    });
    try runTest("`symbol,0 1 0n 0w -0w", .{
        .list = &.{
            .{ .symbol = "symbol" },
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
        },
    });

    try runTest("(),0f", .{
        .float_list = &.{
            .{ .float = 0 },
        },
    });
    try runTest("(1b;2;3f),0f", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .float = 0 },
        },
    });
    try runTest("(1b;2;3f;`symbol),0f", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .symbol = "symbol" },
            .{ .float = 0 },
        },
    });
    try runTest("(),`float$()", .{ .float_list = &.{} });
    try runTest("(),0 1 0n 0w -0w", .{
        .float_list = &.{
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
        },
    });
    try runTest("(1b;2;3f;4;5),`float$()", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .int = 4 },
            .{ .int = 5 },
        },
    });
    try runTest("(1b;2;3f;4;5),0 1 0n 0w -0w", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .int = 4 },
            .{ .int = 5 },
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
        },
    });
    try runTest("(1b;2;3f;4),0 1 0n 0w -0w", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .int = 4 },
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
        },
    });
    try runTest("(1b;2;3f;4;\"a\"),0 1 0n 0w -0w", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .int = 4 },
            .{ .char = 'a' },
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
        },
    });
    try runTest("(1b;2;3f;4;`symbol),0 1 0n 0w -0w", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .int = 4 },
            .{ .symbol = "symbol" },
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
        },
    });

    try runTest("11111b,0f", .{
        .list = &.{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .float = 0 },
        },
    });
    try runTest("11111b,`float$()", .{
        .boolean_list = &.{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTest("11111b,0 1 0n 0w -0w", .{
        .list = &.{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
        },
    });
    try runTest("11111b,0 1 0n 0w -0w 2", .{
        .list = &.{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
            .{ .float = 2 },
        },
    });

    try runTest("5 4 3 2 1,0f", .{
        .list = &.{
            .{ .int = 5 },
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = 2 },
            .{ .int = 1 },
            .{ .float = 0 },
        },
    });
    try runTest("5 4 3 2 1,`float$()", .{
        .int_list = &.{
            .{ .int = 5 },
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = 2 },
            .{ .int = 1 },
        },
    });
    try runTest("5 4 3 2 1,0 1 0n 0w -0w", .{
        .list = &.{
            .{ .int = 5 },
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = 2 },
            .{ .int = 1 },
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
        },
    });
    try runTest("5 4 3 2 1,0 1 0n 0w -0w 2", .{
        .list = &.{
            .{ .int = 5 },
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = 2 },
            .{ .int = 1 },
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
            .{ .float = 2 },
        },
    });

    try runTest("5 4 3 2 1f,0f", .{
        .float_list = &.{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
            .{ .float = 0 },
        },
    });
    try runTest("5 4 3 2 1f,`float$()", .{
        .float_list = &.{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
        },
    });
    try runTest("5 4 3 2 1f,0 1 0n 0w -0w", .{
        .float_list = &.{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
        },
    });
    try runTest("5 4 3 2 1f,0 1 0n 0w -0w 2", .{
        .float_list = &.{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
            .{ .float = 2 },
        },
    });

    try runTest("\"abcde\",0f", .{
        .list = &.{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
            .{ .float = 0 },
        },
    });
    try runTest("\"abcde\",`float$()", .{
        .char_list = &.{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });
    try runTest("\"abcde\",0 1 0n 0w -0w", .{
        .list = &.{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
        },
    });
    try runTest("\"abcde\",0 1 0n 0w -0w 2", .{
        .list = &.{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
            .{ .float = 2 },
        },
    });

    try runTest("`a`b`c`d`e,0f", .{
        .list = &.{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
            .{ .float = 0 },
        },
    });
    try runTest("`a`b`c`d`e,`float$()", .{
        .symbol_list = &.{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
        },
    });
    try runTest("`a`b`c`d`e,0 1 0n 0w -0w", .{
        .list = &.{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
        },
    });
    try runTest("`a`b`c`d`e,0 1 0n 0w -0w 2", .{
        .list = &.{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
            .{ .float = 2 },
        },
    });

    try runTestError("(`a`b!1 2),0f", MergeError.incompatible_types);
    try runTestError("(`a`b!1 2),`float$()", MergeError.incompatible_types);
    try runTestError("(`a`b!1 2),0 1 0n 0w -0w", MergeError.incompatible_types);
    try runTestError("(`a`b!1 2),0 1 0w 0w -0w 2", MergeError.incompatible_types);

    try runTest("(+`a`b!(,1;,2)),0f", .{
        .list = &.{
            .{ .dictionary = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
            } },
            .{ .float = 0 },
        },
    });
    try runTest("(+`a`b!(,1;,2)),`float$()", .{
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
    try runTest("(+`a`b!(,1;,2)),0 1 0n 0w -0w", .{
        .list = &.{
            .{ .dictionary = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
            } },
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
        },
    });
}

test "merge char" {
    try runTest("1b,\"a\"", .{
        .list = &.{
            .{ .boolean = true },
            .{ .char = 'a' },
        },
    });
    try runTest("1b,\"\"", .{
        .boolean_list = &.{
            .{ .boolean = true },
        },
    });
    try runTest("1b,\"abcde\"", .{
        .list = &.{
            .{ .boolean = true },
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });

    try runTest("1,\"a\"", .{
        .list = &.{
            .{ .int = 1 },
            .{ .char = 'a' },
        },
    });
    try runTest("1,\"\"", .{
        .int_list = &.{
            .{ .int = 1 },
        },
    });
    try runTest("1,\"abcde\"", .{
        .list = &.{
            .{ .int = 1 },
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });

    try runTest("1f,\"a\"", .{
        .list = &.{
            .{ .float = 1 },
            .{ .char = 'a' },
        },
    });
    try runTest("1f,\"\"", .{
        .float_list = &.{
            .{ .float = 1 },
        },
    });
    try runTest("1f,\"abcde\"", .{
        .list = &.{
            .{ .float = 1 },
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });

    try runTest("\"1\",\"a\"", .{
        .char_list = &.{
            .{ .char = '1' },
            .{ .char = 'a' },
        },
    });
    try runTest("\"1\",\"\"", .{
        .char_list = &.{
            .{ .char = '1' },
        },
    });
    try runTest("\"1\",\"abcde\"", .{
        .char_list = &.{
            .{ .char = '1' },
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });

    try runTest("`symbol,\"a\"", .{
        .list = &.{
            .{ .symbol = "symbol" },
            .{ .char = 'a' },
        },
    });
    try runTest("`symbol,\"\"", .{
        .symbol_list = &.{
            .{ .symbol = "symbol" },
        },
    });
    try runTest("`symbol,\"abcde\"", .{
        .list = &.{
            .{ .symbol = "symbol" },
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });

    try runTest("(),\"a\"", .{
        .char_list = &.{
            .{ .char = 'a' },
        },
    });
    try runTest("(),\"\"", .{ .char_list = &.{} });
    try runTest("(),\"abcde\"", .{
        .char_list = &.{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });
    try runTest("(1b;2;3f),\"a\"", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .char = 'a' },
        },
    });
    try runTest("(1b;2;3f),\"\"", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
        },
    });
    try runTest("(1b;2;3f),\"abcde\"", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });
    try runTest("(1b;2;3f;`symbol),\"a\"", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .symbol = "symbol" },
            .{ .char = 'a' },
        },
    });
    try runTest("(1b;2;3f;`symbol),\"\"", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .symbol = "symbol" },
        },
    });
    try runTest("(1b;2;3f;`symbol),\"abcde\"", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .symbol = "symbol" },
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });

    try runTest("10011b,\"a\"", .{
        .list = &.{
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .char = 'a' },
        },
    });
    try runTest("10011b,\"\"", .{
        .boolean_list = &.{
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTest("10011b,\"abcde\"", .{
        .list = &.{
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });

    try runTest("5 4 3 2 1,\"a\"", .{
        .list = &.{
            .{ .int = 5 },
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = 2 },
            .{ .int = 1 },
            .{ .char = 'a' },
        },
    });
    try runTest("5 4 3 2 1,\"\"", .{
        .int_list = &.{
            .{ .int = 5 },
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = 2 },
            .{ .int = 1 },
        },
    });
    try runTest("5 4 3 2 1,\"abcde\"", .{
        .list = &.{
            .{ .int = 5 },
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = 2 },
            .{ .int = 1 },
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });

    try runTest("5 4 3 2 1f,\"a\"", .{
        .list = &.{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
            .{ .char = 'a' },
        },
    });
    try runTest("5 4 3 2 1f,\"\"", .{
        .float_list = &.{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
        },
    });
    try runTest("5 4 3 2 1f,\"abcde\"", .{
        .list = &.{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });

    try runTest("\"54321\",\"a\"", .{
        .char_list = &.{
            .{ .char = '5' },
            .{ .char = '4' },
            .{ .char = '3' },
            .{ .char = '2' },
            .{ .char = '1' },
            .{ .char = 'a' },
        },
    });
    try runTest("\"54321\",\"\"", .{
        .char_list = &.{
            .{ .char = '5' },
            .{ .char = '4' },
            .{ .char = '3' },
            .{ .char = '2' },
            .{ .char = '1' },
        },
    });
    try runTest("\"54321\",\"abcde\"", .{
        .char_list = &.{
            .{ .char = '5' },
            .{ .char = '4' },
            .{ .char = '3' },
            .{ .char = '2' },
            .{ .char = '1' },
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });

    try runTest("`a`b`c`d`e,\"a\"", .{
        .list = &.{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
            .{ .char = 'a' },
        },
    });
    try runTest("`a`b`c`d`e,\"\"", .{
        .symbol_list = &.{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
        },
    });
    try runTest("`a`b`c`d`e,\"abcde\"", .{
        .list = &.{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });

    try runTestError("(`a`b!1 2),\"a\"", MergeError.incompatible_types);
    try runTestError("(`a`b!1 2),\"\"", MergeError.incompatible_types);
    try runTestError("(`a`b!1 2),\"abcde\"", MergeError.incompatible_types);

    try runTest("(+`a`b!(,1;,2)),\"a\"", .{
        .list = &.{
            .{ .dictionary = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
            } },
            .{ .char = 'a' },
        },
    });
    try runTest("(+`a`b!(,1;,2)),\"\"", .{
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
    try runTest("(+`a`b!(,1;,2)),\"abcde\"", .{
        .list = &.{
            .{ .dictionary = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
            } },
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });
}

test "merge symbol" {
    try runTest("1b,`symbol", .{
        .list = &.{
            .{ .boolean = true },
            .{ .symbol = "symbol" },
        },
    });
    try runTest("1b,`$()", .{
        .boolean_list = &.{
            .{ .boolean = true },
        },
    });
    try runTest("1b,`a`b`c`d`e", .{
        .list = &.{
            .{ .boolean = true },
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
        },
    });

    try runTest("1,`symbol", .{
        .list = &.{
            .{ .int = 1 },
            .{ .symbol = "symbol" },
        },
    });
    try runTest("1,`$()", .{
        .int_list = &.{
            .{ .int = 1 },
        },
    });
    try runTest("1,`a`b`c`d`e", .{
        .list = &.{
            .{ .int = 1 },
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
        },
    });

    try runTest("1f,`symbol", .{
        .list = &.{
            .{ .float = 1 },
            .{ .symbol = "symbol" },
        },
    });
    try runTest("1f,`$()", .{
        .float_list = &.{
            .{ .float = 1 },
        },
    });
    try runTest("1f,`a`b`c`d`e", .{
        .list = &.{
            .{ .float = 1 },
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
        },
    });

    try runTest("\"a\",`symbol", .{
        .list = &.{
            .{ .char = 'a' },
            .{ .symbol = "symbol" },
        },
    });
    try runTest("\"a\",`$()", .{
        .char_list = &.{
            .{ .char = 'a' },
        },
    });
    try runTest("\"a\",`a`b`c`d`e", .{
        .list = &.{
            .{ .char = 'a' },
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
        },
    });

    try runTest("`symbol,`a", .{
        .symbol_list = &.{
            .{ .symbol = "symbol" },
            .{ .symbol = "a" },
        },
    });
    try runTest("`symbol,`$()", .{
        .symbol_list = &.{
            .{ .symbol = "symbol" },
        },
    });
    try runTest("`symbol,`a`b`c`d`e", .{
        .symbol_list = &.{
            .{ .symbol = "symbol" },
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
        },
    });

    try runTest("(),`symbol", .{
        .symbol_list = &.{
            .{ .symbol = "symbol" },
        },
    });
    try runTest("(),`$()", .{ .symbol_list = &.{} });
    try runTest("(),`a`b`c`d`e", .{
        .symbol_list = &.{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
        },
    });
    try runTest("(1b;2;3f),`symbol", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .symbol = "symbol" },
        },
    });
    try runTest("(1b;2;3f),`$()", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
        },
    });
    try runTest("(1b;2;3f),`a`b`c`d`e", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
        },
    });
    try runTest("(1b;2;3f;`symbol),`symbol", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .symbol = "symbol" },
            .{ .symbol = "symbol" },
        },
    });
    try runTest("(1b;2;3f;`symbol),`$()", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .symbol = "symbol" },
        },
    });
    try runTest("(1b;2;3f;`symbol),`a`b`c`d`e", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .symbol = "symbol" },
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
        },
    });

    try runTest("10011b,`symbol", .{
        .list = &.{
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .symbol = "symbol" },
        },
    });
    try runTest("10011b,`$()", .{
        .boolean_list = &.{
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTest("10011b,`a`b`c`d`e", .{
        .list = &.{
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
        },
    });

    try runTest("5 4 3 2 1,`symbol", .{
        .list = &.{
            .{ .int = 5 },
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = 2 },
            .{ .int = 1 },
            .{ .symbol = "symbol" },
        },
    });
    try runTest("5 4 3 2 1,`$()", .{
        .int_list = &.{
            .{ .int = 5 },
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = 2 },
            .{ .int = 1 },
        },
    });
    try runTest("5 4 3 2 1,`a`b`c`d`e", .{
        .list = &.{
            .{ .int = 5 },
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = 2 },
            .{ .int = 1 },
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
        },
    });

    try runTest("5 4 3 2 1f,`symbol", .{
        .list = &.{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
            .{ .symbol = "symbol" },
        },
    });
    try runTest("5 4 3 2 1f,`$()", .{
        .float_list = &.{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
        },
    });
    try runTest("5 4 3 2 1f,`a`b`c`d`e", .{
        .list = &.{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
        },
    });

    try runTest("\"54321\",`symbol", .{
        .list = &.{
            .{ .char = '5' },
            .{ .char = '4' },
            .{ .char = '3' },
            .{ .char = '2' },
            .{ .char = '1' },
            .{ .symbol = "symbol" },
        },
    });
    try runTest("\"54321\",`$()", .{
        .char_list = &.{
            .{ .char = '5' },
            .{ .char = '4' },
            .{ .char = '3' },
            .{ .char = '2' },
            .{ .char = '1' },
        },
    });
    try runTest("\"54321\",`a`b`c`d`e", .{
        .list = &.{
            .{ .char = '5' },
            .{ .char = '4' },
            .{ .char = '3' },
            .{ .char = '2' },
            .{ .char = '1' },
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
        },
    });

    try runTest("`5`4`3`2`1,`symbol", .{
        .symbol_list = &.{
            .{ .symbol = "5" },
            .{ .symbol = "4" },
            .{ .symbol = "3" },
            .{ .symbol = "2" },
            .{ .symbol = "1" },
            .{ .symbol = "symbol" },
        },
    });
    try runTest("`5`4`3`2`1,`$()", .{
        .symbol_list = &.{
            .{ .symbol = "5" },
            .{ .symbol = "4" },
            .{ .symbol = "3" },
            .{ .symbol = "2" },
            .{ .symbol = "1" },
        },
    });
    try runTest("`5`4`3`2`1,`a`b`c`d`e", .{
        .symbol_list = &.{
            .{ .symbol = "5" },
            .{ .symbol = "4" },
            .{ .symbol = "3" },
            .{ .symbol = "2" },
            .{ .symbol = "1" },
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
        },
    });

    try runTestError("(`a`b!1 2),`symbol", MergeError.incompatible_types);
    try runTestError("(`a`b!1 2),`$()", MergeError.incompatible_types);
    try runTestError("(`a`b!1 2),`a`b`c`d`e", MergeError.incompatible_types);

    try runTest("(+`a`b!(,1;,2)),`symbol", .{
        .list = &.{
            .{ .dictionary = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
            } },
            .{ .symbol = "symbol" },
        },
    });
    try runTest("(+`a`b!(,1;,2)),`$()", .{
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
    try runTest("(+`a`b!(,1;,2)),`a`b`c`d`e", .{
        .list = &.{
            .{ .dictionary = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
            } },
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
        },
    });
}

test "merge list" {
    try runTest("1b,()", .{
        .boolean_list = &.{
            .{ .boolean = true },
        },
    });
    try runTest("1b,(0b;1;0N;0W;-0W)", .{
        .list = &.{
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
        },
    });
    try runTest("1b,(0b;1;0N;0W;-0W;1f;0n;0w;-0w)", .{
        .list = &.{
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
        },
    });
    try runTest("1b,(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", .{
        .list = &.{
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
            .{ .char = 'a' },
        },
    });

    try runTest("1,()", .{
        .int_list = &.{
            .{ .int = 1 },
        },
    });
    try runTest("1,(0b;1;0N;0W;-0W)", .{
        .list = &.{
            .{ .int = 1 },
            .{ .boolean = false },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
        },
    });
    try runTest("1,(0b;1;0N;0W;-0W;1f;0n;0w;-0w)", .{
        .list = &.{
            .{ .int = 1 },
            .{ .boolean = false },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
        },
    });
    try runTest("1,(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", .{
        .list = &.{
            .{ .int = 1 },
            .{ .boolean = false },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
            .{ .char = 'a' },
        },
    });

    try runTest("1f,()", .{
        .float_list = &.{
            .{ .float = 1 },
        },
    });
    try runTest("1f,(0b;1;0N;0W;-0W)", .{
        .list = &.{
            .{ .float = 1 },
            .{ .boolean = false },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
        },
    });
    try runTest("1f,(0b;1;0N;0W;-0W;1f;0n;0w;-0w)", .{
        .list = &.{
            .{ .float = 1 },
            .{ .boolean = false },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
        },
    });
    try runTest("1f,(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", .{
        .list = &.{
            .{ .float = 1 },
            .{ .boolean = false },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
            .{ .char = 'a' },
        },
    });

    try runTest("\"a\",()", .{
        .char_list = &.{
            .{ .char = 'a' },
        },
    });
    try runTest("\"a\",(0b;1;0N;0W;-0W)", .{
        .list = &.{
            .{ .char = 'a' },
            .{ .boolean = false },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
        },
    });
    try runTest("\"a\",(0b;1;0N;0W;-0W;1f;0n;0w;-0w)", .{
        .list = &.{
            .{ .char = 'a' },
            .{ .boolean = false },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
        },
    });
    try runTest("\"a\",(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", .{
        .list = &.{
            .{ .char = 'a' },
            .{ .boolean = false },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
            .{ .char = 'a' },
        },
    });

    try runTest("`symbol,()", .{
        .symbol_list = &.{
            .{ .symbol = "symbol" },
        },
    });
    try runTest("`symbol,(0b;1;0N;0W;-0W)", .{
        .list = &.{
            .{ .symbol = "symbol" },
            .{ .boolean = false },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
        },
    });
    try runTest("`symbol,(0b;1;0N;0W;-0W;1f;0n;0w;-0w)", .{
        .list = &.{
            .{ .symbol = "symbol" },
            .{ .boolean = false },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
        },
    });
    try runTest("`symbol,(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", .{
        .list = &.{
            .{ .symbol = "symbol" },
            .{ .boolean = false },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
            .{ .char = 'a' },
        },
    });

    try runTest("(),()", .{ .list = &.{} });
    try runTest("(0N;0n),()", .{
        .list = &.{
            .{ .int = Value.null_int },
            .{ .float = Value.null_float },
        },
    });
    try runTest("(),(0N;0n)", .{
        .list = &.{
            .{ .int = Value.null_int },
            .{ .float = Value.null_float },
        },
    });
    try runTest("(1b;2),(1b;2)", .{
        .list = &.{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .boolean = true },
            .{ .int = 2 },
        },
    });
    try runTest("(1b;2f),(2f;1b)", .{
        .list = &.{
            .{ .boolean = true },
            .{ .float = 2 },
            .{ .float = 2 },
            .{ .boolean = true },
        },
    });
    try runTest("(2;3f),(2;3f)", .{
        .list = &.{
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .int = 2 },
            .{ .float = 3 },
        },
    });
    try runTest("(1b;(2;3f)),(0N;(0n;0N))", .{
        .list = &.{
            .{ .boolean = true },
            .{ .list = &.{
                .{ .int = 2 },
                .{ .float = 3 },
            } },
            .{ .int = Value.null_int },
            .{ .list = &.{
                .{ .float = Value.null_float },
                .{ .int = Value.null_int },
            } },
        },
    });
    try runTest("(0b;1;2;3;4;5;6;7;8;9),(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", .{
        .list = &.{
            .{ .boolean = false },
            .{ .int = 1 },
            .{ .int = 2 },
            .{ .int = 3 },
            .{ .int = 4 },
            .{ .int = 5 },
            .{ .int = 6 },
            .{ .int = 7 },
            .{ .int = 8 },
            .{ .int = 9 },
            .{ .boolean = false },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
            .{ .char = 'a' },
        },
    });

    try runTest("010b,()", .{
        .boolean_list = &.{
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
        },
    });
    try runTest("01b,(0b;0N)", .{
        .list = &.{
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .int = Value.null_int },
        },
    });
    try runTest("010b,(0b;0N;0n)", .{
        .list = &.{
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .int = Value.null_int },
            .{ .float = Value.null_float },
        },
    });
    try runTest("0101010101b,(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", .{
        .list = &.{
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
            .{ .char = 'a' },
        },
    });

    try runTest("0 1 2,()", .{
        .int_list = &.{
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = 2 },
        },
    });
    try runTest("0 1,(0b;0N)", .{
        .list = &.{
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .boolean = false },
            .{ .int = Value.null_int },
        },
    });
    try runTest("0 1 2,(0b;0N;0n)", .{
        .list = &.{
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = 2 },
            .{ .boolean = false },
            .{ .int = Value.null_int },
            .{ .float = Value.null_float },
        },
    });
    try runTest("0 1 2 3 4 5 6 7 8 9,(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", .{
        .list = &.{
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
            .{ .boolean = false },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
            .{ .char = 'a' },
        },
    });

    try runTest("0 1 2f,()", .{
        .float_list = &.{
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = 2 },
        },
    });
    try runTest("0 1 2f,(0b;0N;0n)", .{
        .list = &.{
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = 2 },
            .{ .boolean = false },
            .{ .int = Value.null_int },
            .{ .float = Value.null_float },
        },
    });
    try runTest("0 1 2 3 4 5 6 7 8 9f,(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", .{
        .list = &.{
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = 2 },
            .{ .float = 3 },
            .{ .float = 4 },
            .{ .float = 5 },
            .{ .float = 6 },
            .{ .float = 7 },
            .{ .float = 8 },
            .{ .float = 9 },
            .{ .boolean = false },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
            .{ .char = 'a' },
        },
    });

    try runTest("\"abcde\",()", .{
        .char_list = &.{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });
    try runTest("\"abcde\",(0b;0N;0n)", .{
        .list = &.{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
            .{ .boolean = false },
            .{ .int = Value.null_int },
            .{ .float = Value.null_float },
        },
    });
    try runTest("\"abcde\",(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", .{
        .list = &.{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
            .{ .boolean = false },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
            .{ .char = 'a' },
        },
    });

    try runTest("`a`b`c`d`e,()", .{
        .symbol_list = &.{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
        },
    });
    try runTest("`a`b`c`d`e,(0b;0N;0n)", .{
        .list = &.{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
            .{ .boolean = false },
            .{ .int = Value.null_int },
            .{ .float = Value.null_float },
        },
    });
    try runTest("`a`b`c`d`e,(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", .{
        .list = &.{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
            .{ .boolean = false },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
            .{ .char = 'a' },
        },
    });

    try runTest("(`a`b!1 2),()", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .int_list = &.{
                .{ .int = 1 },
                .{ .int = 2 },
            } },
        },
    });
    try runTestError("(`a`b!1 2),(0b;0N;0n)", MergeError.incompatible_types);
    try runTestError("(`a`b!1 2),(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", MergeError.incompatible_types);

    try runTest("(+`a`b!(,1;,2)),()", .{
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
    try runTest("(+`a`b!(,1;,2)),(0b;0N;0n)", .{
        .list = &.{
            .{ .dictionary = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
            } },
            .{ .boolean = false },
            .{ .int = Value.null_int },
            .{ .float = Value.null_float },
        },
    });
    try runTest("(+`a`b!(,1;,2)),(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", .{
        .list = &.{
            .{ .dictionary = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
            } },
            .{ .boolean = false },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
            .{ .char = 'a' },
        },
    });
}

test "merge dictionary" {
    try runTestError("1b,`a`b!1 2", MergeError.incompatible_types);

    try runTestError("1,`a`b!1 2", MergeError.incompatible_types);

    try runTestError("1f,`a`b!1 2", MergeError.incompatible_types);

    try runTestError("\"a\",`a`b!1 2", MergeError.incompatible_types);

    try runTestError("`symbol,`a`b!1 2", MergeError.incompatible_types);

    try runTest("(),`a`b!1 2", .{ .dictionary = &.{
        .{ .symbol_list = &.{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
        } },
        .{ .int_list = &.{
            .{ .int = 1 },
            .{ .int = 2 },
        } },
    } });

    try runTestError("010b,`a`b!1 2", MergeError.incompatible_types);

    try runTestError("0 1 2,`a`b!1 2", MergeError.incompatible_types);

    try runTestError("0 1 2f,`a`b!1 2", MergeError.incompatible_types);

    try runTestError("\"abcde\",`a`b!1 2", MergeError.incompatible_types);

    try runTestError("`a`b`c`d`e,`a`b!1 2", MergeError.incompatible_types);

    try runTest("(`a`b!1 2),`a`b!1 2", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .int_list = &.{
                .{ .int = 1 },
                .{ .int = 2 },
            } },
        },
    });
    try runTest("(`a`b!1 2),`a`b!3 4", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .int_list = &.{
                .{ .int = 3 },
                .{ .int = 4 },
            } },
        },
    });
    try runTest("(`a`b!1 2),`c`d!3 4", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
                .{ .symbol = "c" },
                .{ .symbol = "d" },
            } },
            .{ .int_list = &.{
                .{ .int = 1 },
                .{ .int = 2 },
                .{ .int = 3 },
                .{ .int = 4 },
            } },
        },
    });
    try runTest("((`a;`b;1)!1 2 3),1 2!4 5", .{ .dictionary = &.{
        .{ .list = &.{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .int = 1 },
            .{ .int = 2 },
        } },
        .{ .int_list = &.{
            .{ .int = 1 },
            .{ .int = 2 },
            .{ .int = 4 },
            .{ .int = 5 },
        } },
    } });

    try runTest("(+`a`b!(,1;,2)),`a`b!1 2", .{
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
    try runTest("(+`a`b!(,1;,2)),`a`b!3 4", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 1 },
                    .{ .int = 3 },
                } },
                .{ .int_list = &.{
                    .{ .int = 2 },
                    .{ .int = 4 },
                } },
            } },
        },
    });
    try runTestError("(+`a`b!(,1;,2)),`c`d!3 4", MergeError.incompatible_types);
    try runTest("(+`b`a!(,2;,1)),`a`b!1 2", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "b" },
                .{ .symbol = "a" },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 2 },
                    .{ .int = 2 },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                    .{ .int = 1 },
                } },
            } },
        },
    });
}

test "merge table" {
    try runTest("1b,+`a`b!(,1;,2)", .{
        .list = &.{
            .{ .boolean = true },
            .{ .dictionary = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
            } },
        },
    });

    try runTest("1,+`a`b!(,1;,2)", .{
        .list = &.{
            .{ .int = 1 },
            .{ .dictionary = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
            } },
        },
    });

    try runTest("1f,+`a`b!(,1;,2)", .{
        .list = &.{
            .{ .float = 1 },
            .{ .dictionary = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
            } },
        },
    });

    try runTest("\"a\",+`a`b!(,1;,2)", .{
        .list = &.{
            .{ .char = 'a' },
            .{ .dictionary = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
            } },
        },
    });

    try runTest("`symbol,+`a`b!(,1;,2)", .{
        .list = &.{
            .{ .symbol = "symbol" },
            .{ .dictionary = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
            } },
        },
    });

    try runTest("(),+`a`b!(,1;,2)", .{
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
    try runTest("(0b;1;2f),+`a`b!(,1;,2)", .{
        .list = &.{
            .{ .boolean = false },
            .{ .int = 1 },
            .{ .float = 2 },
            .{ .dictionary = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
            } },
        },
    });

    try runTest("(`boolean$()),+`a`b!(,1;,2)", .{
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
    try runTest("010b,+`a`b!(,1;,2)", .{
        .list = &.{
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .dictionary = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
            } },
        },
    });

    try runTest("(`int$()),+`a`b!(,1;,2)", .{
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
    try runTest("0 1 2,+`a`b!(,1;,2)", .{
        .list = &.{
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = 2 },
            .{ .dictionary = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
            } },
        },
    });

    try runTest("(`float$()),+`a`b!(,1;,2)", .{
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
    try runTest("0 1 2f,+`a`b!(,1;,2)", .{
        .list = &.{
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = 2 },
            .{ .dictionary = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
            } },
        },
    });

    try runTest("\"\",+`a`b!(,1;,2)", .{
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
    try runTest("\"abcde\",+`a`b!(,1;,2)", .{
        .list = &.{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
            .{ .dictionary = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
            } },
        },
    });

    try runTest("(`$()),+`a`b!(,1;,2)", .{
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
    try runTest("`a`b`c`d`e,+`a`b!(,1;,2)", .{
        .list = &.{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
            .{ .dictionary = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
            } },
        },
    });

    try runTest("(`a`b!1 2),+`a`b!(,3;,4)", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 1 },
                    .{ .int = 3 },
                } },
                .{ .int_list = &.{
                    .{ .int = 2 },
                    .{ .int = 4 },
                } },
            } },
        },
    });
    try runTest("(`a`b!1 2),+`b`a!(,4;,3)", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 1 },
                    .{ .int = 3 },
                } },
                .{ .int_list = &.{
                    .{ .int = 2 },
                    .{ .int = 4 },
                } },
            } },
        },
    });
    try runTest("(`b`a!2 1),+`a`b!(,3;,4)", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "b" },
                .{ .symbol = "a" },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 2 },
                    .{ .int = 4 },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                    .{ .int = 3 },
                } },
            } },
        },
    });
    try runTestError("(`a`b!(1;2)),+`c`d!(,3;,4)", MergeError.incompatible_types);

    try runTest("(+`a`b!(,1;,2)),+`a`b!(,3;,4)", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 1 },
                    .{ .int = 3 },
                } },
                .{ .int_list = &.{
                    .{ .int = 2 },
                    .{ .int = 4 },
                } },
            } },
        },
    });
    try runTest("(+`a`b!(,1;,2)),+`b`a!(,4;,3)", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 1 },
                    .{ .int = 3 },
                } },
                .{ .int_list = &.{
                    .{ .int = 2 },
                    .{ .int = 4 },
                } },
            } },
        },
    });
    try runTest("(+`b`a!(,2;,1)),+`a`b!(,3;,4)", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "b" },
                .{ .symbol = "a" },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 2 },
                    .{ .int = 4 },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                    .{ .int = 3 },
                } },
            } },
        },
    });
    try runTestError("(+`a`b!(,1;,2)),+`c`d!(,3;,4)", MergeError.incompatible_types);
}
