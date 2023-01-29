const value_mod = @import("../../value.zig");
const Value = value_mod.Value;

const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;
const runTestError = vm_mod.runTestError;
const TestValue = vm_mod.TestValue;

const MultiplyError = @import("../../verbs/multiply.zig").MultiplyError;

test "multiply boolean" {
    try runTest("1b*0b", .{ .int = 0 });
    try runTest("1b*`boolean$()", .{ .int_list = &[_]TestValue{} });
    try runTest("1b*00000b", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 0 },
            .{ .int = 0 },
            .{ .int = 0 },
            .{ .int = 0 },
        },
    });

    try runTest("1*0b", .{ .int = 0 });
    try runTest("1*`boolean$()", .{ .int_list = &[_]TestValue{} });
    try runTest("1*00000b", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 0 },
            .{ .int = 0 },
            .{ .int = 0 },
            .{ .int = 0 },
        },
    });

    try runTest("1f*0b", .{ .float = 0 });
    try runTest("1f*`boolean$()", .{ .float_list = &[_]TestValue{} });
    try runTest("1f*00000b", .{
        .float_list = &[_]TestValue{
            .{ .float = 0 },
            .{ .float = 0 },
            .{ .float = 0 },
            .{ .float = 0 },
            .{ .float = 0 },
        },
    });

    try runTestError("\"a\"*0b", MultiplyError.incompatible_types);
    try runTestError("\"a\"*`boolean$()", MultiplyError.incompatible_types);
    try runTestError("\"a\"*00000b", MultiplyError.incompatible_types);

    try runTestError("`symbol*0b", MultiplyError.incompatible_types);
    try runTestError("`symbol*`boolean$()", MultiplyError.incompatible_types);
    try runTestError("`symbol*00000b", MultiplyError.incompatible_types);

    try runTest("()*0b", .{ .list = &[_]TestValue{} });
    try runTest("(1b;2)*0b", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 0 },
        },
    });
    try runTest("(1b;2;3f)*0b", .{
        .list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 0 },
            .{ .float = 0 },
        },
    });
    try runTestError("(1b;2;3f;`symbol)*0b", MultiplyError.incompatible_types);
    try runTest("()*`boolean$()", .{ .list = &[_]TestValue{} });
    try runTestError("()*010b", MultiplyError.length_mismatch);
    try runTestError("(1b;2)*`boolean$()", MultiplyError.length_mismatch);
    try runTest("(1b;2)*01b", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 2 },
        },
    });
    try runTest("(1b;2;3f)*010b", .{
        .list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 2 },
            .{ .float = 0 },
        },
    });
    try runTestError("(1b;2;3f)*0101b", MultiplyError.length_mismatch);
    try runTestError("(1b;2;3f;\"a\")*0101b", MultiplyError.incompatible_types);
    try runTestError("(1b;2;3f;`symbol)*0101b", MultiplyError.incompatible_types);

    try runTest("11111b*0b", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 0 },
            .{ .int = 0 },
            .{ .int = 0 },
            .{ .int = 0 },
        },
    });
    try runTestError("11111b*`boolean$()", MultiplyError.length_mismatch);
    try runTest("11111b*00000b", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 0 },
            .{ .int = 0 },
            .{ .int = 0 },
            .{ .int = 0 },
        },
    });
    try runTestError("11111b*000000b", MultiplyError.length_mismatch);

    try runTest("5 4 3 2 1*0b", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 0 },
            .{ .int = 0 },
            .{ .int = 0 },
            .{ .int = 0 },
        },
    });
    try runTestError("5 4 3 2 1*`boolean$()", MultiplyError.length_mismatch);
    try runTest("5 4 3 2 1*00000b", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 0 },
            .{ .int = 0 },
            .{ .int = 0 },
            .{ .int = 0 },
        },
    });
    try runTestError("5 4 3 2 1*000000b", MultiplyError.length_mismatch);

    try runTest("5 4 3 2 1f*0b", .{
        .float_list = &[_]TestValue{
            .{ .float = 0 },
            .{ .float = 0 },
            .{ .float = 0 },
            .{ .float = 0 },
            .{ .float = 0 },
        },
    });
    try runTestError("5 4 3 2 1f*`boolean$()", MultiplyError.length_mismatch);
    try runTest("5 4 3 2 1f*00000b", .{
        .float_list = &[_]TestValue{
            .{ .float = 0 },
            .{ .float = 0 },
            .{ .float = 0 },
            .{ .float = 0 },
            .{ .float = 0 },
        },
    });
    try runTestError("5 4 3 2 1f*000000b", MultiplyError.length_mismatch);

    try runTestError("\"abcde\"*0b", MultiplyError.incompatible_types);
    try runTestError("\"abcde\"*`boolean$()", MultiplyError.incompatible_types);
    try runTestError("\"abcde\"*00000b", MultiplyError.incompatible_types);
    try runTestError("\"abcde\"*000000b", MultiplyError.incompatible_types);

    try runTestError("`a`b`c`d`e*0b", MultiplyError.incompatible_types);
    try runTestError("`a`b`c`d`e*`boolean$()", MultiplyError.incompatible_types);
    try runTestError("`a`b`c`d`e*00000b", MultiplyError.incompatible_types);
    try runTestError("`a`b`c`d`e*000000b", MultiplyError.incompatible_types);
}

test "multiply int" {
    try runTest("1b*0", .{ .int = 0 });
    try runTest("1b*`int$()", .{ .int_list = &[_]TestValue{} });
    try runTest("1b*0 1 0N 0W -0W", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
        },
    });

    try runTest("1*0", .{ .int = 0 });
    try runTest("1*`int$()", .{ .int_list = &[_]TestValue{} });
    try runTest("1*0 1 0N 0W -0W", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
        },
    });

    try runTest("1f*0", .{ .float = 0 });
    try runTest("1f*`int$()", .{ .float_list = &[_]TestValue{} });
    try runTest("1f*0 1 0N 0W -0W", .{
        .float_list = &[_]TestValue{
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_int },
            .{ .float = -Value.inf_int },
        },
    });

    try runTestError("\"a\"*0", MultiplyError.incompatible_types);
    try runTestError("\"a\"*`int$()", MultiplyError.incompatible_types);
    try runTestError("\"a\"*0 1 0N 0W -0W", MultiplyError.incompatible_types);

    try runTestError("`symbol*0", MultiplyError.incompatible_types);
    try runTestError("`symbol*`int$()", MultiplyError.incompatible_types);
    try runTestError("`symbol*0 1 0N 0W -0W", MultiplyError.incompatible_types);

    try runTest("()*0", .{ .list = &[_]TestValue{} });
    try runTest("(1b;2)*0", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 0 },
        },
    });
    try runTest("(1b;2;3f)*0", .{
        .list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 0 },
            .{ .float = 0 },
        },
    });
    try runTestError("(1b;2;3f;`symbol)*0", MultiplyError.incompatible_types);
    try runTest("()*`int$()", .{ .list = &[_]TestValue{} });
    try runTestError("()*0 1 0N 0W -0W", MultiplyError.length_mismatch);
    try runTestError("(1b;2;3;4;5)*`int$()", MultiplyError.length_mismatch);
    try runTest("(1b;2;3;4;5)*0 1 0N 0W -0W", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 2 },
            .{ .int = Value.null_int },
            .{ .int = -4 },
            .{ .int = -9223372036854775803 },
        },
    });
    try runTest("(1b;2;3f;4;5)*0 1 0N 0W -0W", .{
        .list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 2 },
            .{ .float = Value.null_float },
            .{ .int = -4 },
            .{ .int = -9223372036854775803 },
        },
    });
    try runTestError("(1b;2;3f;4)*0 1 0N 0W -0W", MultiplyError.length_mismatch);
    try runTestError("(1b;2;3f;4;\"a\")*0 1 0N 0W -0W", MultiplyError.incompatible_types);
    try runTestError("(1b;2;3f;4;`symbol)*0 1 0N 0W -0W", MultiplyError.incompatible_types);

    try runTest("11111b*0", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 0 },
            .{ .int = 0 },
            .{ .int = 0 },
            .{ .int = 0 },
        },
    });
    try runTestError("11111b*`int$()", MultiplyError.length_mismatch);
    try runTest("11111b*0 1 0N 0W -0W", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
        },
    });
    try runTestError("11111b*0 1 0N 0W -0W 2", MultiplyError.length_mismatch);

    try runTest("5 4 3 2 1*0", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 0 },
            .{ .int = 0 },
            .{ .int = 0 },
            .{ .int = 0 },
        },
    });
    try runTestError("5 4 3 2 1*`int$()", MultiplyError.length_mismatch);
    try runTest("5 4 3 2 1*0 1 0N 0W -0W", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 4 },
            .{ .int = Value.null_int },
            .{ .int = -2 },
            .{ .int = -Value.inf_int },
        },
    });
    try runTestError("5 4 3 2 1*0 1 0N 0W -0W 2", MultiplyError.length_mismatch);

    try runTest("5 4 3 2 1f*0", .{
        .float_list = &[_]TestValue{
            .{ .float = 0 },
            .{ .float = 0 },
            .{ .float = 0 },
            .{ .float = 0 },
            .{ .float = 0 },
        },
    });
    try runTestError("5 4 3 2 1f*`int$()", MultiplyError.length_mismatch);
    try runTest("5 4 3 2 1f*0 1 0N 0W -0W", .{
        .float_list = &[_]TestValue{
            .{ .float = 0 },
            .{ .float = 4 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_int * 2 },
            .{ .float = -Value.inf_int },
        },
    });
    try runTestError("5 4 3 2 1f*0 1 0N 0W -0W 2", MultiplyError.length_mismatch);

    try runTestError("\"abcde\"*0", MultiplyError.incompatible_types);
    try runTestError("\"abcde\"*`int$()", MultiplyError.incompatible_types);
    try runTestError("\"abcde\"*0 1 0N 0W -0W", MultiplyError.incompatible_types);
    try runTestError("\"abcde\"*0 1 0N 0W -0W 2", MultiplyError.incompatible_types);

    try runTestError("`a`b`c`d`e*0", MultiplyError.incompatible_types);
    try runTestError("`a`b`c`d`e*`int$()", MultiplyError.incompatible_types);
    try runTestError("`a`b`c`d`e*0 1 0N 0W -0W", MultiplyError.incompatible_types);
    try runTestError("`a`b`c`d`e*0 1 0N 0W -0W 2", MultiplyError.incompatible_types);
}

test "multiply float" {
    try runTest("1b*0f", .{ .float = 0 });
    try runTest("1b*`float$()", .{ .float_list = &[_]TestValue{} });
    try runTest("1b*0 1 0n 0w -0w", .{
        .float_list = &[_]TestValue{
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
        },
    });

    try runTest("1*0f", .{ .float = 0 });
    try runTest("1*`float$()", .{ .float_list = &[_]TestValue{} });
    try runTest("1*0 1 0n 0w -0w", .{
        .float_list = &[_]TestValue{
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
        },
    });

    try runTest("1f*0f", .{ .float = 0 });
    try runTest("1f*`float$()", .{ .float_list = &[_]TestValue{} });
    try runTest("1f*0 1 0n 0w -0w", .{
        .float_list = &[_]TestValue{
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
        },
    });

    try runTestError("\"a\"*0f", MultiplyError.incompatible_types);
    try runTestError("\"a\"*`float$()", MultiplyError.incompatible_types);
    try runTestError("\"a\"*0 1 0n 0w -0w", MultiplyError.incompatible_types);

    try runTestError("`symbol*0f", MultiplyError.incompatible_types);
    try runTestError("`symbol*`float$()", MultiplyError.incompatible_types);
    try runTestError("`symbol*0 1 0n 0w -0w", MultiplyError.incompatible_types);

    try runTest("()*0f", .{ .list = &[_]TestValue{} });
    try runTest("(1b;2;3f)*0f", .{
        .float_list = &[_]TestValue{
            .{ .float = 0 },
            .{ .float = 0 },
            .{ .float = 0 },
        },
    });
    try runTestError("(1b;2;3f;`symbol)*0f", MultiplyError.incompatible_types);
    try runTest("()*`float$()", .{ .list = &[_]TestValue{} });
    try runTestError("()*0 1 0n 0w -0w", MultiplyError.length_mismatch);
    try runTestError("(1b;2;3f;4;5)*`float$()", MultiplyError.length_mismatch);
    try runTest("(1b;2;3f;4;5)*0 1 0n 0w -0w", .{
        .float_list = &[_]TestValue{
            .{ .float = 0 },
            .{ .float = 2 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
        },
    });
    try runTestError("(1b;2;3f;4)*0 1 0n 0w -0w", MultiplyError.length_mismatch);
    try runTestError("(1b;2;3f;4;\"a\")*0 1 0n 0w -0w", MultiplyError.incompatible_types);
    try runTestError("(1b;2;3f;4;`symbol)*0 1 0n 0w -0w", MultiplyError.incompatible_types);

    try runTest("11111b*0f", .{
        .float_list = &[_]TestValue{
            .{ .float = 0 },
            .{ .float = 0 },
            .{ .float = 0 },
            .{ .float = 0 },
            .{ .float = 0 },
        },
    });
    try runTestError("11111b*`float$()", MultiplyError.length_mismatch);
    try runTest("11111b*0 1 0n 0w -0w", .{
        .float_list = &[_]TestValue{
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
        },
    });
    try runTestError("11111b*0 1 0n 0w -0w 2", MultiplyError.length_mismatch);

    try runTest("5 4 3 2 1*0f", .{
        .float_list = &[_]TestValue{
            .{ .float = 0 },
            .{ .float = 0 },
            .{ .float = 0 },
            .{ .float = 0 },
            .{ .float = 0 },
        },
    });
    try runTestError("5 4 3 2 1*`float$()", MultiplyError.length_mismatch);
    try runTest("5 4 3 2 1*0 1 0n 0w -0w", .{
        .float_list = &[_]TestValue{
            .{ .float = 0 },
            .{ .float = 4 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
        },
    });
    try runTestError("5 4 3 2 1*0 1 0n 0w -0w 2", MultiplyError.length_mismatch);

    try runTest("5 4 3 2 1f*0f", .{
        .float_list = &[_]TestValue{
            .{ .float = 0 },
            .{ .float = 0 },
            .{ .float = 0 },
            .{ .float = 0 },
            .{ .float = 0 },
        },
    });
    try runTestError("5 4 3 2 1f*`float$()", MultiplyError.length_mismatch);
    try runTest("5 4 3 2 1f*0 1 0n 0w -0w", .{
        .float_list = &[_]TestValue{
            .{ .float = 0 },
            .{ .float = 4 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
        },
    });
    try runTestError("5 4 3 2 1f*0 1 0n 0w -0w 2", MultiplyError.length_mismatch);

    try runTestError("\"abcde\"*0f", MultiplyError.incompatible_types);
    try runTestError("\"abcde\"*`float$()", MultiplyError.incompatible_types);
    try runTestError("\"abcde\"*0 1 0n 0w -0w", MultiplyError.incompatible_types);
    try runTestError("\"abcde\"*0 1 0n 0w -0w 2", MultiplyError.incompatible_types);

    try runTestError("`a`b`c`d`e*0f", MultiplyError.incompatible_types);
    try runTestError("`a`b`c`d`e*`float$()", MultiplyError.incompatible_types);
    try runTestError("`a`b`c`d`e*0 1 0n 0w -0w", MultiplyError.incompatible_types);
    try runTestError("`a`b`c`d`e*0 1 0n 0w -0w 2", MultiplyError.incompatible_types);
}

test "multiply char" {
    try runTestError("1b*\"a\"", MultiplyError.incompatible_types);
    try runTestError("1b*\"\"", MultiplyError.incompatible_types);
    try runTestError("1b*\"abcde\"", MultiplyError.incompatible_types);

    try runTestError("1*\"a\"", MultiplyError.incompatible_types);
    try runTestError("1*\"\"", MultiplyError.incompatible_types);
    try runTestError("1*\"abcde\"", MultiplyError.incompatible_types);

    try runTestError("1f*\"a\"", MultiplyError.incompatible_types);
    try runTestError("1f*\"\"", MultiplyError.incompatible_types);
    try runTestError("1f*\"abcde\"", MultiplyError.incompatible_types);

    try runTestError("\"1\"*\"a\"", MultiplyError.incompatible_types);
    try runTestError("\"1\"*\"\"", MultiplyError.incompatible_types);
    try runTestError("\"1\"*\"abcde\"", MultiplyError.incompatible_types);

    try runTestError("`symbol*\"a\"", MultiplyError.incompatible_types);
    try runTestError("`symbol*\"\"", MultiplyError.incompatible_types);
    try runTestError("`symbol*\"abcde\"", MultiplyError.incompatible_types);

    try runTestError("()*\"a\"", MultiplyError.incompatible_types);
    try runTestError("()*\"\"", MultiplyError.incompatible_types);
    try runTestError("()*\"abcde\"", MultiplyError.incompatible_types);

    try runTestError("10011b*\"a\"", MultiplyError.incompatible_types);
    try runTestError("10011b*\"\"", MultiplyError.incompatible_types);
    try runTestError("10011b*\"abcde\"", MultiplyError.incompatible_types);

    try runTestError("5 4 3 2 1*\"a\"", MultiplyError.incompatible_types);
    try runTestError("5 4 3 2 1*\"\"", MultiplyError.incompatible_types);
    try runTestError("5 4 3 2 1*\"abcde\"", MultiplyError.incompatible_types);

    try runTestError("5 4 3 2 1f*\"a\"", MultiplyError.incompatible_types);
    try runTestError("5 4 3 2 1f*\"\"", MultiplyError.incompatible_types);
    try runTestError("5 4 3 2 1f*\"abcde\"", MultiplyError.incompatible_types);

    try runTestError("\"54321\"*\"a\"", MultiplyError.incompatible_types);
    try runTestError("\"54321\"*\"\"", MultiplyError.incompatible_types);
    try runTestError("\"54321\"*\"abcde\"", MultiplyError.incompatible_types);

    try runTestError("`a`b`c`d`e*\"a\"", MultiplyError.incompatible_types);
    try runTestError("`a`b`c`d`e*\"\"", MultiplyError.incompatible_types);
    try runTestError("`a`b`c`d`e*\"abcde\"", MultiplyError.incompatible_types);
}

test "multiply symbol" {
    try runTestError("1b*`symbol", MultiplyError.incompatible_types);
    try runTestError("1b*`$()", MultiplyError.incompatible_types);
    try runTestError("1b*`a`b`c`d`e", MultiplyError.incompatible_types);

    try runTestError("1*`symbol", MultiplyError.incompatible_types);
    try runTestError("1*`$()", MultiplyError.incompatible_types);
    try runTestError("1*`a`b`c`d`e", MultiplyError.incompatible_types);

    try runTestError("1f*`symbol", MultiplyError.incompatible_types);
    try runTestError("1f*`$()", MultiplyError.incompatible_types);
    try runTestError("1f*`a`b`c`d`e", MultiplyError.incompatible_types);

    try runTestError("\"a\"*`symbol", MultiplyError.incompatible_types);
    try runTestError("\"a\"*`$()", MultiplyError.incompatible_types);
    try runTestError("\"a\"*`a`b`c`d`e", MultiplyError.incompatible_types);

    try runTestError("`symbol*`a", MultiplyError.incompatible_types);
    try runTestError("`symbol*`$()", MultiplyError.incompatible_types);
    try runTestError("`symbol*`a`b`c`d`e", MultiplyError.incompatible_types);

    try runTestError("()*`symbol", MultiplyError.incompatible_types);
    try runTestError("()*`$()", MultiplyError.incompatible_types);
    try runTestError("()*`a`b`c`d`e", MultiplyError.incompatible_types);

    try runTestError("10011b*`symbol", MultiplyError.incompatible_types);
    try runTestError("10011b*`$()", MultiplyError.incompatible_types);
    try runTestError("10011b*`a`b`c`d`e", MultiplyError.incompatible_types);

    try runTestError("5 4 3 2 1*`symbol", MultiplyError.incompatible_types);
    try runTestError("5 4 3 2 1*`$()", MultiplyError.incompatible_types);
    try runTestError("5 4 3 2 1*`a`b`c`d`e", MultiplyError.incompatible_types);

    try runTestError("5 4 3 2 1f*`symbol", MultiplyError.incompatible_types);
    try runTestError("5 4 3 2 1f*`$()", MultiplyError.incompatible_types);
    try runTestError("5 4 3 2 1f*`a`b`c`d`e", MultiplyError.incompatible_types);

    try runTestError("\"54321\"*`symbol", MultiplyError.incompatible_types);
    try runTestError("\"54321\"*`$()", MultiplyError.incompatible_types);
    try runTestError("\"54321\"*`a`b`c`d`e", MultiplyError.incompatible_types);

    try runTestError("`5`4`3`2`1*`symbol", MultiplyError.incompatible_types);
    try runTestError("`5`4`3`2`1*`$()", MultiplyError.incompatible_types);
    try runTestError("`5`4`3`2`1*`a`b`c`d`e", MultiplyError.incompatible_types);
}

test "multiply list" {
    try runTest("1b*()", .{ .list = &[_]TestValue{} });
    try runTest("1b*(0b;1;0N;0W;-0W)", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
        },
    });
    try runTest("1b*(0b;1;0N;0W;-0W;1f;0n;0w;-0w)", .{
        .list = &[_]TestValue{
            .{ .int = 0 },
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
    try runTestError("1b*(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", MultiplyError.incompatible_types);
    try runTestError("1b*(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", MultiplyError.incompatible_types);

    try runTest("1*()", .{ .list = &[_]TestValue{} });
    try runTest("1*(0b;1;0N;0W;-0W)", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
        },
    });
    try runTest("1*(0b;1;0N;0W;-0W;1f;0n;0w;-0w)", .{
        .list = &[_]TestValue{
            .{ .int = 0 },
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
    try runTestError("1*(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", MultiplyError.incompatible_types);
    try runTestError("1*(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", MultiplyError.incompatible_types);

    try runTest("1f*()", .{ .list = &[_]TestValue{} });
    try runTest("1f*(0b;1;0N;0W;-0W;1f;0n;0w;-0w)", .{
        .float_list = &[_]TestValue{
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_int },
            .{ .float = -Value.inf_int },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
        },
    });
    try runTestError("1f*(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", MultiplyError.incompatible_types);
    try runTestError("1f*(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", MultiplyError.incompatible_types);

    try runTestError("\"a\"*()", MultiplyError.incompatible_types);

    try runTestError("`symbol*()", MultiplyError.incompatible_types);

    try runTest("()*()", .{ .list = &[_]TestValue{} });
    try runTestError("(0N;0n)*()", MultiplyError.length_mismatch);
    try runTestError("()*(0N;0n)", MultiplyError.length_mismatch);
    try runTest("(1b;2)*(1b;2)", .{
        .int_list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 4 },
        },
    });
    try runTest("(1b;2f)*(2f;1b)", .{
        .float_list = &[_]TestValue{
            .{ .float = 2 },
            .{ .float = 2 },
        },
    });
    try runTest("(2;3f)*(2;3f)", .{
        .list = &[_]TestValue{
            .{ .int = 4 },
            .{ .float = 9 },
        },
    });
    try runTest("(1b;(2;3f))*(0N;(0n;0N))", .{
        .list = &[_]TestValue{
            .{ .int = Value.null_int },
            .{ .float_list = &[_]TestValue{
                .{ .float = Value.null_float },
                .{ .float = Value.null_float },
            } },
        },
    });
    try runTestError("(0b;1;2;3;4;5;6;7;8;9)*(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", MultiplyError.incompatible_types);
    try runTestError("(0b;1;2;3;4;5;6;7;8;9)*(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", MultiplyError.incompatible_types);

    try runTestError("010b*()", MultiplyError.length_mismatch);
    try runTest("01b*(0b;0N)", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = Value.null_int },
        },
    });
    try runTest("010b*(0b;0N;0n)", .{
        .list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = Value.null_int },
            .{ .float = Value.null_float },
        },
    });
    try runTestError("0101010101b*(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", MultiplyError.incompatible_types);
    try runTestError("0101010101b*(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", MultiplyError.incompatible_types);

    try runTestError("0 1 2*()", MultiplyError.length_mismatch);
    try runTest("0 1*(0b;0N)", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = Value.null_int },
        },
    });
    try runTest("0 1 2*(0b;0N;0n)", .{
        .list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = Value.null_int },
            .{ .float = Value.null_float },
        },
    });
    try runTestError("0 1 2 3 4 5 6 7 8 9*(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", MultiplyError.incompatible_types);
    try runTestError("0 1 2 3 4 5 6 7 8 9*(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", MultiplyError.incompatible_types);

    try runTestError("0 1 2f*()", MultiplyError.length_mismatch);
    try runTest("0 1 2f*(0b;0N;0n)", .{
        .float_list = &[_]TestValue{
            .{ .float = 0 },
            .{ .float = Value.null_float },
            .{ .float = Value.null_float },
        },
    });
    try runTestError("0 1 2 3 4 5 6 7 8 9f*(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", MultiplyError.incompatible_types);
    try runTestError("0 1 2 3 4 5 6 7 8 9f*(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", MultiplyError.incompatible_types);

    try runTestError("\"abcde\"*()", MultiplyError.incompatible_types);

    try runTestError("`a`b`c`d`e*()", MultiplyError.incompatible_types);
}
