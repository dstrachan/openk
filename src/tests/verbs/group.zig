const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;
const runTestError = vm_mod.runTestError;
const TestValue = vm_mod.TestValue;

const GroupError = @import("../../verbs/group.zig").GroupError;

test "group boolean" {
    try runTestError("=0b", GroupError.invalid_type);
    try runTest("=`boolean$()", .{
        .dictionary = &.{
            .{ .boolean_list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("=01b", .{
        .dictionary = &.{
            .{ .boolean_list = &.{
                .{ .boolean = false },
                .{ .boolean = true },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 0 },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                } },
            } },
        },
    });
    try runTest("=011101b", .{
        .dictionary = &.{
            .{ .boolean_list = &.{
                .{ .boolean = false },
                .{ .boolean = true },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 0 },
                    .{ .int = 4 },
                } },
                .{ .int_list = &.{
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
        .dictionary = &.{
            .{ .int_list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("=0 1", .{
        .dictionary = &.{
            .{ .int_list = &.{
                .{ .int = 0 },
                .{ .int = 1 },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 0 },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                } },
            } },
        },
    });
    try runTest("=0 1 0 3 2 0", .{
        .dictionary = &.{
            .{ .int_list = &.{
                .{ .int = 0 },
                .{ .int = 1 },
                .{ .int = 3 },
                .{ .int = 2 },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 0 },
                    .{ .int = 2 },
                    .{ .int = 5 },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                } },
                .{ .int_list = &.{
                    .{ .int = 3 },
                } },
                .{ .int_list = &.{
                    .{ .int = 4 },
                } },
            } },
        },
    });
}

test "group float" {
    try runTestError("=0f", GroupError.invalid_type);
    try runTest("=`float$()", .{
        .dictionary = &.{
            .{ .float_list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("=0 1f", .{
        .dictionary = &.{
            .{ .float_list = &.{
                .{ .float = 0 },
                .{ .float = 1 },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 0 },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                } },
            } },
        },
    });
    try runTest("=0 1 0 3 2 0f", .{
        .dictionary = &.{
            .{ .float_list = &.{
                .{ .float = 0 },
                .{ .float = 1 },
                .{ .float = 3 },
                .{ .float = 2 },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 0 },
                    .{ .int = 2 },
                    .{ .int = 5 },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                } },
                .{ .int_list = &.{
                    .{ .int = 3 },
                } },
                .{ .int_list = &.{
                    .{ .int = 4 },
                } },
            } },
        },
    });
}

test "group char" {
    try runTestError("=\"a\"", GroupError.invalid_type);
    try runTest("=\"\"", .{
        .dictionary = &.{
            .{ .char_list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("=\"test\"", .{
        .dictionary = &.{
            .{ .char_list = &.{
                .{ .char = 't' },
                .{ .char = 'e' },
                .{ .char = 's' },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 0 },
                    .{ .int = 3 },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                } },
                .{ .int_list = &.{
                    .{ .int = 2 },
                } },
            } },
        },
    });
}

test "group symbol" {
    try runTestError("=`symbol", GroupError.invalid_type);
    try runTest("=`$()", .{
        .dictionary = &.{
            .{ .symbol_list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("=`t`e`s`t", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "t" },
                .{ .symbol = "e" },
                .{ .symbol = "s" },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 0 },
                    .{ .int = 3 },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                } },
                .{ .int_list = &.{
                    .{ .int = 2 },
                } },
            } },
        },
    });
    try runTest("=`symbol1`testing`testing`symbol`Symbol", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "symbol1" },
                .{ .symbol = "testing" },
                .{ .symbol = "symbol" },
                .{ .symbol = "Symbol" },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 0 },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
                .{ .int_list = &.{
                    .{ .int = 3 },
                } },
                .{ .int_list = &.{
                    .{ .int = 4 },
                } },
            } },
        },
    });
}

test "group list" {
    try runTest("=()", .{
        .dictionary = &.{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });

    try runTest("=(1b;2;3f)", .{
        .dictionary = &.{
            .{ .list = &.{
                .{ .boolean = true },
                .{ .int = 2 },
                .{ .float = 3 },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 0 },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                } },
                .{ .int_list = &.{
                    .{ .int = 2 },
                } },
            } },
        },
    });

    try runTest("=(0 1;2 3)", .{
        .dictionary = &.{
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 0 },
                    .{ .int = 1 },
                } },
                .{ .int_list = &.{
                    .{ .int = 2 },
                    .{ .int = 3 },
                } },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 0 },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                } },
            } },
        },
    });
    try runTest("=(`a`b;`c`d)", .{
        .dictionary = &.{
            .{ .list = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .symbol_list = &.{
                    .{ .symbol = "c" },
                    .{ .symbol = "d" },
                } },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 0 },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                } },
            } },
        },
    });

    try runTest("=((1b;2;3f);(1b;2;3f))", .{
        .dictionary = &.{
            .{ .list = &.{
                .{ .list = &.{
                    .{ .boolean = true },
                    .{ .int = 2 },
                    .{ .float = 3 },
                } },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 0 },
                    .{ .int = 1 },
                } },
            } },
        },
    });

    try runTest("=(`a;1;\"ab\";\"cd\")", .{
        .dictionary = &.{
            .{ .list = &.{
                .{ .symbol = "a" },
                .{ .int = 1 },
                .{ .char_list = &.{
                    .{ .char = 'a' },
                    .{ .char = 'b' },
                } },
                .{ .char_list = &.{
                    .{ .char = 'c' },
                    .{ .char = 'd' },
                } },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 0 },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                } },
                .{ .int_list = &.{
                    .{ .int = 2 },
                } },
                .{ .int_list = &.{
                    .{ .int = 3 },
                } },
            } },
        },
    });

    try runTest("=(``;(`a`b;`symbol))", .{
        .dictionary = &.{
            .{ .list = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "" },
                    .{ .symbol = "" },
                } },
                .{ .list = &.{
                    .{ .symbol_list = &.{
                        .{ .symbol = "a" },
                        .{ .symbol = "b" },
                    } },
                    .{ .symbol = "symbol" },
                } },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 0 },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                } },
            } },
        },
    });
}

test "group dictionary" {
    try runTest("=()!()", .{
        .dictionary = &.{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("=(`$())!()", .{
        .dictionary = &.{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("=()!`$()", .{
        .dictionary = &.{
            .{ .symbol_list = &.{} },
            .{ .list = &.{} },
        },
    });

    try runTest("=`a`b!2 1", .{
        .dictionary = &.{
            .{ .int_list = &.{
                .{ .int = 2 },
                .{ .int = 1 },
            } },
            .{ .list = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                } },
                .{ .symbol_list = &.{
                    .{ .symbol = "b" },
                } },
            } },
        },
    });

    try runTest("=10 20!2 1", .{
        .dictionary = &.{
            .{ .int_list = &.{
                .{ .int = 2 },
                .{ .int = 1 },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 10 },
                } },
                .{ .int_list = &.{
                    .{ .int = 20 },
                } },
            } },
        },
    });

    try runTest("=`a`b`c!(0b;1;2f)", .{
        .dictionary = &.{
            .{ .list = &.{
                .{ .boolean = false },
                .{ .int = 1 },
                .{ .float = 2 },
            } },
            .{ .list = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                } },
                .{ .symbol_list = &.{
                    .{ .symbol = "b" },
                } },
                .{ .symbol_list = &.{
                    .{ .symbol = "c" },
                } },
            } },
        },
    });

    try runTest("=`a`b`c!`x`y`x", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "x" },
                .{ .symbol = "y" },
            } },
            .{ .list = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "c" },
                } },
                .{ .symbol_list = &.{
                    .{ .symbol = "b" },
                } },
            } },
        },
    });
}

test "group table" {
    try runTest("=+`a`b!(();())", .{
        .dictionary = &.{
            .{ .table = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .list = &.{
                    .{ .list = &.{} },
                    .{ .list = &.{} },
                } },
            } },
            .{ .list = &.{} },
        },
    });
    try runTest("=+`a`b!(`int$();`float$())", .{
        .dictionary = &.{
            .{ .table = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .list = &.{
                    .{ .int_list = &.{} },
                    .{ .float_list = &.{} },
                } },
            } },
            .{ .list = &.{} },
        },
    });

    try runTest("=+`a`b!(,1;,2)", .{
        .dictionary = &.{
            .{ .table = &.{
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
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 0 },
                } },
            } },
        },
    });

    try runTest("=+`a`b!(0 1 0 3 2 0;0 2 3 0 1 0)", .{
        .dictionary = &.{
            .{ .table = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .list = &.{
                    .{ .int_list = &.{
                        .{ .int = 0 },
                        .{ .int = 1 },
                        .{ .int = 0 },
                        .{ .int = 3 },
                        .{ .int = 2 },
                    } },
                    .{ .int_list = &.{
                        .{ .int = 0 },
                        .{ .int = 2 },
                        .{ .int = 3 },
                        .{ .int = 0 },
                        .{ .int = 1 },
                    } },
                } },
            } },
            .{ .list = &.{
                .{ .int_list = &.{
                    .{ .int = 0 },
                    .{ .int = 5 },
                } },
                .{ .int_list = &.{
                    .{ .int = 1 },
                } },
                .{ .int_list = &.{
                    .{ .int = 2 },
                } },
                .{ .int_list = &.{
                    .{ .int = 3 },
                } },
                .{ .int_list = &.{
                    .{ .int = 4 },
                } },
            } },
        },
    });
}
