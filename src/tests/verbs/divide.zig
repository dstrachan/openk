const value_mod = @import("../../value.zig");
const Value = value_mod.Value;

const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;
const runTestError = vm_mod.runTestError;

const DivideError = @import("../../verbs/divide.zig").DivideError;

test "divide boolean" {
    try runTest("1b%0b", .{ .float = Value.inf_float });
    try runTest("1b%`boolean$()", .{ .float_list = &.{} });
    try runTest("1b%00000b", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
        },
    });

    try runTest("1%0b", .{ .float = Value.inf_float });
    try runTest("1%`boolean$()", .{ .float_list = &.{} });
    try runTest("1%00000b", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
        },
    });

    try runTest("1f%0b", .{ .float = Value.inf_float });
    try runTest("1f%`boolean$()", .{ .float_list = &.{} });
    try runTest("1f%00000b", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
        },
    });

    try runTestError("\"a\"%0b", DivideError.incompatible_types);
    try runTestError("\"a\"%`boolean$()", DivideError.incompatible_types);
    try runTestError("\"a\"%00000b", DivideError.incompatible_types);

    try runTestError("`symbol%0b", DivideError.incompatible_types);
    try runTestError("`symbol%`boolean$()", DivideError.incompatible_types);
    try runTestError("`symbol%00000b", DivideError.incompatible_types);

    try runTest("()%0b", .{ .list = &.{} });
    try runTest("(1b;2)%0b", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
        },
    });
    try runTest("(1b;2;3f)%0b", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
        },
    });
    try runTest("(1b;2;3f;(0b;1))%0b", .{
        .list = &.{
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float_list = &.{
                .{ .float = Value.null_float },
                .{ .float = Value.inf_float },
            } },
        },
    });
    try runTestError("(1b;2;3f;`symbol)%0b", DivideError.incompatible_types);
    try runTest("()%`boolean$()", .{ .list = &.{} });
    try runTestError("()%010b", DivideError.length_mismatch);
    try runTestError("(1b;2)%`boolean$()", DivideError.length_mismatch);
    try runTest("(1b;2)%01b", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = 2 },
        },
    });
    try runTest("(1b;2;3f)%010b", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = 2 },
            .{ .float = Value.inf_float },
        },
    });
    try runTestError("(1b;2;3f)%0101b", DivideError.length_mismatch);
    try runTestError("(1b;2;3f;\"a\")%0101b", DivideError.incompatible_types);
    try runTestError("(1b;2;3f;`symbol)%0101b", DivideError.incompatible_types);

    try runTest("11111b%0b", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
        },
    });
    try runTestError("11111b%`boolean$()", DivideError.length_mismatch);
    try runTest("11111b%00000b", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
        },
    });
    try runTestError("11111b%000000b", DivideError.length_mismatch);

    try runTest("5 4 3 2 1%0b", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
        },
    });
    try runTestError("5 4 3 2 1%`boolean$()", DivideError.length_mismatch);
    try runTest("5 4 3 2 1%00000b", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
        },
    });
    try runTestError("5 4 3 2 1%000000b", DivideError.length_mismatch);

    try runTest("5 4 3 2 1f%0b", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
        },
    });
    try runTestError("5 4 3 2 1f%`boolean$()", DivideError.length_mismatch);
    try runTest("5 4 3 2 1f%00000b", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
        },
    });
    try runTestError("5 4 3 2 1f%000000b", DivideError.length_mismatch);

    try runTestError("\"abcde\"%0b", DivideError.incompatible_types);
    try runTestError("\"abcde\"%`boolean$()", DivideError.incompatible_types);
    try runTestError("\"abcde\"%00000b", DivideError.incompatible_types);
    try runTestError("\"abcde\"%000000b", DivideError.incompatible_types);

    try runTestError("`a`b`c`d`e%0b", DivideError.incompatible_types);
    try runTestError("`a`b`c`d`e%`boolean$()", DivideError.incompatible_types);
    try runTestError("`a`b`c`d`e%00000b", DivideError.incompatible_types);
    try runTestError("`a`b`c`d`e%000000b", DivideError.incompatible_types);

    try runTest("(()!())%0b", .{
        .dictionary = &.{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("(`a`b!1 2)%0b", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .float_list = &.{
                .{ .float = Value.inf_float },
                .{ .float = Value.inf_float },
            } },
        },
    });
    try runTestError("(`a`b!1 2)%`boolean$()", DivideError.length_mismatch);
    try runTest("(`a`b!1 2)%01b", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .float_list = &.{
                .{ .float = Value.inf_float },
                .{ .float = 2 },
            } },
        },
    });
    try runTestError("(`a`b!1 2)%010b", DivideError.length_mismatch);

    try runTest("(+`a`b!(,1;,2))%0b", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .float_list = &.{
                    .{ .float = Value.inf_float },
                } },
                .{ .float_list = &.{
                    .{ .float = Value.inf_float },
                } },
            } },
        },
    });
    try runTestError("(+`a`b!(,1;,`symbol))%0b", DivideError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))%`boolean$()", DivideError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))%01b", DivideError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))%010b", DivideError.incompatible_types);
}

test "divide int" {
    try runTest("1b%0", .{ .float = Value.inf_float });
    try runTest("1b%`int$()", .{ .float_list = &.{} });
    try runTest("1b%0 1 0N 0W -0W", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = 1 / Value.inf_int },
            .{ .float = 1 / -Value.inf_int },
        },
    });

    try runTest("1%0", .{ .float = Value.inf_float });
    try runTest("1%`int$()", .{ .float_list = &.{} });
    try runTest("1%0 1 0N 0W -0W", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = 1 / Value.inf_int },
            .{ .float = 1 / -Value.inf_int },
        },
    });

    try runTest("1f%0", .{ .float = Value.inf_float });
    try runTest("1f%`int$()", .{ .float_list = &.{} });
    try runTest("1f%0 1 0N 0W -0W", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = 1 / Value.inf_int },
            .{ .float = 1 / -Value.inf_int },
        },
    });

    try runTestError("\"a\"%0", DivideError.incompatible_types);
    try runTestError("\"a\"%`int$()", DivideError.incompatible_types);
    try runTestError("\"a\"%0 1 0N 0W -0W", DivideError.incompatible_types);

    try runTestError("`symbol%0", DivideError.incompatible_types);
    try runTestError("`symbol%`int$()", DivideError.incompatible_types);
    try runTestError("`symbol%0 1 0N 0W -0W", DivideError.incompatible_types);

    try runTest("()%0", .{ .list = &.{} });
    try runTest("(1b;2)%0", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
        },
    });
    try runTest("(1b;2;3f)%0", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
        },
    });
    try runTest("(1b;2;3f;(0b;1))%0", .{
        .list = &.{
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float_list = &.{
                .{ .float = Value.null_float },
                .{ .float = Value.inf_float },
            } },
        },
    });
    try runTestError("(1b;2;3f;`symbol)%0", DivideError.incompatible_types);
    try runTest("()%`int$()", .{ .list = &.{} });
    try runTestError("()%0 1 0N 0W -0W", DivideError.length_mismatch);
    try runTestError("(1b;2;3;4;5)%`int$()", DivideError.length_mismatch);
    try runTest("(1b;2;3f;4;5)%0 1 0N 0W -0W", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = 2 },
            .{ .float = Value.null_float },
            .{ .float = 4 / Value.inf_int },
            .{ .float = 5 / -Value.inf_int },
        },
    });
    try runTestError("(1b;2;3f;4)%0 1 0N 0W -0W", DivideError.length_mismatch);
    try runTestError("(1b;2;3f;4;\"a\")%0 1 0N 0W -0W", DivideError.incompatible_types);
    try runTestError("(1b;2;3f;4;`symbol)%0 1 0N 0W -0W", DivideError.incompatible_types);

    try runTest("11111b%0", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
        },
    });
    try runTestError("11111b%`int$()", DivideError.length_mismatch);
    try runTest("11111b%0 1 0N 0W -0W", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = 1 / Value.null_int },
            .{ .float = 1 / -Value.null_int },
        },
    });
    try runTestError("11111b%0 1 0N 0W -0W 2", DivideError.length_mismatch);

    try runTest("5 4 3 2 1%0", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
        },
    });
    try runTestError("5 4 3 2 1%`int$()", DivideError.length_mismatch);
    try runTest("5 4 3 2 1%0 1 0N 0W -0W", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = 4 },
            .{ .float = Value.null_float },
            .{ .float = 2 / Value.inf_int },
            .{ .float = 1 / -Value.inf_int },
        },
    });
    try runTestError("5 4 3 2 1%0 1 0N 0W -0W 2", DivideError.length_mismatch);

    try runTest("5 4 3 2 1f%0", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
        },
    });
    try runTestError("5 4 3 2 1f%`int$()", DivideError.length_mismatch);
    try runTest("5 4 3 2 1f%0 1 0N 0W -0W", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = 4 },
            .{ .float = Value.null_float },
            .{ .float = 2 / Value.inf_int },
            .{ .float = 1 / -Value.inf_int },
        },
    });
    try runTestError("5 4 3 2 1f%0 1 0N 0W -0W 2", DivideError.length_mismatch);

    try runTestError("\"abcde\"%0", DivideError.incompatible_types);
    try runTestError("\"abcde\"%`int$()", DivideError.incompatible_types);
    try runTestError("\"abcde\"%0 1 0N 0W -0W", DivideError.incompatible_types);
    try runTestError("\"abcde\"%0 1 0N 0W -0W 2", DivideError.incompatible_types);

    try runTestError("`a`b`c`d`e%0", DivideError.incompatible_types);
    try runTestError("`a`b`c`d`e%`int$()", DivideError.incompatible_types);
    try runTestError("`a`b`c`d`e%0 1 0N 0W -0W", DivideError.incompatible_types);
    try runTestError("`a`b`c`d`e%0 1 0N 0W -0W 2", DivideError.incompatible_types);

    try runTest("(()!())%0", .{
        .dictionary = &.{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("(`a`b!1 2)%0", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .float_list = &.{
                .{ .float = Value.inf_float },
                .{ .float = Value.inf_float },
            } },
        },
    });
    try runTestError("(`a`b!1 2)%`int$()", DivideError.length_mismatch);
    try runTest("(`a`b!1 2)%0 1", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .float_list = &.{
                .{ .float = Value.inf_float },
                .{ .float = 2 },
            } },
        },
    });
    try runTestError("(`a`b!1 2)%0 1 2", DivideError.length_mismatch);

    try runTest("(+`a`b!(,1;,2))%0", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .float_list = &.{
                    .{ .float = Value.inf_float },
                } },
                .{ .float_list = &.{
                    .{ .float = Value.inf_float },
                } },
            } },
        },
    });
    try runTestError("(+`a`b!(,1;,`symbol))%0", DivideError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))%`int$()", DivideError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))%0 1", DivideError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))%0 1 2", DivideError.incompatible_types);
}

test "divide float" {
    try runTest("1b%0f", .{ .float = Value.inf_float });
    try runTest("1b%`float$()", .{ .float_list = &.{} });
    try runTest("1b%0 1 0n 0w -0w", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = 0 },
            .{ .float = 0 },
        },
    });

    try runTest("1%0f", .{ .float = Value.inf_float });
    try runTest("1%`float$()", .{ .float_list = &.{} });
    try runTest("1%0 1 0n 0w -0w", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = 0 },
            .{ .float = 0 },
        },
    });

    try runTest("1f%0f", .{ .float = Value.inf_float });
    try runTest("1f%`float$()", .{ .float_list = &.{} });
    try runTest("1f%0 1 0n 0w -0w", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = 0 },
            .{ .float = 0 },
        },
    });

    try runTestError("\"a\"%0f", DivideError.incompatible_types);
    try runTestError("\"a\"%`float$()", DivideError.incompatible_types);
    try runTestError("\"a\"%0 1 0n 0w -0w", DivideError.incompatible_types);

    try runTestError("`symbol%0f", DivideError.incompatible_types);
    try runTestError("`symbol%`float$()", DivideError.incompatible_types);
    try runTestError("`symbol%0 1 0n 0w -0w", DivideError.incompatible_types);

    try runTest("()%0f", .{ .list = &.{} });
    try runTest("(1b;2;3f)%0f", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
        },
    });
    try runTest("(1b;2;3f;(0b;1))%0f", .{
        .list = &.{
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float_list = &.{
                .{ .float = Value.null_float },
                .{ .float = Value.inf_float },
            } },
        },
    });
    try runTestError("(1b;2;3f;`symbol)%0f", DivideError.incompatible_types);
    try runTest("()%`float$()", .{ .list = &.{} });
    try runTestError("()%0 1 0n 0w -0w", DivideError.length_mismatch);
    try runTestError("(1b;2;3f;4;5)%`float$()", DivideError.length_mismatch);
    try runTest("(1b;2;3f;4;5)%0 1 0n 0w -0w", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = 2 },
            .{ .float = Value.null_float },
            .{ .float = 0 },
            .{ .float = 0 },
        },
    });
    try runTestError("(1b;2;3f;4)%0 1 0n 0w -0w", DivideError.length_mismatch);
    try runTestError("(1b;2;3f;4;\"a\")%0 1 0n 0w -0w", DivideError.incompatible_types);
    try runTestError("(1b;2;3f;4;`symbol)%0 1 0n 0w -0w", DivideError.incompatible_types);

    try runTest("11111b%0f", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
        },
    });
    try runTestError("11111b%`float$()", DivideError.length_mismatch);
    try runTest("11111b%0 1 0n 0w -0w", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = 0 },
            .{ .float = 0 },
        },
    });
    try runTestError("11111b%0 1 0n 0w -0w 2", DivideError.length_mismatch);

    try runTest("5 4 3 2 1%0f", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
        },
    });
    try runTestError("5 4 3 2 1%`float$()", DivideError.length_mismatch);
    try runTest("5 4 3 2 1%0 1 0n 0w -0w", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = 4 },
            .{ .float = Value.null_float },
            .{ .float = 0 },
            .{ .float = 0 },
        },
    });
    try runTestError("5 4 3 2 1%0 1 0n 0w -0w 2", DivideError.length_mismatch);

    try runTest("5 4 3 2 1f%0f", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
            .{ .float = Value.inf_float },
        },
    });
    try runTestError("5 4 3 2 1f%`float$()", DivideError.length_mismatch);
    try runTest("5 4 3 2 1f%0 1 0n 0w -0w", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = 4 },
            .{ .float = Value.null_float },
            .{ .float = 0 },
            .{ .float = 0 },
        },
    });
    try runTestError("5 4 3 2 1f%0 1 0n 0w -0w 2", DivideError.length_mismatch);

    try runTestError("\"abcde\"%0f", DivideError.incompatible_types);
    try runTestError("\"abcde\"%`float$()", DivideError.incompatible_types);
    try runTestError("\"abcde\"%0 1 0n 0w -0w", DivideError.incompatible_types);
    try runTestError("\"abcde\"%0 1 0n 0w -0w 2", DivideError.incompatible_types);

    try runTestError("`a`b`c`d`e%0f", DivideError.incompatible_types);
    try runTestError("`a`b`c`d`e%`float$()", DivideError.incompatible_types);
    try runTestError("`a`b`c`d`e%0 1 0n 0w -0w", DivideError.incompatible_types);
    try runTestError("`a`b`c`d`e%0 1 0n 0w -0w 2", DivideError.incompatible_types);

    try runTest("(()!())%0f", .{
        .dictionary = &.{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("(`a`b!1 2)%0f", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .float_list = &.{
                .{ .float = Value.inf_float },
                .{ .float = Value.inf_float },
            } },
        },
    });
    try runTestError("(`a`b!1 2)%`float$()", DivideError.length_mismatch);
    try runTest("(`a`b!1 2)%0 1f", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .float_list = &.{
                .{ .float = Value.inf_float },
                .{ .float = 2 },
            } },
        },
    });
    try runTestError("(`a`b!1 2)%0 1 2f", DivideError.length_mismatch);

    try runTest("(+`a`b!(,1;,2))%0f", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{
                .list = &.{
                    .{ .float_list = &.{
                        .{ .float = Value.inf_float },
                    } },
                    .{ .float_list = &.{
                        .{ .float = Value.inf_float },
                    } },
                },
            },
        },
    });
    try runTestError("(+`a`b!(,1;,`symbol))%0f", DivideError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))%`float$()", DivideError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))%0 1f", DivideError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))%0 1 2f", DivideError.incompatible_types);
}

test "divide char" {
    try runTestError("1b%\"a\"", DivideError.incompatible_types);
    try runTestError("1b%\"\"", DivideError.incompatible_types);
    try runTestError("1b%\"abcde\"", DivideError.incompatible_types);

    try runTestError("1%\"a\"", DivideError.incompatible_types);
    try runTestError("1%\"\"", DivideError.incompatible_types);
    try runTestError("1%\"abcde\"", DivideError.incompatible_types);

    try runTestError("1f%\"a\"", DivideError.incompatible_types);
    try runTestError("1f%\"\"", DivideError.incompatible_types);
    try runTestError("1f%\"abcde\"", DivideError.incompatible_types);

    try runTestError("\"1\"%\"a\"", DivideError.incompatible_types);
    try runTestError("\"1\"%\"\"", DivideError.incompatible_types);
    try runTestError("\"1\"%\"abcde\"", DivideError.incompatible_types);

    try runTestError("`symbol%\"a\"", DivideError.incompatible_types);
    try runTestError("`symbol%\"\"", DivideError.incompatible_types);
    try runTestError("`symbol%\"abcde\"", DivideError.incompatible_types);

    try runTestError("()%\"a\"", DivideError.incompatible_types);
    try runTestError("()%\"\"", DivideError.incompatible_types);
    try runTestError("()%\"abcde\"", DivideError.incompatible_types);

    try runTestError("10011b%\"a\"", DivideError.incompatible_types);
    try runTestError("10011b%\"\"", DivideError.incompatible_types);
    try runTestError("10011b%\"abcde\"", DivideError.incompatible_types);

    try runTestError("5 4 3 2 1%\"a\"", DivideError.incompatible_types);
    try runTestError("5 4 3 2 1%\"\"", DivideError.incompatible_types);
    try runTestError("5 4 3 2 1%\"abcde\"", DivideError.incompatible_types);

    try runTestError("5 4 3 2 1f%\"a\"", DivideError.incompatible_types);
    try runTestError("5 4 3 2 1f%\"\"", DivideError.incompatible_types);
    try runTestError("5 4 3 2 1f%\"abcde\"", DivideError.incompatible_types);

    try runTestError("\"54321\"%\"a\"", DivideError.incompatible_types);
    try runTestError("\"54321\"%\"\"", DivideError.incompatible_types);
    try runTestError("\"54321\"%\"abcde\"", DivideError.incompatible_types);

    try runTestError("`a`b`c`d`e%\"a\"", DivideError.incompatible_types);
    try runTestError("`a`b`c`d`e%\"\"", DivideError.incompatible_types);
    try runTestError("`a`b`c`d`e%\"abcde\"", DivideError.incompatible_types);

    try runTestError("(`a`b!1 2)%\"a\"", DivideError.incompatible_types);
    try runTestError("(`a`b!1 2)%\"\"", DivideError.incompatible_types);
    try runTestError("(`a`b!1 2)%\"ab\"", DivideError.incompatible_types);

    try runTestError("(+`a`b!(,1;,2))%\"a\"", DivideError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))%\"\"", DivideError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))%\"ab\"", DivideError.incompatible_types);
}

test "divide symbol" {
    try runTestError("1b%`symbol", DivideError.incompatible_types);
    try runTestError("1b%`$()", DivideError.incompatible_types);
    try runTestError("1b%`a`b`c`d`e", DivideError.incompatible_types);

    try runTestError("1%`symbol", DivideError.incompatible_types);
    try runTestError("1%`$()", DivideError.incompatible_types);
    try runTestError("1%`a`b`c`d`e", DivideError.incompatible_types);

    try runTestError("1f%`symbol", DivideError.incompatible_types);
    try runTestError("1f%`$()", DivideError.incompatible_types);
    try runTestError("1f%`a`b`c`d`e", DivideError.incompatible_types);

    try runTestError("\"a\"%`symbol", DivideError.incompatible_types);
    try runTestError("\"a\"%`$()", DivideError.incompatible_types);
    try runTestError("\"a\"%`a`b`c`d`e", DivideError.incompatible_types);

    try runTestError("`symbol%`a", DivideError.incompatible_types);
    try runTestError("`symbol%`$()", DivideError.incompatible_types);
    try runTestError("`symbol%`a`b`c`d`e", DivideError.incompatible_types);

    try runTestError("()%`symbol", DivideError.incompatible_types);
    try runTestError("()%`$()", DivideError.incompatible_types);
    try runTestError("()%`a`b`c`d`e", DivideError.incompatible_types);

    try runTestError("10011b%`symbol", DivideError.incompatible_types);
    try runTestError("10011b%`$()", DivideError.incompatible_types);
    try runTestError("10011b%`a`b`c`d`e", DivideError.incompatible_types);

    try runTestError("5 4 3 2 1%`symbol", DivideError.incompatible_types);
    try runTestError("5 4 3 2 1%`$()", DivideError.incompatible_types);
    try runTestError("5 4 3 2 1%`a`b`c`d`e", DivideError.incompatible_types);

    try runTestError("5 4 3 2 1f%`symbol", DivideError.incompatible_types);
    try runTestError("5 4 3 2 1f%`$()", DivideError.incompatible_types);
    try runTestError("5 4 3 2 1f%`a`b`c`d`e", DivideError.incompatible_types);

    try runTestError("\"54321\"%`symbol", DivideError.incompatible_types);
    try runTestError("\"54321\"%`$()", DivideError.incompatible_types);
    try runTestError("\"54321\"%`a`b`c`d`e", DivideError.incompatible_types);

    try runTestError("`5`4`3`2`1%`symbol", DivideError.incompatible_types);
    try runTestError("`5`4`3`2`1%`$()", DivideError.incompatible_types);
    try runTestError("`5`4`3`2`1%`a`b`c`d`e", DivideError.incompatible_types);

    try runTestError("(`a`b!1 2)%`symbol", DivideError.incompatible_types);
    try runTestError("(`a`b!1 2)%`$()", DivideError.incompatible_types);
    try runTestError("(`a`b!1 2)%`a`b", DivideError.incompatible_types);

    try runTestError("(+`a`b!(,1;,2))%`symbol", DivideError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))%`$()", DivideError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))%`a`b", DivideError.incompatible_types);
}

test "divide list" {
    try runTest("1b%()", .{ .list = &.{} });
    try runTest("1b%(0b;1;0N;0W;-0W)", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = 1 / Value.inf_int },
            .{ .float = 1 / -Value.inf_int },
        },
    });
    try runTest("1b%(0b;1;0N;0W;-0W;1f;0n;0w;-0w)", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = 1 / Value.inf_int },
            .{ .float = 1 / -Value.inf_int },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = 0 },
            .{ .float = 0 },
        },
    });
    try runTestError("1b%(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", DivideError.incompatible_types);
    try runTestError("1b%(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", DivideError.incompatible_types);

    try runTest("1%()", .{ .list = &.{} });
    try runTest("1%(0b;1;0N;0W;-0W)", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = 1 / Value.inf_int },
            .{ .float = 1 / -Value.inf_int },
        },
    });
    try runTest("1%(0b;1;0N;0W;-0W;1f;0n;0w;-0w)", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = 1 / Value.inf_int },
            .{ .float = 1 / -Value.inf_int },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = 0 },
            .{ .float = 0 },
        },
    });
    try runTestError("1%(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", DivideError.incompatible_types);
    try runTestError("1%(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", DivideError.incompatible_types);

    try runTest("1f%()", .{ .list = &.{} });
    try runTest("1f%(0b;1;0N;0W;-0W;1f;0n;0w;-0w)", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = 1 / Value.inf_int },
            .{ .float = 1 / -Value.inf_int },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = 0 },
            .{ .float = 0 },
        },
    });
    try runTestError("1f%(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", DivideError.incompatible_types);
    try runTestError("1f%(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", DivideError.incompatible_types);

    try runTestError("\"a\"%()", DivideError.incompatible_types);

    try runTestError("`symbol%()", DivideError.incompatible_types);

    try runTest("()%()", .{ .list = &.{} });
    try runTestError("(0N;0n)%()", DivideError.length_mismatch);
    try runTestError("()%(0N;0n)", DivideError.length_mismatch);
    try runTest("(1b;2f)%(2f;1b)", .{
        .float_list = &.{
            .{ .float = 0.5 },
            .{ .float = 2 },
        },
    });
    try runTest("(1b;(2;3f))%(0N;(0n;0N))", .{
        .list = &.{
            .{ .float = Value.null_float },
            .{ .float_list = &.{
                .{ .float = Value.null_float },
                .{ .float = Value.null_float },
            } },
        },
    });
    try runTestError("(0b;1;2;3;4;5;6;7;8;9)%(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", DivideError.incompatible_types);
    try runTestError("(0b;1;2;3;4;5;6;7;8;9)%(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", DivideError.incompatible_types);

    try runTestError("010b%()", DivideError.length_mismatch);
    try runTest("01b%(0b;0N)", .{
        .float_list = &.{
            .{ .float = Value.null_float },
            .{ .float = Value.null_float },
        },
    });
    try runTest("010b%(0b;0N;0n)", .{
        .float_list = &.{
            .{ .float = Value.null_float },
            .{ .float = Value.null_float },
            .{ .float = Value.null_float },
        },
    });
    try runTestError("0101010101b%(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", DivideError.incompatible_types);
    try runTestError("0101010101b%(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", DivideError.incompatible_types);

    try runTestError("0 1 2%()", DivideError.length_mismatch);
    try runTest("0 1%(0b;0N)", .{
        .float_list = &.{
            .{ .float = Value.null_float },
            .{ .float = Value.null_float },
        },
    });
    try runTest("0 1 2%(0b;0N;0n)", .{
        .float_list = &.{
            .{ .float = Value.null_float },
            .{ .float = Value.null_float },
            .{ .float = Value.null_float },
        },
    });
    try runTestError("0 1 2 3 4 5 6 7 8 9%(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", DivideError.incompatible_types);
    try runTestError("0 1 2 3 4 5 6 7 8 9%(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", DivideError.incompatible_types);

    try runTestError("0 1 2f%()", DivideError.length_mismatch);
    try runTest("0 1 2f%(0b;0N;0n)", .{
        .float_list = &.{
            .{ .float = Value.null_float },
            .{ .float = Value.null_float },
            .{ .float = Value.null_float },
        },
    });
    try runTestError("0 1 2 3 4 5 6 7 8 9f%(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", DivideError.incompatible_types);
    try runTestError("0 1 2 3 4 5 6 7 8 9f%(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", DivideError.incompatible_types);

    try runTestError("\"abcde\"%()", DivideError.incompatible_types);

    try runTestError("`a`b`c`d`e%()", DivideError.incompatible_types);

    try runTestError("(`a`b!1 2)%()", DivideError.length_mismatch);
    try runTest("(`a`b!1 2)%(1;2f)", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .float_list = &.{
                .{ .float = 1 },
                .{ .float = 1 },
            } },
        },
    });
    try runTestError("(`a`b!1 2)%(0b;1;2f)", DivideError.length_mismatch);

    try runTestError("(+`a`b!(,1;,2))%()", DivideError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))%(1;2f)", DivideError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))%(0b;1;2f)", DivideError.incompatible_types);
}

test "divide dictionary" {
    try runTest("1b%()!()", .{
        .dictionary = &.{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("1b%`a`b!1 2", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .float_list = &.{
                .{ .float = 1 },
                .{ .float = 0.5 },
            } },
        },
    });

    try runTest("1%()!()", .{
        .dictionary = &.{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("1%`a`b!1 2", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .float_list = &.{
                .{ .float = 1 },
                .{ .float = 0.5 },
            } },
        },
    });

    try runTest("1f%()!()", .{
        .dictionary = &.{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("1f%`a`b!1 2", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .float_list = &.{
                .{ .float = 1 },
                .{ .float = 0.5 },
            } },
        },
    });

    try runTestError("\"a\"%`a`b!1 2", DivideError.incompatible_types);

    try runTestError("`symbol%`a`b!1 2", DivideError.incompatible_types);

    try runTest("()%()!()", .{
        .dictionary = &.{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTestError("()%`a`b!1 2", DivideError.length_mismatch);
    try runTest("(1;2f)%`a`b!1 2", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .float_list = &.{
                .{ .float = 1 },
                .{ .float = 1 },
            } },
        },
    });
    try runTestError("(0b;1;2f)%`a`b!1 2", DivideError.length_mismatch);

    try runTest("(`boolean$())%()!()", .{
        .dictionary = &.{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTestError("(`boolean$())%`a`b!1 2", DivideError.length_mismatch);
    try runTest("10b%`a`b!1 2", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .float_list = &.{
                .{ .float = 1 },
                .{ .float = 0 },
            } },
        },
    });
    try runTestError("101b%`a`b!1 2", DivideError.length_mismatch);

    try runTest("(`int$())%()!()", .{
        .dictionary = &.{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTestError("(`int$())%`a`b!1 2", DivideError.length_mismatch);
    try runTest("1 2%`a`b!1 2", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .float_list = &.{
                .{ .float = 1 },
                .{ .float = 1 },
            } },
        },
    });
    try runTestError("1 2 3%`a`b!1 2", DivideError.length_mismatch);

    try runTest("(`float$())%()!()", .{
        .dictionary = &.{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTestError("(`float$())%`a`b!1 2", DivideError.length_mismatch);
    try runTest("1 2f%`a`b!1 2", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .float_list = &.{
                .{ .float = 1 },
                .{ .float = 1 },
            } },
        },
    });
    try runTestError("1 2 3f%`a`b!1 2", DivideError.length_mismatch);

    try runTestError("\"\"%`a`b!1 2", DivideError.incompatible_types);
    try runTestError("\"12\"%`a`b!1 2", DivideError.incompatible_types);
    try runTestError("\"123\"%`a`b!1 2", DivideError.incompatible_types);

    try runTestError("(`$())%`a`b!1 2", DivideError.incompatible_types);
    try runTestError("`5`4%`a`b!1 2", DivideError.incompatible_types);
    try runTestError("`5`4`3%`a`b!1 2", DivideError.incompatible_types);

    try runTest("(()!())%()!()", .{
        .dictionary = &.{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("(()!())%`a`b!1 2", .{
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
    try runTest("(`a`b!1 2)%()!()", .{
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
    try runTest("(`a`b!1 2)%`a`b!1 2", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .float_list = &.{
                .{ .float = 1 },
                .{ .float = 1 },
            } },
        },
    });
    try runTest("(`a`b!1 2)%`a`b!1 2f", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .float_list = &.{
                .{ .float = 1 },
                .{ .float = 1 },
            } },
        },
    });
    try runTestError("(`a`b!1 2)%`a`b!(1;`a)", DivideError.incompatible_types);
    try runTest("(`b`a!1 2)%`a`b!1 2", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "b" },
                .{ .symbol = "a" },
            } },
            .{ .float_list = &.{
                .{ .float = 0.5 },
                .{ .float = 2 },
            } },
        },
    });
    try runTest("(`a`b!1 2)%`b`a!1 2", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .float_list = &.{
                .{ .float = 0.5 },
                .{ .float = 2 },
            } },
        },
    });
    try runTest("(`a`b!1 2)%`c`d!1 2", .{
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
                .{ .int = 1 },
                .{ .int = 2 },
            } },
        },
    });
    try runTestError("(`a`b!1 2)%`a`b!(1;\"2\")", DivideError.incompatible_types);

    try runTestError("(+`a`b!(,1;,2))%`a`b!1 2", DivideError.incompatible_types);
}

test "divide table" {
    try runTest("1b%+`a`b!(,1;,2)", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .float_list = &.{
                    .{ .float = 1 },
                } },
                .{ .float_list = &.{
                    .{ .float = 0.5 },
                } },
            } },
        },
    });

    try runTest("1%+`a`b!(,1;,2)", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .float_list = &.{
                    .{ .float = 1 },
                } },
                .{ .float_list = &.{
                    .{ .float = 0.5 },
                } },
            } },
        },
    });

    try runTest("1f%+`a`b!(,1;,2)", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .float_list = &.{
                    .{ .float = 1 },
                } },
                .{ .float_list = &.{
                    .{ .float = 0.5 },
                } },
            } },
        },
    });

    try runTestError("\"a\"%+`a`b!(,1;,2)", DivideError.incompatible_types);

    try runTestError("`symbol%+`a`b!(,1;,2)", DivideError.incompatible_types);

    try runTestError("()%+`a`b!(,1;,2)", DivideError.incompatible_types);
    try runTestError("(1;2f)%+`a`b!(,1;,2)", DivideError.incompatible_types);
    try runTestError("(0b;1;2f)%+`a`b!(,1;,2)", DivideError.incompatible_types);

    try runTestError("(`boolean$())%+`a`b!(,1;,2)", DivideError.incompatible_types);
    try runTestError("10b%+`a`b!(,1;,2)", DivideError.incompatible_types);
    try runTestError("101b%+`a`b!(,1;,2)", DivideError.incompatible_types);

    try runTestError("(`int$())%+`a`b!(,1;,2)", DivideError.incompatible_types);
    try runTestError("1 2%+`a`b!(,1;,2)", DivideError.incompatible_types);
    try runTestError("1 2 3%+`a`b!(,1;,2)", DivideError.incompatible_types);

    try runTestError("(`float$())%+`a`b!(,1;,2)", DivideError.incompatible_types);
    try runTestError("1 2f%+`a`b!(,1;,2)", DivideError.incompatible_types);
    try runTestError("1 2 3f%+`a`b!(,1;,2)", DivideError.incompatible_types);

    try runTestError("\"\"%+`a`b!(,1;,2)", DivideError.incompatible_types);
    try runTestError("\"12\"%+`a`b!(,1;,2)", DivideError.incompatible_types);
    try runTestError("\"123\"%+`a`b!(,1;,2)", DivideError.incompatible_types);

    try runTestError("(`$())%+`a`b!(,1;,2)", DivideError.incompatible_types);
    try runTestError("`5`4%+`a`b!(,1;,2)", DivideError.incompatible_types);
    try runTestError("`5`4`3%+`a`b!(,1;,2)", DivideError.incompatible_types);

    try runTestError("(`a`b!1 2)%+`a`b!(,1;,2)", DivideError.incompatible_types);

    try runTest("(+`a`b!(,1;,2))%+`a`b!(,1;,2)", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .float_list = &.{
                    .{ .float = 1 },
                } },
                .{ .float_list = &.{
                    .{ .float = 1 },
                } },
            } },
        },
    });
    try runTest("(+`b`a!(,1;,2))%+`a`b!(,1;,2)", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "b" },
                .{ .symbol = "a" },
            } },
            .{ .list = &.{
                .{ .float_list = &.{
                    .{ .float = 0.5 },
                } },
                .{ .float_list = &.{
                    .{ .float = 2 },
                } },
            } },
        },
    });
    try runTest("(+`a`b!(,1;,2))%+`b`a!(,1;,2)", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .float_list = &.{
                    .{ .float = 0.5 },
                } },
                .{ .float_list = &.{
                    .{ .float = 2 },
                } },
            } },
        },
    });
    try runTestError("(+`a`b!(,1;,2))%+`a`b!(,1;,`symbol)", DivideError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))%+`a`b!(1 1;2 2)", DivideError.length_mismatch);
    try runTest("(+`a`b!(,1;,2))%+`a`b`c!(,1;,2;,3)", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
                .{ .symbol = "c" },
            } },
            .{ .list = &.{
                .{ .float_list = &.{
                    .{ .float = 1 },
                } },
                .{ .float_list = &.{
                    .{ .float = 1 },
                } },
                .{ .int_list = &.{
                    .{ .int = 3 },
                } },
            } },
        },
    });
    try runTest("(+`a`b`c!(,1;,2;,3))%+`a`b!(,1;,2)", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
                .{ .symbol = "c" },
            } },
            .{ .list = &.{
                .{ .float_list = &.{
                    .{ .float = 1 },
                } },
                .{ .float_list = &.{
                    .{ .float = 1 },
                } },
                .{ .int_list = &.{
                    .{ .int = 3 },
                } },
            } },
        },
    });
}
