const value_mod = @import("../../value.zig");
const Value = value_mod.Value;

const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;
const runTestError = vm_mod.runTestError;
const TestValue = vm_mod.TestValue;

const LessError = @import("../../verbs/less.zig").LessError;

test "less boolean" {
    try runTest("1b>0b", .{ .boolean = true });
    try runTest("1b>`boolean$()", .{ .boolean_list = &.{} });
    try runTest("1b>00000b", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });

    try runTest("1>0b", .{ .boolean = true });
    try runTest("1>`boolean$()", .{ .boolean_list = &.{} });
    try runTest("1>00000b", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });

    try runTest("1f>0b", .{ .boolean = true });
    try runTest("1f>`boolean$()", .{ .boolean_list = &.{} });
    try runTest("1f>00000b", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });

    try runTestError("\"a\">0b", LessError.incompatible_types);
    try runTestError("\"a\">`boolean$()", LessError.incompatible_types);
    try runTestError("\"a\">00000b", LessError.incompatible_types);

    try runTestError("`symbol>0b", LessError.incompatible_types);
    try runTestError("`symbol>`boolean$()", LessError.incompatible_types);
    try runTestError("`symbol>00000b", LessError.incompatible_types);

    try runTest("()>0b", .{ .list = &.{} });
    try runTest("(1b;2)>0b", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTest("(1b;2;3f)>0b", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTest("(1b;2;3f;(0b;1))>0b", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = false },
                .{ .boolean = true },
            } },
        },
    });
    try runTestError("(1b;2;3f;`symbol)>0b", LessError.incompatible_types);
    try runTest("()>`boolean$()", .{ .list = &.{} });
    try runTestError("()>010b", LessError.length_mismatch);
    try runTestError("(1b;2)>`boolean$()", LessError.length_mismatch);
    try runTest("(1b;2)>01b", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTest("(1b;2;3f)>010b", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTestError("(1b;2;3f)>0101b", LessError.length_mismatch);
    try runTestError("(1b;2;3f;\"a\")>0101b", LessError.incompatible_types);
    try runTestError("(1b;2;3f;`symbol)>0101b", LessError.incompatible_types);

    try runTest("11111b>0b", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTestError("11111b>`boolean$()", LessError.length_mismatch);
    try runTest("11111b>00000b", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTestError("11111b>000000b", LessError.length_mismatch);

    try runTest("5 4 3 2 1>0b", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTestError("5 4 3 2 1>`boolean$()", LessError.length_mismatch);
    try runTest("5 4 3 2 1>00000b", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTestError("5 4 3 2 1>000000b", LessError.length_mismatch);

    try runTest("5 4 3 2 1f>0b", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTestError("5 4 3 2 1f>`boolean$()", LessError.length_mismatch);
    try runTest("5 4 3 2 1f>00000b", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTestError("5 4 3 2 1f>000000b", LessError.length_mismatch);

    try runTestError("\"abcde\">0b", LessError.incompatible_types);
    try runTestError("\"abcde\">`boolean$()", LessError.incompatible_types);
    try runTestError("\"abcde\">00000b", LessError.incompatible_types);
    try runTestError("\"abcde\">000000b", LessError.incompatible_types);

    try runTestError("`a`b`c`d`e>0b", LessError.incompatible_types);
    try runTestError("`a`b`c`d`e>`boolean$()", LessError.incompatible_types);
    try runTestError("`a`b`c`d`e>00000b", LessError.incompatible_types);
    try runTestError("`a`b`c`d`e>000000b", LessError.incompatible_types);

    try runTest("(()!())>0b", .{
        .dictionary = &[_]TestValue{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("(`a`b!1 2)>0b", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = true },
                .{ .boolean = true },
            } },
        },
    });
    try runTestError("(`a`b!1 2)>`boolean$()", LessError.length_mismatch);
    try runTest("(`a`b!1 2)>01b", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = true },
                .{ .boolean = true },
            } },
        },
    });
    try runTestError("(`a`b!1 2)>010b", LessError.length_mismatch);

    try runTest("(+`a`b!(,1;,2))>0b", .{
        .table = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .boolean_list = &[_]TestValue{
                    .{ .boolean = true },
                } },
                .{ .boolean_list = &[_]TestValue{
                    .{ .boolean = true },
                } },
            } },
        },
    });
    try runTestError("(+`a`b!(,1;,`symbol))>0b", LessError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))>`boolean$()", LessError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))>01b", LessError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))>010b", LessError.incompatible_types);
}

test "less int" {
    try runTest("1b>0", .{ .boolean = true });
    try runTest("1b>`int$()", .{ .boolean_list = &.{} });
    try runTest("1b>0 1 2 3 4", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });

    try runTest("1>0", .{ .boolean = true });
    try runTest("1>`int$()", .{ .boolean_list = &.{} });
    try runTest("1>0 1 2 3 4", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });

    try runTest("1f>0", .{ .boolean = true });
    try runTest("1f>`int$()", .{ .boolean_list = &.{} });
    try runTest("1f>0 1 2 3 4", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });

    try runTestError("\"a\">0", LessError.incompatible_types);
    try runTestError("\"a\">`int$()", LessError.incompatible_types);
    try runTestError("\"a\">0 1 2 3 4", LessError.incompatible_types);

    try runTestError("`symbol>0", LessError.incompatible_types);
    try runTestError("`symbol>`int$()", LessError.incompatible_types);
    try runTestError("`symbol>0 1 2 3 4", LessError.incompatible_types);

    try runTest("()>0", .{ .list = &.{} });
    try runTest("(1b;2)>0", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTest("(1b;2;3f)>0", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTest("(1b;2;3f;(0b;1))>0", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = false },
                .{ .boolean = true },
            } },
        },
    });
    try runTestError("(1b;2;3f;`symbol)>0", LessError.incompatible_types);
    try runTest("()>`int$()", .{ .list = &.{} });
    try runTestError("()>0 1 2", LessError.length_mismatch);
    try runTestError("(1b;2)>`int$()", LessError.length_mismatch);
    try runTest("(1b;2)>0 1", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTest("(1b;2;3f)>0 1 2", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTestError("(1b;2;3f)>0 1 2 3", LessError.length_mismatch);
    try runTestError("(1b;2;3f;\"a\")>0 1 2 3", LessError.incompatible_types);
    try runTestError("(1b;2;3f;`symbol)>0 1 2 3", LessError.incompatible_types);

    try runTest("11111b>0", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTestError("11111b>`int$()", LessError.length_mismatch);
    try runTest("11111b>0 1 2 3 4", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTestError("11111b>0 1 2 3 4 5", LessError.length_mismatch);

    try runTest("5 4 3 2 1>0", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTestError("5 4 3 2 1>`int$()", LessError.length_mismatch);
    try runTest("5 4 3 2 1>0 1 2 3 4", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTestError("5 4 3 2 1>0 1 2 3 4 5", LessError.length_mismatch);

    try runTest("5 4 3 2 1f>0", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTestError("5 4 3 2 1f>`int$()", LessError.length_mismatch);
    try runTest("5 4 3 2 1f>0 1 2 3 4", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTestError("5 4 3 2 1f>0 1 2 3 4 5", LessError.length_mismatch);

    try runTestError("\"abcde\">0", LessError.incompatible_types);
    try runTestError("\"abcde\">`int$()", LessError.incompatible_types);
    try runTestError("\"abcde\">0 1 2 3 4", LessError.incompatible_types);
    try runTestError("\"abcde\">0 1 2 3 4 5", LessError.incompatible_types);

    try runTestError("`a`b`c`d`e>0", LessError.incompatible_types);
    try runTestError("`a`b`c`d`e>`int$()", LessError.incompatible_types);
    try runTestError("`a`b`c`d`e>0 1 2 3 4", LessError.incompatible_types);
    try runTestError("`a`b`c`d`e>0 1 2 3 4 5", LessError.incompatible_types);

    try runTest("(()!())>0", .{
        .dictionary = &[_]TestValue{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("(`a`b!1 2)>0", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = true },
                .{ .boolean = true },
            } },
        },
    });
    try runTestError("(`a`b!1 2)>`int$()", LessError.length_mismatch);
    try runTest("(`a`b!1 2)>0 1", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = true },
                .{ .boolean = true },
            } },
        },
    });
    try runTestError("(`a`b!1 2)>0 1 2", LessError.length_mismatch);

    try runTest("(+`a`b!(,1;,2))>0", .{
        .table = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .boolean_list = &[_]TestValue{
                    .{ .boolean = true },
                } },
                .{ .boolean_list = &[_]TestValue{
                    .{ .boolean = true },
                } },
            } },
        },
    });
    try runTestError("(+`a`b!(,1;,`symbol))>0", LessError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))>`int$()", LessError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))>0 1", LessError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))>0 1 2", LessError.incompatible_types);
}

test "less float" {
    try runTest("1b>0f", .{ .boolean = true });
    try runTest("1b>`float$()", .{ .boolean_list = &.{} });
    try runTest("1b>0 1 2 3 4f", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });

    try runTest("1>0f", .{ .boolean = true });
    try runTest("1>`float$()", .{ .boolean_list = &.{} });
    try runTest("1>0 1 2 3 4f", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });

    try runTest("1f>0f", .{ .boolean = true });
    try runTest("1f>`float$()", .{ .boolean_list = &.{} });
    try runTest("1f>0 1 2 3 4f", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });

    try runTestError("\"a\">0f", LessError.incompatible_types);
    try runTestError("\"a\">`float$()", LessError.incompatible_types);
    try runTestError("\"a\">0 1 2 3 4f", LessError.incompatible_types);

    try runTestError("`symbol>0f", LessError.incompatible_types);
    try runTestError("`symbol>`float$()", LessError.incompatible_types);
    try runTestError("`symbol>0 1 2 3 4f", LessError.incompatible_types);

    try runTest("()>0f", .{ .list = &.{} });
    try runTest("(1b;2)>0f", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTest("(1b;2;3f)>0f", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTest("(1b;2;3f;(0b;1))>0f", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = false },
                .{ .boolean = true },
            } },
        },
    });
    try runTestError("(1b;2;3f;`symbol)>0f", LessError.incompatible_types);
    try runTest("()>`float$()", .{ .list = &.{} });
    try runTestError("()>0 1 2f", LessError.length_mismatch);
    try runTestError("(1b;2)>`float$()", LessError.length_mismatch);
    try runTest("(1b;2)>0 1f", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTest("(1b;2;3f)>0 1 2f", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTestError("(1b;2;3f)>0 1 2 3f", LessError.length_mismatch);
    try runTestError("(1b;2;3f;\"a\")>0 1 2 3f", LessError.incompatible_types);
    try runTestError("(1b;2;3f;`symbol)>0 1 2 3f", LessError.incompatible_types);

    try runTest("11111b>0f", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTestError("11111b>`float$()", LessError.length_mismatch);
    try runTest("11111b>0 1 2 3 4f", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTestError("11111b>0 1 2 3 4 5f", LessError.length_mismatch);

    try runTest("5 4 3 2 1>0f", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTestError("5 4 3 2 1>`float$()", LessError.length_mismatch);
    try runTest("5 4 3 2 1>0 1 2 3 4f", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTestError("5 4 3 2 1>0 1 2 3 4 5f", LessError.length_mismatch);

    try runTest("5 4 3 2 1f>0f", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTestError("5 4 3 2 1f>`float$()", LessError.length_mismatch);
    try runTest("5 4 3 2 1f>0 1 2 3 4f", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTestError("5 4 3 2 1f>0 1 2 3 4 5f", LessError.length_mismatch);

    try runTestError("\"abcde\">0f", LessError.incompatible_types);
    try runTestError("\"abcde\">`float$()", LessError.incompatible_types);
    try runTestError("\"abcde\">0 1 2 3 4f", LessError.incompatible_types);
    try runTestError("\"abcde\">0 1 2 3 4 5f", LessError.incompatible_types);

    try runTestError("`a`b`c`d`e>0f", LessError.incompatible_types);
    try runTestError("`a`b`c`d`e>`float$()", LessError.incompatible_types);
    try runTestError("`a`b`c`d`e>0 1 2 3 4f", LessError.incompatible_types);
    try runTestError("`a`b`c`d`e>0 1 2 3 4 5f", LessError.incompatible_types);

    try runTest("(()!())>0f", .{
        .dictionary = &[_]TestValue{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("(`a`b!1 2)>0f", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = true },
                .{ .boolean = true },
            } },
        },
    });
    try runTestError("(`a`b!1 2)>`float$()", LessError.length_mismatch);
    try runTest("(`a`b!1 2)>0 1f", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = true },
                .{ .boolean = true },
            } },
        },
    });
    try runTestError("(`a`b!1 2)>0 1 2f", LessError.length_mismatch);

    try runTest("(+`a`b!(,1;,2))>0f", .{
        .table = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .boolean_list = &[_]TestValue{
                    .{ .boolean = true },
                } },
                .{ .boolean_list = &[_]TestValue{
                    .{ .boolean = true },
                } },
            } },
        },
    });
    try runTestError("(+`a`b!(,1;,`symbol))>0f", LessError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))>`float$()", LessError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))>0 1f", LessError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))>0 1 2f", LessError.incompatible_types);
}

test "less char" {
    try runTestError("1b>\"a\"", LessError.incompatible_types);
    try runTestError("1b>\"\"", LessError.incompatible_types);
    try runTestError("1b>\"abcde\"", LessError.incompatible_types);

    try runTestError("1>\"a\"", LessError.incompatible_types);
    try runTestError("1>\"\"", LessError.incompatible_types);
    try runTestError("1>\"abcde\"", LessError.incompatible_types);

    try runTestError("1f>\"a\"", LessError.incompatible_types);
    try runTestError("1f>\"\"", LessError.incompatible_types);
    try runTestError("1f>\"abcde\"", LessError.incompatible_types);

    try runTestError("\"1\">\"a\"", LessError.incompatible_types);
    try runTestError("\"1\">\"\"", LessError.incompatible_types);
    try runTestError("\"1\">\"abcde\"", LessError.incompatible_types);

    try runTestError("`symbol>\"a\"", LessError.incompatible_types);
    try runTestError("`symbol>\"\"", LessError.incompatible_types);
    try runTestError("`symbol>\"abcde\"", LessError.incompatible_types);

    try runTestError("()>\"a\"", LessError.incompatible_types);
    try runTestError("()>\"\"", LessError.incompatible_types);
    try runTestError("()>\"abcde\"", LessError.incompatible_types);

    try runTestError("10011b>\"a\"", LessError.incompatible_types);
    try runTestError("10011b>\"\"", LessError.incompatible_types);
    try runTestError("10011b>\"abcde\"", LessError.incompatible_types);

    try runTestError("5 4 3 2 1>\"a\"", LessError.incompatible_types);
    try runTestError("5 4 3 2 1>\"\"", LessError.incompatible_types);
    try runTestError("5 4 3 2 1>\"abcde\"", LessError.incompatible_types);

    try runTestError("5 4 3 2 1f>\"a\"", LessError.incompatible_types);
    try runTestError("5 4 3 2 1f>\"\"", LessError.incompatible_types);
    try runTestError("5 4 3 2 1f>\"abcde\"", LessError.incompatible_types);

    try runTestError("\"54321\">\"a\"", LessError.incompatible_types);
    try runTestError("\"54321\">\"\"", LessError.incompatible_types);
    try runTestError("\"54321\">\"abcde\"", LessError.incompatible_types);

    try runTestError("`a`b`c`d`e>\"a\"", LessError.incompatible_types);
    try runTestError("`a`b`c`d`e>\"\"", LessError.incompatible_types);
    try runTestError("`a`b`c`d`e>\"abcde\"", LessError.incompatible_types);

    try runTestError("(`a`b!1 2)>\"a\"", LessError.incompatible_types);
    try runTestError("(`a`b!1 2)>\"\"", LessError.incompatible_types);
    try runTestError("(`a`b!1 2)>\"ab\"", LessError.incompatible_types);

    try runTestError("(+`a`b!(,1;,2))>\"a\"", LessError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))>\"\"", LessError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))>\"ab\"", LessError.incompatible_types);
}

test "less symbol" {
    try runTestError("1b>`symbol", LessError.incompatible_types);
    try runTestError("1b>`$()", LessError.incompatible_types);
    try runTestError("1b>`a`b`c`d`e", LessError.incompatible_types);

    try runTestError("1>`symbol", LessError.incompatible_types);
    try runTestError("1>`$()", LessError.incompatible_types);
    try runTestError("1>`a`b`c`d`e", LessError.incompatible_types);

    try runTestError("1f>`symbol", LessError.incompatible_types);
    try runTestError("1f>`$()", LessError.incompatible_types);
    try runTestError("1f>`a`b`c`d`e", LessError.incompatible_types);

    try runTestError("\"a\">`symbol", LessError.incompatible_types);
    try runTestError("\"a\">`$()", LessError.incompatible_types);
    try runTestError("\"a\">`a`b`c`d`e", LessError.incompatible_types);

    try runTestError("`symbol>`a", LessError.incompatible_types);
    try runTestError("`symbol>`$()", LessError.incompatible_types);
    try runTestError("`symbol>`a`b`c`d`e", LessError.incompatible_types);

    try runTestError("()>`symbol", LessError.incompatible_types);
    try runTestError("()>`$()", LessError.incompatible_types);
    try runTestError("()>`a`b`c`d`e", LessError.incompatible_types);

    try runTestError("10011b>`symbol", LessError.incompatible_types);
    try runTestError("10011b>`$()", LessError.incompatible_types);
    try runTestError("10011b>`a`b`c`d`e", LessError.incompatible_types);

    try runTestError("5 4 3 2 1>`symbol", LessError.incompatible_types);
    try runTestError("5 4 3 2 1>`$()", LessError.incompatible_types);
    try runTestError("5 4 3 2 1>`a`b`c`d`e", LessError.incompatible_types);

    try runTestError("5 4 3 2 1f>`symbol", LessError.incompatible_types);
    try runTestError("5 4 3 2 1f>`$()", LessError.incompatible_types);
    try runTestError("5 4 3 2 1f>`a`b`c`d`e", LessError.incompatible_types);

    try runTestError("\"54321\">`symbol", LessError.incompatible_types);
    try runTestError("\"54321\">`$()", LessError.incompatible_types);
    try runTestError("\"54321\">`a`b`c`d`e", LessError.incompatible_types);

    try runTestError("`5`4`3`2`1>`symbol", LessError.incompatible_types);
    try runTestError("`5`4`3`2`1>`$()", LessError.incompatible_types);
    try runTestError("`5`4`3`2`1>`a`b`c`d`e", LessError.incompatible_types);

    try runTestError("(`a`b!1 2)>`symbol", LessError.incompatible_types);
    try runTestError("(`a`b!1 2)>`$()", LessError.incompatible_types);
    try runTestError("(`a`b!1 2)>`a`b", LessError.incompatible_types);

    try runTestError("(+`a`b!(,1;,2))>`symbol", LessError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))>`$()", LessError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))>`a`b", LessError.incompatible_types);
}

test "less list" {
    try runTest("1b>()", .{ .list = &.{} });
    try runTest("1b>(0b;1;0N;0W;-0W)", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = true },
        },
    });
    try runTest("1b>(0b;1;0N;0W;-0W;1f;0n;0w;-0w)", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = true },
        },
    });
    try runTestError("1b>(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", LessError.incompatible_types);
    try runTestError("1b>(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", LessError.incompatible_types);

    try runTest("1>()", .{ .list = &.{} });
    try runTest("1>(0b;1;0N;0W;-0W)", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = true },
        },
    });
    try runTest("1>(0b;1;0N;0W;-0W;1f;0n;0w;-0w)", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = true },
        },
    });
    try runTestError("1>(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", LessError.incompatible_types);
    try runTestError("1>(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", LessError.incompatible_types);

    try runTest("1f>()", .{ .list = &.{} });
    try runTest("1f>(0b;1;0N;0W;-0W;1f;0n;0w;-0w)", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = true },
        },
    });
    try runTestError("1f>(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", LessError.incompatible_types);
    try runTestError("1f>(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", LessError.incompatible_types);

    try runTestError("\"a\">()", LessError.incompatible_types);

    try runTestError("`symbol>()", LessError.incompatible_types);

    try runTest("()>()", .{ .list = &.{} });
    try runTestError("(0N;0n)>()", LessError.length_mismatch);
    try runTestError("()>(0N;0n)", LessError.length_mismatch);
    try runTest("(1b;2)>(1b;2)", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTest("(1b;2f)>(2f;1b)", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = true },
        },
    });
    try runTest("(2;3f)>(2;3f)", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTest("(1b;(2;3f))>(0N;(0n;0N))", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = true },
                .{ .boolean = true },
            } },
        },
    });
    try runTestError("(0b;1;2;3;4;5;6;7;8;9)>(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", LessError.incompatible_types);
    try runTestError("(0b;1;2;3;4;5;6;7;8;9)>(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", LessError.incompatible_types);

    try runTestError("010b>()", LessError.length_mismatch);
    try runTest("01b>(0b;0N)", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = true },
        },
    });
    try runTest("010b>(0b;0N;0n)", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTestError("0101010101b>(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", LessError.incompatible_types);
    try runTestError("0101010101b>(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", LessError.incompatible_types);

    try runTestError("0 1 2>()", LessError.length_mismatch);
    try runTest("0 1>(0b;0N)", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = true },
        },
    });
    try runTest("0 1 2>(0b;0N;0n)", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTestError("0 1 2 3 4 5 6 7 8 9>(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", LessError.incompatible_types);
    try runTestError("0 1 2 3 4 5 6 7 8 9>(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", LessError.incompatible_types);

    try runTestError("0 1 2f>()", LessError.length_mismatch);
    try runTest("0 1 2f>(0b;0N;0n)", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTestError("0 1 2 3 4 5 6 7 8 9f>(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", LessError.incompatible_types);
    try runTestError("0 1 2 3 4 5 6 7 8 9f>(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", LessError.incompatible_types);

    try runTestError("\"abcde\">()", LessError.incompatible_types);

    try runTestError("`a`b`c`d`e>()", LessError.incompatible_types);

    try runTestError("(`a`b!1 2)>()", LessError.length_mismatch);
    try runTest("(`a`b!1 2)>(1;2f)", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = false },
                .{ .boolean = false },
            } },
        },
    });
    try runTestError("(`a`b!1 2)>(0b;1;2f)", LessError.length_mismatch);

    try runTestError("(+`a`b!(,1;,2))>()", LessError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))>(1;2f)", LessError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))>(0b;1;2f)", LessError.incompatible_types);
}

test "less dictionary" {
    try runTest("1b>()!()", .{
        .dictionary = &[_]TestValue{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("1b>`a`b!1 2", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = false },
                .{ .boolean = false },
            } },
        },
    });

    try runTest("1>()!()", .{
        .dictionary = &[_]TestValue{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("1>`a`b!1 2", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = false },
                .{ .boolean = false },
            } },
        },
    });

    try runTest("1f>()!()", .{
        .dictionary = &[_]TestValue{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("1f>`a`b!1 2", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = false },
                .{ .boolean = false },
            } },
        },
    });

    try runTestError("\"a\">`a`b!1 2", LessError.incompatible_types);

    try runTestError("`symbol>`a`b!1 2", LessError.incompatible_types);

    try runTest("()>()!()", .{
        .dictionary = &[_]TestValue{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTestError("()>`a`b!1 2", LessError.length_mismatch);
    try runTest("(1;2f)>`a`b!1 2", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = false },
                .{ .boolean = false },
            } },
        },
    });
    try runTestError("(0b;1;2f)>`a`b!1 2", LessError.length_mismatch);

    try runTest("(`boolean$())>()!()", .{
        .dictionary = &[_]TestValue{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTestError("(`boolean$())>`a`b!1 2", LessError.length_mismatch);
    try runTest("10b>`a`b!1 2", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = false },
                .{ .boolean = false },
            } },
        },
    });
    try runTestError("101b>`a`b!1 2", LessError.length_mismatch);

    try runTest("(`int$())>()!()", .{
        .dictionary = &[_]TestValue{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTestError("(`int$())>`a`b!1 2", LessError.length_mismatch);
    try runTest("1 2>`a`b!1 2", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = false },
                .{ .boolean = false },
            } },
        },
    });
    try runTestError("1 2 3>`a`b!1 2", LessError.length_mismatch);

    try runTest("(`float$())>()!()", .{
        .dictionary = &[_]TestValue{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTestError("(`float$())>`a`b!1 2", LessError.length_mismatch);
    try runTest("1 2f>`a`b!1 2", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = false },
                .{ .boolean = false },
            } },
        },
    });
    try runTestError("1 2 3f>`a`b!1 2", LessError.length_mismatch);

    try runTestError("\"\">`a`b!1 2", LessError.incompatible_types);
    try runTestError("\"12\">`a`b!1 2", LessError.incompatible_types);
    try runTestError("\"123\">`a`b!1 2", LessError.incompatible_types);

    try runTestError("(`$())>`a`b!1 2", LessError.incompatible_types);
    try runTestError("`5`4>`a`b!1 2", LessError.incompatible_types);
    try runTestError("`5`4`3>`a`b!1 2", LessError.incompatible_types);

    try runTest("(()!())>()!()", .{
        .dictionary = &[_]TestValue{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("(()!())>`a`b!1 2", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .list = &.{} },
                .{ .list = &.{} },
            } },
        },
    });
    try runTest("(`a`b!1 2)>()!()", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .list = &.{} },
                .{ .list = &.{} },
            } },
        },
    });
    try runTest("(`a`b!1 2)>`a`b!1 2", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = false },
                .{ .boolean = false },
            } },
        },
    });
    try runTest("(`b`a!1 2)>`a`b!1 2", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "b" },
                .{ .symbol = "a" },
            } },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = false },
                .{ .boolean = true },
            } },
        },
    });
    try runTest("(`a`b!1 2)>`b`a!1 2", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = false },
                .{ .boolean = true },
            } },
        },
    });
    try runTest("(`a`b!1 2)>`c`d!1 2", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
                .{ .symbol = "c" },
                .{ .symbol = "d" },
            } },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = true },
                .{ .boolean = true },
                .{ .boolean = false },
                .{ .boolean = false },
            } },
        },
    });
    try runTest("(`a`b!0N 0W)>`c`d!0N 0W", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
                .{ .symbol = "c" },
                .{ .symbol = "d" },
            } },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = false },
                .{ .boolean = true },
                .{ .boolean = false },
                .{ .boolean = false },
            } },
        },
    });
    try runTestError("(`a`b!1 2)>`a`b!(1;\"2\")", LessError.incompatible_types);

    try runTestError("(+`a`b!(,1;,2))>`a`b!1 2", LessError.incompatible_types);
}

test "less table" {
    try runTest("1b>+`a`b!(,1;,2)", .{
        .table = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .boolean_list = &[_]TestValue{
                    .{ .boolean = false },
                } },
                .{ .boolean_list = &[_]TestValue{
                    .{ .boolean = false },
                } },
            } },
        },
    });

    try runTest("1>+`a`b!(,1;,2)", .{
        .table = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .boolean_list = &[_]TestValue{
                    .{ .boolean = false },
                } },
                .{ .boolean_list = &[_]TestValue{
                    .{ .boolean = false },
                } },
            } },
        },
    });

    try runTest("1f>+`a`b!(,1;,2)", .{
        .table = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .boolean_list = &[_]TestValue{
                    .{ .boolean = false },
                } },
                .{ .boolean_list = &[_]TestValue{
                    .{ .boolean = false },
                } },
            } },
        },
    });

    try runTestError("\"a\">+`a`b!(,1;,2)", LessError.incompatible_types);

    try runTestError("`symbol>+`a`b!(,1;,2)", LessError.incompatible_types);

    try runTestError("()>+`a`b!(,1;,2)", LessError.incompatible_types);
    try runTestError("(1;2f)>+`a`b!(,1;,2)", LessError.incompatible_types);
    try runTestError("(0b;1;2f)>+`a`b!(,1;,2)", LessError.incompatible_types);

    try runTestError("(`boolean$())>+`a`b!(,1;,2)", LessError.incompatible_types);
    try runTestError("10b>+`a`b!(,1;,2)", LessError.incompatible_types);
    try runTestError("101b>+`a`b!(,1;,2)", LessError.incompatible_types);

    try runTestError("(`int$())>+`a`b!(,1;,2)", LessError.incompatible_types);
    try runTestError("1 2>+`a`b!(,1;,2)", LessError.incompatible_types);
    try runTestError("1 2 3>+`a`b!(,1;,2)", LessError.incompatible_types);

    try runTestError("(`float$())>+`a`b!(,1;,2)", LessError.incompatible_types);
    try runTestError("1 2f>+`a`b!(,1;,2)", LessError.incompatible_types);
    try runTestError("1 2 3f>+`a`b!(,1;,2)", LessError.incompatible_types);

    try runTestError("\"\">+`a`b!(,1;,2)", LessError.incompatible_types);
    try runTestError("\"12\">+`a`b!(,1;,2)", LessError.incompatible_types);
    try runTestError("\"123\">+`a`b!(,1;,2)", LessError.incompatible_types);

    try runTestError("(`$())>+`a`b!(,1;,2)", LessError.incompatible_types);
    try runTestError("`5`4>+`a`b!(,1;,2)", LessError.incompatible_types);
    try runTestError("`5`4`3>+`a`b!(,1;,2)", LessError.incompatible_types);

    try runTestError("(`a`b!1 2)>+`a`b!(,1;,2)", LessError.incompatible_types);

    try runTest("(+`a`b!(,1;,2))>+`a`b!(,1;,2)", .{
        .table = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .boolean_list = &[_]TestValue{
                    .{ .boolean = false },
                } },
                .{ .boolean_list = &[_]TestValue{
                    .{ .boolean = false },
                } },
            } },
        },
    });
    try runTest("(+`b`a!(,1;,2))>+`a`b!(,1;,2)", .{
        .table = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "b" },
                .{ .symbol = "a" },
            } },
            .{ .list = &[_]TestValue{
                .{ .boolean_list = &[_]TestValue{
                    .{ .boolean = false },
                } },
                .{ .boolean_list = &[_]TestValue{
                    .{ .boolean = true },
                } },
            } },
        },
    });
    try runTest("(+`a`b!(,1;,2))>+`b`a!(,1;,2)", .{
        .table = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .boolean_list = &[_]TestValue{
                    .{ .boolean = false },
                } },
                .{ .boolean_list = &[_]TestValue{
                    .{ .boolean = true },
                } },
            } },
        },
    });
    try runTestError("(+`a`b!(,1;,2))>+`a`b!(,1;,`symbol)", LessError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))>+`a`b!(1 1;2 2)", LessError.length_mismatch);
    try runTestError("(+`a`b!(,1;,2))>+`a`b`c!(,1;,2;,3)", LessError.length_mismatch);
    try runTestError("(+`a`b`c!(,1;,2;,3))>+`a`b!(,1;,2)", LessError.length_mismatch);
}
