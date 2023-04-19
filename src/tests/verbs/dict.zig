const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;
const runTestError = vm_mod.runTestError;

const DictError = @import("../../verbs/dict.zig").DictError;

test "dict boolean" {
    try runTestError("1b!0b", DictError.incompatible_types);
    try runTestError("1b!`boolean$()", DictError.incompatible_types);
    try runTestError("1b!01b", DictError.incompatible_types);

    try runTestError("1!0b", DictError.incompatible_types);
    try runTestError("1!`boolean$()", DictError.incompatible_types);
    try runTestError("1!01b", DictError.incompatible_types);

    try runTestError("1f!0b", DictError.incompatible_types);
    try runTestError("1f!`boolean$()", DictError.incompatible_types);
    try runTestError("1f!01b", DictError.incompatible_types);

    try runTestError("\"a\"!0b", DictError.incompatible_types);
    try runTestError("\"a\"!`boolean$()", DictError.incompatible_types);
    try runTestError("\"a\"!01b", DictError.incompatible_types);

    try runTestError("`symbol!0b", DictError.incompatible_types);
    try runTestError("`symbol!`boolean$()", DictError.incompatible_types);
    try runTestError("`symbol!01b", DictError.incompatible_types);

    try runTestError("()!0b", DictError.incompatible_types);
    try runTest("()!`boolean$()", .{
        .dictionary = &.{
            .{ .list = &.{} },
            .{ .boolean_list = &.{} },
        },
    });
    try runTestError("()!01b", DictError.length_mismatch);
    try runTestError("(1b;2)!0b", DictError.incompatible_types);
    try runTestError("(1b;2)!`boolean$()", DictError.length_mismatch);
    try runTest("(1b;2)!01b", .{
        .dictionary = &.{
            .{ .list = &.{
                .{ .boolean = true },
                .{ .int = 2 },
            } },
            .{ .boolean_list = &.{
                .{ .boolean = false },
                .{ .boolean = true },
            } },
        },
    });

    try runTestError("(`boolean$())!0b", DictError.incompatible_types);
    try runTestError("11111b!0b", DictError.incompatible_types);
    try runTest("(`boolean$())!`boolean$()", .{
        .dictionary = &.{
            .{ .boolean_list = &.{} },
            .{ .boolean_list = &.{} },
        },
    });
    try runTestError("11111b!`boolean$()", DictError.length_mismatch);
    try runTest("11111b!00000b", .{
        .dictionary = &.{
            .{ .boolean_list = &.{
                .{ .boolean = true },
                .{ .boolean = true },
                .{ .boolean = true },
                .{ .boolean = true },
                .{ .boolean = true },
            } },
            .{ .boolean_list = &.{
                .{ .boolean = false },
                .{ .boolean = false },
                .{ .boolean = false },
                .{ .boolean = false },
                .{ .boolean = false },
            } },
        },
    });
    try runTestError("11111b!000000b", DictError.length_mismatch);

    try runTestError("(`int$())!0b", DictError.incompatible_types);
    try runTestError("5 4 3 2 1!0b", DictError.incompatible_types);
    try runTest("(`int$())!`boolean$()", .{
        .dictionary = &.{
            .{ .int_list = &.{} },
            .{ .boolean_list = &.{} },
        },
    });
    try runTestError("5 4 3 2 1!`boolean$()", DictError.length_mismatch);
    try runTest("5 4 3 2 1!00000b", .{
        .dictionary = &.{
            .{ .int_list = &.{
                .{ .int = 5 },
                .{ .int = 4 },
                .{ .int = 3 },
                .{ .int = 2 },
                .{ .int = 1 },
            } },
            .{ .boolean_list = &.{
                .{ .boolean = false },
                .{ .boolean = false },
                .{ .boolean = false },
                .{ .boolean = false },
                .{ .boolean = false },
            } },
        },
    });
    try runTestError("5 4 3 2 1!000000b", DictError.length_mismatch);

    try runTestError("(`float$())!0b", DictError.incompatible_types);
    try runTestError("5 4 3 2 1f!0b", DictError.incompatible_types);
    try runTest("(`float$())!`boolean$()", .{
        .dictionary = &.{
            .{ .float_list = &.{} },
            .{ .boolean_list = &.{} },
        },
    });
    try runTestError("5 4 3 2 1f!`boolean$()", DictError.length_mismatch);
    try runTest("5 4 3 2 1f!00000b", .{
        .dictionary = &.{
            .{ .float_list = &.{
                .{ .float = 5 },
                .{ .float = 4 },
                .{ .float = 3 },
                .{ .float = 2 },
                .{ .float = 1 },
            } },
            .{ .boolean_list = &.{
                .{ .boolean = false },
                .{ .boolean = false },
                .{ .boolean = false },
                .{ .boolean = false },
                .{ .boolean = false },
            } },
        },
    });
    try runTestError("5 4 3 2 1f!000000b", DictError.length_mismatch);

    try runTestError("\"\"!0b", DictError.incompatible_types);
    try runTestError("\"abcde\"!0b", DictError.incompatible_types);
    try runTest("\"\"!`boolean$()", .{
        .dictionary = &.{
            .{ .char_list = &.{} },
            .{ .boolean_list = &.{} },
        },
    });
    try runTestError("\"abcde\"!`boolean$()", DictError.length_mismatch);
    try runTest("\"abcde\"!00000b", .{
        .dictionary = &.{
            .{ .char_list = &.{
                .{ .char = 'a' },
                .{ .char = 'b' },
                .{ .char = 'c' },
                .{ .char = 'd' },
                .{ .char = 'e' },
            } },
            .{ .boolean_list = &.{
                .{ .boolean = false },
                .{ .boolean = false },
                .{ .boolean = false },
                .{ .boolean = false },
                .{ .boolean = false },
            } },
        },
    });
    try runTestError("\"abcde\"!000000b", DictError.length_mismatch);

    try runTestError("(`$())!0b", DictError.incompatible_types);
    try runTestError("`a`b`c`d`e!0b", DictError.incompatible_types);
    try runTest("(`$())!`boolean$()", .{
        .dictionary = &.{
            .{ .symbol_list = &.{} },
            .{ .boolean_list = &.{} },
        },
    });
    try runTestError("`a`b`c`d`e!`boolean$()", DictError.length_mismatch);
    try runTest("`a`b`c`d`e!00000b", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
                .{ .symbol = "c" },
                .{ .symbol = "d" },
                .{ .symbol = "e" },
            } },
            .{ .boolean_list = &.{
                .{ .boolean = false },
                .{ .boolean = false },
                .{ .boolean = false },
                .{ .boolean = false },
                .{ .boolean = false },
            } },
        },
    });
    try runTestError("`a`b`c`d`e!000000b", DictError.length_mismatch);

    try runTestError("(()!())!0b", DictError.incompatible_types);
    try runTestError("(()!())!`boolean$()", DictError.incompatible_types);
    try runTestError("(()!())!01b", DictError.incompatible_types);
    try runTestError("(`a`b!1 2)!0b", DictError.incompatible_types);
    try runTestError("(`a`b!1 2)!`boolean$()", DictError.incompatible_types);
    try runTestError("(`a`b!1 2)!01b", DictError.incompatible_types);

    try runTestError("(+`a`b!(();()))!0b", DictError.incompatible_types);
    try runTestError("(+`a`b!(();()))!`boolean$()", DictError.incompatible_types);
    try runTestError("(+`a`b!(();()))!01b", DictError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))!0b", DictError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))!`boolean$()", DictError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))!01b", DictError.incompatible_types);
}

test "dict int" {
    try runTestError("1b!0", DictError.incompatible_types);
    try runTestError("1b!`int$()", DictError.incompatible_types);
    try runTestError("1b!0 1", DictError.incompatible_types);

    try runTestError("1!0", DictError.incompatible_types);
    try runTestError("1!`int$()", DictError.incompatible_types);
    try runTestError("1!0 1", DictError.incompatible_types);

    try runTestError("1f!0", DictError.incompatible_types);
    try runTestError("1f!`int$()", DictError.incompatible_types);
    try runTestError("1f!0 1", DictError.incompatible_types);

    try runTestError("\"a\"!0", DictError.incompatible_types);
    try runTestError("\"a\"!`int$()", DictError.incompatible_types);
    try runTestError("\"a\"!0 1", DictError.incompatible_types);

    try runTestError("`symbol!0", DictError.incompatible_types);
    try runTestError("`symbol!`int$()", DictError.incompatible_types);
    try runTestError("`symbol!0 1", DictError.incompatible_types);

    try runTestError("()!0", DictError.incompatible_types);
    try runTest("()!`int$()", .{
        .dictionary = &.{
            .{ .list = &.{} },
            .{ .int_list = &.{} },
        },
    });
    try runTestError("()!0 1", DictError.length_mismatch);
    try runTestError("(1b;2)!0", DictError.incompatible_types);
    try runTestError("(1b;2)!`int$()", DictError.length_mismatch);
    try runTest("(1b;2)!0 1", .{
        .dictionary = &.{
            .{ .list = &.{
                .{ .boolean = true },
                .{ .int = 2 },
            } },
            .{ .int_list = &.{
                .{ .int = 0 },
                .{ .int = 1 },
            } },
        },
    });

    try runTestError("(`boolean$())!0", DictError.incompatible_types);
    try runTestError("11111b!0", DictError.incompatible_types);
    try runTest("(`boolean$())!`int$()", .{
        .dictionary = &.{
            .{ .boolean_list = &.{} },
            .{ .int_list = &.{} },
        },
    });
    try runTestError("11111b!`int$()", DictError.length_mismatch);
    try runTest("11111b!0 1 2 3 4", .{
        .dictionary = &.{
            .{ .boolean_list = &.{
                .{ .boolean = true },
                .{ .boolean = true },
                .{ .boolean = true },
                .{ .boolean = true },
                .{ .boolean = true },
            } },
            .{ .int_list = &.{
                .{ .int = 0 },
                .{ .int = 1 },
                .{ .int = 2 },
                .{ .int = 3 },
                .{ .int = 4 },
            } },
        },
    });
    try runTestError("11111b!0 1 2 3 4 5", DictError.length_mismatch);

    try runTestError("(`int$())!0", DictError.incompatible_types);
    try runTestError("5 4 3 2 1!0", DictError.incompatible_types);
    try runTest("(`int$())!`int$()", .{
        .dictionary = &.{
            .{ .int_list = &.{} },
            .{ .int_list = &.{} },
        },
    });
    try runTestError("5 4 3 2 1!`int$()", DictError.length_mismatch);
    try runTest("5 4 3 2 1!0 1 2 3 4", .{
        .dictionary = &.{
            .{ .int_list = &.{
                .{ .int = 5 },
                .{ .int = 4 },
                .{ .int = 3 },
                .{ .int = 2 },
                .{ .int = 1 },
            } },
            .{ .int_list = &.{
                .{ .int = 0 },
                .{ .int = 1 },
                .{ .int = 2 },
                .{ .int = 3 },
                .{ .int = 4 },
            } },
        },
    });
    try runTestError("5 4 3 2 1!0 1 2 3 4 5", DictError.length_mismatch);

    try runTestError("(`float$())!0", DictError.incompatible_types);
    try runTestError("5 4 3 2 1f!0", DictError.incompatible_types);
    try runTest("(`float$())!`int$()", .{
        .dictionary = &.{
            .{ .float_list = &.{} },
            .{ .int_list = &.{} },
        },
    });
    try runTestError("5 4 3 2 1f!`int$()", DictError.length_mismatch);
    try runTest("5 4 3 2 1f!0 1 2 3 4", .{
        .dictionary = &.{
            .{ .float_list = &.{
                .{ .float = 5 },
                .{ .float = 4 },
                .{ .float = 3 },
                .{ .float = 2 },
                .{ .float = 1 },
            } },
            .{ .int_list = &.{
                .{ .int = 0 },
                .{ .int = 1 },
                .{ .int = 2 },
                .{ .int = 3 },
                .{ .int = 4 },
            } },
        },
    });
    try runTestError("5 4 3 2 1f!0 1 2 3 4 5", DictError.length_mismatch);

    try runTestError("\"\"!0", DictError.incompatible_types);
    try runTestError("\"abcde\"!0", DictError.incompatible_types);
    try runTest("\"\"!`int$()", .{
        .dictionary = &.{
            .{ .char_list = &.{} },
            .{ .int_list = &.{} },
        },
    });
    try runTestError("\"abcde\"!`int$()", DictError.length_mismatch);
    try runTest("\"abcde\"!0 1 2 3 4", .{
        .dictionary = &.{
            .{ .char_list = &.{
                .{ .char = 'a' },
                .{ .char = 'b' },
                .{ .char = 'c' },
                .{ .char = 'd' },
                .{ .char = 'e' },
            } },
            .{ .int_list = &.{
                .{ .int = 0 },
                .{ .int = 1 },
                .{ .int = 2 },
                .{ .int = 3 },
                .{ .int = 4 },
            } },
        },
    });
    try runTestError("\"abcde\"!0 1 2 3 4 5", DictError.length_mismatch);

    try runTestError("(`$())!0", DictError.incompatible_types);
    try runTestError("`a`b`c`d`e!0", DictError.incompatible_types);
    try runTest("(`$())!`int$()", .{
        .dictionary = &.{
            .{ .symbol_list = &.{} },
            .{ .int_list = &.{} },
        },
    });
    try runTestError("`a`b`c`d`e!`int$()", DictError.length_mismatch);
    try runTest("`a`b`c`d`e!0 1 2 3 4", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
                .{ .symbol = "c" },
                .{ .symbol = "d" },
                .{ .symbol = "e" },
            } },
            .{ .int_list = &.{
                .{ .int = 0 },
                .{ .int = 1 },
                .{ .int = 2 },
                .{ .int = 3 },
                .{ .int = 4 },
            } },
        },
    });
    try runTestError("`a`b`c`d`e!0 1 2 3 4 5", DictError.length_mismatch);

    try runTestError("(()!())!0", DictError.incompatible_types);
    try runTestError("(()!())!`int$()", DictError.incompatible_types);
    try runTestError("(()!())!0 1", DictError.incompatible_types);
    try runTestError("(`a`b!1 2)!0", DictError.incompatible_types);
    try runTestError("(`a`b!1 2)!`int$()", DictError.incompatible_types);
    try runTestError("(`a`b!1 2)!0 1", DictError.incompatible_types);

    try runTestError("(+`a`b!(();()))!0", DictError.incompatible_types);
    try runTestError("(+`a`b!(();()))!`int$()", DictError.incompatible_types);
    try runTestError("(+`a`b!(();()))!0 1", DictError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))!0", DictError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))!`int$()", DictError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))!0 1", DictError.incompatible_types);
}

test "dict float" {
    if (true) return error.SkipZigTest;
    try runTest("1b!0f", .{ .boolean = false });
    try runTest("1b!`float$()", .{ .boolean = false });
    try runTest("1b!0 1 2 3 4f", .{ .boolean = false });

    try runTest("1!0f", .{ .boolean = false });
    try runTest("1!`float$()", .{ .boolean = false });
    try runTest("1!0 1 2 3 4f", .{ .boolean = false });

    try runTest("1f!0f", .{ .boolean = false });
    try runTest("1f!`float$()", .{ .boolean = false });
    try runTest("1f!0 1 2 3 4f", .{ .boolean = false });

    try runTest("\"a\"!0f", .{ .boolean = false });
    try runTest("\"a\"!`float$()", .{ .boolean = false });
    try runTest("\"a\"!0 1 2 3 4f", .{ .boolean = false });

    try runTest("`symbol!0f", .{ .boolean = false });
    try runTest("`symbol!`float$()", .{ .boolean = false });
    try runTest("`symbol!0 1 2 3 4f", .{ .boolean = false });

    try runTest("()!0f", .{ .boolean = false });
    try runTest("(1b;2)!0f", .{ .boolean = false });
    try runTest("(1b;2;3f)!0f", .{ .boolean = false });
    try runTest("(1b;2;3f;(0b;1))!0f", .{ .boolean = false });
    try runTest("(1b;2;3f;`symbol)!0f", .{ .boolean = false });
    try runTest("()!`float$()", .{ .boolean = false });
    try runTest("()!0 1 2f", .{ .boolean = false });
    try runTest("(1b;2)!`float$()", .{ .boolean = false });
    try runTest("(1b;2)!0 1f", .{ .boolean = false });
    try runTest("(1b;2;3f)!0 1 2f", .{ .boolean = false });
    try runTest("(1b;2;3f)!0 1 2 3f", .{ .boolean = false });
    try runTest("(1b;2;3f;\"a\")!0 1 2 3f", .{ .boolean = false });
    try runTest("(1b;2;3f;`symbol)!0 1 2 3f", .{ .boolean = false });

    try runTest("(`boolean$())!0f", .{ .boolean = false });
    try runTest("11111b!0f", .{ .boolean = false });
    try runTest("(`boolean$())!`float$()", .{ .boolean = false });
    try runTest("11111b!`float$()", .{ .boolean = false });
    try runTest("11111b!0 1 2 3 4f", .{ .boolean = false });
    try runTest("11111b!0 1 2 3 4 5f", .{ .boolean = false });

    try runTest("(`int$())!0f", .{ .boolean = false });
    try runTest("5 4 3 2 1!0f", .{ .boolean = false });
    try runTest("(`int$())!`float$()", .{ .boolean = false });
    try runTest("5 4 3 2 1!`float$()", .{ .boolean = false });
    try runTest("5 4 3 2 1!0 1 2 3 4f", .{ .boolean = false });
    try runTest("5 4 3 2 1!0 1 2 3 4 5f", .{ .boolean = false });

    try runTest("(`float$())!0f", .{ .boolean = false });
    try runTest("5 4 3 2 1f!0f", .{ .boolean = false });
    try runTest("(`float$())!`float$()", .{ .boolean = true });
    try runTest("5 4 3 2 1f!`float$()", .{ .boolean = false });
    try runTest("5 4 3 2 1f!0 1 2 3 4f", .{ .boolean = false });
    try runTest("5 4 3 2 1f!0 1 2 3 4 5f", .{ .boolean = false });

    try runTest("\"\"!0f", .{ .boolean = false });
    try runTest("\"abcde\"!0f", .{ .boolean = false });
    try runTest("\"\"!`float$()", .{ .boolean = false });
    try runTest("\"abcde\"!`float$()", .{ .boolean = false });
    try runTest("\"abcde\"!0 1 2 3 4f", .{ .boolean = false });
    try runTest("\"abcde\"!0 1 2 3 4 5f", .{ .boolean = false });

    try runTest("(`$())!0f", .{ .boolean = false });
    try runTest("`a`b`c`d`e!0f", .{ .boolean = false });
    try runTest("(`$())!`float$()", .{ .boolean = false });
    try runTest("`a`b`c`d`e!`float$()", .{ .boolean = false });
    try runTest("`a`b`c`d`e!0 1 2 3 4f", .{ .boolean = false });
    try runTest("`a`b`c`d`e!0 1 2 3 4 5f", .{ .boolean = false });

    try runTest("(()!())!0f", .{ .boolean = false });
    try runTest("(()!())!`float$()", .{ .boolean = false });
    try runTest("(`a`b!1 2)!0f", .{ .boolean = false });
    try runTest("(`a`b!1 2)!`float$()", .{ .boolean = false });
    try runTest("(`a`b!1 2)!0 1f", .{ .boolean = false });
    try runTest("(`a`b!1 2)!0 1 2f", .{ .boolean = false });

    try runTest("(+`a`b!(();()))!0f", .{ .boolean = false });
    try runTest("(+`a`b!(();()))!`float$()", .{ .boolean = false });
    try runTest("(+`a`b!(();()))!0 1f", .{ .boolean = false });
    try runTest("(+`a`b!(`int$();`float$()))!0f", .{ .boolean = false });
    try runTest("(+`a`b!(`int$();`float$()))!`float$()", .{ .boolean = false });
    try runTest("(+`a`b!(`int$();`float$()))!0 1f", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))!0", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,`symbol))!0f", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))!`float$()", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))!0 1f", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))!0 1 2f", .{ .boolean = false });
}

test "dict char" {
    if (true) return error.SkipZigTest;
    try runTest("1b!\"a\"", .{ .boolean = false });
    try runTest("1b!\"\"", .{ .boolean = false });
    try runTest("1b!\"abcde\"", .{ .boolean = false });

    try runTest("1!\"a\"", .{ .boolean = false });
    try runTest("1!\"\"", .{ .boolean = false });
    try runTest("1!\"abcde\"", .{ .boolean = false });

    try runTest("1f!\"a\"", .{ .boolean = false });
    try runTest("1f!\"\"", .{ .boolean = false });
    try runTest("1f!\"abcde\"", .{ .boolean = false });

    try runTest("\"1\"!\"a\"", .{ .boolean = false });
    try runTest("\"1\"!\"\"", .{ .boolean = false });
    try runTest("\"1\"!\"abcde\"", .{ .boolean = false });

    try runTest("`symbol!\"a\"", .{ .boolean = false });
    try runTest("`symbol!\"\"", .{ .boolean = false });
    try runTest("`symbol!\"abcde\"", .{ .boolean = false });

    try runTest("()!\"a\"", .{ .boolean = false });
    try runTest("()!\"\"", .{ .boolean = false });
    try runTest("()!\"abcde\"", .{ .boolean = false });

    try runTest("10011b!\"a\"", .{ .boolean = false });
    try runTest("10011b!\"\"", .{ .boolean = false });
    try runTest("10011b!\"abcde\"", .{ .boolean = false });

    try runTest("5 4 3 2 1!\"a\"", .{ .boolean = false });
    try runTest("5 4 3 2 1!\"\"", .{ .boolean = false });
    try runTest("5 4 3 2 1!\"abcde\"", .{ .boolean = false });

    try runTest("5 4 3 2 1f!\"a\"", .{ .boolean = false });
    try runTest("5 4 3 2 1f!\"\"", .{ .boolean = false });
    try runTest("5 4 3 2 1f!\"abcde\"", .{ .boolean = false });

    try runTest("\"54321\"!\"a\"", .{ .boolean = false });
    try runTest("\"54321\"!\"\"", .{ .boolean = false });
    try runTest("\"54321\"!\"abcde\"", .{ .boolean = false });

    try runTest("`a`b`c`d`e!\"a\"", .{ .boolean = false });
    try runTest("`a`b`c`d`e!\"\"", .{ .boolean = false });
    try runTest("`a`b`c`d`e!\"abcde\"", .{ .boolean = false });

    try runTest("(`a`b!1 2)!\"a\"", .{ .boolean = false });
    try runTest("(`a`b!1 2)!\"\"", .{ .boolean = false });
    try runTest("(`a`b!1 2)!\"ab\"", .{ .boolean = false });

    try runTest("(+`a`b!(,1;,2))!\"a\"", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))!\"\"", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))!\"ab\"", .{ .boolean = false });
}

test "dict symbol" {
    if (true) return error.SkipZigTest;
    try runTest("1b!`symbol", .{ .boolean = false });
    try runTest("1b!`$()", .{ .boolean = false });
    try runTest("1b!`a`b`c`d`e", .{ .boolean = false });

    try runTest("1!`symbol", .{ .boolean = false });
    try runTest("1!`$()", .{ .boolean = false });
    try runTest("1!`a`b`c`d`e", .{ .boolean = false });

    try runTest("1f!`symbol", .{ .boolean = false });
    try runTest("1f!`$()", .{ .boolean = false });
    try runTest("1f!`a`b`c`d`e", .{ .boolean = false });

    try runTest("\"a\"!`symbol", .{ .boolean = false });
    try runTest("\"a\"!`$()", .{ .boolean = false });
    try runTest("\"a\"!`a`b`c`d`e", .{ .boolean = false });

    try runTest("`symbol!`a", .{ .boolean = false });
    try runTest("`symbol!`$()", .{ .boolean = false });
    try runTest("`symbol!`a`b`c`d`e", .{ .boolean = false });

    try runTest("()!`symbol", .{ .boolean = false });
    try runTest("()!`$()", .{ .boolean = false });
    try runTest("()!`a`b`c`d`e", .{ .boolean = false });

    try runTest("10011b!`symbol", .{ .boolean = false });
    try runTest("10011b!`$()", .{ .boolean = false });
    try runTest("10011b!`a`b`c`d`e", .{ .boolean = false });

    try runTest("5 4 3 2 1!`symbol", .{ .boolean = false });
    try runTest("5 4 3 2 1!`$()", .{ .boolean = false });
    try runTest("5 4 3 2 1!`a`b`c`d`e", .{ .boolean = false });

    try runTest("5 4 3 2 1f!`symbol", .{ .boolean = false });
    try runTest("5 4 3 2 1f!`$()", .{ .boolean = false });
    try runTest("5 4 3 2 1f!`a`b`c`d`e", .{ .boolean = false });

    try runTest("\"54321\"!`symbol", .{ .boolean = false });
    try runTest("\"54321\"!`$()", .{ .boolean = false });
    try runTest("\"54321\"!`a`b`c`d`e", .{ .boolean = false });

    try runTest("`5`4`3`2`1!`symbol", .{ .boolean = false });
    try runTest("`5`4`3`2`1!`$()", .{ .boolean = false });
    try runTest("`5`4`3`2`1!`a`b`c`d`e", .{ .boolean = false });

    try runTest("(`a`b!1 2)!`symbol", .{ .boolean = false });
    try runTest("(`a`b!1 2)!`$()", .{ .boolean = false });
    try runTest("(`a`b!1 2)!`a`b", .{ .boolean = false });

    try runTest("(+`a`b!(,1;,2))!`symbol", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))!`$()", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))!`a`b", .{ .boolean = false });
}

test "dict list" {
    if (true) return error.SkipZigTest;
    try runTest("1b!()", .{ .boolean = false });
    try runTest("1b!(0b;1;0N;0W;-0W)", .{ .boolean = false });
    try runTest("1b!(0b;1;0N;0W;-0W;1f;0n;0w;-0w)", .{ .boolean = false });
    try runTest("1b!(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", .{ .boolean = false });
    try runTest("1b!(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", .{ .boolean = false });

    try runTest("1!()", .{ .boolean = false });
    try runTest("1!(0b;1;0N;0W;-0W)", .{ .boolean = false });
    try runTest("1!(0b;1;0N;0W;-0W;1f;0n;0w;-0w)", .{ .boolean = false });
    try runTest("1!(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", .{ .boolean = false });
    try runTest("1!(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", .{ .boolean = false });

    try runTest("1f!()", .{ .boolean = false });
    try runTest("1f!(0b;1;0N;0W;-0W;1f;0n;0w;-0w)", .{ .boolean = false });
    try runTest("1f!(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", .{ .boolean = false });
    try runTest("1f!(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", .{ .boolean = false });

    try runTest("\"a\"!()", .{ .boolean = false });

    try runTest("`symbol!()", .{ .boolean = false });

    try runTest("()!()", .{ .boolean = true });
    try runTest("(0N;0n)!()", .{ .boolean = false });
    try runTest("()!(0N;0n)", .{ .boolean = false });
    try runTest("(1b;2)!(1b;2)", .{ .boolean = true });
    try runTest("(1b;2f)!(2f;1b)", .{ .boolean = false });
    try runTest("(2;3f)!(2;3f)", .{ .boolean = true });
    try runTest("(1b;(2;3f))!(0N;(0n;0N))", .{ .boolean = false });
    try runTest("(0b;1;2;3;4;5;6;7;8;9)!(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", .{ .boolean = false });
    try runTest("(0b;1;2;3;4;5;6;7;8;9)!(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", .{ .boolean = false });

    try runTest("(`boolean$())!()", .{ .boolean = false });
    try runTest("010b!()", .{ .boolean = false });
    try runTest("01b!(0b;0N)", .{ .boolean = false });
    try runTest("010b!(0b;0N;0n)", .{ .boolean = false });
    try runTest("0101010101b!(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", .{ .boolean = false });
    try runTest("0101010101b!(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", .{ .boolean = false });

    try runTest("(`int$())!()", .{ .boolean = false });
    try runTest("0 1 2!()", .{ .boolean = false });
    try runTest("0 1!(0b;0N)", .{ .boolean = false });
    try runTest("0 1 2!(0b;0N;0n)", .{ .boolean = false });
    try runTest("0 1 2 3 4 5 6 7 8 9!(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", .{ .boolean = false });
    try runTest("0 1 2 3 4 5 6 7 8 9!(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", .{ .boolean = false });

    try runTest("(`float$())!()", .{ .boolean = false });
    try runTest("0 1 2f!()", .{ .boolean = false });
    try runTest("0 1 2f!(0b;0N;0n)", .{ .boolean = false });
    try runTest("0 1 2 3 4 5 6 7 8 9f!(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", .{ .boolean = false });
    try runTest("0 1 2 3 4 5 6 7 8 9f!(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", .{ .boolean = false });

    try runTest("\"\"!()", .{ .boolean = false });
    try runTest("\"abcde\"!()", .{ .boolean = false });

    try runTest("(`$())!()", .{ .boolean = false });
    try runTest("`a`b`c`d`e!()", .{ .boolean = false });

    try runTest("(()!())!()", .{ .boolean = false });
    try runTest("(`a`b!1 2)!()", .{ .boolean = false });
    try runTest("(`a`b!1 2)!(1;2f)", .{ .boolean = false });
    try runTest("(`a`b!1 2)!(0b;1;2f)", .{ .boolean = false });

    try runTest("(+`a`b!(,1;,2))!()", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))!(1;2f)", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))!(0b;1;2f)", .{ .boolean = false });
}

test "dict dictionary" {
    if (true) return error.SkipZigTest;
    try runTest("1b!()!()", .{ .boolean = false });
    try runTest("1b!(`int$())!()", .{ .boolean = false });
    try runTest("1b!(`int$())!`float$()", .{ .boolean = false });
    try runTest("1b!`a`b!1 2", .{ .boolean = false });

    try runTest("1!()!()", .{ .boolean = false });
    try runTest("1!(`int$())!()", .{ .boolean = false });
    try runTest("1!(`int$())!`float$()", .{ .boolean = false });
    try runTest("1!`a`b!1 2", .{ .boolean = false });

    try runTest("1f!()!()", .{ .boolean = false });
    try runTest("1f!(`int$())!()", .{ .boolean = false });
    try runTest("1f!(`int$())!`float$()", .{ .boolean = false });
    try runTest("1f!`a`b!1 2", .{ .boolean = false });

    try runTest("\"a\"!`a`b!1 2", .{ .boolean = false });

    try runTest("`symbol!`a`b!1 2", .{ .boolean = false });

    try runTest("()!()!()", .{ .boolean = false });
    try runTest("()!(`int$())!()", .{ .boolean = false });
    try runTest("()!(`int$())!`float$()", .{ .boolean = false });
    try runTest("()!`a`b!1 2", .{ .boolean = false });
    try runTest("(1;2f)!`a`b!1 2", .{ .boolean = false });
    try runTest("(0b;1;2f)!`a`b!1 2", .{ .boolean = false });

    try runTest("(`boolean$())!()!()", .{ .boolean = false });
    try runTest("(`boolean$())!(`int$())!()", .{ .boolean = false });
    try runTest("(`boolean$())!(`int$())!`float$()", .{ .boolean = false });
    try runTest("(`boolean$())!`a`b!1 2", .{ .boolean = false });
    try runTest("10b!`a`b!1 2", .{ .boolean = false });
    try runTest("101b!`a`b!1 2", .{ .boolean = false });

    try runTest("(`int$())!()!()", .{ .boolean = false });
    try runTest("(`int$())!(`int$())!()", .{ .boolean = false });
    try runTest("(`int$())!(`int$())!`float$()", .{ .boolean = false });
    try runTest("(`int$())!`a`b!1 2", .{ .boolean = false });
    try runTest("1 2!`a`b!1 2", .{ .boolean = false });
    try runTest("1 2 3!`a`b!1 2", .{ .boolean = false });

    try runTest("(`float$())!()!()", .{ .boolean = false });
    try runTest("(`float$())!(`int$())!()", .{ .boolean = false });
    try runTest("(`float$())!(`int$())!`float$()", .{ .boolean = false });
    try runTest("(`float$())!`a`b!1 2", .{ .boolean = false });
    try runTest("1 2f!`a`b!1 2", .{ .boolean = false });
    try runTest("1 2 3f!`a`b!1 2", .{ .boolean = false });

    try runTest("\"\"!`a`b!1 2", .{ .boolean = false });
    try runTest("\"12\"!`a`b!1 2", .{ .boolean = false });
    try runTest("\"123\"!`a`b!1 2", .{ .boolean = false });

    try runTest("(`$())!`a`b!1 2", .{ .boolean = false });
    try runTest("`5`4!`a`b!1 2", .{ .boolean = false });
    try runTest("`5`4`3!`a`b!1 2", .{ .boolean = false });

    try runTest("(()!())!()!()", .{ .boolean = true });
    try runTest("(()!())!(`int$())!()", .{ .boolean = false });
    try runTest("(()!())!(`int$())!(`float$())", .{ .boolean = false });
    try runTest("((`int$())!())!()!()", .{ .boolean = false });
    try runTest("((`int$())!())!(`int$())!()", .{ .boolean = true });
    try runTest("((`int$())!())!(`int$())!(`float$())", .{ .boolean = false });
    try runTest("((`int$())!`float$())!()!()", .{ .boolean = false });
    try runTest("((`int$())!`float$())!(`int$())!()", .{ .boolean = false });
    try runTest("((`int$())!`float$())!(`int$())!(`float$())", .{ .boolean = true });
    try runTest("(()!())!`a`b!1 2", .{ .boolean = false });
    try runTest("(`a`b!1 2)!()!()", .{ .boolean = false });
    try runTest("(`a`b!1 2)!`a`b!1 2", .{ .boolean = true });
    try runTest("(`b`a!1 2)!`a`b!1 2", .{ .boolean = false });
    try runTest("(`a`b!1 2)!`b`a!1 2", .{ .boolean = false });
    try runTest("(`a`b!1 2)!`c`d!1 2", .{ .boolean = false });
    try runTest("(`a`b!0N 0W)!`c`d!0N 0W", .{ .boolean = false });
    try runTest("(`a`b!1 2)!`a`b!(1;\"2\")", .{ .boolean = false });

    try runTest("(+`a`b!(,1;,2))!`a`b!1 2", .{ .boolean = false });
}

test "dict table" {
    if (true) return error.SkipZigTest;
    try runTest("1b!+`a`b!(();())", .{ .boolean = false });
    try runTest("1b!+`a`b!(`int$();`float$())", .{ .boolean = false });
    try runTest("1b!+`a`b!(,1;,2)", .{ .boolean = false });

    try runTest("1!+`a`b!(();())", .{ .boolean = false });
    try runTest("1!+`a`b!(`int$();`float$())", .{ .boolean = false });
    try runTest("1!+`a`b!(,1;,2)", .{ .boolean = false });

    try runTest("1f!+`a`b!(();())", .{ .boolean = false });
    try runTest("1f!+`a`b!(`int$();`float$())", .{ .boolean = false });
    try runTest("1f!+`a`b!(,1;,2)", .{ .boolean = false });

    try runTest("\"a\"!+`a`b!(,1;,2)", .{ .boolean = false });

    try runTest("`symbol!+`a`b!(,1;,2)", .{ .boolean = false });

    try runTest("()!+`a`b!(,1;,2)", .{ .boolean = false });
    try runTest("(1;2f)!+`a`b!(,1;,2)", .{ .boolean = false });
    try runTest("(0b;1;2f)!+`a`b!(,1;,2)", .{ .boolean = false });

    try runTest("(`boolean$())!+`a`b!(,1;,2)", .{ .boolean = false });
    try runTest("10b!+`a`b!(,1;,2)", .{ .boolean = false });
    try runTest("101b!+`a`b!(,1;,2)", .{ .boolean = false });

    try runTest("(`int$())!+`a`b!(,1;,2)", .{ .boolean = false });
    try runTest("1 2!+`a`b!(,1;,2)", .{ .boolean = false });
    try runTest("1 2 3!+`a`b!(,1;,2)", .{ .boolean = false });

    try runTest("(`float$())!+`a`b!(,1;,2)", .{ .boolean = false });
    try runTest("1 2f!+`a`b!(,1;,2)", .{ .boolean = false });
    try runTest("1 2 3f!+`a`b!(,1;,2)", .{ .boolean = false });

    try runTest("\"\"!+`a`b!(,1;,2)", .{ .boolean = false });
    try runTest("\"12\"!+`a`b!(,1;,2)", .{ .boolean = false });
    try runTest("\"123\"!+`a`b!(,1;,2)", .{ .boolean = false });

    try runTest("(`$())!+`a`b!(,1;,2)", .{ .boolean = false });
    try runTest("`5`4!+`a`b!(,1;,2)", .{ .boolean = false });
    try runTest("`5`4`3!+`a`b!(,1;,2)", .{ .boolean = false });

    try runTest("(`a`b!1 2)!+`a`b!(,1;,2)", .{ .boolean = false });

    try runTest("(+`a`b!(();()))!+`a`b!(();())", .{ .boolean = true });
    try runTest("(+`a`b!(();()))!+`a`b!(`int$();`float$())", .{ .boolean = false });
    try runTest("(+`a`b!(();()))!+`a`b!(,1;,2)", .{ .boolean = false });
    try runTest("(+`a`b!(`int$();`float$()))!+`a`b!(();())", .{ .boolean = false });
    try runTest("(+`a`b!(`int$();`float$()))!+`a`b!(`int$();`float$())", .{ .boolean = true });
    try runTest("(+`a`b!(`int$();`float$()))!+`a`b!(,1;,2)", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))!+`a`b!(();())", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))!+`a`b!(`int$();`float$())", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))!+`a`b!(,1;,2)", .{ .boolean = true });
    try runTest("(+`b`a!(,1;,2))!+`a`b!(,1;,2)", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))!+`b`a!(,1;,2)", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))!+`a`b!(,1;,`symbol)", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))!+`a`b!(1 1;2 2)", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))!+`a`b`c!(,1;,2;,3)", .{ .boolean = false });
    try runTest("(+`a`b`c!(,1;,2;,3))!+`a`b!(,1;,2)", .{ .boolean = false });
}
