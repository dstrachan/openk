const value_mod = @import("../../value.zig");
const Value = value_mod.Value;

const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;
const runTestError = vm_mod.runTestError;

const SubtractError = @import("../../verbs/subtract.zig").SubtractError;

test "subtract boolean" {
    try runTest("1b-0b", .{ .int = 1 });
    try runTest("1b-`boolean$()", .{ .int_list = &.{} });
    try runTest("1b-00000b", .{
        .int_list = &.{
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 1 },
        },
    });

    try runTest("1-0b", .{ .int = 1 });
    try runTest("1-`boolean$()", .{ .int_list = &.{} });
    try runTest("1-00000b", .{
        .int_list = &.{
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 1 },
        },
    });

    try runTest("1f-0b", .{ .float = 1 });
    try runTest("1f-`boolean$()", .{ .float_list = &.{} });
    try runTest("1f-00000b", .{
        .float_list = &.{
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .float = 1 },
        },
    });

    try runTestError("\"a\"-0b", SubtractError.incompatible_types);
    try runTestError("\"a\"-`boolean$()", SubtractError.incompatible_types);
    try runTestError("\"a\"-00000b", SubtractError.incompatible_types);

    try runTestError("`symbol-0b", SubtractError.incompatible_types);
    try runTestError("`symbol-`boolean$()", SubtractError.incompatible_types);
    try runTestError("`symbol-00000b", SubtractError.incompatible_types);

    try runTest("()-0b", .{ .list = &.{} });
    try runTest("(1b;2)-0b", .{
        .int_list = &.{
            .{ .int = 1 },
            .{ .int = 2 },
        },
    });
    try runTest("(1b;2;3f)-0b", .{
        .list = &.{
            .{ .int = 1 },
            .{ .int = 2 },
            .{ .float = 3 },
        },
    });
    try runTest("(1b;2;3f;(0b;1))-0b", .{
        .list = &.{
            .{ .int = 1 },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .int_list = &.{
                .{ .int = 0 },
                .{ .int = 1 },
            } },
        },
    });
    try runTestError("(1b;2;3f;`symbol)-0b", SubtractError.incompatible_types);
    try runTest("()-`boolean$()", .{ .list = &.{} });
    try runTestError("()-010b", SubtractError.length_mismatch);
    try runTestError("(1b;2)-`boolean$()", SubtractError.length_mismatch);
    try runTest("(1b;2)-01b", .{
        .int_list = &.{
            .{ .int = 1 },
            .{ .int = 1 },
        },
    });
    try runTest("(1b;2;3f)-010b", .{
        .list = &.{
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .float = 3 },
        },
    });
    try runTestError("(1b;2;3f)-0101b", SubtractError.length_mismatch);
    try runTestError("(1b;2;3f;\"a\")-0101b", SubtractError.incompatible_types);
    try runTestError("(1b;2;3f;`symbol)-0101b", SubtractError.incompatible_types);

    try runTest("11111b-0b", .{
        .int_list = &.{
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 1 },
        },
    });
    try runTestError("11111b-`boolean$()", SubtractError.length_mismatch);
    try runTest("11111b-00000b", .{
        .int_list = &.{
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 1 },
        },
    });
    try runTestError("11111b-000000b", SubtractError.length_mismatch);

    try runTest("5 4 3 2 1-0b", .{
        .int_list = &.{
            .{ .int = 5 },
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = 2 },
            .{ .int = 1 },
        },
    });
    try runTestError("5 4 3 2 1-`boolean$()", SubtractError.length_mismatch);
    try runTest("5 4 3 2 1-00000b", .{
        .int_list = &.{
            .{ .int = 5 },
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = 2 },
            .{ .int = 1 },
        },
    });
    try runTestError("5 4 3 2 1-000000b", SubtractError.length_mismatch);

    try runTest("5 4 3 2 1f-0b", .{
        .float_list = &.{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
        },
    });
    try runTestError("5 4 3 2 1f-`boolean$()", SubtractError.length_mismatch);
    try runTest("5 4 3 2 1f-00000b", .{
        .float_list = &.{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
        },
    });
    try runTestError("5 4 3 2 1f-000000b", SubtractError.length_mismatch);

    try runTestError("\"abcde\"-0b", SubtractError.incompatible_types);
    try runTestError("\"abcde\"-`boolean$()", SubtractError.incompatible_types);
    try runTestError("\"abcde\"-00000b", SubtractError.incompatible_types);
    try runTestError("\"abcde\"-000000b", SubtractError.incompatible_types);

    try runTestError("`a`b`c`d`e-0b", SubtractError.incompatible_types);
    try runTestError("`a`b`c`d`e-`boolean$()", SubtractError.incompatible_types);
    try runTestError("`a`b`c`d`e-00000b", SubtractError.incompatible_types);
    try runTestError("`a`b`c`d`e-000000b", SubtractError.incompatible_types);

    try runTest("(()!())-0b", .{
        .dictionary = &.{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("(`a`b!1 2)-0b", .{
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
    try runTestError("(`a`b!1 2)-`boolean$()", SubtractError.length_mismatch);
    try runTest("(`a`b!1 2)-01b", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .int_list = &.{
                .{ .int = 1 },
                .{ .int = 1 },
            } },
        },
    });
    try runTestError("(`a`b!1 2)-010b", SubtractError.length_mismatch);

    try runTest("(+`a`b!(,1;,2))-0b", .{
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
    try runTestError("(+`a`b!(,1;,`symbol))-0b", SubtractError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))-`boolean$()", SubtractError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))-01b", SubtractError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))-010b", SubtractError.incompatible_types);
}

test "subtract int" {
    try runTest("1b-0", .{ .int = 1 });
    try runTest("1b-`int$()", .{ .int_list = &.{} });
    try runTest("1b-0 1 0N 0W -0W", .{
        .int_list = &.{
            .{ .int = 1 },
            .{ .int = 0 },
            .{ .int = Value.null_int },
            .{ .int = -9223372036854775806 },
            .{ .int = Value.null_int },
        },
    });

    try runTest("1-0", .{ .int = 1 });
    try runTest("1-`int$()", .{ .int_list = &.{} });
    try runTest("1-0 1 0N 0W -0W", .{
        .int_list = &.{
            .{ .int = 1 },
            .{ .int = 0 },
            .{ .int = Value.null_int },
            .{ .int = -9223372036854775806 },
            .{ .int = Value.null_int },
        },
    });

    try runTest("1f-0", .{ .float = 1 });
    try runTest("1f-`int$()", .{ .float_list = &.{} });
    try runTest("1f-0 1 0N 0W -0W", .{
        .float_list = &.{
            .{ .float = 1 },
            .{ .float = 0 },
            .{ .float = Value.null_float },
            .{ .float = -Value.inf_int },
            .{ .float = Value.inf_int },
        },
    });

    try runTestError("\"a\"-0", SubtractError.incompatible_types);
    try runTestError("\"a\"-`int$()", SubtractError.incompatible_types);
    try runTestError("\"a\"-0 1 0N 0W -0W", SubtractError.incompatible_types);

    try runTestError("`symbol-0", SubtractError.incompatible_types);
    try runTestError("`symbol-`int$()", SubtractError.incompatible_types);
    try runTestError("`symbol-0 1 0N 0W -0W", SubtractError.incompatible_types);

    try runTest("()-0", .{ .list = &.{} });
    try runTest("(1b;2)-0", .{
        .int_list = &.{
            .{ .int = 1 },
            .{ .int = 2 },
        },
    });
    try runTest("(1b;2;3f)-0", .{
        .list = &.{
            .{ .int = 1 },
            .{ .int = 2 },
            .{ .float = 3 },
        },
    });
    try runTest("(1b;2;3f;(0b;1))-0", .{
        .list = &.{
            .{ .int = 1 },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .int_list = &.{
                .{ .int = 0 },
                .{ .int = 1 },
            } },
        },
    });
    try runTestError("(1b;2;3f;`symbol)-0", SubtractError.incompatible_types);
    try runTest("()-`int$()", .{ .list = &.{} });
    try runTestError("()-0 1 0N 0W -0W", SubtractError.length_mismatch);
    try runTestError("(1b;2;3;4;5)-`int$()", SubtractError.length_mismatch);
    try runTest("(1b;2;3;4;5)-0 1 0N 0W -0W", .{
        .int_list = &.{
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = -9223372036854775803 },
            .{ .int = -9223372036854775804 },
        },
    });
    try runTest("(1b;2;3f;4;5)-0 1 0N 0W -0W", .{
        .list = &.{
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .float = Value.null_float },
            .{ .int = -9223372036854775803 },
            .{ .int = -9223372036854775804 },
        },
    });
    try runTestError("(1b;2;3f;4)-0 1 0N 0W -0W", SubtractError.length_mismatch);
    try runTestError("(1b;2;3f;4;\"a\")-0 1 0N 0W -0W", SubtractError.incompatible_types);
    try runTestError("(1b;2;3f;4;`symbol)-0 1 0N 0W -0W", SubtractError.incompatible_types);

    try runTest("11111b-0", .{
        .int_list = &.{
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 1 },
        },
    });
    try runTestError("11111b-`int$()", SubtractError.length_mismatch);
    try runTest("11111b-0 1 0N 0W -0W", .{
        .int_list = &.{
            .{ .int = 1 },
            .{ .int = 0 },
            .{ .int = Value.null_int },
            .{ .int = -9223372036854775806 },
            .{ .int = Value.null_int },
        },
    });
    try runTestError("11111b-0 1 0N 0W -0W 2", SubtractError.length_mismatch);

    try runTest("5 4 3 2 1-0", .{
        .int_list = &.{
            .{ .int = 5 },
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = 2 },
            .{ .int = 1 },
        },
    });
    try runTestError("5 4 3 2 1-`int$()", SubtractError.length_mismatch);
    try runTest("5 4 3 2 1-0 1 0N 0W -0W", .{
        .int_list = &.{
            .{ .int = 5 },
            .{ .int = 3 },
            .{ .int = Value.null_int },
            .{ .int = -9223372036854775805 },
            .{ .int = Value.null_int },
        },
    });
    try runTestError("5 4 3 2 1-0 1 0N 0W -0W 2", SubtractError.length_mismatch);

    try runTest("5 4 3 2 1f-0", .{
        .float_list = &.{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
        },
    });
    try runTestError("5 4 3 2 1f-`int$()", SubtractError.length_mismatch);
    try runTest("5 4 3 2 1f-0 1 0N 0W -0W", .{
        .float_list = &.{
            .{ .float = 5 },
            .{ .float = 3 },
            .{ .float = Value.null_float },
            .{ .float = -Value.inf_int },
            .{ .float = Value.inf_int },
        },
    });
    try runTestError("5 4 3 2 1f-0 1 0N 0W -0W 2", SubtractError.length_mismatch);

    try runTestError("\"abcde\"-0", SubtractError.incompatible_types);
    try runTestError("\"abcde\"-`int$()", SubtractError.incompatible_types);
    try runTestError("\"abcde\"-0 1 0N 0W -0W", SubtractError.incompatible_types);
    try runTestError("\"abcde\"-0 1 0N 0W -0W 2", SubtractError.incompatible_types);

    try runTestError("`a`b`c`d`e-0", SubtractError.incompatible_types);
    try runTestError("`a`b`c`d`e-`int$()", SubtractError.incompatible_types);
    try runTestError("`a`b`c`d`e-0 1 0N 0W -0W", SubtractError.incompatible_types);
    try runTestError("`a`b`c`d`e-0 1 0N 0W -0W 2", SubtractError.incompatible_types);

    try runTest("(()!())-0", .{
        .dictionary = &.{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("(`a`b!1 2)-0", .{
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
    try runTestError("(`a`b!1 2)-`int$()", SubtractError.length_mismatch);
    try runTest("(`a`b!1 2)-0 1", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .int_list = &.{
                .{ .int = 1 },
                .{ .int = 1 },
            } },
        },
    });
    try runTestError("(`a`b!1 2)-0 1 2", SubtractError.length_mismatch);

    try runTest("(+`a`b!(,1;,2))-0", .{
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
    try runTestError("(+`a`b!(,1;,`symbol))-0", SubtractError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))-`int$()", SubtractError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))-0 1", SubtractError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))-0 1 2", SubtractError.incompatible_types);
}

test "subtract float" {
    try runTest("1b-0f", .{ .float = 1 });
    try runTest("1b-`float$()", .{ .float_list = &.{} });
    try runTest("1b-0 1 0n 0w -0w", .{
        .float_list = &.{
            .{ .float = 1 },
            .{ .float = 0 },
            .{ .float = Value.null_float },
            .{ .float = -Value.inf_float },
            .{ .float = Value.inf_float },
        },
    });

    try runTest("1-0f", .{ .float = 1 });
    try runTest("1-`float$()", .{ .float_list = &.{} });
    try runTest("1-0 1 0n 0w -0w", .{
        .float_list = &.{
            .{ .float = 1 },
            .{ .float = 0 },
            .{ .float = Value.null_float },
            .{ .float = -Value.inf_float },
            .{ .float = Value.inf_float },
        },
    });

    try runTest("1f-0f", .{ .float = 1 });
    try runTest("1f-`float$()", .{ .float_list = &.{} });
    try runTest("1f-0 1 0n 0w -0w", .{
        .float_list = &.{
            .{ .float = 1 },
            .{ .float = 0 },
            .{ .float = Value.null_float },
            .{ .float = -Value.inf_float },
            .{ .float = Value.inf_float },
        },
    });

    try runTestError("\"a\"-0f", SubtractError.incompatible_types);
    try runTestError("\"a\"-`float$()", SubtractError.incompatible_types);
    try runTestError("\"a\"-0 1 0n 0w -0w", SubtractError.incompatible_types);

    try runTestError("`symbol-0f", SubtractError.incompatible_types);
    try runTestError("`symbol-`float$()", SubtractError.incompatible_types);
    try runTestError("`symbol-0 1 0n 0w -0w", SubtractError.incompatible_types);

    try runTest("()-0f", .{ .list = &.{} });
    try runTest("(1b;2;3f)-0f", .{
        .float_list = &.{
            .{ .float = 1 },
            .{ .float = 2 },
            .{ .float = 3 },
        },
    });
    try runTest("(1b;2;3f;(0b;1))-0f", .{
        .list = &.{
            .{ .float = 1 },
            .{ .float = 2 },
            .{ .float = 3 },
            .{ .float_list = &.{
                .{ .float = 0 },
                .{ .float = 1 },
            } },
        },
    });
    try runTestError("(1b;2;3f;`symbol)-0f", SubtractError.incompatible_types);
    try runTest("()-`float$()", .{ .list = &.{} });
    try runTestError("()-0 1 0n 0w -0w", SubtractError.length_mismatch);
    try runTestError("(1b;2;3f;4;5)-`float$()", SubtractError.length_mismatch);
    try runTest("(1b;2;3f;4;5)-0 1 0n 0w -0w", .{
        .float_list = &.{
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = -Value.inf_float },
            .{ .float = Value.inf_float },
        },
    });
    try runTestError("(1b;2;3f;4)-0 1 0n 0w -0w", SubtractError.length_mismatch);
    try runTestError("(1b;2;3f;4;\"a\")-0 1 0n 0w -0w", SubtractError.incompatible_types);
    try runTestError("(1b;2;3f;4;`symbol)-0 1 0n 0w -0w", SubtractError.incompatible_types);

    try runTest("11111b-0f", .{
        .float_list = &.{
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .float = 1 },
        },
    });
    try runTestError("11111b-`float$()", SubtractError.length_mismatch);
    try runTest("11111b-0 1 0n 0w -0w", .{
        .float_list = &.{
            .{ .float = 1 },
            .{ .float = 0 },
            .{ .float = Value.null_float },
            .{ .float = -Value.inf_float },
            .{ .float = Value.inf_float },
        },
    });
    try runTestError("11111b-0 1 0n 0w -0w 2", SubtractError.length_mismatch);

    try runTest("5 4 3 2 1-0f", .{
        .float_list = &.{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
        },
    });
    try runTestError("5 4 3 2 1-`float$()", SubtractError.length_mismatch);
    try runTest("5 4 3 2 1-0 1 0n 0w -0w", .{
        .float_list = &.{
            .{ .float = 5 },
            .{ .float = 3 },
            .{ .float = Value.null_float },
            .{ .float = -Value.inf_float },
            .{ .float = Value.inf_float },
        },
    });
    try runTestError("5 4 3 2 1-0 1 0n 0w -0w 2", SubtractError.length_mismatch);

    try runTest("5 4 3 2 1f-0f", .{
        .float_list = &.{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
        },
    });
    try runTestError("5 4 3 2 1f-`float$()", SubtractError.length_mismatch);
    try runTest("5 4 3 2 1f-0 1 0n 0w -0w", .{
        .float_list = &.{
            .{ .float = 5 },
            .{ .float = 3 },
            .{ .float = Value.null_float },
            .{ .float = -Value.inf_float },
            .{ .float = Value.inf_float },
        },
    });
    try runTestError("5 4 3 2 1f-0 1 0n 0w -0w 2", SubtractError.length_mismatch);

    try runTestError("\"abcde\"-0f", SubtractError.incompatible_types);
    try runTestError("\"abcde\"-`float$()", SubtractError.incompatible_types);
    try runTestError("\"abcde\"-0 1 0n 0w -0w", SubtractError.incompatible_types);
    try runTestError("\"abcde\"-0 1 0n 0w -0w 2", SubtractError.incompatible_types);

    try runTestError("`a`b`c`d`e-0f", SubtractError.incompatible_types);
    try runTestError("`a`b`c`d`e-`float$()", SubtractError.incompatible_types);
    try runTestError("`a`b`c`d`e-0 1 0n 0w -0w", SubtractError.incompatible_types);
    try runTestError("`a`b`c`d`e-0 1 0n 0w -0w 2", SubtractError.incompatible_types);

    try runTest("(()!())-0f", .{
        .dictionary = &.{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("(`a`b!1 2)-0f", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .float_list = &.{
                .{ .float = 1 },
                .{ .float = 2 },
            } },
        },
    });
    try runTestError("(`a`b!1 2)-`float$()", SubtractError.length_mismatch);
    try runTest("(`a`b!1 2)-0 1f", .{
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
    try runTestError("(`a`b!1 2)-0 1 2f", SubtractError.length_mismatch);

    try runTest("(+`a`b!(,1;,2))-0f", .{
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
                    .{ .float = 2 },
                } },
            } },
        },
    });
    try runTestError("(+`a`b!(,1;,`symbol))-0f", SubtractError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))-`float$()", SubtractError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))-0 1f", SubtractError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))-0 1 2f", SubtractError.incompatible_types);
}

test "subtract char" {
    try runTestError("1b-\"a\"", SubtractError.incompatible_types);
    try runTestError("1b-\"\"", SubtractError.incompatible_types);
    try runTestError("1b-\"abcde\"", SubtractError.incompatible_types);

    try runTestError("1-\"a\"", SubtractError.incompatible_types);
    try runTestError("1-\"\"", SubtractError.incompatible_types);
    try runTestError("1-\"abcde\"", SubtractError.incompatible_types);

    try runTestError("1f-\"a\"", SubtractError.incompatible_types);
    try runTestError("1f-\"\"", SubtractError.incompatible_types);
    try runTestError("1f-\"abcde\"", SubtractError.incompatible_types);

    try runTestError("\"1\"-\"a\"", SubtractError.incompatible_types);
    try runTestError("\"1\"-\"\"", SubtractError.incompatible_types);
    try runTestError("\"1\"-\"abcde\"", SubtractError.incompatible_types);

    try runTestError("`symbol-\"a\"", SubtractError.incompatible_types);
    try runTestError("`symbol-\"\"", SubtractError.incompatible_types);
    try runTestError("`symbol-\"abcde\"", SubtractError.incompatible_types);

    try runTestError("()-\"a\"", SubtractError.incompatible_types);
    try runTestError("()-\"\"", SubtractError.incompatible_types);
    try runTestError("()-\"abcde\"", SubtractError.incompatible_types);

    try runTestError("10011b-\"a\"", SubtractError.incompatible_types);
    try runTestError("10011b-\"\"", SubtractError.incompatible_types);
    try runTestError("10011b-\"abcde\"", SubtractError.incompatible_types);

    try runTestError("5 4 3 2 1-\"a\"", SubtractError.incompatible_types);
    try runTestError("5 4 3 2 1-\"\"", SubtractError.incompatible_types);
    try runTestError("5 4 3 2 1-\"abcde\"", SubtractError.incompatible_types);

    try runTestError("5 4 3 2 1f-\"a\"", SubtractError.incompatible_types);
    try runTestError("5 4 3 2 1f-\"\"", SubtractError.incompatible_types);
    try runTestError("5 4 3 2 1f-\"abcde\"", SubtractError.incompatible_types);

    try runTestError("\"54321\"-\"a\"", SubtractError.incompatible_types);
    try runTestError("\"54321\"-\"\"", SubtractError.incompatible_types);
    try runTestError("\"54321\"-\"abcde\"", SubtractError.incompatible_types);

    try runTestError("`a`b`c`d`e-\"a\"", SubtractError.incompatible_types);
    try runTestError("`a`b`c`d`e-\"\"", SubtractError.incompatible_types);
    try runTestError("`a`b`c`d`e-\"abcde\"", SubtractError.incompatible_types);

    try runTestError("(`a`b!1 2)-\"a\"", SubtractError.incompatible_types);
    try runTestError("(`a`b!1 2)-\"\"", SubtractError.incompatible_types);
    try runTestError("(`a`b!1 2)-\"ab\"", SubtractError.incompatible_types);

    try runTestError("(+`a`b!(,1;,2))-\"a\"", SubtractError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))-\"\"", SubtractError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))-\"ab\"", SubtractError.incompatible_types);
}

test "subtract symbol" {
    try runTestError("1b-`symbol", SubtractError.incompatible_types);
    try runTestError("1b-`$()", SubtractError.incompatible_types);
    try runTestError("1b-`a`b`c`d`e", SubtractError.incompatible_types);

    try runTestError("1-`symbol", SubtractError.incompatible_types);
    try runTestError("1-`$()", SubtractError.incompatible_types);
    try runTestError("1-`a`b`c`d`e", SubtractError.incompatible_types);

    try runTestError("1f-`symbol", SubtractError.incompatible_types);
    try runTestError("1f-`$()", SubtractError.incompatible_types);
    try runTestError("1f-`a`b`c`d`e", SubtractError.incompatible_types);

    try runTestError("\"a\"-`symbol", SubtractError.incompatible_types);
    try runTestError("\"a\"-`$()", SubtractError.incompatible_types);
    try runTestError("\"a\"-`a`b`c`d`e", SubtractError.incompatible_types);

    try runTestError("`symbol-`a", SubtractError.incompatible_types);
    try runTestError("`symbol-`$()", SubtractError.incompatible_types);
    try runTestError("`symbol-`a`b`c`d`e", SubtractError.incompatible_types);

    try runTestError("()-`symbol", SubtractError.incompatible_types);
    try runTestError("()-`$()", SubtractError.incompatible_types);
    try runTestError("()-`a`b`c`d`e", SubtractError.incompatible_types);

    try runTestError("10011b-`symbol", SubtractError.incompatible_types);
    try runTestError("10011b-`$()", SubtractError.incompatible_types);
    try runTestError("10011b-`a`b`c`d`e", SubtractError.incompatible_types);

    try runTestError("5 4 3 2 1-`symbol", SubtractError.incompatible_types);
    try runTestError("5 4 3 2 1-`$()", SubtractError.incompatible_types);
    try runTestError("5 4 3 2 1-`a`b`c`d`e", SubtractError.incompatible_types);

    try runTestError("5 4 3 2 1f-`symbol", SubtractError.incompatible_types);
    try runTestError("5 4 3 2 1f-`$()", SubtractError.incompatible_types);
    try runTestError("5 4 3 2 1f-`a`b`c`d`e", SubtractError.incompatible_types);

    try runTestError("\"54321\"-`symbol", SubtractError.incompatible_types);
    try runTestError("\"54321\"-`$()", SubtractError.incompatible_types);
    try runTestError("\"54321\"-`a`b`c`d`e", SubtractError.incompatible_types);

    try runTestError("`5`4`3`2`1-`symbol", SubtractError.incompatible_types);
    try runTestError("`5`4`3`2`1-`$()", SubtractError.incompatible_types);
    try runTestError("`5`4`3`2`1-`a`b`c`d`e", SubtractError.incompatible_types);

    try runTestError("(`a`b!1 2)-`symbol", SubtractError.incompatible_types);
    try runTestError("(`a`b!1 2)-`$()", SubtractError.incompatible_types);
    try runTestError("(`a`b!1 2)-`a`b", SubtractError.incompatible_types);

    try runTestError("(+`a`b!(,1;,2))-`symbol", SubtractError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))-`$()", SubtractError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))-`a`b", SubtractError.incompatible_types);
}

test "subtract list" {
    try runTest("1b-()", .{ .list = &.{} });
    try runTest("1b-(0b;1;0N;0W;-0W)", .{
        .int_list = &.{
            .{ .int = 1 },
            .{ .int = 0 },
            .{ .int = Value.null_int },
            .{ .int = -9223372036854775806 },
            .{ .int = Value.null_int },
        },
    });
    try runTest("1b-(0b;1;0N;0W;-0W;1f;0n;0w;-0w)", .{
        .list = &.{
            .{ .int = 1 },
            .{ .int = 0 },
            .{ .int = Value.null_int },
            .{ .int = -9223372036854775806 },
            .{ .int = Value.null_int },
            .{ .float = 0 },
            .{ .float = Value.null_float },
            .{ .float = -Value.inf_float },
            .{ .float = Value.inf_float },
        },
    });
    try runTestError("1b-(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", SubtractError.incompatible_types);
    try runTestError("1b-(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", SubtractError.incompatible_types);

    try runTest("1-()", .{ .list = &.{} });
    try runTest("1-(0b;1;0N;0W;-0W)", .{
        .int_list = &.{
            .{ .int = 1 },
            .{ .int = 0 },
            .{ .int = Value.null_int },
            .{ .int = -9223372036854775806 },
            .{ .int = Value.null_int },
        },
    });
    try runTest("1-(0b;1;0N;0W;-0W;1f;0n;0w;-0w)", .{
        .list = &.{
            .{ .int = 1 },
            .{ .int = 0 },
            .{ .int = Value.null_int },
            .{ .int = -9223372036854775806 },
            .{ .int = Value.null_int },
            .{ .float = 0 },
            .{ .float = Value.null_float },
            .{ .float = -Value.inf_float },
            .{ .float = Value.inf_float },
        },
    });
    try runTestError("1-(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", SubtractError.incompatible_types);
    try runTestError("1-(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", SubtractError.incompatible_types);

    try runTest("1f-()", .{ .list = &.{} });
    try runTest("1f-(0b;1;0N;0W;-0W;1f;0n;0w;-0w)", .{
        .float_list = &.{
            .{ .float = 1 },
            .{ .float = 0 },
            .{ .float = Value.null_float },
            .{ .float = -Value.inf_int },
            .{ .float = Value.inf_int },
            .{ .float = 0 },
            .{ .float = Value.null_float },
            .{ .float = -Value.inf_float },
            .{ .float = Value.inf_float },
        },
    });
    try runTestError("1f-(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", SubtractError.incompatible_types);
    try runTestError("1f-(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", SubtractError.incompatible_types);

    try runTestError("\"a\"-()", SubtractError.incompatible_types);

    try runTestError("`symbol-()", SubtractError.incompatible_types);

    try runTest("()-()", .{ .list = &.{} });
    try runTestError("(0N;0n)-()", SubtractError.length_mismatch);
    try runTestError("()-(0N;0n)", SubtractError.length_mismatch);
    try runTest("(1b;2)-(1b;2)", .{
        .int_list = &.{
            .{ .int = 0 },
            .{ .int = 0 },
        },
    });
    try runTest("(1b;2f)-(2f;1b)", .{
        .float_list = &.{
            .{ .float = -1 },
            .{ .float = 1 },
        },
    });
    try runTest("(2;3f)-(2;3f)", .{
        .list = &.{
            .{ .int = 0 },
            .{ .float = 0 },
        },
    });
    try runTest("(1b;(2;3f))-(0N;(0n;0N))", .{
        .list = &.{
            .{ .int = Value.null_int },
            .{ .float_list = &.{
                .{ .float = Value.null_float },
                .{ .float = Value.null_float },
            } },
        },
    });
    try runTestError("(0b;1;2;3;4;5;6;7;8;9)-(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", SubtractError.incompatible_types);
    try runTestError("(0b;1;2;3;4;5;6;7;8;9)-(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", SubtractError.incompatible_types);

    try runTestError("010b-()", SubtractError.length_mismatch);
    try runTest("01b-(0b;0N)", .{
        .int_list = &.{
            .{ .int = 0 },
            .{ .int = Value.null_int },
        },
    });
    try runTest("010b-(0b;0N;0n)", .{
        .list = &.{
            .{ .int = 0 },
            .{ .int = Value.null_int },
            .{ .float = Value.null_float },
        },
    });
    try runTestError("0101010101b-(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", SubtractError.incompatible_types);
    try runTestError("0101010101b-(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", SubtractError.incompatible_types);

    try runTestError("0 1 2-()", SubtractError.length_mismatch);
    try runTest("0 1-(0b;0N)", .{
        .int_list = &.{
            .{ .int = 0 },
            .{ .int = Value.null_int },
        },
    });
    try runTest("0 1 2-(0b;0N;0n)", .{
        .list = &.{
            .{ .int = 0 },
            .{ .int = Value.null_int },
            .{ .float = Value.null_float },
        },
    });
    try runTestError("0 1 2 3 4 5 6 7 8 9-(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", SubtractError.incompatible_types);
    try runTestError("0 1 2 3 4 5 6 7 8 9-(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", SubtractError.incompatible_types);

    try runTestError("0 1 2f-()", SubtractError.length_mismatch);
    try runTest("0 1 2f-(0b;0N;0n)", .{
        .float_list = &.{
            .{ .float = 0 },
            .{ .float = Value.null_float },
            .{ .float = Value.null_float },
        },
    });
    try runTestError("0 1 2 3 4 5 6 7 8 9f-(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", SubtractError.incompatible_types);
    try runTestError("0 1 2 3 4 5 6 7 8 9f-(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", SubtractError.incompatible_types);

    try runTestError("\"abcde\"-()", SubtractError.incompatible_types);

    try runTestError("`a`b`c`d`e-()", SubtractError.incompatible_types);

    try runTestError("(`a`b!1 2)-()", SubtractError.length_mismatch);
    try runTest("(`a`b!1 2)-(1;2f)", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .int = 0 },
                .{ .float = 0 },
            } },
        },
    });
    try runTestError("(`a`b!1 2)-(0b;1;2f)", SubtractError.length_mismatch);

    try runTestError("(+`a`b!(,1;,2))-()", SubtractError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))-(1;2f)", SubtractError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))-(0b;1;2f)", SubtractError.incompatible_types);
}

test "subtract dictionary" {
    try runTest("1b-()!()", .{
        .dictionary = &.{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("1b-`a`b!1 2", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .int_list = &.{
                .{ .int = 0 },
                .{ .int = -1 },
            } },
        },
    });

    try runTest("1-()!()", .{
        .dictionary = &.{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("1-`a`b!1 2", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .int_list = &.{
                .{ .int = 0 },
                .{ .int = -1 },
            } },
        },
    });

    try runTest("1f-()!()", .{
        .dictionary = &.{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("1f-`a`b!1 2", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .float_list = &.{
                .{ .float = 0 },
                .{ .float = -1 },
            } },
        },
    });

    try runTestError("\"a\"-`a`b!1 2", SubtractError.incompatible_types);

    try runTestError("`symbol-`a`b!1 2", SubtractError.incompatible_types);

    try runTest("()-()!()", .{
        .dictionary = &.{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTestError("()-`a`b!1 2", SubtractError.length_mismatch);
    try runTest("(1;2f)-`a`b!1 2", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .int = 0 },
                .{ .float = 0 },
            } },
        },
    });
    try runTestError("(0b;1;2f)-`a`b!1 2", SubtractError.length_mismatch);

    try runTest("(`boolean$())-()!()", .{
        .dictionary = &.{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTestError("(`boolean$())-`a`b!1 2", SubtractError.length_mismatch);
    try runTest("10b-`a`b!1 2", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .int_list = &.{
                .{ .int = 0 },
                .{ .int = -2 },
            } },
        },
    });
    try runTestError("101b-`a`b!1 2", SubtractError.length_mismatch);

    try runTest("(`int$())-()!()", .{
        .dictionary = &.{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTestError("(`int$())-`a`b!1 2", SubtractError.length_mismatch);
    try runTest("1 2-`a`b!1 2", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .int_list = &.{
                .{ .int = 0 },
                .{ .int = 0 },
            } },
        },
    });
    try runTestError("1 2 3-`a`b!1 2", SubtractError.length_mismatch);

    try runTest("(`float$())-()!()", .{
        .dictionary = &.{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTestError("(`float$())-`a`b!1 2", SubtractError.length_mismatch);
    try runTest("1 2f-`a`b!1 2", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .float_list = &.{
                .{ .float = 0 },
                .{ .float = 0 },
            } },
        },
    });
    try runTestError("1 2 3f-`a`b!1 2", SubtractError.length_mismatch);

    try runTestError("\"\"-`a`b!1 2", SubtractError.incompatible_types);
    try runTestError("\"12\"-`a`b!1 2", SubtractError.incompatible_types);
    try runTestError("\"123\"-`a`b!1 2", SubtractError.incompatible_types);

    try runTestError("(`$())-`a`b!1 2", SubtractError.incompatible_types);
    try runTestError("`5`4-`a`b!1 2", SubtractError.incompatible_types);
    try runTestError("`5`4`3-`a`b!1 2", SubtractError.incompatible_types);

    try runTest("(()!())-()!()", .{
        .dictionary = &.{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("(()!())-`a`b!1 2", .{
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
    try runTest("(`a`b!1 2)-()!()", .{
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
    try runTest("(`a`b!1 2)-`a`b!1 2", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .int_list = &.{
                .{ .int = 0 },
                .{ .int = 0 },
            } },
        },
    });
    try runTest("(`a`b!1 2)-`a`b!1 2f", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .float_list = &.{
                .{ .float = 0 },
                .{ .float = 0 },
            } },
        },
    });
    try runTestError("(`a`b!1 2)-`a`b!(1;`a)", SubtractError.incompatible_types);
    try runTest("(`b`a!1 2)-`a`b!1 2", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "b" },
                .{ .symbol = "a" },
            } },
            .{ .int_list = &.{
                .{ .int = -1 },
                .{ .int = 1 },
            } },
        },
    });
    try runTest("(`a`b!1 2)-`b`a!1 2", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .int_list = &.{
                .{ .int = -1 },
                .{ .int = 1 },
            } },
        },
    });
    try runTest("(`a`b!1 2)-`c`d!1 2", .{
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
                .{ .int = -1 },
                .{ .int = -2 },
            } },
        },
    });
    try runTestError("(`a`b!1 2)-`a`b!(1;\"2\")", SubtractError.incompatible_types);

    try runTestError("(+`a`b!(,1;,2))-`a`b!1 2", SubtractError.incompatible_types);
}

test "subtract table" {
    try runTest("1b-+`a`b!(,1;,2)", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 0 },
                } },
                .{ .int_list = &.{
                    .{ .int = -1 },
                } },
            } },
        },
    });

    try runTest("1-+`a`b!(,1;,2)", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 0 },
                } },
                .{ .int_list = &.{
                    .{ .int = -1 },
                } },
            } },
        },
    });

    try runTest("1f-+`a`b!(,1;,2)", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .float_list = &.{
                    .{ .float = 0 },
                } },
                .{ .float_list = &.{
                    .{ .float = -1 },
                } },
            } },
        },
    });

    try runTestError("\"a\"-+`a`b!(,1;,2)", SubtractError.incompatible_types);

    try runTestError("`symbol-+`a`b!(,1;,2)", SubtractError.incompatible_types);

    try runTestError("()-+`a`b!(,1;,2)", SubtractError.incompatible_types);
    try runTestError("(1;2f)-+`a`b!(,1;,2)", SubtractError.incompatible_types);
    try runTestError("(0b;1;2f)-+`a`b!(,1;,2)", SubtractError.incompatible_types);

    try runTestError("(`boolean$())-+`a`b!(,1;,2)", SubtractError.incompatible_types);
    try runTestError("10b-+`a`b!(,1;,2)", SubtractError.incompatible_types);
    try runTestError("101b-+`a`b!(,1;,2)", SubtractError.incompatible_types);

    try runTestError("(`int$())-+`a`b!(,1;,2)", SubtractError.incompatible_types);
    try runTestError("1 2-+`a`b!(,1;,2)", SubtractError.incompatible_types);
    try runTestError("1 2 3-+`a`b!(,1;,2)", SubtractError.incompatible_types);

    try runTestError("(`float$())-+`a`b!(,1;,2)", SubtractError.incompatible_types);
    try runTestError("1 2f-+`a`b!(,1;,2)", SubtractError.incompatible_types);
    try runTestError("1 2 3f-+`a`b!(,1;,2)", SubtractError.incompatible_types);

    try runTestError("\"\"-+`a`b!(,1;,2)", SubtractError.incompatible_types);
    try runTestError("\"12\"-+`a`b!(,1;,2)", SubtractError.incompatible_types);
    try runTestError("\"123\"-+`a`b!(,1;,2)", SubtractError.incompatible_types);

    try runTestError("(`$())-+`a`b!(,1;,2)", SubtractError.incompatible_types);
    try runTestError("`5`4-+`a`b!(,1;,2)", SubtractError.incompatible_types);
    try runTestError("`5`4`3-+`a`b!(,1;,2)", SubtractError.incompatible_types);

    try runTestError("(`a`b!1 2)-+`a`b!(,1;,2)", SubtractError.incompatible_types);

    try runTest("(+`a`b!(,1;,2))-+`a`b!(,1;,2)", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 0 },
                } },
                .{ .int_list = &.{
                    .{ .int = 0 },
                } },
            } },
        },
    });
    try runTest("(+`b`a!(,1;,2))-+`a`b!(,1;,2)", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "b" },
                .{ .symbol = "a" },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = -1 },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                } },
            } },
        },
    });
    try runTest("(+`a`b!(,1;,2))-+`b`a!(,1;,2)", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = -1 },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                } },
            } },
        },
    });
    try runTestError("(+`a`b!(,1;,2))-+`a`b!(,1;,`symbol)", SubtractError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))-+`a`b!(1 1;2 2)", SubtractError.length_mismatch);
    try runTest("(+`a`b!(,1;,2))-+`a`b`c!(,1;,2;,3)", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
                .{ .symbol = "c" },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 0 },
                } },
                .{ .int_list = &.{
                    .{ .int = 0 },
                } },
                .{ .int_list = &.{
                    .{ .int = -3 },
                } },
            } },
        },
    });
    try runTest("(+`a`b`c!(,1;,2;,3))-+`a`b!(,1;,2)", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
                .{ .symbol = "c" },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 0 },
                } },
                .{ .int_list = &.{
                    .{ .int = 0 },
                } },
                .{ .int_list = &.{
                    .{ .int = 3 },
                } },
            } },
        },
    });
}
