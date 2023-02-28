const value_mod = @import("../../value.zig");
const Value = value_mod.Value;

const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;
const runTestError = vm_mod.runTestError;
const TestValue = vm_mod.TestValue;

const NegateError = @import("../../verbs/negate.zig").NegateError;

test "negate boolean" {
    try runTest("- 0b", .{ .int = 0 });
    try runTest("-`boolean$()", .{ .int_list = &[_]TestValue{} });
    try runTest("- 01b", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = -1 },
        },
    });
}

test "negate int" {
    try runTest("- 0", .{ .int = 0 });
    try runTest("-`int$()", .{ .int_list = &[_]TestValue{} });
    try runTest("- 0 1 0N 0W -0W", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = -1 },
            .{ .int = Value.null_int },
            .{ .int = -Value.inf_int },
            .{ .int = Value.inf_int },
        },
    });
}

test "negate float" {
    try runTest("- 0f", .{ .float = 0 });
    try runTest("-`float$()", .{ .float_list = &[_]TestValue{} });
    try runTest("- 0 1 0n 0w -0w", .{
        .float_list = &[_]TestValue{
            .{ .float = 0 },
            .{ .float = -1 },
            .{ .float = Value.null_float },
            .{ .float = -Value.inf_float },
            .{ .float = Value.inf_float },
        },
    });
}

test "negate char" {
    try runTestError("-\"a\"", NegateError.invalid_type);
    try runTestError("-\"\"", NegateError.invalid_type);
    try runTestError("-\"abcde\"", NegateError.invalid_type);
}

test "negate symbol" {
    try runTestError("-`symbol", NegateError.invalid_type);
    try runTestError("-`$()", NegateError.invalid_type);
    try runTestError("-`a`b`c`d`e", NegateError.invalid_type);
}

test "negate list" {
    try runTest("-()", .{ .list = &[_]TestValue{} });
    try runTest("-(0b;1;0N;0W;-0W)", .{
        .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = -1 },
            .{ .int = Value.null_int },
            .{ .int = -Value.inf_int },
            .{ .int = Value.inf_int },
        },
    });
    try runTest("-(0b;1;0N;0W;-0W;1f;0n;0w;-0w)", .{
        .list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = -1 },
            .{ .int = Value.null_int },
            .{ .int = -Value.inf_int },
            .{ .int = Value.inf_int },
            .{ .float = -1 },
            .{ .float = Value.null_float },
            .{ .float = -Value.inf_float },
            .{ .float = Value.inf_float },
        },
    });
    try runTestError("-(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", NegateError.invalid_type);
    try runTestError("-(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", NegateError.invalid_type);
}

test "negate dictionary" {
    try runTest("-()!()", .{
        .dictionary = &[_]TestValue{
            .{ .list = &[_]TestValue{} },
            .{ .list = &[_]TestValue{} },
        },
    });
    try runTest("-`a`b!1 2", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .int_list = &[_]TestValue{
                .{ .int = -1 },
                .{ .int = -2 },
            } },
        },
    });
    try runTest("-`a`b!(0b;1)", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .int_list = &[_]TestValue{
                .{ .int = 0 },
                .{ .int = -1 },
            } },
        },
    });
    try runTest("-`a`b`c!(0b;1;2f)", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
                .{ .symbol = "c" },
            } },
            .{ .list = &[_]TestValue{
                .{ .int = 0 },
                .{ .int = -1 },
                .{ .float = -2 },
            } },
        },
    });
    try runTest("-`a`b!(1 2 3;4 5 6)", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = -1 },
                    .{ .int = -2 },
                    .{ .int = -3 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = -4 },
                    .{ .int = -5 },
                    .{ .int = -6 },
                } },
            } },
        },
    });
    try runTestError("-`a`b`c`d!(0b;1;2f;\"a\")", NegateError.invalid_type);
    try runTestError("-`a`b`c`d!(\"a\";2f;1;0b)", NegateError.invalid_type);
}

test "negate table" {
    try runTest("-+`a`b!(,1;,2)", .{
        .table = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = -1 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = -2 },
                } },
            } },
        },
    });
    try runTest("-+`a`b!((0b;1);0 1)", .{
        .table = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = 0 },
                    .{ .int = -1 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 0 },
                    .{ .int = -1 },
                } },
            } },
        },
    });
    try runTestError("-+`a`b`c`d!(,0b;,1;,2f;,\"a\")", NegateError.invalid_type);
    try runTestError("-+`a`b`c`d!(,\"a\";,2f;,1;,0b)", NegateError.invalid_type);
}
