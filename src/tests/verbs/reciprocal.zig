const value_mod = @import("../../value.zig");
const Value = value_mod.Value;

const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;
const runTestError = vm_mod.runTestError;

const ReciprocalError = @import("../../verbs/reciprocal.zig").ReciprocalError;

test "reciprocal boolean" {
    try runTest("%0b", .{ .float = Value.inf_float });
    try runTest("%1b", .{ .float = 1 });
    try runTest("%`boolean$()", .{ .float_list = &.{} });
    try runTest("%01b", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = 1 },
        },
    });
}

test "reciprocal int" {
    try runTest("%0", .{ .float = Value.inf_float });
    try runTest("%`int$()", .{ .float_list = &.{} });
    try runTest("%0 1 0N 0W -0W", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = 1 / Value.inf_int },
            .{ .float = 1 / -Value.inf_int },
        },
    });
}

test "reciprocal float" {
    try runTest("%0f", .{ .float = Value.inf_float });
    try runTest("%`float$()", .{ .float_list = &.{} });
    try runTest("%0 1 0n 0w -0w", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = 1 },
            .{ .float = Value.null_float },
            .{ .float = 0 },
            .{ .float = -0 },
        },
    });
}

test "reciprocal char" {
    try runTestError("%\"a\"", ReciprocalError.invalid_type);
    try runTestError("%\"\"", ReciprocalError.invalid_type);
    try runTestError("%\"abcde\"", ReciprocalError.invalid_type);
}

test "reciprocal symbol" {
    try runTestError("%`symbol", ReciprocalError.invalid_type);
    try runTestError("%`$()", ReciprocalError.invalid_type);
    try runTestError("%`a`b`c`d`e", ReciprocalError.invalid_type);
}

test "reciprocal list" {
    try runTest("%()", .{ .list = &.{} });
    try runTest("%(0b;1;2f)", .{
        .float_list = &.{
            .{ .float = Value.inf_float },
            .{ .float = 1 },
            .{ .float = 0.5 },
        },
    });
    try runTest("%(0b;(1;2f))", .{
        .list = &.{
            .{ .float = Value.inf_float },
            .{ .float_list = &.{
                .{ .float = 1 },
                .{ .float = 0.5 },
            } },
        },
    });
    try runTestError("%(0b;1;2f;\"a\")", ReciprocalError.invalid_type);
    try runTestError("%(\"a\";2f;1;0b)", ReciprocalError.invalid_type);
}

test "reciprocal dictionary" {
    try runTest("%()!()", .{
        .dictionary = &.{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("%()!`float$()", .{
        .dictionary = &.{
            .{ .list = &.{} },
            .{ .float_list = &.{} },
        },
    });
    try runTest("%(`int$())!()", .{
        .dictionary = &.{
            .{ .int_list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("%(`int$())!`float$()", .{
        .dictionary = &.{
            .{ .int_list = &.{} },
            .{ .float_list = &.{} },
        },
    });
    try runTest("%`a`b!1 2", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .float_list = &.{
                .{ .float = 1 },
                .{ .float = 0.5 },
            } },
        },
    });
}

test "reciprocal table" {
    try runTest("%+`a`b!(();())", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .list = &.{} },
                .{ .list = &.{} },
            } },
        },
    });
    try runTest("%+`a`b!(`int$();`float$())", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .float_list = &.{} },
                .{ .float_list = &.{} },
            } },
        },
    });
    try runTest("%+`a`b!(,1;,2)", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .float_list = &.{
                    .{ .float = 1 },
                } },
                .{ .float_list = &.{
                    .{ .float = 0.5 },
                } },
            } },
        },
    });
    try runTest("%+`a`b!(1 1;2 2)", .{
        .table = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .float_list = &.{
                    .{ .float = 1 },
                    .{ .float = 1 },
                } },
                .{ .float_list = &.{
                    .{ .float = 0.5 },
                    .{ .float = 0.5 },
                } },
            } },
        },
    });
}
