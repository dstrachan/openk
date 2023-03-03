const value_mod = @import("../../value.zig");
const Value = value_mod.Value;

const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;
const runTestError = vm_mod.runTestError;
const TestValue = vm_mod.TestValue;

const MaxError = @import("../../verbs/max.zig").MaxError;

test "max boolean" {
    try runTest("1b|0b", .{ .boolean = true });
    try runTest("1b|`boolean$()", .{ .boolean_list = &[_]TestValue{} });
    try runTest("1b|00000b", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });

    try runTest("1|0b", .{ .int = 1 });
    try runTest("1|`boolean$()", .{ .int_list = &[_]TestValue{} });
    try runTest("1|00000b", .{
        .int_list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 1 },
        },
    });

    try runTest("1f|0b", .{ .float = 1 });
    try runTest("1f|`boolean$()", .{ .float_list = &[_]TestValue{} });
    try runTest("1f|00000b", .{
        .float_list = &[_]TestValue{
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .float = 1 },
        },
    });

    try runTestError("\"a\"|0b", MaxError.incompatible_types);
    try runTestError("\"a\"|`boolean$()", MaxError.incompatible_types);
    try runTestError("\"a\"|00000b", MaxError.incompatible_types);

    try runTestError("`symbol|0b", MaxError.incompatible_types);
    try runTestError("`symbol|`boolean$()", MaxError.incompatible_types);
    try runTestError("`symbol|00000b", MaxError.incompatible_types);

    try runTest("()|0b", .{ .list = &[_]TestValue{} });
    try runTest("(1b;2)|0b", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .int = 2 },
        },
    });
    try runTest("(1b;2;3f)|0b", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
        },
    });
    try runTestError("(1b;2;3f;`symbol)|0b", MaxError.incompatible_types);
    try runTest("()|`boolean$()", .{ .list = &[_]TestValue{} });
    try runTestError("()|010b", MaxError.length_mismatch);
    try runTestError("(1b;2)|`boolean$()", MaxError.length_mismatch);
    try runTest("(1b;2)|01b", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .int = 2 },
        },
    });
    try runTest("(1b;2;3f)|010b", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
        },
    });
    try runTestError("(1b;2;3f)|0101b", MaxError.length_mismatch);
    try runTestError("(1b;2;3f;\"a\")|0101b", MaxError.incompatible_types);
    try runTestError("(1b;2;3f;`symbol)|0101b", MaxError.incompatible_types);

    try runTest("11111b|0b", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTestError("11111b|`boolean$()", MaxError.length_mismatch);
    try runTest("11111b|00000b", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTestError("11111b|000000b", MaxError.length_mismatch);

    try runTest("5 4 3 2 1|0b", .{
        .int_list = &[_]TestValue{
            .{ .int = 5 },
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = 2 },
            .{ .int = 1 },
        },
    });
    try runTestError("5 4 3 2 1|`boolean$()", MaxError.length_mismatch);
    try runTest("5 4 3 2 1|00000b", .{
        .int_list = &[_]TestValue{
            .{ .int = 5 },
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = 2 },
            .{ .int = 1 },
        },
    });
    try runTestError("5 4 3 2 1|000000b", MaxError.length_mismatch);

    try runTest("5 4 3 2 1f|0b", .{
        .float_list = &[_]TestValue{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
        },
    });
    try runTestError("5 4 3 2 1f|`boolean$()", MaxError.length_mismatch);
    try runTest("5 4 3 2 1f|00000b", .{
        .float_list = &[_]TestValue{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
        },
    });
    try runTestError("5 4 3 2 1f|000000b", MaxError.length_mismatch);

    try runTestError("\"abcde\"|0b", MaxError.incompatible_types);
    try runTestError("\"abcde\"|`boolean$()", MaxError.incompatible_types);
    try runTestError("\"abcde\"|00000b", MaxError.incompatible_types);
    try runTestError("\"abcde\"|000000b", MaxError.incompatible_types);

    try runTestError("`a`b`c`d`e|0b", MaxError.incompatible_types);
    try runTestError("`a`b`c`d`e|`boolean$()", MaxError.incompatible_types);
    try runTestError("`a`b`c`d`e|00000b", MaxError.incompatible_types);
    try runTestError("`a`b`c`d`e|000000b", MaxError.incompatible_types);

    try runTest("(()!())|0b", .{
        .dictionary = &[_]TestValue{
            .{ .list = &[_]TestValue{} },
            .{ .list = &[_]TestValue{} },
        },
    });
    try runTest("(`a`b!1 2)|0b", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .int_list = &[_]TestValue{
                .{ .int = 1 },
                .{ .int = 2 },
            } },
        },
    });
    try runTestError("(`a`b!1 2)|`boolean$()", MaxError.length_mismatch);
    try runTest("(`a`b!1 2)|01b", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .int_list = &[_]TestValue{
                .{ .int = 1 },
                .{ .int = 2 },
            } },
        },
    });
    try runTestError("(`a`b!1 2)|010b", MaxError.length_mismatch);

    try runTest("(+`a`b!(,1;,2))|0b", .{
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
    try runTestError("(+`a`b!(,1;,`symbol))|0b", MaxError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))|`boolean$()", MaxError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))|01b", MaxError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))|010b", MaxError.incompatible_types);
}

test "max int" {
    try runTest("1b|0", .{ .int = 1 });
    try runTest("1b|`int$()", .{ .int_list = &[_]TestValue{} });
    try runTest("1b|0 1 0N 0W -0W", .{
        .int_list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = Value.inf_int },
            .{ .int = 1 },
        },
    });

    try runTest("1|0", .{ .int = 1 });
    try runTest("1|`int$()", .{ .int_list = &[_]TestValue{} });
    try runTest("1|0 1 0N 0W -0W", .{
        .int_list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = Value.inf_int },
            .{ .int = 1 },
        },
    });

    try runTest("1f|0", .{ .float = 1 });
    try runTest("1f|`int$()", .{ .float_list = &[_]TestValue{} });
    try runTest("1f|0 1 0N 0W -0W", .{
        .float_list = &[_]TestValue{
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .float = Value.inf_int },
            .{ .float = 1 },
        },
    });

    try runTestError("\"a\"|0", MaxError.incompatible_types);
    try runTestError("\"a\"|`int$()", MaxError.incompatible_types);
    try runTestError("\"a\"|0 1 0N 0W -0W", MaxError.incompatible_types);

    try runTestError("`symbol|0", MaxError.incompatible_types);
    try runTestError("`symbol|`int$()", MaxError.incompatible_types);
    try runTestError("`symbol|0 1 0N 0W -0W", MaxError.incompatible_types);

    try runTest("()|0", .{ .list = &[_]TestValue{} });
    try runTest("(1b;2)|0", .{
        .int_list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 2 },
        },
    });
    try runTest("(1b;2;3f)|0", .{
        .list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 2 },
            .{ .float = 3 },
        },
    });
    try runTestError("(1b;2;3f;`symbol)|0", MaxError.incompatible_types);
    try runTest("()|`int$()", .{ .list = &[_]TestValue{} });
    try runTestError("()|0 1 0N 0W -0W", MaxError.length_mismatch);
    try runTestError("(1b;2;3;4;5)|`int$()", MaxError.length_mismatch);
    try runTest("(1b;2;3;4;5)|0 1 0N 0W -0W", .{
        .int_list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 2 },
            .{ .int = 3 },
            .{ .int = Value.inf_int },
            .{ .int = 5 },
        },
    });
    try runTest("(1b;2;3f;4;5)|0 1 0N 0W -0W", .{
        .list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .int = Value.inf_int },
            .{ .int = 5 },
        },
    });
    try runTestError("(1b;2;3f;4)|0 1 0N 0W -0W", MaxError.length_mismatch);
    try runTestError("(1b;2;3f;4;\"a\")|0 1 0N 0W -0W", MaxError.incompatible_types);
    try runTestError("(1b;2;3f;4;`symbol)|0 1 0N 0W -0W", MaxError.incompatible_types);

    try runTest("11111b|0", .{
        .int_list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 1 },
        },
    });
    try runTestError("11111b|`int$()", MaxError.length_mismatch);
    try runTest("11111b|0 1 0N 0W -0W", .{
        .int_list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = Value.inf_int },
            .{ .int = 1 },
        },
    });
    try runTestError("11111b|0 1 0N 0W -0W 2", MaxError.length_mismatch);

    try runTest("5 4 3 2 1|0", .{
        .int_list = &[_]TestValue{
            .{ .int = 5 },
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = 2 },
            .{ .int = 1 },
        },
    });
    try runTestError("5 4 3 2 1|`int$()", MaxError.length_mismatch);
    try runTest("5 4 3 2 1|0 1 0N 0W -0W", .{
        .int_list = &[_]TestValue{
            .{ .int = 5 },
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = Value.inf_int },
            .{ .int = 1 },
        },
    });
    try runTestError("5 4 3 2 1|0 1 0N 0W -0W 2", MaxError.length_mismatch);

    try runTest("5 4 3 2 1f|0", .{
        .float_list = &[_]TestValue{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
        },
    });
    try runTestError("5 4 3 2 1f|`int$()", MaxError.length_mismatch);
    try runTest("5 4 3 2 1f|0 1 0N 0W -0W", .{
        .float_list = &[_]TestValue{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = Value.inf_int },
            .{ .float = 1 },
        },
    });
    try runTestError("5 4 3 2 1f|0 1 0N 0W -0W 2", MaxError.length_mismatch);

    try runTestError("\"abcde\"|0", MaxError.incompatible_types);
    try runTestError("\"abcde\"|`int$()", MaxError.incompatible_types);
    try runTestError("\"abcde\"|0 1 0N 0W -0W", MaxError.incompatible_types);
    try runTestError("\"abcde\"|0 1 0N 0W -0W 2", MaxError.incompatible_types);

    try runTestError("`a`b`c`d`e|0", MaxError.incompatible_types);
    try runTestError("`a`b`c`d`e|`int$()", MaxError.incompatible_types);
    try runTestError("`a`b`c`d`e|0 1 0N 0W -0W", MaxError.incompatible_types);
    try runTestError("`a`b`c`d`e|0 1 0N 0W -0W 2", MaxError.incompatible_types);

    try runTest("(()!())|0", .{
        .dictionary = &[_]TestValue{
            .{ .list = &[_]TestValue{} },
            .{ .list = &[_]TestValue{} },
        },
    });
    try runTest("(`a`b!1 2)|0", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .int_list = &[_]TestValue{
                .{ .int = 1 },
                .{ .int = 2 },
            } },
        },
    });
    try runTestError("(`a`b!1 2)|`int$()", MaxError.length_mismatch);
    try runTest("(`a`b!1 2)|0 1", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .int_list = &[_]TestValue{
                .{ .int = 1 },
                .{ .int = 2 },
            } },
        },
    });
    try runTestError("(`a`b!1 2)|0 1 2", MaxError.length_mismatch);

    try runTest("(+`a`b!(,1;,2))|0", .{
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
    try runTestError("(+`a`b!(,1;,`symbol))|0", MaxError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))|`int$()", MaxError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))|0 1", MaxError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))|0 1 2", MaxError.incompatible_types);
}

test "max float" {
    try runTest("1b|0f", .{ .float = 1 });
    try runTest("1b|`float$()", .{ .float_list = &[_]TestValue{} });
    try runTest("1b|0 1 0n 0w -0w", .{
        .float_list = &[_]TestValue{
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .float = Value.inf_float },
            .{ .float = 1 },
        },
    });

    try runTest("1|0f", .{ .float = 1 });
    try runTest("1|`float$()", .{ .float_list = &[_]TestValue{} });
    try runTest("1|0 1 0n 0w -0w", .{
        .float_list = &[_]TestValue{
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .float = Value.inf_float },
            .{ .float = 1 },
        },
    });

    try runTest("1f|0f", .{ .float = 1 });
    try runTest("1f|`float$()", .{ .float_list = &[_]TestValue{} });
    try runTest("1f|0 1 0n 0w -0w", .{
        .float_list = &[_]TestValue{
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .float = Value.inf_float },
            .{ .float = 1 },
        },
    });

    try runTestError("\"a\"|0f", MaxError.incompatible_types);
    try runTestError("\"a\"|`float$()", MaxError.incompatible_types);
    try runTestError("\"a\"|0 1 0n 0w -0w", MaxError.incompatible_types);

    try runTestError("`symbol|0f", MaxError.incompatible_types);
    try runTestError("`symbol|`float$()", MaxError.incompatible_types);
    try runTestError("`symbol|0 1 0n 0w -0w", MaxError.incompatible_types);

    try runTest("()|0f", .{ .list = &[_]TestValue{} });
    try runTest("(1b;2;3f)|0f", .{
        .float_list = &[_]TestValue{
            .{ .float = 1 },
            .{ .float = 2 },
            .{ .float = 3 },
        },
    });
    try runTestError("(1b;2;3f;`symbol)|0f", MaxError.incompatible_types);
    try runTest("()|`float$()", .{ .list = &[_]TestValue{} });
    try runTestError("()|0 1 0n 0w -0w", MaxError.length_mismatch);
    try runTestError("(1b;2;3f;4;5)|`float$()", MaxError.length_mismatch);
    try runTest("(1b;2;3f;4;5)|0 1 0n 0w -0w", .{
        .float_list = &[_]TestValue{
            .{ .float = 1 },
            .{ .float = 2 },
            .{ .float = 3 },
            .{ .float = Value.inf_float },
            .{ .float = 5 },
        },
    });
    try runTestError("(1b;2;3f;4)|0 1 0n 0w -0w", MaxError.length_mismatch);
    try runTestError("(1b;2;3f;4;\"a\")|0 1 0n 0w -0w", MaxError.incompatible_types);
    try runTestError("(1b;2;3f;4;`symbol)|0 1 0n 0w -0w", MaxError.incompatible_types);

    try runTest("11111b|0f", .{
        .float_list = &[_]TestValue{
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .float = 1 },
        },
    });
    try runTestError("11111b|`float$()", MaxError.length_mismatch);
    try runTest("11111b|0 1 0n 0w -0w", .{
        .float_list = &[_]TestValue{
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .float = Value.inf_float },
            .{ .float = 1 },
        },
    });
    try runTestError("11111b|0 1 0n 0w -0w 2", MaxError.length_mismatch);

    try runTest("5 4 3 2 1|0f", .{
        .float_list = &[_]TestValue{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
        },
    });
    try runTestError("5 4 3 2 1|`float$()", MaxError.length_mismatch);
    try runTest("5 4 3 2 1|0 1 0n 0w -0w", .{
        .float_list = &[_]TestValue{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = Value.inf_float },
            .{ .float = 1 },
        },
    });
    try runTestError("5 4 3 2 1|0 1 0n 0w -0w 2", MaxError.length_mismatch);

    try runTest("5 4 3 2 1f|0f", .{
        .float_list = &[_]TestValue{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
        },
    });
    try runTestError("5 4 3 2 1f|`float$()", MaxError.length_mismatch);
    try runTest("5 4 3 2 1f|0 1 0n 0w -0w", .{
        .float_list = &[_]TestValue{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = Value.inf_float },
            .{ .float = 1 },
        },
    });
    try runTestError("5 4 3 2 1f|0 1 0n 0w -0w 2", MaxError.length_mismatch);

    try runTestError("\"abcde\"|0f", MaxError.incompatible_types);
    try runTestError("\"abcde\"|`float$()", MaxError.incompatible_types);
    try runTestError("\"abcde\"|0 1 0n 0w -0w", MaxError.incompatible_types);
    try runTestError("\"abcde\"|0 1 0n 0w -0w 2", MaxError.incompatible_types);

    try runTestError("`a`b`c`d`e|0f", MaxError.incompatible_types);
    try runTestError("`a`b`c`d`e|`float$()", MaxError.incompatible_types);
    try runTestError("`a`b`c`d`e|0 1 0n 0w -0w", MaxError.incompatible_types);
    try runTestError("`a`b`c`d`e|0 1 0n 0w -0w 2", MaxError.incompatible_types);

    try runTest("(()!())|0f", .{
        .dictionary = &[_]TestValue{
            .{ .list = &[_]TestValue{} },
            .{ .list = &[_]TestValue{} },
        },
    });
    try runTest("(`a`b!1 2)|0f", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .float_list = &[_]TestValue{
                .{ .float = 1 },
                .{ .float = 2 },
            } },
        },
    });
    try runTestError("(`a`b!1 2)|`float$()", MaxError.length_mismatch);
    try runTest("(`a`b!1 2)|0 1f", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .float_list = &[_]TestValue{
                .{ .float = 1 },
                .{ .float = 2 },
            } },
        },
    });
    try runTestError("(`a`b!1 2)|0 1 2f", MaxError.length_mismatch);

    try runTest("(+`a`b!(,1;,2))|0f", .{
        .table = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .float_list = &[_]TestValue{
                    .{ .float = 1 },
                } },
                .{ .float_list = &[_]TestValue{
                    .{ .float = 2 },
                } },
            } },
        },
    });
    try runTestError("(+`a`b!(,1;,`symbol))|0f", MaxError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))|`float$()", MaxError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))|0 1f", MaxError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))|0 1 2f", MaxError.incompatible_types);
}

test "max char" {
    try runTestError("1b&\"a\"", MaxError.incompatible_types);
    try runTestError("1b&\"\"", MaxError.incompatible_types);
    try runTestError("1b&\"abcde\"", MaxError.incompatible_types);

    try runTestError("1&\"a\"", MaxError.incompatible_types);
    try runTestError("1&\"\"", MaxError.incompatible_types);
    try runTestError("1&\"abcde\"", MaxError.incompatible_types);

    try runTestError("1f&\"a\"", MaxError.incompatible_types);
    try runTestError("1f&\"\"", MaxError.incompatible_types);
    try runTestError("1f&\"abcde\"", MaxError.incompatible_types);

    try runTestError("\"1\"&\"a\"", MaxError.incompatible_types);
    try runTestError("\"1\"&\"\"", MaxError.incompatible_types);
    try runTestError("\"1\"&\"abcde\"", MaxError.incompatible_types);

    try runTestError("`symbol&\"a\"", MaxError.incompatible_types);
    try runTestError("`symbol&\"\"", MaxError.incompatible_types);
    try runTestError("`symbol&\"abcde\"", MaxError.incompatible_types);

    try runTestError("()&\"a\"", MaxError.incompatible_types);
    try runTestError("()&\"\"", MaxError.incompatible_types);
    try runTestError("()&\"abcde\"", MaxError.incompatible_types);

    try runTestError("10011b&\"a\"", MaxError.incompatible_types);
    try runTestError("10011b&\"\"", MaxError.incompatible_types);
    try runTestError("10011b&\"abcde\"", MaxError.incompatible_types);

    try runTestError("5 4 3 2 1&\"a\"", MaxError.incompatible_types);
    try runTestError("5 4 3 2 1&\"\"", MaxError.incompatible_types);
    try runTestError("5 4 3 2 1&\"abcde\"", MaxError.incompatible_types);

    try runTestError("5 4 3 2 1f&\"a\"", MaxError.incompatible_types);
    try runTestError("5 4 3 2 1f&\"\"", MaxError.incompatible_types);
    try runTestError("5 4 3 2 1f&\"abcde\"", MaxError.incompatible_types);

    try runTestError("\"54321\"&\"a\"", MaxError.incompatible_types);
    try runTestError("\"54321\"&\"\"", MaxError.incompatible_types);
    try runTestError("\"54321\"&\"abcde\"", MaxError.incompatible_types);

    try runTestError("`a`b`c`d`e&\"a\"", MaxError.incompatible_types);
    try runTestError("`a`b`c`d`e&\"\"", MaxError.incompatible_types);
    try runTestError("`a`b`c`d`e&\"abcde\"", MaxError.incompatible_types);

    try runTestError("(`a`b!1 2)&\"a\"", MaxError.incompatible_types);
    try runTestError("(`a`b!1 2)&\"\"", MaxError.incompatible_types);
    try runTestError("(`a`b!1 2)&\"ab\"", MaxError.incompatible_types);

    try runTestError("(+`a`b!(,1;,2))&\"a\"", MaxError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))&\"\"", MaxError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))&\"ab\"", MaxError.incompatible_types);
}

test "max symbol" {
    try runTestError("1b|`symbol", MaxError.incompatible_types);
    try runTestError("1b|`$()", MaxError.incompatible_types);
    try runTestError("1b|`a`b`c`d`e", MaxError.incompatible_types);

    try runTestError("1|`symbol", MaxError.incompatible_types);
    try runTestError("1|`$()", MaxError.incompatible_types);
    try runTestError("1|`a`b`c`d`e", MaxError.incompatible_types);

    try runTestError("1f|`symbol", MaxError.incompatible_types);
    try runTestError("1f|`$()", MaxError.incompatible_types);
    try runTestError("1f|`a`b`c`d`e", MaxError.incompatible_types);

    try runTestError("\"a\"|`symbol", MaxError.incompatible_types);
    try runTestError("\"a\"|`$()", MaxError.incompatible_types);
    try runTestError("\"a\"|`a`b`c`d`e", MaxError.incompatible_types);

    try runTestError("`symbol|`a", MaxError.incompatible_types);
    try runTestError("`symbol|`$()", MaxError.incompatible_types);
    try runTestError("`symbol|`a`b`c`d`e", MaxError.incompatible_types);

    try runTestError("()|`symbol", MaxError.incompatible_types);
    try runTestError("()|`$()", MaxError.incompatible_types);
    try runTestError("()|`a`b`c`d`e", MaxError.incompatible_types);

    try runTestError("10011b|`symbol", MaxError.incompatible_types);
    try runTestError("10011b|`$()", MaxError.incompatible_types);
    try runTestError("10011b|`a`b`c`d`e", MaxError.incompatible_types);

    try runTestError("5 4 3 2 1|`symbol", MaxError.incompatible_types);
    try runTestError("5 4 3 2 1|`$()", MaxError.incompatible_types);
    try runTestError("5 4 3 2 1|`a`b`c`d`e", MaxError.incompatible_types);

    try runTestError("5 4 3 2 1f|`symbol", MaxError.incompatible_types);
    try runTestError("5 4 3 2 1f|`$()", MaxError.incompatible_types);
    try runTestError("5 4 3 2 1f|`a`b`c`d`e", MaxError.incompatible_types);

    try runTestError("\"54321\"|`symbol", MaxError.incompatible_types);
    try runTestError("\"54321\"|`$()", MaxError.incompatible_types);
    try runTestError("\"54321\"|`a`b`c`d`e", MaxError.incompatible_types);

    try runTestError("`5`4`3`2`1|`symbol", MaxError.incompatible_types);
    try runTestError("`5`4`3`2`1|`$()", MaxError.incompatible_types);
    try runTestError("`5`4`3`2`1|`a`b`c`d`e", MaxError.incompatible_types);

    try runTestError("(`a`b!1 2)|`symbol", MaxError.incompatible_types);
    try runTestError("(`a`b!1 2)|`$()", MaxError.incompatible_types);
    try runTestError("(`a`b!1 2)|`a`b", MaxError.incompatible_types);

    try runTestError("(+`a`b!(,1;,2))|`symbol", MaxError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))|`$()", MaxError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))|`a`b", MaxError.incompatible_types);
}

test "max list" {
    try runTest("1b|()", .{ .list = &[_]TestValue{} });
    try runTest("1b|(0b;1;0N;0W;-0W)", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = Value.inf_int },
            .{ .int = 1 },
        },
    });
    try runTest("1b|(0b;1;0N;0W;-0W;1f;0n;0w;-0w)", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = Value.inf_int },
            .{ .int = 1 },
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .float = Value.inf_float },
            .{ .float = 1 },
        },
    });
    try runTestError("1b|(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", MaxError.incompatible_types);
    try runTestError("1b|(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", MaxError.incompatible_types);

    try runTest("1|()", .{ .list = &[_]TestValue{} });
    try runTest("1|(0b;1;0N;0W;-0W)", .{
        .int_list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = Value.inf_int },
            .{ .int = 1 },
        },
    });
    try runTest("1|(0b;1;0N;0W;-0W;1f;0n;0w;-0w)", .{
        .list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = Value.inf_int },
            .{ .int = 1 },
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .float = Value.inf_float },
            .{ .float = 1 },
        },
    });
    try runTestError("1|(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", MaxError.incompatible_types);
    try runTestError("1|(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", MaxError.incompatible_types);

    try runTest("1f|()", .{ .list = &[_]TestValue{} });
    try runTest("1f|(0b;1;0N;0W;-0W;1f;0n;0w;-0w)", .{
        .float_list = &[_]TestValue{
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .float = Value.inf_int },
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .float = Value.inf_float },
            .{ .float = 1 },
        },
    });
    try runTestError("1f|(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", MaxError.incompatible_types);
    try runTestError("1f|(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", MaxError.incompatible_types);

    try runTestError("\"a\"|()", MaxError.incompatible_types);

    try runTestError("`symbol|()", MaxError.incompatible_types);

    try runTest("()|()", .{ .list = &[_]TestValue{} });
    try runTestError("(0N;0n)|()", MaxError.length_mismatch);
    try runTestError("()|(0N;0n)", MaxError.length_mismatch);
    try runTest("(1b;2)|(1b;2)", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .int = 2 },
        },
    });
    try runTest("(1b;2f)|(2f;1b)", .{
        .float_list = &[_]TestValue{
            .{ .float = 2 },
            .{ .float = 2 },
        },
    });
    try runTest("(2;3f)|(2;3f)", .{
        .list = &[_]TestValue{
            .{ .int = 2 },
            .{ .float = 3 },
        },
    });
    try runTest("(1b;(2;3f))|(0N;(0n;0N))", .{
        .list = &[_]TestValue{
            .{ .int = 1 },
            .{ .float_list = &[_]TestValue{
                .{ .float = 2 },
                .{ .float = 3 },
            } },
        },
    });
    try runTestError("(0b;1;2;3;4;5;6;7;8;9)|(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", MaxError.incompatible_types);
    try runTestError("(0b;1;2;3;4;5;6;7;8;9)|(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", MaxError.incompatible_types);

    try runTestError("010b|()", MaxError.length_mismatch);
    try runTest("01b|(0b;0N)", .{
        .list = &[_]TestValue{
            .{ .boolean = false },
            .{ .int = 1 },
        },
    });
    try runTest("010b|(0b;0N;0n)", .{
        .list = &[_]TestValue{
            .{ .boolean = false },
            .{ .int = 1 },
            .{ .float = 0 },
        },
    });
    try runTestError("0101010101b|(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", MaxError.incompatible_types);
    try runTestError("0101010101b|(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", MaxError.incompatible_types);

    try runTestError("0 1 2|()", MaxError.length_mismatch);
    try runTest("0 1|(0b;0N)", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 1 },
        },
    });
    try runTest("0 1 2|(0b;0N;0n)", .{
        .list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .float = 2 },
        },
    });
    try runTestError("0 1 2 3 4 5 6 7 8 9|(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", MaxError.incompatible_types);
    try runTestError("0 1 2 3 4 5 6 7 8 9|(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", MaxError.incompatible_types);

    try runTestError("0 1 2f|()", MaxError.length_mismatch);
    try runTest("0 1 2f|(0b;0N;0n)", .{
        .float_list = &[_]TestValue{
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = 2 },
        },
    });
    try runTestError("0 1 2 3 4 5 6 7 8 9f|(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", MaxError.incompatible_types);
    try runTestError("0 1 2 3 4 5 6 7 8 9f|(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", MaxError.incompatible_types);

    try runTestError("\"abcde\"|()", MaxError.incompatible_types);

    try runTestError("`a`b`c`d`e|()", MaxError.incompatible_types);

    try runTestError("(`a`b!1 2)|()", MaxError.length_mismatch);
    try runTest("(`a`b!1 2)|(1;2f)", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .int = 1 },
                .{ .float = 2 },
            } },
        },
    });
    try runTestError("(`a`b!1 2)|(0b;1;2f)", MaxError.length_mismatch);

    try runTestError("(+`a`b!(,1;,2))|()", MaxError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))|(1;2f)", MaxError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))|(0b;1;2f)", MaxError.incompatible_types);
}

test "max dictionary" {
    try runTest("1b|()!()", .{
        .dictionary = &[_]TestValue{
            .{ .list = &[_]TestValue{} },
            .{ .list = &[_]TestValue{} },
        },
    });
    try runTest("1b|`a`b!1 2", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .int_list = &[_]TestValue{
                .{ .int = 1 },
                .{ .int = 2 },
            } },
        },
    });

    try runTest("1|()!()", .{
        .dictionary = &[_]TestValue{
            .{ .list = &[_]TestValue{} },
            .{ .list = &[_]TestValue{} },
        },
    });
    try runTest("1|`a`b!1 2", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .int_list = &[_]TestValue{
                .{ .int = 1 },
                .{ .int = 2 },
            } },
        },
    });

    try runTest("1f|()!()", .{
        .dictionary = &[_]TestValue{
            .{ .list = &[_]TestValue{} },
            .{ .list = &[_]TestValue{} },
        },
    });
    try runTest("1f|`a`b!1 2", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .float_list = &[_]TestValue{
                .{ .float = 1 },
                .{ .float = 2 },
            } },
        },
    });

    try runTestError("\"a\"|`a`b!1 2", MaxError.incompatible_types);

    try runTestError("`symbol|`a`b!1 2", MaxError.incompatible_types);

    try runTest("()|()!()", .{
        .dictionary = &[_]TestValue{
            .{ .list = &[_]TestValue{} },
            .{ .list = &[_]TestValue{} },
        },
    });
    try runTestError("()|`a`b!1 2", MaxError.length_mismatch);
    try runTest("(1;2f)|`a`b!1 2", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .int = 1 },
                .{ .float = 2 },
            } },
        },
    });
    try runTestError("(0b;1;2f)|`a`b!1 2", MaxError.length_mismatch);

    try runTest("(`boolean$())|()!()", .{
        .dictionary = &[_]TestValue{
            .{ .list = &[_]TestValue{} },
            .{ .list = &[_]TestValue{} },
        },
    });
    try runTestError("(`boolean$())|`a`b!1 2", MaxError.length_mismatch);
    try runTest("10b|`a`b!1 2", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .int_list = &[_]TestValue{
                .{ .int = 1 },
                .{ .int = 2 },
            } },
        },
    });
    try runTestError("101b|`a`b!1 2", MaxError.length_mismatch);

    try runTest("(`int$())|()!()", .{
        .dictionary = &[_]TestValue{
            .{ .list = &[_]TestValue{} },
            .{ .list = &[_]TestValue{} },
        },
    });
    try runTestError("(`int$())|`a`b!1 2", MaxError.length_mismatch);
    try runTest("1 2|`a`b!1 2", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .int_list = &[_]TestValue{
                .{ .int = 1 },
                .{ .int = 2 },
            } },
        },
    });
    try runTestError("1 2 3|`a`b!1 2", MaxError.length_mismatch);

    try runTest("(`float$())|()!()", .{
        .dictionary = &[_]TestValue{
            .{ .list = &[_]TestValue{} },
            .{ .list = &[_]TestValue{} },
        },
    });
    try runTestError("(`float$())|`a`b!1 2", MaxError.length_mismatch);
    try runTest("1 2f|`a`b!1 2", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .float_list = &[_]TestValue{
                .{ .float = 1 },
                .{ .float = 2 },
            } },
        },
    });
    try runTestError("1 2 3f|`a`b!1 2", MaxError.length_mismatch);

    try runTestError("\"\"|`a`b!1 2", MaxError.incompatible_types);
    try runTestError("\"12\"|`a`b!1 2", MaxError.incompatible_types);
    try runTestError("\"123\"|`a`b!1 2", MaxError.incompatible_types);

    try runTestError("(`$())|`a`b!1 2", MaxError.incompatible_types);
    try runTestError("`5`4|`a`b!1 2", MaxError.incompatible_types);
    try runTestError("`5`4`3|`a`b!1 2", MaxError.incompatible_types);

    try runTest("(()!())|()!()", .{
        .dictionary = &[_]TestValue{
            .{ .list = &[_]TestValue{} },
            .{ .list = &[_]TestValue{} },
        },
    });
    try runTest("(`a`b!1 2)|`a`b!1 2", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .int_list = &[_]TestValue{
                .{ .int = 1 },
                .{ .int = 2 },
            } },
        },
    });
    try runTest("(`b`a!1 2)|`a`b!1 2", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "b" },
                .{ .symbol = "a" },
            } },
            .{ .int_list = &[_]TestValue{
                .{ .int = 2 },
                .{ .int = 2 },
            } },
        },
    });
    try runTest("(`a`b!1 2)|`b`a!1 2", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .int_list = &[_]TestValue{
                .{ .int = 2 },
                .{ .int = 2 },
            } },
        },
    });
    try runTest("(`a`b!1 2)|`c`d!1 2", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
                .{ .symbol = "c" },
                .{ .symbol = "d" },
            } },
            .{ .int_list = &[_]TestValue{
                .{ .int = 1 },
                .{ .int = 2 },
                .{ .int = 1 },
                .{ .int = 2 },
            } },
        },
    });
    try runTestError("(`a`b!1 2)|`a`b!(1;\"2\")", MaxError.incompatible_types);

    try runTestError("(+`a`b!(,1;,2))|`a`b!1 2", MaxError.incompatible_types);
}

test "max table" {
    try runTest("1b|+`a`b!(,1;,2)", .{
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

    try runTest("1|+`a`b!(,1;,2)", .{
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

    try runTest("1f|+`a`b!(,1;,2)", .{
        .table = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .float_list = &[_]TestValue{
                    .{ .float = 1 },
                } },
                .{ .float_list = &[_]TestValue{
                    .{ .float = 2 },
                } },
            } },
        },
    });

    try runTestError("\"a\"|+`a`b!(,1;,2)", MaxError.incompatible_types);

    try runTestError("`symbol|+`a`b!(,1;,2)", MaxError.incompatible_types);

    try runTestError("()|+`a`b!(,1;,2)", MaxError.incompatible_types);
    try runTestError("(1;2f)|+`a`b!(,1;,2)", MaxError.incompatible_types);
    try runTestError("(0b;1;2f)|+`a`b!(,1;,2)", MaxError.incompatible_types);

    try runTestError("(`boolean$())|+`a`b!(,1;,2)", MaxError.incompatible_types);
    try runTestError("10b|+`a`b!(,1;,2)", MaxError.incompatible_types);
    try runTestError("101b|+`a`b!(,1;,2)", MaxError.incompatible_types);

    try runTestError("(`int$())|+`a`b!(,1;,2)", MaxError.incompatible_types);
    try runTestError("1 2|+`a`b!(,1;,2)", MaxError.incompatible_types);
    try runTestError("1 2 3|+`a`b!(,1;,2)", MaxError.incompatible_types);

    try runTestError("(`float$())|+`a`b!(,1;,2)", MaxError.incompatible_types);
    try runTestError("1 2f|+`a`b!(,1;,2)", MaxError.incompatible_types);
    try runTestError("1 2 3f|+`a`b!(,1;,2)", MaxError.incompatible_types);

    try runTestError("\"\"|+`a`b!(,1;,2)", MaxError.incompatible_types);
    try runTestError("\"12\"|+`a`b!(,1;,2)", MaxError.incompatible_types);
    try runTestError("\"123\"|+`a`b!(,1;,2)", MaxError.incompatible_types);

    try runTestError("(`$())|+`a`b!(,1;,2)", MaxError.incompatible_types);
    try runTestError("`5`4|+`a`b!(,1;,2)", MaxError.incompatible_types);
    try runTestError("`5`4`3|+`a`b!(,1;,2)", MaxError.incompatible_types);

    try runTestError("(`a`b!1 2)|+`a`b!(,1;,2)", MaxError.incompatible_types);

    try runTest("(+`a`b!(,1;,2))|+`a`b!(,1;,2)", .{
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
    try runTest("(+`b`a!(,1;,2))|+`a`b!(,1;,2)", .{
        .table = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "b" },
                .{ .symbol = "a" },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = 2 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 2 },
                } },
            } },
        },
    });
    try runTest("(+`a`b!(,1;,2))|+`b`a!(,1;,2)", .{
        .table = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = 2 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 2 },
                } },
            } },
        },
    });
    try runTestError("(+`a`b!(,1;,2))|+`a`b!(,1;,`symbol)", MaxError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))|+`a`b!(1 1;2 2)", MaxError.length_mismatch);
    try runTest("(+`a`b!(,1;,2))|+`a`b`c!(,1;,2;,3)", .{
        .table = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
                .{ .symbol = "c" },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 2 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 3 },
                } },
            } },
        },
    });
    try runTest("(+`a`b`c!(,1;,2;,3))|+`a`b!(,1;,2)", .{
        .table = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
                .{ .symbol = "c" },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 2 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 3 },
                } },
            } },
        },
    });
}
