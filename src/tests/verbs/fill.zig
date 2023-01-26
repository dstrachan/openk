const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;
const runTestError = vm_mod.runTestError;
const TestValue = vm_mod.TestValue;

const FillError = @import("../../verbs/fill.zig").FillError;

test "fill boolean" {
    try runTest("1b^0b", .{ .boolean = false });
    try runTest("1b^`boolean$()", .{ .boolean_list = &[_]TestValue{} });
    try runTest("1b^00000b", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });

    try runTest("1^0b", .{ .int = 0 });
    try runTest("1^`boolean$()", .{ .int_list = &[_]TestValue{} });
    try runTest("1^00000b", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 0 },
            .{ .int = 0 },
            .{ .int = 0 },
            .{ .int = 0 },
        },
    });

    try runTest("1f^0b", .{ .float = 0 });
    try runTest("1f^`boolean$()", .{ .float_list = &[_]TestValue{} });
    try runTest("1f^00000b", .{
        .float_list = &[_]TestValue{
            .{ .float = 0 },
            .{ .float = 0 },
            .{ .float = 0 },
            .{ .float = 0 },
            .{ .float = 0 },
        },
    });

    try runTest("\"a\"^0b", .{ .char = 0 });
    try runTest("\"a\"^`boolean$()", .{ .char_list = &[_]TestValue{} });
    try runTest("\"a\"^00000b", .{
        .char_list = &[_]TestValue{
            .{ .char = 0 },
            .{ .char = 0 },
            .{ .char = 0 },
            .{ .char = 0 },
            .{ .char = 0 },
        },
    });

    try runTestError("`symbol^0b", FillError.incompatible_types);
    try runTestError("`symbol^`boolean$()", FillError.incompatible_types);
    try runTestError("`symbol^00000b", FillError.incompatible_types);

    try runTestError("()^0b", FillError.incompatible_types);
    try runTestError("(1b;2;3f)^0b", FillError.incompatible_types);
    try runTest("()^`boolean$()", .{ .list = &[_]TestValue{} });
    try runTestError("()^010b", FillError.length_mismatch);
    try runTestError("(1b;2;3f;\"a\")^`boolean$()", FillError.length_mismatch);
    try runTest("(1b;2;3f;\"a\")^0101b", .{
        .list = &[_]TestValue{
            .{ .boolean = false },
            .{ .int = 1 },
            .{ .float = 0 },
            .{ .char = 1 },
        },
    });
    try runTestError("(1b;2;3f)^0101b", FillError.length_mismatch);
    try runTestError("(1b;2;3f;`symbol)^0101b", FillError.incompatible_types);

    try runTestError("11111b^0b", FillError.incompatible_types);
    try runTestError("11111b^`boolean$()", FillError.length_mismatch);
    try runTest("11111b^00000b", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTestError("11111b^000000b", FillError.length_mismatch);

    try runTestError("5 4 3 2 1^0b", FillError.incompatible_types);
    try runTestError("5 4 3 2 1^`boolean$()", FillError.length_mismatch);
    try runTest("5 4 3 2 1^00000b", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 0 },
            .{ .int = 0 },
            .{ .int = 0 },
            .{ .int = 0 },
        },
    });
    try runTestError("5 4 3 2 1^000000b", FillError.length_mismatch);

    try runTestError("5 4 3 2 1f^0b", FillError.incompatible_types);
    try runTestError("5 4 3 2 1f^`boolean$()", FillError.length_mismatch);
    try runTest("5 4 3 2 1f^00000b", .{
        .float_list = &[_]TestValue{
            .{ .float = 0 },
            .{ .float = 0 },
            .{ .float = 0 },
            .{ .float = 0 },
            .{ .float = 0 },
        },
    });
    try runTestError("5 4 3 2 1f^000000b", FillError.length_mismatch);

    try runTestError("\"abcde\"^0b", FillError.incompatible_types);
    try runTestError("\"abcde\"^`boolean$()", FillError.length_mismatch);
    try runTest("\"abcde\"^00000b", .{
        .char_list = &[_]TestValue{
            .{ .char = 0 },
            .{ .char = 0 },
            .{ .char = 0 },
            .{ .char = 0 },
            .{ .char = 0 },
        },
    });
    try runTestError("\"abcde\"^000000b", FillError.length_mismatch);

    try runTestError("`a`b`c`d`e^0b", FillError.incompatible_types);
    try runTestError("`a`b`c`d`e^`boolean$()", FillError.incompatible_types);
    try runTestError("`a`b`c`d`e^00000b", FillError.incompatible_types);
    try runTestError("`a`b`c`d`e^000000b", FillError.incompatible_types);
}

test "fill int" {
    try runTest("1b^0", .{ .int = 0 });
    try runTest("1b^0N", .{ .int = 1 });
    try runTest("1b^`int$()", .{ .int_list = &[_]TestValue{} });
    try runTest("1b^1 2 3 4 5", .{
        .int_list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 2 },
            .{ .int = 3 },
            .{ .int = 4 },
            .{ .int = 5 },
        },
    });
    try runTest("1b^1 0N 3 0N 5", .{
        .int_list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 3 },
            .{ .int = 1 },
            .{ .int = 5 },
        },
    });

    try runTest("1^0", .{ .int = 0 });
    try runTest("1^0N", .{ .int = 1 });
    try runTest("1^`int$()", .{ .int_list = &[_]TestValue{} });
    try runTest("1^1 2 3 4 5", .{
        .int_list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 2 },
            .{ .int = 3 },
            .{ .int = 4 },
            .{ .int = 5 },
        },
    });
    try runTest("1^1 0N 3 0N 5", .{
        .int_list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 3 },
            .{ .int = 1 },
            .{ .int = 5 },
        },
    });

    try runTest("1f^0", .{ .float = 0 });
    try runTest("1f^0N", .{ .float = 1 });
    try runTest("1f^`int$()", .{ .float_list = &[_]TestValue{} });
    try runTest("1f^1 2 3 4 5", .{
        .float_list = &[_]TestValue{
            .{ .float = 1 },
            .{ .float = 2 },
            .{ .float = 3 },
            .{ .float = 4 },
            .{ .float = 5 },
        },
    });
    try runTest("1f^1 0N 3 0N 5", .{
        .float_list = &[_]TestValue{
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .float = 3 },
            .{ .float = 1 },
            .{ .float = 5 },
        },
    });

    try runTest("\"a\"^0", .{ .char = 0 });
    try runTest("\"a\"^0N", .{ .char = 0 });
    try runTest("\"a\"^256", .{ .char = 0 });
    try runTest("\"a\"^-256", .{ .char = 0 });
    try runTest("\"a\"^`int$()", .{ .char_list = &[_]TestValue{} });
    try runTest("\"a\"^1 2 3 256 -256", .{
        .char_list = &[_]TestValue{
            .{ .char = 1 },
            .{ .char = 2 },
            .{ .char = 3 },
            .{ .char = 0 },
            .{ .char = 0 },
        },
    });
    try runTest("\"a\"^1 0N 3 0N -256", .{
        .char_list = &[_]TestValue{
            .{ .char = 1 },
            .{ .char = 0 },
            .{ .char = 3 },
            .{ .char = 0 },
            .{ .char = 0 },
        },
    });

    try runTestError("`symbol^0", FillError.incompatible_types);
    try runTestError("`symbol^0N", FillError.incompatible_types);
    try runTestError("`symbol^`int$()", FillError.incompatible_types);
    try runTestError("`symbol^1 2 3 4 5", FillError.incompatible_types);
    try runTestError("`symbol^1 0N 3 0N 5", FillError.incompatible_types);

    try runTestError("()^0", FillError.incompatible_types);
    try runTestError("(1b;2;3f)^0", FillError.incompatible_types);
    try runTest("()^`int$()", .{ .list = &[_]TestValue{} });
    try runTestError("()^0 0N", FillError.length_mismatch);
    try runTest("(1b;2)^0 0N", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 2 },
        },
    });
    try runTest("(1b;2;3f;4;\"a\")^1 2 3 4 5", .{
        .list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .int = 4 },
            .{ .char = 5 },
        },
    });
    try runTest("(1b;2;3f;4;\"a\")^1 0N 3 0N 5", .{
        .list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .int = 4 },
            .{ .char = 5 },
        },
    });
    try runTestError("(1b;2;3f;4;\"a\")^1 0N 3 0N 5 6", FillError.length_mismatch);
    try runTestError("(1b;2;3f;4;`symbol)^1 0N 3 0N 5", FillError.incompatible_types);

    try runTestError("10011b^1", FillError.incompatible_types);
    try runTestError("10011b^`int$()", FillError.length_mismatch);
    try runTest("10011b^1 2 3 4 5", .{
        .int_list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 2 },
            .{ .int = 3 },
            .{ .int = 4 },
            .{ .int = 5 },
        },
    });
    try runTest("10011b^1 0N 3 0N 5", .{
        .int_list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 0 },
            .{ .int = 3 },
            .{ .int = 1 },
            .{ .int = 5 },
        },
    });
    try runTestError("10011b^1 0N 3 0N 5 6", FillError.length_mismatch);

    try runTestError("5 4 3 2 1^1", FillError.incompatible_types);
    try runTestError("5 4 3 2 1^`int$()", FillError.length_mismatch);
    try runTest("5 4 3 2 1^1 2 3 4 5", .{
        .int_list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 2 },
            .{ .int = 3 },
            .{ .int = 4 },
            .{ .int = 5 },
        },
    });
    try runTest("5 4 3 2 1^1 0N 3 0N 5", .{
        .int_list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = 2 },
            .{ .int = 5 },
        },
    });
    try runTestError("5 4 3 2 1^1 0N 3 0N 5 6", FillError.length_mismatch);

    try runTestError("5 4 3 2 1f^1", FillError.incompatible_types);
    try runTestError("5 4 3 2 1f^`int$()", FillError.length_mismatch);
    try runTest("5 4 3 2 1f^1 2 3 4 5", .{
        .float_list = &[_]TestValue{
            .{ .float = 1 },
            .{ .float = 2 },
            .{ .float = 3 },
            .{ .float = 4 },
            .{ .float = 5 },
        },
    });
    try runTest("5 4 3 2 1f^1 0N 3 0N 5", .{
        .float_list = &[_]TestValue{
            .{ .float = 1 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 5 },
        },
    });
    try runTestError("5 4 3 2 1f^1 0N 3 0N 5 6", FillError.length_mismatch);

    try runTestError("\"abcde\"^1", FillError.incompatible_types);
    try runTestError("\"abcde\"^`int$()", FillError.length_mismatch);
    try runTest("\"abcde\"^1 2 3 256 -256", .{
        .char_list = &[_]TestValue{
            .{ .char = 1 },
            .{ .char = 2 },
            .{ .char = 3 },
            .{ .char = 0 },
            .{ .char = 0 },
        },
    });
    try runTest("\"abcde\"^1 0N 3 0N -256", .{
        .char_list = &[_]TestValue{
            .{ .char = 1 },
            .{ .char = 0 },
            .{ .char = 3 },
            .{ .char = 0 },
            .{ .char = 0 },
        },
    });
    try runTestError("\"abcde\"^1 0N 3 0N 5 6", FillError.length_mismatch);

    try runTestError("`a`b`c`d`e^1", FillError.incompatible_types);
    try runTestError("`a`b`c`d`e^`int$()", FillError.incompatible_types);
    try runTestError("`a`b`c`d`e^1 2 3 4 5", FillError.incompatible_types);
    try runTestError("`a`b`c`d`e^1 0N 3 0N 5", FillError.incompatible_types);
    try runTestError("`a`b`c`d`e^1 0N 3 0N 5 6", FillError.incompatible_types);
}

test "fill float" {
    try runTest("1b^0f", .{ .float = 0 });
    try runTest("1b^0n", .{ .float = 1 });
    try runTest("1b^`float$()", .{ .float_list = &[_]TestValue{} });
    try runTest("1b^1 2 3 4 5f", .{
        .float_list = &[_]TestValue{
            .{ .float = 1 },
            .{ .float = 2 },
            .{ .float = 3 },
            .{ .float = 4 },
            .{ .float = 5 },
        },
    });
    try runTest("1b^1 0n 3 0n 5", .{
        .float_list = &[_]TestValue{
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .float = 3 },
            .{ .float = 1 },
            .{ .float = 5 },
        },
    });

    try runTest("1^0f", .{ .float = 0 });
    try runTest("1^0n", .{ .float = 1 });
    try runTest("1^`float$()", .{ .float_list = &[_]TestValue{} });
    try runTest("1^1 2 3 4 5f", .{
        .float_list = &[_]TestValue{
            .{ .float = 1 },
            .{ .float = 2 },
            .{ .float = 3 },
            .{ .float = 4 },
            .{ .float = 5 },
        },
    });
    try runTest("1^1 0n 3 0n 5", .{
        .float_list = &[_]TestValue{
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .float = 3 },
            .{ .float = 1 },
            .{ .float = 5 },
        },
    });

    try runTest("1f^0f", .{ .float = 0 });
    try runTest("1f^0n", .{ .float = 1 });
    try runTest("1f^`float$()", .{ .float_list = &[_]TestValue{} });
    try runTest("1f^1 2 3 4 5f", .{
        .float_list = &[_]TestValue{
            .{ .float = 1 },
            .{ .float = 2 },
            .{ .float = 3 },
            .{ .float = 4 },
            .{ .float = 5 },
        },
    });
    try runTest("1f^1 0n 3 0n 5", .{
        .float_list = &[_]TestValue{
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .float = 3 },
            .{ .float = 1 },
            .{ .float = 5 },
        },
    });

    try runTest("\"a\"^0f", .{ .char = 0 });
    try runTest("\"a\"^0n", .{ .char = 0 });
    try runTest("\"a\"^256f", .{ .char = 0 });
    try runTest("\"a\"^-256f", .{ .char = 0 });
    try runTest("\"a\"^1.4", .{ .char = 1 });
    try runTest("\"a\"^1.5", .{ .char = 2 });
    try runTest("\"a\"^-1.4", .{ .char = 255 });
    try runTest("\"a\"^-1.5", .{ .char = 254 });
    try runTest("\"a\"^`float$()", .{ .char_list = &[_]TestValue{} });
    try runTest("\"a\"^0 256 -256 1.4 1.5 -1.4 -1.5", .{
        .char_list = &[_]TestValue{
            .{ .char = 0 },
            .{ .char = 0 },
            .{ .char = 0 },
            .{ .char = 1 },
            .{ .char = 2 },
            .{ .char = 255 },
            .{ .char = 254 },
        },
    });
    try runTest("\"a\"^0n 256 -256 1.4 1.5 -1.4 -1.5", .{
        .char_list = &[_]TestValue{
            .{ .char = 0 },
            .{ .char = 0 },
            .{ .char = 0 },
            .{ .char = 1 },
            .{ .char = 2 },
            .{ .char = 255 },
            .{ .char = 254 },
        },
    });

    try runTestError("`symbol^0f", FillError.incompatible_types);
    try runTestError("`symbol^0n", FillError.incompatible_types);
    try runTestError("`symbol^`float$()", FillError.incompatible_types);
    try runTestError("`symbol^1 2 3 4 5f", FillError.incompatible_types);
    try runTestError("`symbol^1 0n 3 0n 5", FillError.incompatible_types);

    try runTestError("()^0f", FillError.incompatible_types);
    try runTestError("(1b;2;3f)^0f", FillError.incompatible_types);
    try runTest("()^`float$()", .{ .list = &[_]TestValue{} });
    try runTestError("()^0 0n", FillError.length_mismatch);
    try runTest("(1b;2)^0 0n", .{
        .float_list = &[_]TestValue{
            .{ .float = 0 },
            .{ .float = 2 },
        },
    });
    try runTest("(1b;2;3f;4;\"a\")^1 2 3 4 5f", .{
        .list = &[_]TestValue{
            .{ .float = 1 },
            .{ .float = 2 },
            .{ .float = 3 },
            .{ .float = 4 },
            .{ .char = 5 },
        },
    });
    try runTest("(1b;2;3f;4;\"a\")^1 0n 3 0n 5", .{
        .list = &[_]TestValue{
            .{ .float = 1 },
            .{ .float = 2 },
            .{ .float = 3 },
            .{ .float = 4 },
            .{ .char = 5 },
        },
    });
    try runTestError("(1b;2;3f;4;\"a\")^1 0n 3 0n 5 6", FillError.length_mismatch);
    try runTestError("(1b;2;3f;4;`symbol)^1 0n 3 0n 5", FillError.incompatible_types);

    try runTestError("10011b^1f", FillError.incompatible_types);
    try runTestError("10011b^`float$()", FillError.length_mismatch);
    try runTest("10011b^1 2 3 4 5f", .{
        .float_list = &[_]TestValue{
            .{ .float = 1 },
            .{ .float = 2 },
            .{ .float = 3 },
            .{ .float = 4 },
            .{ .float = 5 },
        },
    });
    try runTest("10011b^1 0n 3 0n 5", .{
        .float_list = &[_]TestValue{
            .{ .float = 1 },
            .{ .float = 0 },
            .{ .float = 3 },
            .{ .float = 1 },
            .{ .float = 5 },
        },
    });
    try runTestError("10011b^1 0n 3 0n 5 6", FillError.length_mismatch);

    try runTestError("5 4 3 2 1^1f", FillError.incompatible_types);
    try runTestError("5 4 3 2 1^`float$()", FillError.length_mismatch);
    try runTest("5 4 3 2 1^1 2 3 4 5f", .{
        .float_list = &[_]TestValue{
            .{ .float = 1 },
            .{ .float = 2 },
            .{ .float = 3 },
            .{ .float = 4 },
            .{ .float = 5 },
        },
    });
    try runTest("5 4 3 2 1^1 0n 3 0n 5", .{
        .float_list = &[_]TestValue{
            .{ .float = 1 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 5 },
        },
    });
    try runTestError("5 4 3 2 1^1 0n 3 0n 5 6", FillError.length_mismatch);

    try runTestError("5 4 3 2 1f^1f", FillError.incompatible_types);
    try runTestError("5 4 3 2 1f^`float$()", FillError.length_mismatch);
    try runTest("5 4 3 2 1f^1 2 3 4 5f", .{
        .float_list = &[_]TestValue{
            .{ .float = 1 },
            .{ .float = 2 },
            .{ .float = 3 },
            .{ .float = 4 },
            .{ .float = 5 },
        },
    });
    try runTest("5 4 3 2 1f^1 0n 3 0n 5", .{
        .float_list = &[_]TestValue{
            .{ .float = 1 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 5 },
        },
    });
    try runTestError("5 4 3 2 1f^1 0n 3 0n 5 6", FillError.length_mismatch);

    try runTestError("\"abcde\"^1f", FillError.incompatible_types);
    try runTestError("\"abcde\"^`float$()", FillError.length_mismatch);
    try runTest("\"abcdefg\"^0 256 -256 1.4 1.5 -1.4 -1.5", .{
        .char_list = &[_]TestValue{
            .{ .char = 0 },
            .{ .char = 0 },
            .{ .char = 0 },
            .{ .char = 1 },
            .{ .char = 2 },
            .{ .char = 255 },
            .{ .char = 254 },
        },
    });
    try runTest("\"abcdefg\"^0n 256 -256 1.4 1.5 -1.4 -1.5", .{
        .char_list = &[_]TestValue{
            .{ .char = 0 },
            .{ .char = 0 },
            .{ .char = 0 },
            .{ .char = 1 },
            .{ .char = 2 },
            .{ .char = 255 },
            .{ .char = 254 },
        },
    });
    try runTestError("\"abcdefg\"^0n 256 -256 1.4 1.5 -1.4 -1.5 6", FillError.length_mismatch);

    try runTestError("`a`b`c`d`e^1f", FillError.incompatible_types);
    try runTestError("`a`b`c`d`e^`float$()", FillError.incompatible_types);
    try runTestError("`a`b`c`d`e^1 2 3 4 5f", FillError.incompatible_types);
    try runTestError("`a`b`c`d`e^1 0n 3 0n 5", FillError.incompatible_types);
    try runTestError("`a`b`c`d`e^1 0n 3 0n 5 6", FillError.incompatible_types);
}

test "fill char" {
    try runTest("1b^\"a\"", .{ .char = 'a' });
    try runTest("1b^\" \"", .{ .char = 1 });
    try runTest("1b^\"\"", .{ .char_list = &[_]TestValue{} });
    try runTest("1b^\"abcde\"", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });
    try runTest("1b^\"a c e\"", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = 1 },
            .{ .char = 'c' },
            .{ .char = 1 },
            .{ .char = 'e' },
        },
    });

    try runTest("1^\"a\"", .{ .char = 'a' });
    try runTest("1^\" \"", .{ .char = 1 });
    try runTest("-1^\"a\"", .{ .char = 'a' });
    try runTest("-1^\" \"", .{ .char = 255 });
    try runTest("256^\"a\"", .{ .char = 'a' });
    try runTest("256^\" \"", .{ .char = 0 });
    try runTest("1^\"\"", .{ .char_list = &[_]TestValue{} });
    try runTest("1^\"abcde\"", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });
    try runTest("1^\"a c e\"", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = 1 },
            .{ .char = 'c' },
            .{ .char = 1 },
            .{ .char = 'e' },
        },
    });
    try runTest("-1^\"abcde\"", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });
    try runTest("-1^\"a c e\"", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = 255 },
            .{ .char = 'c' },
            .{ .char = 255 },
            .{ .char = 'e' },
        },
    });
    try runTest("256^\"abcde\"", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });
    try runTest("256^\"a c e\"", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = 0 },
            .{ .char = 'c' },
            .{ .char = 0 },
            .{ .char = 'e' },
        },
    });

    try runTest("1f^\"a\"", .{ .char = 'a' });
    try runTest("1f^\" \"", .{ .char = 1 });
    try runTest("1.4^\"a\"", .{ .char = 'a' });
    try runTest("1.4^\" \"", .{ .char = 1 });
    try runTest("1.5^\"a\"", .{ .char = 'a' });
    try runTest("1.5^\" \"", .{ .char = 2 });
    try runTest("-1.4^\"a\"", .{ .char = 'a' });
    try runTest("-1.4^\" \"", .{ .char = 255 });
    try runTest("-1.5^\"a\"", .{ .char = 'a' });
    try runTest("-1.5^\" \"", .{ .char = 254 });
    try runTest("-1f^\"a\"", .{ .char = 'a' });
    try runTest("-1f^\" \"", .{ .char = 255 });
    try runTest("256f^\"a\"", .{ .char = 'a' });
    try runTest("256f^\" \"", .{ .char = 0 });
    try runTest("1f^\"\"", .{ .char_list = &[_]TestValue{} });
    try runTest("1f^\"abcde\"", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });
    try runTest("1f^\"a c e\"", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = 1 },
            .{ .char = 'c' },
            .{ .char = 1 },
            .{ .char = 'e' },
        },
    });
    try runTest("-1f^\"abcde\"", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });
    try runTest("-1f^\"a c e\"", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = 255 },
            .{ .char = 'c' },
            .{ .char = 255 },
            .{ .char = 'e' },
        },
    });
    try runTest("256f^\"abcde\"", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });
    try runTest("256f^\"a c e\"", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = 0 },
            .{ .char = 'c' },
            .{ .char = 0 },
            .{ .char = 'e' },
        },
    });

    try runTest("\"1\"^\"a\"", .{ .char = 'a' });
    try runTest("\"1\"^\" \"", .{ .char = '1' });
    try runTest("\"1\"^\"\"", .{ .char_list = &[_]TestValue{} });
    try runTest("\"1\"^\"abcde\"", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });
    try runTest("\"1\"^\"a c e\"", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = '1' },
            .{ .char = 'c' },
            .{ .char = '1' },
            .{ .char = 'e' },
        },
    });

    try runTestError("`symbol^\"a\"", FillError.incompatible_types);
    try runTestError("`symbol^\" \"", FillError.incompatible_types);
    try runTestError("`symbol^\"\"", FillError.incompatible_types);
    try runTestError("`symbol^\"abcde\"", FillError.incompatible_types);
    try runTestError("`symbol^\"a c e\"", FillError.incompatible_types);

    try runTestError("()^\"a\"", FillError.incompatible_types);
    try runTestError("(1b;2;3f)^\"a\"", FillError.incompatible_types);
    try runTest("()^\"\"", .{ .list = &[_]TestValue{} });
    try runTestError("()^\"abcde\"", FillError.length_mismatch);
    try runTest("(1b;2;3f;4;5f)^\"abcde\"", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });
    try runTest("(1b;2;3f;4;5f)^\"a c e\"", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = 2 },
            .{ .char = 'c' },
            .{ .char = 4 },
            .{ .char = 'e' },
        },
    });
    try runTestError("(1b;2;3f;4;5f)^\"a c ef\"", FillError.length_mismatch);
    try runTest("(1b;2;3f;4;\"a\")^\"a c e\"", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = 2 },
            .{ .char = 'c' },
            .{ .char = 4 },
            .{ .char = 'e' },
        },
    });
    try runTestError("(1b;2;3f;4;`symbol)^\"a c e\"", FillError.incompatible_types);

    try runTestError("10011b^\"a\"", FillError.incompatible_types);
    try runTestError("10011b^\"\"", FillError.length_mismatch);
    try runTest("10011b^\"abcde\"", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });
    try runTest("10011b^\"a c e\"", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = 0 },
            .{ .char = 'c' },
            .{ .char = 1 },
            .{ .char = 'e' },
        },
    });
    try runTestError("10011b^\"a c ef\"", FillError.length_mismatch);

    try runTestError("5 4 3 2 1^\"a\"", FillError.incompatible_types);
    try runTestError("5 4 3 2 1^\"\"", FillError.length_mismatch);
    try runTest("5 4 3 2 1^\"abcde\"", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });
    try runTest("5 4 3 2 1^\"a c e\"", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = 4 },
            .{ .char = 'c' },
            .{ .char = 2 },
            .{ .char = 'e' },
        },
    });
    try runTest("-1 256 256 -1 -1^\"abcde\"", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });
    try runTest("-1 256 256 -1 -1^\"a c e\"", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = 0 },
            .{ .char = 'c' },
            .{ .char = 255 },
            .{ .char = 'e' },
        },
    });
    try runTestError("5 4 3 2 1^\"a c ef\"", FillError.length_mismatch);

    try runTestError("5 4 3 2 1f^\"a\"", FillError.incompatible_types);
    try runTestError("5 4 3 2 1f^\"\"", FillError.length_mismatch);
    try runTest("5 4 3 2 1f^\"abcde\"", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });
    try runTest("5 4 3 2 1f^\"a c e\"", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = 4 },
            .{ .char = 'c' },
            .{ .char = 2 },
            .{ .char = 'e' },
        },
    });
    try runTest("-1 256 256 -1 -1f^\"abcde\"", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });
    try runTest("-1 256 256 -1 -1f^\"a c e\"", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = 0 },
            .{ .char = 'c' },
            .{ .char = 255 },
            .{ .char = 'e' },
        },
    });
    try runTestError("-1 256 256 -1 -1f^\"a c ef\"", FillError.length_mismatch);

    try runTestError("\"54321\"^\"a\"", FillError.incompatible_types);
    try runTestError("\"54321\"^\"\"", FillError.length_mismatch);
    try runTest("\"54321\"^\"abcde\"", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });
    try runTest("\"54321\"^\"a c e\"", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = '4' },
            .{ .char = 'c' },
            .{ .char = '2' },
            .{ .char = 'e' },
        },
    });
    try runTestError("\"54321\"^\"a c ef\"", FillError.length_mismatch);

    try runTestError("`a`b`c`d`e^\"a\"", FillError.incompatible_types);
    try runTestError("`a`b`c`d`e^\"\"", FillError.incompatible_types);
    try runTestError("`a`b`c`d`e^\"abcde\"", FillError.incompatible_types);
    try runTestError("`a`b`c`d`e^\"a c e\"", FillError.incompatible_types);
    try runTestError("`a`b`c`d`e^\"a c ef\"", FillError.incompatible_types);
}

test "fill symbol" {
    try runTestError("1b^`symbol", FillError.incompatible_types);
    try runTestError("1b^`", FillError.incompatible_types);
    try runTestError("1b^`$()", FillError.incompatible_types);
    try runTestError("1b^`a`b`c`d`e", FillError.incompatible_types);
    try runTestError("1b^`a``c``e", FillError.incompatible_types);

    try runTestError("1^`symbol", FillError.incompatible_types);
    try runTestError("1^`", FillError.incompatible_types);
    try runTestError("1^`$()", FillError.incompatible_types);
    try runTestError("1^`a`b`c`d`e", FillError.incompatible_types);
    try runTestError("1^`a``c``e", FillError.incompatible_types);

    try runTestError("1f^`symbol", FillError.incompatible_types);
    try runTestError("1f^`", FillError.incompatible_types);
    try runTestError("1f^`$()", FillError.incompatible_types);
    try runTestError("1f^`a`b`c`d`e", FillError.incompatible_types);
    try runTestError("1f^`a``c``e", FillError.incompatible_types);

    try runTestError("\"a\"^`symbol", FillError.incompatible_types);
    try runTestError("\"a\"^`", FillError.incompatible_types);
    try runTestError("\"a\"^`$()", FillError.incompatible_types);
    try runTestError("\"a\"^`a`b`c`d`e", FillError.incompatible_types);
    try runTestError("\"a\"^`a``c``e", FillError.incompatible_types);

    try runTest("`symbol^`a", .{ .symbol = "a" });
    try runTest("`symbol^`", .{ .symbol = "symbol" });
    try runTest("`symbol^`$()", .{ .symbol_list = &[_]TestValue{} });
    try runTest("`symbol^`a`b`c`d`e", .{
        .symbol_list = &[_]TestValue{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
        },
    });
    try runTest("`symbol^`a``c``e", .{
        .symbol_list = &[_]TestValue{
            .{ .symbol = "a" },
            .{ .symbol = "symbol" },
            .{ .symbol = "c" },
            .{ .symbol = "symbol" },
            .{ .symbol = "e" },
        },
    });

    try runTestError("()^`symbol", FillError.incompatible_types);
    try runTestError("(1b;2;3f;4;5f)^`symbol", FillError.incompatible_types);
    try runTestError("()^`$()", FillError.incompatible_types);
    try runTestError("()^`a`b`c`d`e", FillError.incompatible_types);
    try runTestError("(1b;2;3f;4;5f)^`a`b`c`d`e", FillError.incompatible_types);
    try runTestError("(1b;2;3f;4;5f)^`a``c``e", FillError.incompatible_types);
    try runTestError("(1b;2;3f;4;\"a\")^`a``c``e", FillError.incompatible_types);
    try runTestError("(1b;2;3f;4;`symbol)^`a``c``e", FillError.incompatible_types);

    try runTestError("10011b^`symbol", FillError.incompatible_types);
    try runTestError("10011b^`$()", FillError.incompatible_types);
    try runTestError("10011b^`a`b`c`d`e", FillError.incompatible_types);
    try runTestError("10011b^`a``c``e", FillError.incompatible_types);
    try runTestError("10011b^`a``c``e`f", FillError.incompatible_types);

    try runTestError("5 4 3 2 1^`symbol", FillError.incompatible_types);
    try runTestError("5 4 3 2 1^`$()", FillError.incompatible_types);
    try runTestError("5 4 3 2 1^`a`b`c`d`e", FillError.incompatible_types);
    try runTestError("5 4 3 2 1^`a``c``e", FillError.incompatible_types);
    try runTestError("5 4 3 2 1^`a``c``e`f", FillError.incompatible_types);

    try runTestError("5 4 3 2 1f^`symbol", FillError.incompatible_types);
    try runTestError("5 4 3 2 1f^`$()", FillError.incompatible_types);
    try runTestError("5 4 3 2 1f^`a`b`c`d`e", FillError.incompatible_types);
    try runTestError("5 4 3 2 1f^`a``c``e", FillError.incompatible_types);
    try runTestError("5 4 3 2 1f^`a``c``e`f", FillError.incompatible_types);

    try runTestError("\"54321\"^`symbol", FillError.incompatible_types);
    try runTestError("\"54321\"^`$()", FillError.incompatible_types);
    try runTestError("\"54321\"^`a`b`c`d`e", FillError.incompatible_types);
    try runTestError("\"54321\"^`a``c``e", FillError.incompatible_types);
    try runTestError("\"54321\"^`a``c``e`f", FillError.incompatible_types);

    try runTestError("`5`4`3`2`1^`symbol", FillError.incompatible_types);
    try runTestError("`5`4`3`2`1^`$()", FillError.length_mismatch);
    try runTest("`5`4`3`2`1^`a`b`c`d`e", .{
        .symbol_list = &[_]TestValue{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
        },
    });
    try runTest("`5`4`3`2`1^`a``c``e", .{
        .symbol_list = &[_]TestValue{
            .{ .symbol = "a" },
            .{ .symbol = "4" },
            .{ .symbol = "c" },
            .{ .symbol = "2" },
            .{ .symbol = "e" },
        },
    });
    try runTestError("`5`4`3`2`1^`a``c``e`f", FillError.length_mismatch);
}

test "fill list" {
    try runTest("1b^()", .{ .list = &[_]TestValue{} });
    try runTest("1b^(0b;1;0N;1f;0n;\"a\";\" \")", .{
        .list = &[_]TestValue{
            .{ .boolean = false },
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .char = 'a' },
            .{ .char = 1 },
        },
    });
    try runTestError("1b^(0b;1;0N;1f;0n;\"a\";\" \";`symbol;`)", FillError.incompatible_types);
    try runTestError("1b^(`;`symbol;\" \";\"a\";0n;1f;0N;1;0b)", FillError.incompatible_types);

    try runTest("1^()", .{ .list = &[_]TestValue{} });
    try runTest("1^(0b;1;0N;1f;0n;\"a\";\" \")", .{
        .list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .char = 'a' },
            .{ .char = 1 },
        },
    });
    try runTest("1^(0b;0N)", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 1 },
        },
    });
    try runTestError("1^(0b;1;0N;1f;0n;\"a\";\" \";`symbol;`)", FillError.incompatible_types);
    try runTestError("1^(`;`symbol;\" \";\"a\";0n;1f;0N;1;0b)", FillError.incompatible_types);

    try runTest("1f^()", .{ .list = &[_]TestValue{} });
    try runTest("1f^(0b;1;0N;1f;0n;\"a\";\" \")", .{
        .list = &[_]TestValue{
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .char = 'a' },
            .{ .char = 1 },
        },
    });
    try runTest("1f^(0b;0N)", .{
        .float_list = &[_]TestValue{
            .{ .float = 0 },
            .{ .float = 1 },
        },
    });
    try runTestError("1f^(0b;1;0N;1f;0n;\"a\";\" \";`symbol;`)", FillError.incompatible_types);
    try runTestError("1f^(`;`symbol;\" \";\"a\";0n;1f;0N;1;0b)", FillError.incompatible_types);

    try runTest("\"a\"^()", .{ .list = &[_]TestValue{} });
    try runTest("\"a\"^(\" \";\"b \")", .{
        .list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char_list = &[_]TestValue{
                .{ .char = 'b' },
                .{ .char = 'a' },
            } },
        },
    });
    try runTestError("\"a\"^(0b;1;0N;1f;0n;\"a\";\" \";`symbol;`)", FillError.incompatible_types);
    try runTestError("\"a\"^(`;`symbol;\" \";\"a\";0n;1f;0N;1;0b)", FillError.incompatible_types);

    try runTest("`test^()", .{ .list = &[_]TestValue{} });
    try runTest("`test^(`;`symbol`)", .{
        .list = &[_]TestValue{
            .{ .symbol = "test" },
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "symbol" },
                .{ .symbol = "test" },
            } },
        },
    });
    try runTestError("`test^(0b;1;0N;1f;0n;\"a\";\" \";`symbol;`)", FillError.incompatible_types);
    try runTestError("`test^(`;`symbol;\" \";\"a\";0n;1f;0N;1;0b)", FillError.incompatible_types);

    try runTest("()^()", .{ .list = &[_]TestValue{} });
    try runTestError("(2;3f)^()", FillError.length_mismatch);
    try runTestError("()^(0n;0N)", FillError.length_mismatch);
    try runTest("(2;3f)^(0n;0N)", .{
        .float_list = &[_]TestValue{
            .{ .float = 2 },
            .{ .float = 3 },
        },
    });
    try runTest("(1b;(2;3f);(\"a\";`a`b`c`d`e))^(0N;(0n;0N);(\" \";`a``c``e))", .{
        .list = &[_]TestValue{
            .{ .int = 1 },
            .{ .float_list = &[_]TestValue{
                .{ .float = 2 },
                .{ .float = 3 },
            } },
            .{ .list = &[_]TestValue{
                .{ .char = 'a' },
                .{ .symbol_list = &[_]TestValue{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                    .{ .symbol = "c" },
                    .{ .symbol = "d" },
                    .{ .symbol = "e" },
                } },
            } },
        },
    });
    try runTestError("(0b;1;2;3;4;5;6;7;8)^(0b;1;0N;1f;0n;\"a\";\" \";`symbol;`)", FillError.incompatible_types);
    try runTestError("(0b;1;2;3;4;5;6;7;8)^(`;`symbol;\" \";\"a\";0n;1f;0N;1;0b)", FillError.incompatible_types);

    try runTestError("010b^()", FillError.length_mismatch);
    try runTest("010b^(0b;0N;0n)", .{
        .list = &[_]TestValue{
            .{ .boolean = false },
            .{ .int = 1 },
            .{ .float = 0 },
        },
    });
    try runTestError("010101010b^(0b;1;0N;1f;0n;\"a\";\" \";`symbol;`)", FillError.incompatible_types);
    try runTestError("010101010b^(`;`symbol;\" \";\"a\";0n;1f;0N;1;0b)", FillError.incompatible_types);

    try runTestError("0 1 2^()", FillError.length_mismatch);
    try runTest("0 1 2^(0b;0N;0n)", .{
        .list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .float = 2 },
        },
    });
    try runTestError("0 1 2 3 4 5 6 7 8^(0b;1;0N;1f;0n;\"a\";\" \";`symbol;`)", FillError.incompatible_types);
    try runTestError("0 1 2 3 4 5 6 7 8^(`;`symbol;\" \";\"a\";0n;1f;0N;1;0b)", FillError.incompatible_types);

    try runTestError("0 1 2f^()", FillError.length_mismatch);
    try runTest("0 1 2f^(0b;0N;0n)", .{
        .float_list = &[_]TestValue{
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = 2 },
        },
    });
    try runTestError("0 1 2 3 4 5 6 7 8f^(0b;1;0N;1f;0n;\"a\";\" \";`symbol;`)", FillError.incompatible_types);
    try runTestError("0 1 2 3 4 5 6 7 8f^(`;`symbol;\" \";\"a\";0n;1f;0N;1;0b)", FillError.incompatible_types);

    try runTestError("\"abcde\"^()", FillError.length_mismatch);
    try runTest("\"ab\"^(\" \";\"  \")", .{
        .list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char_list = &[_]TestValue{
                .{ .char = 'b' },
                .{ .char = 'b' },
            } },
        },
    });
    try runTestError("\"abcdefghi\"^(0b;1;0N;1f;0n;\"a\";\" \";`symbol;`)", FillError.incompatible_types);
    try runTestError("\"abcdefghi\"^(`;`symbol;\" \";\"a\";0n;1f;0N;1;0b)", FillError.incompatible_types);

    try runTestError("`a`b`c`d`e^()", FillError.length_mismatch);
    try runTest("`a`b^(`;``)", .{
        .list = &[_]TestValue{
            .{ .symbol = "a" },
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "b" },
                .{ .symbol = "b" },
            } },
        },
    });
    try runTestError("`a`b`c`d`e`f`g`h`i^(0b;1;0N;1f;0n;\"a\";\" \";`symbol;`)", FillError.incompatible_types);
    try runTestError("`a`b`c`d`e`f`g`h`i^(`;`symbol;\" \";\"a\";0n;1f;0N;1;0b)", FillError.incompatible_types);
}
