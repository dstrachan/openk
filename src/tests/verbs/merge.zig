const value_mod = @import("../../value.zig");
const Value = value_mod.Value;

const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;
const runTestError = vm_mod.runTestError;
const TestValue = vm_mod.TestValue;

const MergeError = @import("../../verbs/merge.zig").MergeError;

test "merge boolean" {
    try runTest("1b,0b", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = false },
        },
    });
    try runTest("1b,`boolean$()", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
        },
    });
    try runTest("1b,00000b", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });

    try runTest("1,0b", .{
        .list = &[_]TestValue{
            .{ .int = 1 },
            .{ .boolean = false },
        },
    });
    try runTest("1,`boolean$()", .{
        .int_list = &[_]TestValue{
            .{ .int = 1 },
        },
    });
    try runTest("1,00000b", .{
        .list = &[_]TestValue{
            .{ .int = 1 },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });

    try runTest("1f,0b", .{
        .list = &[_]TestValue{
            .{ .float = 1 },
            .{ .boolean = false },
        },
    });
    try runTest("1f,`boolean$()", .{
        .float_list = &[_]TestValue{
            .{ .float = 1 },
        },
    });
    try runTest("1f,00000b", .{
        .list = &[_]TestValue{
            .{ .float = 1 },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });

    try runTest("\"a\",0b", .{
        .list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .boolean = false },
        },
    });
    try runTest("\"a\",`boolean$()", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
        },
    });
    try runTest("\"a\",00000b", .{
        .list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });

    try runTest("`symbol,0b", .{
        .list = &[_]TestValue{
            .{ .symbol = "symbol" },
            .{ .boolean = false },
        },
    });
    try runTest("`symbol,`boolean$()", .{
        .symbol_list = &[_]TestValue{
            .{ .symbol = "symbol" },
        },
    });
    try runTest("`symbol,00000b", .{
        .list = &[_]TestValue{
            .{ .symbol = "symbol" },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });

    try runTest("(),0b", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
        },
    });
    try runTest("(1b;2),0b", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .boolean = false },
        },
    });
    try runTest("(1b;2;3f),0b", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .boolean = false },
        },
    });
    try runTest("(1b;2;3f;`symbol),0b", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .symbol = "symbol" },
            .{ .boolean = false },
        },
    });
    try runTest("(),`boolean$()", .{ .boolean_list = &[_]TestValue{} });
    try runTest("(),010b", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
        },
    });
    try runTest("(1b;2),`boolean$()", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .int = 2 },
        },
    });
    try runTest("(1b;2),01b", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .boolean = false },
            .{ .boolean = true },
        },
    });
    try runTest("(1b;2;3f),010b", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
        },
    });
    try runTest("(1b;2;3f),0101b", .{
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
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
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = false },
        },
    });
    try runTest("11111b,`boolean$()", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTest("11111b,00000b", .{
        .boolean_list = &[_]TestValue{
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
        .boolean_list = &[_]TestValue{
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
        .list = &[_]TestValue{
            .{ .int = 5 },
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = 2 },
            .{ .int = 1 },
            .{ .boolean = false },
        },
    });
    try runTest("5 4 3 2 1,`boolean$()", .{
        .int_list = &[_]TestValue{
            .{ .int = 5 },
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = 2 },
            .{ .int = 1 },
        },
    });
    try runTest("5 4 3 2 1,00000b", .{
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
            .{ .boolean = false },
        },
    });
    try runTest("5 4 3 2 1f,`boolean$()", .{
        .float_list = &[_]TestValue{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
        },
    });
    try runTest("5 4 3 2 1f,00000b", .{
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
            .{ .boolean = false },
        },
    });
    try runTest("\"abcde\",`boolean$()", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });
    try runTest("\"abcde\",00000b", .{
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
            .{ .boolean = false },
        },
    });
    try runTest("`a`b`c`d`e,`boolean$()", .{
        .symbol_list = &[_]TestValue{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
        },
    });
    try runTest("`a`b`c`d`e,00000b", .{
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
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
}

test "merge int" {
    try runTest("1b,0", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .int = 0 },
        },
    });
    try runTest("1b,`int$()", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
        },
    });
    try runTest("1b,0 1 0N 0W -0W", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
        },
    });

    try runTest("1,0", .{
        .int_list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 0 },
        },
    });
    try runTest("1,`int$()", .{
        .int_list = &[_]TestValue{
            .{ .int = 1 },
        },
    });
    try runTest("1,0 1 0N 0W -0W", .{
        .int_list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
        },
    });

    try runTest("1f,0", .{
        .list = &[_]TestValue{
            .{ .float = 1 },
            .{ .int = 0 },
        },
    });
    try runTest("1f,`int$()", .{
        .float_list = &[_]TestValue{
            .{ .float = 1 },
        },
    });
    try runTest("1f,0 1 0N 0W -0W", .{
        .list = &[_]TestValue{
            .{ .float = 1 },
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
        },
    });

    try runTest("\"a\",0", .{
        .list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .int = 0 },
        },
    });
    try runTest("\"a\",`int$()", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
        },
    });
    try runTest("\"a\",0 1 0N 0W -0W", .{
        .list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
        },
    });

    try runTest("`symbol,0", .{
        .list = &[_]TestValue{
            .{ .symbol = "symbol" },
            .{ .int = 0 },
        },
    });
    try runTest("`symbol,`int$()", .{
        .symbol_list = &[_]TestValue{
            .{ .symbol = "symbol" },
        },
    });
    try runTest("`symbol,0 1 0N 0W -0W", .{
        .list = &[_]TestValue{
            .{ .symbol = "symbol" },
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
        },
    });

    try runTest("(),0", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
        },
    });
    try runTest("(1b;2),0", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .int = 0 },
        },
    });
    try runTest("(1b;2;3f),0", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .int = 0 },
        },
    });
    try runTest("(1b;2;3f;`symbol),0", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .symbol = "symbol" },
            .{ .int = 0 },
        },
    });
    try runTest("(),`int$()", .{ .int_list = &[_]TestValue{} });
    try runTest("(),0 1 0N 0W -0W", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
        },
    });
    try runTest("(1b;2;3;4;5),`int$()", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .int = 3 },
            .{ .int = 4 },
            .{ .int = 5 },
        },
    });
    try runTest("(1b;2;3;4;5),0 1 0N 0W -0W", .{
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .int = 0 },
        },
    });
    try runTest("11111b,`int$()", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTest("11111b,0 1 0N 0W -0W", .{
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
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
        .int_list = &[_]TestValue{
            .{ .int = 5 },
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = 2 },
            .{ .int = 1 },
            .{ .int = 0 },
        },
    });
    try runTest("5 4 3 2 1,`int$()", .{
        .int_list = &[_]TestValue{
            .{ .int = 5 },
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = 2 },
            .{ .int = 1 },
        },
    });
    try runTest("5 4 3 2 1,0 1 0N 0W -0W", .{
        .int_list = &[_]TestValue{
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
        .int_list = &[_]TestValue{
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
        .list = &[_]TestValue{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
            .{ .int = 0 },
        },
    });
    try runTest("5 4 3 2 1f,`int$()", .{
        .float_list = &[_]TestValue{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
        },
    });
    try runTest("5 4 3 2 1f,0 1 0N 0W -0W", .{
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
            .{ .int = 0 },
        },
    });
    try runTest("\"abcde\",`int$()", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });
    try runTest("\"abcde\",0 1 0N 0W -0W", .{
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
            .{ .int = 0 },
        },
    });
    try runTest("`a`b`c`d`e,`int$()", .{
        .symbol_list = &[_]TestValue{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
        },
    });
    try runTest("`a`b`c`d`e,0 1 0N 0W -0W", .{
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
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
}

test "merge float" {
    try runTest("1b,0f", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .float = 0 },
        },
    });
    try runTest("1b,`float$()", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
        },
    });
    try runTest("1b,0 1 0n 0w -0w", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
        },
    });

    try runTest("1,0f", .{
        .list = &[_]TestValue{
            .{ .int = 1 },
            .{ .float = 0 },
        },
    });
    try runTest("1,`float$()", .{
        .int_list = &[_]TestValue{
            .{ .int = 1 },
        },
    });
    try runTest("1,0 1 0n 0w -0w", .{
        .list = &[_]TestValue{
            .{ .int = 1 },
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
        },
    });

    try runTest("1f,0f", .{
        .float_list = &[_]TestValue{
            .{ .float = 1 },
            .{ .float = 0 },
        },
    });
    try runTest("1f,`float$()", .{
        .float_list = &[_]TestValue{
            .{ .float = 1 },
        },
    });
    try runTest("1f,0 1 0n 0w -0w", .{
        .float_list = &[_]TestValue{
            .{ .float = 1 },
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
        },
    });

    try runTest("\"a\",0f", .{
        .list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .float = 0 },
        },
    });
    try runTest("\"a\",`float$()", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
        },
    });
    try runTest("\"a\",0 1 0n 0w -0w", .{
        .list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
        },
    });

    try runTest("`symbol,0f", .{
        .list = &[_]TestValue{
            .{ .symbol = "symbol" },
            .{ .float = 0 },
        },
    });
    try runTest("`symbol,`float$()", .{
        .symbol_list = &[_]TestValue{
            .{ .symbol = "symbol" },
        },
    });
    try runTest("`symbol,0 1 0n 0w -0w", .{
        .list = &[_]TestValue{
            .{ .symbol = "symbol" },
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
        },
    });

    try runTest("(),0f", .{
        .float_list = &[_]TestValue{
            .{ .float = 0 },
        },
    });
    try runTest("(1b;2;3f),0f", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .float = 0 },
        },
    });
    try runTest("(1b;2;3f;`symbol),0f", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .symbol = "symbol" },
            .{ .float = 0 },
        },
    });
    try runTest("(),`float$()", .{ .float_list = &[_]TestValue{} });
    try runTest("(),0 1 0n 0w -0w", .{
        .float_list = &[_]TestValue{
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = Value.inf_float },
            .{ .float = -Value.inf_float },
        },
    });
    try runTest("(1b;2;3f;4;5),`float$()", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .int = 4 },
            .{ .int = 5 },
        },
    });
    try runTest("(1b;2;3f;4;5),0 1 0n 0w -0w", .{
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .float = 0 },
        },
    });
    try runTest("11111b,`float$()", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTest("11111b,0 1 0n 0w -0w", .{
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
            .{ .int = 5 },
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = 2 },
            .{ .int = 1 },
            .{ .float = 0 },
        },
    });
    try runTest("5 4 3 2 1,`float$()", .{
        .int_list = &[_]TestValue{
            .{ .int = 5 },
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = 2 },
            .{ .int = 1 },
        },
    });
    try runTest("5 4 3 2 1,0 1 0n 0w -0w", .{
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
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
        .float_list = &[_]TestValue{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
            .{ .float = 0 },
        },
    });
    try runTest("5 4 3 2 1f,`float$()", .{
        .float_list = &[_]TestValue{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
        },
    });
    try runTest("5 4 3 2 1f,0 1 0n 0w -0w", .{
        .float_list = &[_]TestValue{
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
        .float_list = &[_]TestValue{
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
        .list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
            .{ .float = 0 },
        },
    });
    try runTest("\"abcde\",`float$()", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });
    try runTest("\"abcde\",0 1 0n 0w -0w", .{
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
            .{ .float = 0 },
        },
    });
    try runTest("`a`b`c`d`e,`float$()", .{
        .symbol_list = &[_]TestValue{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
        },
    });
    try runTest("`a`b`c`d`e,0 1 0n 0w -0w", .{
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
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
}

test "merge char" {
    try runTest("1b,\"a\"", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .char = 'a' },
        },
    });
    try runTest("1b,\"\"", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
        },
    });
    try runTest("1b,\"abcde\"", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });

    try runTest("1,\"a\"", .{
        .list = &[_]TestValue{
            .{ .int = 1 },
            .{ .char = 'a' },
        },
    });
    try runTest("1,\"\"", .{
        .int_list = &[_]TestValue{
            .{ .int = 1 },
        },
    });
    try runTest("1,\"abcde\"", .{
        .list = &[_]TestValue{
            .{ .int = 1 },
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });

    try runTest("1f,\"a\"", .{
        .list = &[_]TestValue{
            .{ .float = 1 },
            .{ .char = 'a' },
        },
    });
    try runTest("1f,\"\"", .{
        .float_list = &[_]TestValue{
            .{ .float = 1 },
        },
    });
    try runTest("1f,\"abcde\"", .{
        .list = &[_]TestValue{
            .{ .float = 1 },
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });

    try runTest("\"1\",\"a\"", .{
        .char_list = &[_]TestValue{
            .{ .char = '1' },
            .{ .char = 'a' },
        },
    });
    try runTest("\"1\",\"\"", .{
        .char_list = &[_]TestValue{
            .{ .char = '1' },
        },
    });
    try runTest("\"1\",\"abcde\"", .{
        .char_list = &[_]TestValue{
            .{ .char = '1' },
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });

    try runTest("`symbol,\"a\"", .{
        .list = &[_]TestValue{
            .{ .symbol = "symbol" },
            .{ .char = 'a' },
        },
    });
    try runTest("`symbol,\"\"", .{
        .symbol_list = &[_]TestValue{
            .{ .symbol = "symbol" },
        },
    });
    try runTest("`symbol,\"abcde\"", .{
        .list = &[_]TestValue{
            .{ .symbol = "symbol" },
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });

    try runTest("(),\"a\"", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
        },
    });
    try runTest("(),\"\"", .{ .char_list = &[_]TestValue{} });
    try runTest("(),\"abcde\"", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });
    try runTest("(1b;2;3f),\"a\"", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .char = 'a' },
        },
    });
    try runTest("(1b;2;3f),\"\"", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
        },
    });
    try runTest("(1b;2;3f),\"abcde\"", .{
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .symbol = "symbol" },
            .{ .char = 'a' },
        },
    });
    try runTest("(1b;2;3f;`symbol),\"\"", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .symbol = "symbol" },
        },
    });
    try runTest("(1b;2;3f;`symbol),\"abcde\"", .{
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .char = 'a' },
        },
    });
    try runTest("10011b,\"\"", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTest("10011b,\"abcde\"", .{
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
            .{ .int = 5 },
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = 2 },
            .{ .int = 1 },
            .{ .char = 'a' },
        },
    });
    try runTest("5 4 3 2 1,\"\"", .{
        .int_list = &[_]TestValue{
            .{ .int = 5 },
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = 2 },
            .{ .int = 1 },
        },
    });
    try runTest("5 4 3 2 1,\"abcde\"", .{
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
            .{ .char = 'a' },
        },
    });
    try runTest("5 4 3 2 1f,\"\"", .{
        .float_list = &[_]TestValue{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
        },
    });
    try runTest("5 4 3 2 1f,\"abcde\"", .{
        .list = &[_]TestValue{
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
        .char_list = &[_]TestValue{
            .{ .char = '5' },
            .{ .char = '4' },
            .{ .char = '3' },
            .{ .char = '2' },
            .{ .char = '1' },
            .{ .char = 'a' },
        },
    });
    try runTest("\"54321\",\"\"", .{
        .char_list = &[_]TestValue{
            .{ .char = '5' },
            .{ .char = '4' },
            .{ .char = '3' },
            .{ .char = '2' },
            .{ .char = '1' },
        },
    });
    try runTest("\"54321\",\"abcde\"", .{
        .char_list = &[_]TestValue{
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
        .list = &[_]TestValue{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
            .{ .char = 'a' },
        },
    });
    try runTest("`a`b`c`d`e,\"\"", .{
        .symbol_list = &[_]TestValue{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
        },
    });
    try runTest("`a`b`c`d`e,\"abcde\"", .{
        .list = &[_]TestValue{
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
}

test "merge symbol" {
    try runTest("1b,`symbol", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .symbol = "symbol" },
        },
    });
    try runTest("1b,`$()", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
        },
    });
    try runTest("1b,`a`b`c`d`e", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
        },
    });

    try runTest("1,`symbol", .{
        .list = &[_]TestValue{
            .{ .int = 1 },
            .{ .symbol = "symbol" },
        },
    });
    try runTest("1,`$()", .{
        .int_list = &[_]TestValue{
            .{ .int = 1 },
        },
    });
    try runTest("1,`a`b`c`d`e", .{
        .list = &[_]TestValue{
            .{ .int = 1 },
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
        },
    });

    try runTest("1f,`symbol", .{
        .list = &[_]TestValue{
            .{ .float = 1 },
            .{ .symbol = "symbol" },
        },
    });
    try runTest("1f,`$()", .{
        .float_list = &[_]TestValue{
            .{ .float = 1 },
        },
    });
    try runTest("1f,`a`b`c`d`e", .{
        .list = &[_]TestValue{
            .{ .float = 1 },
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
        },
    });

    try runTest("\"a\",`symbol", .{
        .list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .symbol = "symbol" },
        },
    });
    try runTest("\"a\",`$()", .{
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
        },
    });
    try runTest("\"a\",`a`b`c`d`e", .{
        .list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
        },
    });

    try runTest("`symbol,`a", .{
        .symbol_list = &[_]TestValue{
            .{ .symbol = "symbol" },
            .{ .symbol = "a" },
        },
    });
    try runTest("`symbol,`$()", .{
        .symbol_list = &[_]TestValue{
            .{ .symbol = "symbol" },
        },
    });
    try runTest("`symbol,`a`b`c`d`e", .{
        .symbol_list = &[_]TestValue{
            .{ .symbol = "symbol" },
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
        },
    });

    try runTest("(),`symbol", .{
        .symbol_list = &[_]TestValue{
            .{ .symbol = "symbol" },
        },
    });
    try runTest("(),`$()", .{ .symbol_list = &[_]TestValue{} });
    try runTest("(),`a`b`c`d`e", .{
        .symbol_list = &[_]TestValue{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
        },
    });
    try runTest("(1b;2;3f),`symbol", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .symbol = "symbol" },
        },
    });
    try runTest("(1b;2;3f),`$()", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
        },
    });
    try runTest("(1b;2;3f),`a`b`c`d`e", .{
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .symbol = "symbol" },
            .{ .symbol = "symbol" },
        },
    });
    try runTest("(1b;2;3f;`symbol),`$()", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .symbol = "symbol" },
        },
    });
    try runTest("(1b;2;3f;`symbol),`a`b`c`d`e", .{
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = true },
            .{ .symbol = "symbol" },
        },
    });
    try runTest("10011b,`$()", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = true },
        },
    });
    try runTest("10011b,`a`b`c`d`e", .{
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
            .{ .int = 5 },
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = 2 },
            .{ .int = 1 },
            .{ .symbol = "symbol" },
        },
    });
    try runTest("5 4 3 2 1,`$()", .{
        .int_list = &[_]TestValue{
            .{ .int = 5 },
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = 2 },
            .{ .int = 1 },
        },
    });
    try runTest("5 4 3 2 1,`a`b`c`d`e", .{
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
            .{ .symbol = "symbol" },
        },
    });
    try runTest("5 4 3 2 1f,`$()", .{
        .float_list = &[_]TestValue{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
        },
    });
    try runTest("5 4 3 2 1f,`a`b`c`d`e", .{
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
            .{ .char = '5' },
            .{ .char = '4' },
            .{ .char = '3' },
            .{ .char = '2' },
            .{ .char = '1' },
            .{ .symbol = "symbol" },
        },
    });
    try runTest("\"54321\",`$()", .{
        .char_list = &[_]TestValue{
            .{ .char = '5' },
            .{ .char = '4' },
            .{ .char = '3' },
            .{ .char = '2' },
            .{ .char = '1' },
        },
    });
    try runTest("\"54321\",`a`b`c`d`e", .{
        .list = &[_]TestValue{
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
        .symbol_list = &[_]TestValue{
            .{ .symbol = "5" },
            .{ .symbol = "4" },
            .{ .symbol = "3" },
            .{ .symbol = "2" },
            .{ .symbol = "1" },
            .{ .symbol = "symbol" },
        },
    });
    try runTest("`5`4`3`2`1,`$()", .{
        .symbol_list = &[_]TestValue{
            .{ .symbol = "5" },
            .{ .symbol = "4" },
            .{ .symbol = "3" },
            .{ .symbol = "2" },
            .{ .symbol = "1" },
        },
    });
    try runTest("`5`4`3`2`1,`a`b`c`d`e", .{
        .symbol_list = &[_]TestValue{
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
}

test "merge list" {
    try runTest("1b,()", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
        },
    });
    try runTest("1b,(0b;1;0N;0W;-0W)", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
        },
    });
    try runTest("1b,(0b;1;0N;0W;-0W;1f;0n;0w;-0w)", .{
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
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
        .int_list = &[_]TestValue{
            .{ .int = 1 },
        },
    });
    try runTest("1,(0b;1;0N;0W;-0W)", .{
        .list = &[_]TestValue{
            .{ .int = 1 },
            .{ .boolean = false },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
        },
    });
    try runTest("1,(0b;1;0N;0W;-0W;1f;0n;0w;-0w)", .{
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
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
        .float_list = &[_]TestValue{
            .{ .float = 1 },
        },
    });
    try runTest("1f,(0b;1;0N;0W;-0W)", .{
        .list = &[_]TestValue{
            .{ .float = 1 },
            .{ .boolean = false },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
        },
    });
    try runTest("1f,(0b;1;0N;0W;-0W;1f;0n;0w;-0w)", .{
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
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
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
        },
    });
    try runTest("\"a\",(0b;1;0N;0W;-0W)", .{
        .list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .boolean = false },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
        },
    });
    try runTest("\"a\",(0b;1;0N;0W;-0W;1f;0n;0w;-0w)", .{
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
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
        .symbol_list = &[_]TestValue{
            .{ .symbol = "symbol" },
        },
    });
    try runTest("`symbol,(0b;1;0N;0W;-0W)", .{
        .list = &[_]TestValue{
            .{ .symbol = "symbol" },
            .{ .boolean = false },
            .{ .int = 1 },
            .{ .int = Value.null_int },
            .{ .int = Value.inf_int },
            .{ .int = -Value.inf_int },
        },
    });
    try runTest("`symbol,(0b;1;0N;0W;-0W;1f;0n;0w;-0w)", .{
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
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

    try runTest("(),()", .{ .list = &[_]TestValue{} });
    try runTest("(0N;0n),()", .{
        .list = &[_]TestValue{
            .{ .int = Value.null_int },
            .{ .float = Value.null_float },
        },
    });
    try runTest("(),(0N;0n)", .{
        .list = &[_]TestValue{
            .{ .int = Value.null_int },
            .{ .float = Value.null_float },
        },
    });
    try runTest("(1b;2),(1b;2)", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .int = 2 },
            .{ .boolean = true },
            .{ .int = 2 },
        },
    });
    try runTest("(1b;2f),(2f;1b)", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .float = 2 },
            .{ .float = 2 },
            .{ .boolean = true },
        },
    });
    try runTest("(2;3f),(2;3f)", .{
        .list = &[_]TestValue{
            .{ .int = 2 },
            .{ .float = 3 },
            .{ .int = 2 },
            .{ .float = 3 },
        },
    });
    try runTest("(1b;(2;3f)),(0N;(0n;0N))", .{
        .list = &[_]TestValue{
            .{ .boolean = true },
            .{ .list = &[_]TestValue{
                .{ .int = 2 },
                .{ .float = 3 },
            } },
            .{ .int = Value.null_int },
            .{ .list = &[_]TestValue{
                .{ .float = Value.null_float },
                .{ .int = Value.null_int },
            } },
        },
    });
    try runTest("(0b;1;2;3;4;5;6;7;8;9),(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", .{
        .list = &[_]TestValue{
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
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
        },
    });
    try runTest("01b,(0b;0N)", .{
        .list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .int = Value.null_int },
        },
    });
    try runTest("010b,(0b;0N;0n)", .{
        .list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .int = Value.null_int },
            .{ .float = Value.null_float },
        },
    });
    try runTest("0101010101b,(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", .{
        .list = &[_]TestValue{
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
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = 2 },
        },
    });
    try runTest("0 1,(0b;0N)", .{
        .list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .boolean = false },
            .{ .int = Value.null_int },
        },
    });
    try runTest("0 1 2,(0b;0N;0n)", .{
        .list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = 2 },
            .{ .boolean = false },
            .{ .int = Value.null_int },
            .{ .float = Value.null_float },
        },
    });
    try runTest("0 1 2 3 4 5 6 7 8 9,(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", .{
        .list = &[_]TestValue{
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
        .float_list = &[_]TestValue{
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = 2 },
        },
    });
    try runTest("0 1 2f,(0b;0N;0n)", .{
        .list = &[_]TestValue{
            .{ .float = 0 },
            .{ .float = 1 },
            .{ .float = 2 },
            .{ .boolean = false },
            .{ .int = Value.null_int },
            .{ .float = Value.null_float },
        },
    });
    try runTest("0 1 2 3 4 5 6 7 8 9f,(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", .{
        .list = &[_]TestValue{
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
        .char_list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .char = 'b' },
            .{ .char = 'c' },
            .{ .char = 'd' },
            .{ .char = 'e' },
        },
    });
    try runTest("\"abcde\",(0b;0N;0n)", .{
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
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
        .symbol_list = &[_]TestValue{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
            .{ .symbol = "d" },
            .{ .symbol = "e" },
        },
    });
    try runTest("`a`b`c`d`e,(0b;0N;0n)", .{
        .list = &[_]TestValue{
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
        .list = &[_]TestValue{
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
    try runTestError("(`a`b!1 2),(0b;0N;0n)", MergeError.incompatible_types);
    try runTestError("(`a`b!1 2),(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", MergeError.incompatible_types);
}

test "merge dictionary" {
    try runTestError("1b,`a`b!1 2", MergeError.incompatible_types);

    try runTestError("1,`a`b!1 2", MergeError.incompatible_types);

    try runTestError("1f,`a`b!1 2", MergeError.incompatible_types);

    try runTestError("\"a\",`a`b!1 2", MergeError.incompatible_types);

    try runTestError("`symbol,`a`b!1 2", MergeError.incompatible_types);

    try runTest("(),`a`b!1 2", .{ .dictionary = &[_]TestValue{
        .{ .symbol_list = &[_]TestValue{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
        } },
        .{ .int_list = &[_]TestValue{
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
    try runTest("(`a`b!1 2),`a`b!3 4", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .int_list = &[_]TestValue{
                .{ .int = 3 },
                .{ .int = 4 },
            } },
        },
    });
    try runTest("(`a`b!1 2),`c`d!3 4", .{
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
                .{ .int = 3 },
                .{ .int = 4 },
            } },
        },
    });
    try runTest("((`a;`b;1)!1 2 3),1 2!4 5", .{ .dictionary = &[_]TestValue{
        .{ .list = &[_]TestValue{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .int = 1 },
            .{ .int = 2 },
        } },
        .{ .int_list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 2 },
            .{ .int = 4 },
            .{ .int = 5 },
        } },
    } });
}

test "merge table" {
    try runTestError("1b,+`a`b!(,1;,2)", MergeError.incompatible_types);

    try runTestError("1,+`a`b!(,1;,2)", MergeError.incompatible_types);

    try runTestError("1f,+`a`b!(,1;,2)", MergeError.incompatible_types);

    try runTestError("\"a\",+`a`b!(,1;,2)", MergeError.incompatible_types);

    try runTestError("`symbol,+`a`b!(,1;,2)", MergeError.incompatible_types);

    try runTest("(),+`a`b!(,1;,2)", .{ .dictionary = &[_]TestValue{
        .{ .symbol_list = &[_]TestValue{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
        } },
        .{ .int_list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 2 },
        } },
    } });

    try runTestError("010b,+`a`b!(,1;,2)", MergeError.incompatible_types);

    try runTestError("0 1 2,+`a`b!(,1;,2)", MergeError.incompatible_types);

    try runTestError("0 1 2f,+`a`b!(,1;,2)", MergeError.incompatible_types);

    try runTestError("\"abcde\",+`a`b!(,1;,2)", MergeError.incompatible_types);

    try runTestError("`a`b`c`d`e,+`a`b!(,1;,2)", MergeError.incompatible_types);

    try runTest("(`a`b!1 2),+`a`b!(,3;,4)", .{
        .table = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                    .{ .int = 3 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 2 },
                    .{ .int = 4 },
                } },
            } },
        },
    });
    try runTestError("(`a`b!1 2),+`c`d!(,3;,4)", MergeError.incompatible_types);

    try runTest("(+`a`b!(,1;,2)),+`a`b!(,3;,4)", .{});
}
