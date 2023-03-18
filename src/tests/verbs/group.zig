const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;
const runTestError = vm_mod.runTestError;
const TestValue = vm_mod.TestValue;

const GroupError = @import("../../verbs/group.zig").GroupError;

test "group boolean" {
    try runTestError("=0b", GroupError.invalid_type);
    try runTest("=`boolean$()", .{
        .dictionary = &[_]TestValue{
            .{ .boolean_list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("=01b", .{
        .dictionary = &[_]TestValue{
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = false },
                .{ .boolean = true },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = 0 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                } },
            } },
        },
    });
    try runTest("=011101b", .{
        .dictionary = &[_]TestValue{
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = false },
                .{ .boolean = true },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = 0 },
                    .{ .int = 4 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                    .{ .int = 2 },
                    .{ .int = 3 },
                    .{ .int = 5 },
                } },
            } },
        },
    });
}

test "group int" {
    try runTestError("=0", GroupError.invalid_type);
    try runTest("=`int$()", .{
        .dictionary = &[_]TestValue{
            .{ .int_list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("=0 1", .{
        .dictionary = &[_]TestValue{
            .{ .int_list = &[_]TestValue{
                .{ .int = 0 },
                .{ .int = 1 },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = 0 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                } },
            } },
        },
    });
    try runTest("=0 1 0 3 2 0", .{
        .dictionary = &[_]TestValue{
            .{ .int_list = &[_]TestValue{
                .{ .int = 0 },
                .{ .int = 1 },
                .{ .int = 3 },
                .{ .int = 2 },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = 0 },
                    .{ .int = 2 },
                    .{ .int = 5 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 3 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 4 },
                } },
            } },
        },
    });
}

test "group float" {
    try runTestError("=0f", GroupError.invalid_type);
    try runTest("=`float$()", .{
        .dictionary = &[_]TestValue{
            .{ .float_list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("=0 1f", .{
        .dictionary = &[_]TestValue{
            .{ .float_list = &[_]TestValue{
                .{ .float = 0 },
                .{ .float = 1 },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = 0 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                } },
            } },
        },
    });
    try runTest("=0 1 0 3 2 0f", .{
        .dictionary = &[_]TestValue{
            .{ .float_list = &[_]TestValue{
                .{ .float = 0 },
                .{ .float = 1 },
                .{ .float = 3 },
                .{ .float = 2 },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = 0 },
                    .{ .int = 2 },
                    .{ .int = 5 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 3 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 4 },
                } },
            } },
        },
    });
}

test "group char" {
    try runTestError("=\"a\"", GroupError.invalid_type);
    try runTest("=\"\"", .{
        .dictionary = &[_]TestValue{
            .{ .char_list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("=\"test\"", .{
        .dictionary = &[_]TestValue{
            .{ .char_list = &[_]TestValue{
                .{ .char = 't' },
                .{ .char = 'e' },
                .{ .char = 's' },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = 0 },
                    .{ .int = 3 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 2 },
                } },
            } },
        },
    });
}

test "group symbol" {
    try runTestError("=`symbol", GroupError.invalid_type);
    try runTest("=`$()", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("=`t`e`s`t", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "t" },
                .{ .symbol = "e" },
                .{ .symbol = "s" },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = 0 },
                    .{ .int = 3 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 2 },
                } },
            } },
        },
    });
    try runTest("=`symbol1`testing`testing`symbol`Symbol", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "symbol1" },
                .{ .symbol = "testing" },
                .{ .symbol = "symbol" },
                .{ .symbol = "Symbol" },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = 0 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 3 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 4 },
                } },
            } },
        },
    });
}

test "group list" {
    try runTest("=()", .{
        .dictionary = &[_]TestValue{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });

    try runTest("=(1b;2;3f)", .{
        .dictionary = &[_]TestValue{
            .{ .list = &[_]TestValue{
                .{ .boolean = true },
                .{ .int = 2 },
                .{ .float = 3 },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = 0 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 2 },
                } },
            } },
        },
    });

    try runTest("=(0 1;2 3)", .{
        .dictionary = &[_]TestValue{
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = 0 },
                    .{ .int = 1 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 2 },
                    .{ .int = 3 },
                } },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = 0 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                } },
            } },
        },
    });
    try runTest("=(`a`b;`c`d)", .{
        .dictionary = &[_]TestValue{
            .{ .list = &[_]TestValue{
                .{ .symbol_list = &[_]TestValue{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .symbol_list = &[_]TestValue{
                    .{ .symbol = "c" },
                    .{ .symbol = "d" },
                } },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = 0 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                } },
            } },
        },
    });

    try runTest("=((1b;2;3f);(1b;2;3f))", .{
        .dictionary = &[_]TestValue{
            .{ .list = &[_]TestValue{
                .{ .list = &[_]TestValue{
                    .{ .boolean = true },
                    .{ .int = 2 },
                    .{ .float = 3 },
                } },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = 0 },
                    .{ .int = 1 },
                } },
            } },
        },
    });

    try runTest("=(`a;1;\"ab\";\"cd\")", .{
        .dictionary = &[_]TestValue{
            .{ .list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .int = 1 },
                .{ .char_list = &[_]TestValue{
                    .{ .char = 'a' },
                    .{ .char = 'b' },
                } },
                .{ .char_list = &[_]TestValue{
                    .{ .char = 'c' },
                    .{ .char = 'd' },
                } },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = 0 },
                } },
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

    try runTest("=(``;(`a`b;`symbol))", .{
        .dictionary = &[_]TestValue{
            .{ .list = &[_]TestValue{
                .{ .symbol_list = &[_]TestValue{
                    .{ .symbol = "" },
                    .{ .symbol = "" },
                } },
                .{ .list = &[_]TestValue{
                    .{ .symbol_list = &[_]TestValue{
                        .{ .symbol = "a" },
                        .{ .symbol = "b" },
                    } },
                    .{ .symbol = "symbol" },
                } },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = 0 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                } },
            } },
        },
    });
}

test "group dictionary" {
    try runTest("=()!()", .{
        .dictionary = &[_]TestValue{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("=(`$())!()", .{
        .dictionary = &[_]TestValue{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("=()!`$()", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &.{} },
            .{ .list = &.{} },
        },
    });

    try runTest("=`a`b!2 1", .{
        .dictionary = &[_]TestValue{
            .{ .int_list = &[_]TestValue{
                .{ .int = 2 },
                .{ .int = 1 },
            } },
            .{ .list = &[_]TestValue{
                .{ .symbol_list = &[_]TestValue{
                    .{ .symbol = "a" },
                } },
                .{ .symbol_list = &[_]TestValue{
                    .{ .symbol = "b" },
                } },
            } },
        },
    });

    try runTest("=10 20!2 1", .{
        .dictionary = &[_]TestValue{
            .{ .int_list = &[_]TestValue{
                .{ .int = 2 },
                .{ .int = 1 },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = 10 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 20 },
                } },
            } },
        },
    });

    try runTest("=`a`b`c!(0b;1;2f)", .{
        .dictionary = &[_]TestValue{
            .{ .list = &[_]TestValue{
                .{ .boolean = false },
                .{ .int = 1 },
                .{ .float = 2 },
            } },
            .{ .list = &[_]TestValue{
                .{ .symbol_list = &[_]TestValue{
                    .{ .symbol = "a" },
                } },
                .{ .symbol_list = &[_]TestValue{
                    .{ .symbol = "b" },
                } },
                .{ .symbol_list = &[_]TestValue{
                    .{ .symbol = "c" },
                } },
            } },
        },
    });

    try runTest("=`a`b`c!`x`y`x", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "x" },
                .{ .symbol = "y" },
            } },
            .{ .list = &[_]TestValue{
                .{ .symbol_list = &[_]TestValue{
                    .{ .symbol = "a" },
                    .{ .symbol = "c" },
                } },
                .{ .symbol_list = &[_]TestValue{
                    .{ .symbol = "b" },
                } },
            } },
        },
    });
}

test "group table" {
    try runTest("=+`a`b!(();())", .{
        .dictionary = &[_]TestValue{
            .{ .table = &[_]TestValue{
                .{ .symbol_list = &[_]TestValue{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .list = &[_]TestValue{
                    .{ .list = &.{} },
                    .{ .list = &.{} },
                } },
            } },
            .{ .list = &.{} },
        },
    });
    try runTest("=+`a`b!(`int$();`float$())", .{
        .dictionary = &[_]TestValue{
            .{ .table = &[_]TestValue{
                .{ .symbol_list = &[_]TestValue{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .list = &[_]TestValue{
                    .{ .int_list = &.{} },
                    .{ .float_list = &.{} },
                } },
            } },
            .{ .list = &.{} },
        },
    });

    try runTest("=+`a`b!(,1;,2)", .{
        .dictionary = &[_]TestValue{
            .{ .table = &[_]TestValue{
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
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = 0 },
                } },
            } },
        },
    });

    try runTest("=+`a`b!(0 1 0 3 2 0;0 2 3 0 1 0)", .{
        .dictionary = &[_]TestValue{
            .{ .table = &[_]TestValue{
                .{ .symbol_list = &[_]TestValue{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .list = &[_]TestValue{
                    .{ .int_list = &[_]TestValue{
                        .{ .int = 0 },
                        .{ .int = 1 },
                        .{ .int = 0 },
                        .{ .int = 3 },
                        .{ .int = 2 },
                    } },
                    .{ .int_list = &[_]TestValue{
                        .{ .int = 0 },
                        .{ .int = 2 },
                        .{ .int = 3 },
                        .{ .int = 0 },
                        .{ .int = 1 },
                    } },
                } },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = 0 },
                    .{ .int = 5 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 2 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 3 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 4 },
                } },
            } },
        },
    });
}
