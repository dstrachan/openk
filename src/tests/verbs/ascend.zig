const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;
const runTestError = vm_mod.runTestError;
const TestValue = vm_mod.TestValue;

const AscendError = @import("../../verbs/ascend.zig").AscendError;

test "ascend boolean" {
    try runTestError("<0b", AscendError.invalid_type);
    try runTest("<`boolean$()", .{ .int_list = &[_]TestValue{} });
    try runTest("<01b", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 1 },
        },
    });
    try runTest("<011101b", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 4 },
            .{ .int = 1 },
            .{ .int = 2 },
            .{ .int = 3 },
            .{ .int = 5 },
        },
    });
}

test "ascend int" {
    try runTestError("<0", AscendError.invalid_type);
    try runTest("<`int$()", .{ .int_list = &[_]TestValue{} });
    try runTest("<0 1", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 1 },
        },
    });
    try runTest("<0 1 0 3 2 0", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 2 },
            .{ .int = 5 },
            .{ .int = 1 },
            .{ .int = 4 },
            .{ .int = 3 },
        },
    });
}

test "ascend float" {
    try runTestError("<0f", AscendError.invalid_type);
    try runTest("<`float$()", .{ .int_list = &[_]TestValue{} });
    try runTest("<0 1f", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 1 },
        },
    });
    try runTest("<0 1 0 3 2 0f", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 2 },
            .{ .int = 5 },
            .{ .int = 1 },
            .{ .int = 4 },
            .{ .int = 3 },
        },
    });
}

test "ascend char" {
    try runTestError("<\"a\"", AscendError.invalid_type);
    try runTest("<\"\"", .{ .int_list = &[_]TestValue{} });
    try runTest("<\"test\"", .{
        .int_list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 2 },
            .{ .int = 0 },
            .{ .int = 3 },
        },
    });
}

test "ascend symbol" {
    try runTestError("<`symbol", AscendError.invalid_type);
    try runTest("<`$()", .{ .int_list = &[_]TestValue{} });
    try runTest("<`t`e`s`t", .{
        .int_list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 2 },
            .{ .int = 0 },
            .{ .int = 3 },
        },
    });
    try runTest("<`symbol1`testing`testing`symbol`Symbol", .{
        .int_list = &[_]TestValue{
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = 2 },
        },
    });
}

// TODO: boolean < int < float < char < symbol < list
test "ascend list" {
    try runTest("<()", .{ .int_list = &[_]TestValue{} });

    try runTest("<(1b;2;3f)", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = 2 },
        },
    });
    try runTest("<(1b;0;-1f)", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 1 },
            .{ .int = 2 },
        },
    });
    try runTest("<(-1f;0;1b)", .{
        .int_list = &[_]TestValue{
            .{ .int = 2 },
            .{ .int = 1 },
            .{ .int = 0 },
        },
    });

    try runTest("<(0 1;2 3)", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 1 },
        },
    });

    try runTest("<(`a`b;`c`d)", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 1 },
        },
    });

    try runTest("<((1b;2;3f);(1b;2;3f))", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 1 },
        },
    });
    try runTest("<((1b;2;3f;4);(1b;2;3f))", .{
        .int_list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 0 },
        },
    });
    try runTest("<((1b;2;3f);(0b;2;3f))", .{
        .int_list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 0 },
        },
    });
    try runTest("<((1b;2;3f);(0b;2;3f;4))", .{
        .int_list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 0 },
        },
    });

    try runTest("<(`a;1;\"ab\";\"cd\")", .{
        .int_list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 2 },
            .{ .int = 3 },
            .{ .int = 0 },
        },
    });

    try runTest("<(``;(`a`b;`symbol))", .{
        .int_list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 0 },
        },
    });
}

test "ascend dictionary" {
    return error.SkipZigTest;
    //    try runTest("<()!()", .{
    //        .dictionary = &[_]TestValue{
    //            .{ .list = &[_]TestValue{} },
    //            .{ .list = &[_]TestValue{} },
    //        },
    //    });
    //    try runTest("<`a`b!1 2", .{
    //        .dictionary = &[_]TestValue{
    //            .{ .symbol_list = &[_]TestValue{
    //                .{ .symbol = "b" },
    //                .{ .symbol = "a" },
    //            } },
    //            .{ .int_list = &[_]TestValue{
    //                .{ .int = 2 },
    //                .{ .int = 1 },
    //            } },
    //        },
    //    });
    //    try runTest("<`a`b!(();())", .{
    //        .dictionary = &[_]TestValue{
    //            .{ .symbol_list = &[_]TestValue{
    //                .{ .symbol = "b" },
    //                .{ .symbol = "a" },
    //            } },
    //            .{ .list = &[_]TestValue{
    //                .{ .list = &[_]TestValue{} },
    //                .{ .list = &[_]TestValue{} },
    //            } },
    //        },
    //    });
    //    try runTest("<`a`b!(`int$();`float$())", .{
    //        .dictionary = &[_]TestValue{
    //            .{ .symbol_list = &[_]TestValue{
    //                .{ .symbol = "b" },
    //                .{ .symbol = "a" },
    //            } },
    //            .{ .list = &[_]TestValue{
    //                .{ .float_list = &[_]TestValue{} },
    //                .{ .int_list = &[_]TestValue{} },
    //            } },
    //        },
    //    });
    //    try runTest("<`a`b!(,1;,2)", .{
    //        .dictionary = &[_]TestValue{
    //            .{ .symbol_list = &[_]TestValue{
    //                .{ .symbol = "b" },
    //                .{ .symbol = "a" },
    //            } },
    //            .{ .list = &[_]TestValue{
    //                .{ .int_list = &[_]TestValue{
    //                    .{ .int = 2 },
    //                } },
    //                .{ .int_list = &[_]TestValue{
    //                    .{ .int = 1 },
    //                } },
    //            } },
    //        },
    //    });
    //    try runTest("<`a`b!(1 2;3 4)", .{
    //        .dictionary = &[_]TestValue{
    //            .{ .symbol_list = &[_]TestValue{
    //                .{ .symbol = "b" },
    //                .{ .symbol = "a" },
    //            } },
    //            .{ .list = &[_]TestValue{
    //                .{ .int_list = &[_]TestValue{
    //                    .{ .int = 3 },
    //                    .{ .int = 4 },
    //                } },
    //                .{ .int_list = &[_]TestValue{
    //                    .{ .int = 1 },
    //                    .{ .int = 2 },
    //                } },
    //            } },
    //        },
    //    });
    //    try runTest("<`a`b!(1;2 3)", .{
    //        .dictionary = &[_]TestValue{
    //            .{ .symbol_list = &[_]TestValue{
    //                .{ .symbol = "b" },
    //                .{ .symbol = "a" },
    //            } },
    //            .{ .list = &[_]TestValue{
    //                .{ .int_list = &[_]TestValue{
    //                    .{ .int = 2 },
    //                    .{ .int = 3 },
    //                } },
    //                .{ .int = 1 },
    //            } },
    //        },
    //    });
    //    try runTest("<1 2!3 4", .{
    //        .dictionary = &[_]TestValue{
    //            .{ .int_list = &[_]TestValue{
    //                .{ .int = 2 },
    //                .{ .int = 1 },
    //            } },
    //            .{ .int_list = &[_]TestValue{
    //                .{ .int = 4 },
    //                .{ .int = 3 },
    //            } },
    //        },
    //    });
}

test "ascend table" {
    return error.SkipZigTest;
    //    try runTest("<+`a`b!(();())", .{
    //        .table = &[_]TestValue{
    //            .{ .symbol_list = &[_]TestValue{
    //                .{ .symbol = "a" },
    //                .{ .symbol = "b" },
    //            } },
    //            .{ .list = &[_]TestValue{
    //                .{ .list = &[_]TestValue{} },
    //                .{ .list = &[_]TestValue{} },
    //            } },
    //        },
    //    });
    //    try runTest("<+`a`b!(`int$();`float$())", .{
    //        .table = &[_]TestValue{
    //            .{ .symbol_list = &[_]TestValue{
    //                .{ .symbol = "a" },
    //                .{ .symbol = "b" },
    //            } },
    //            .{ .list = &[_]TestValue{
    //                .{ .int_list = &[_]TestValue{} },
    //                .{ .float_list = &[_]TestValue{} },
    //            } },
    //        },
    //    });
    //    try runTest("<+`a`b!(,1;,2)", .{
    //        .table = &[_]TestValue{
    //            .{ .symbol_list = &[_]TestValue{
    //                .{ .symbol = "a" },
    //                .{ .symbol = "b" },
    //            } },
    //            .{ .list = &[_]TestValue{
    //                .{ .int_list = &[_]TestValue{
    //                    .{ .int = 1 },
    //                } },
    //                .{ .int_list = &[_]TestValue{
    //                    .{ .int = 2 },
    //                } },
    //            } },
    //        },
    //    });
    //    try runTest("<+`a`b!(1 2;3 4)", .{
    //        .table = &[_]TestValue{
    //            .{ .symbol_list = &[_]TestValue{
    //                .{ .symbol = "a" },
    //                .{ .symbol = "b" },
    //            } },
    //            .{ .list = &[_]TestValue{
    //                .{ .int_list = &[_]TestValue{
    //                    .{ .int = 2 },
    //                    .{ .int = 1 },
    //                } },
    //                .{ .int_list = &[_]TestValue{
    //                    .{ .int = 4 },
    //                    .{ .int = 3 },
    //                } },
    //            } },
    //        },
    //    });
    //    try runTest("<+`a`b!(1;2 3)", .{
    //        .table = &[_]TestValue{
    //            .{ .symbol_list = &[_]TestValue{
    //                .{ .symbol = "a" },
    //                .{ .symbol = "b" },
    //            } },
    //            .{ .list = &[_]TestValue{
    //                .{ .int_list = &[_]TestValue{
    //                    .{ .int = 1 },
    //                    .{ .int = 1 },
    //                } },
    //                .{ .int_list = &[_]TestValue{
    //                    .{ .int = 3 },
    //                    .{ .int = 2 },
    //                } },
    //            } },
    //        },
    //    });
}
