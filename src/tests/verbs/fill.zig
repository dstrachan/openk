const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;
const TestValue = vm_mod.TestValue;

test "fill boolean" {
    try runTest("1b^0b", .{ .boolean = false });
    try runTest("1b^00000b", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTest("11111b^00000b", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTest("1^0b", .{ .int = 0 });
    try runTest("1^00000b", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 0 },
            .{ .int = 0 },
            .{ .int = 0 },
            .{ .int = 0 },
        },
    });
    try runTest("5 4 3 2 1^00000b", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 0 },
            .{ .int = 0 },
            .{ .int = 0 },
            .{ .int = 0 },
        },
    });
    try runTest("1f^0b", .{ .float = 0 });
    try runTest("1f^00000b", .{
        .float_list = &[_]TestValue{
            .{ .float = 0 },
            .{ .float = 0 },
            .{ .float = 0 },
            .{ .float = 0 },
            .{ .float = 0 },
        },
    });
    try runTest("5 4 3 2 1f^00000b", .{
        .float_list = &[_]TestValue{
            .{ .float = 0 },
            .{ .float = 0 },
            .{ .float = 0 },
            .{ .float = 0 },
            .{ .float = 0 },
        },
    });
}

test "fill int" {
    try runTest("1b^0", .{ .int = 0 });
    try runTest("1b^0N", .{ .int = 1 });
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
    try runTest("1^0", .{ .int = 0 });
    try runTest("1^0N", .{ .int = 1 });
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
    try runTest("1f^0", .{ .float = 0 });
    try runTest("1f^0N", .{ .float = 1 });
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
}

test "fill float" {
    try runTest("1b^0f", .{ .float = 0 });
    try runTest("1b^0n", .{ .float = 1 });
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
    try runTest("1^0f", .{ .float = 0 });
    try runTest("1^0n", .{ .float = 1 });
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
    try runTest("1f^0f", .{ .float = 0 });
    try runTest("1f^0n", .{ .float = 1 });
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
}

test "fill char" {
    try runTest("1b^\"a\"", .{ .char = 'a' });
    try runTest("1b^\" \"", .{ .char = 1 });
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
    try runTest("1^\"a\"", .{ .char = 'a' });
    try runTest("1^\" \"", .{ .char = 1 });
    try runTest("-1^\"a\"", .{ .char = 'a' });
    try runTest("-1^\" \"", .{ .char = 255 });
    try runTest("256^\"a\"", .{ .char = 'a' });
    try runTest("256^\" \"", .{ .char = 0 });
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
    try runTest("1f^\"a\"", .{ .char = 'a' });
    try runTest("1f^\" \"", .{ .char = 1 });
    try runTest("1.4f^\"a\"", .{ .char = 'a' });
    try runTest("1.4f^\" \"", .{ .char = 1 });
    try runTest("1.5f^\"a\"", .{ .char = 'a' });
    try runTest("1.5f^\" \"", .{ .char = 2 });
    try runTest("-1.4f^\"a\"", .{ .char = 'a' });
    try runTest("-1.4f^\" \"", .{ .char = 255 });
    try runTest("-1.5f^\"a\"", .{ .char = 'a' });
    try runTest("-1.5f^\" \"", .{ .char = 254 });
    try runTest("-1f^\"a\"", .{ .char = 'a' });
    try runTest("-1f^\" \"", .{ .char = 255 });
    try runTest("256f^\"a\"", .{ .char = 'a' });
    try runTest("256f^\" \"", .{ .char = 0 });
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
    try runTest("\"1\"^\"a\"", .{ .char = 'a' });
    try runTest("\"1\"^\" \"", .{ .char = '1' });
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
}

test "fill symbol" {
    try runTest("`test^`symbol", .{ .symbol = "symbol" });
    try runTest("`test^`", .{ .symbol = "test" });
    try runTest("`test^`a`b`c`d`e", .{
        .symbol_list = &[_]TestValue{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
        },
    });
    try runTest("`test^`a``c``e", .{
        .symbol_list = &[_]TestValue{
            .{ .symbol = "a" },
            .{ .symbol = "test" },
            .{ .symbol = "c" },
            .{ .symbol = "test" },
            .{ .symbol = "e" },
        },
    });
    try runTest("`e`d`c`b`a^`a`b`c`d`e", .{
        .symbol_list = &[_]TestValue{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
        },
    });
    try runTest("`e`d`c`b`a^`a``c``e", .{
        .symbol_list = &[_]TestValue{
            .{ .symbol = "a" },
            .{ .symbol = "d" },
            .{ .symbol = "c" },
            .{ .symbol = "b" },
            .{ .symbol = "e" },
        },
    });
}

test "fill list" {
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
    try runTest("1^(0b;1;0N;1f;0n;\"a\";\" \")", .{
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
    try runTest("1f^(0b;1;0N;1f;0n;\"a\";\" \")", .{
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
    try runTest("\"a\"^(\" \";\"b \")", .{
        .list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char_list = &[_]TestValue{
                .{ .char = 'b' },
                .{ .char = 'a' },
            } },
        },
    });
    try runTest("`test^(`;`symbol`)", .{
        .list = &[_]TestValue{
            .{ .symbol = "test" },
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "symbol" },
                .{ .symbol = "test" },
            } },
        },
    });
    try runTest("(2;3f)^(0n;0N)", .{
        .float_list = &[_]TestValue{
            .{ .float = 2 },
            .{ .float = 3 },
        },
    });
    try runTest("(1b;(2;3f);(\"a\";`a`b`c`d`e))^(0N;(0n;0N);(\" \";`a``c``e))", .{
        .list = &[_]TestValue{
            .{ .int = 1 },
            .{
                .float_list = &[_]TestValue{
                    .{ .float = 2 },
                    .{ .float = 3 },
                },
            },
            .{
                .list = &[_]TestValue{
                    .{ .char = 'a' },
                    .{
                        .symbol_list = &[_]TestValue{
                            .{ .symbol = "a" },
                            .{ .symbol = "b" },
                            .{ .symbol = "c" },
                            .{ .symbol = "d" },
                            .{ .symbol = "e" },
                        },
                    },
                },
            },
        },
    });
    try runTest("(1b;2;3f)^010b", .{
        .list = &[_]TestValue{
            .{ .boolean = false },
            .{ .int = 1 },
            .{ .float = 0 },
        },
    });
    try runTest("(1b;2;3f)^0 0N 2", .{
        .list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 2 },
            .{ .float = 2 },
        },
    });
    try runTest("(1b;2;3f)^0 0n 2", .{
        .float_list = &[_]TestValue{
            .{ .float = 0 },
            .{ .float = 2 },
            .{ .float = 2 },
        },
    });
    try runTest("010b^(0b;0N;0n)", .{
        .list = &[_]TestValue{
            .{ .boolean = false },
            .{ .int = 1 },
            .{ .float = 0 },
        },
    });
    try runTest("0 1 2^(0b;0N;0n)", .{
        .list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .float = 2 },
        },
    });
    try runTest("0 1 2f^(0b;0N;0n)", .{
        .float_list = &[_]TestValue{
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = 2 },
        },
    });
}
