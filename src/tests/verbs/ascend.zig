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
    try runTest("<()!()", .{ .list = &[_]TestValue{} });
    try runTest("<(`$())!()", .{ .symbol_list = &[_]TestValue{} });

    try runTest("<`a`b!2 1", .{
        .symbol_list = &[_]TestValue{
            .{ .symbol = "b" },
            .{ .symbol = "a" },
        },
    });

    try runTest("<10 20!2 1", .{
        .int_list = &[_]TestValue{
            .{ .int = 20 },
            .{ .int = 10 },
        },
    });

    try runTest("<`a`b`c!(0b;1;2f)", .{
        .symbol_list = &[_]TestValue{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
        },
    });
    try runTest("<`a`b`c!(1b;0;-1f)", .{
        .symbol_list = &[_]TestValue{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "c" },
        },
    });
}

test "ascend table" {
    try runTest("<+`a`b!(();())", .{ .int_list = &[_]TestValue{} });
    try runTest("<+`a`b!(`int$();`float$())", .{ .int_list = &[_]TestValue{} });

    try runTest("<+`a`b!(,1;,2)", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
        },
    });

    try runTest("<+`a`b!(1 2;3 4)", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 1 },
        },
    });

    try runTest("<+`a`b!(1 2 1;20 10 10)", .{
        .int_list = &[_]TestValue{
            .{ .int = 2 },
            .{ .int = 0 },
            .{ .int = 1 },
        },
    });
}
