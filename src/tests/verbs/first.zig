const value_mod = @import("../../value.zig");
const Value = value_mod.Value;

const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;

test "first boolean" {
    try runTest("*0b", .{ .boolean = false });
    try runTest("*`boolean$()", .{ .boolean = false });
    try runTest("*01b", .{ .boolean = false });
}

test "first int" {
    try runTest("*0", .{ .int = 0 });
    try runTest("*`int$()", .{ .int = Value.null_int });
    try runTest("*0 1 0N 0W -0W", .{ .int = 0 });
}

test "first float" {
    try runTest("*0f", .{ .float = 0 });
    try runTest("*`float$()", .{ .float = Value.null_float });
    try runTest("*0 1 0n 0w -0w", .{ .float = 0 });
}

test "first char" {
    try runTest("*\"a\"", .{ .char = 'a' });
    try runTest("*\"\"", .{ .char = ' ' });
    try runTest("*\"abcde\"", .{ .char = 'a' });
}

test "first symbol" {
    try runTest("*`symbol", .{ .symbol = "symbol" });
    try runTest("*`$()", .{ .symbol = "" });
    try runTest("*`a`b`c`d`e", .{ .symbol = "a" });
}

test "first list" {
    try runTest("*()", .{ .list = &.{} });
    try runTest("*(0b;1;2f)", .{ .boolean = false });
    try runTest("*(0 1;2 3)", .{
        .int_list = &.{
            .{ .int = 0 },
            .{ .int = 1 },
        },
    });
    try runTest("*(1 2;3;4 5)", .{
        .int_list = &.{
            .{ .int = 1 },
            .{ .int = 2 },
        },
    });
    try runTest("*(``;(`a`b;`symbol))", .{
        .symbol_list = &.{
            .{ .symbol = "" },
            .{ .symbol = "" },
        },
    });
}

test "first dictionary" {
    try runTest("*()!()", .{ .list = &.{} });
    try runTest("*`a`b!(();())", .{ .list = &.{} });
    try runTest("*`a`b!1 2", .{ .int = 1 });
    try runTest("*10 20!1 2", .{ .int = 1 });
    try runTest("*`a`b!(1;2 2)", .{ .int = 1 });
    try runTest("*`a`b!(`int$();`float$())", .{ .int_list = &.{} });
    try runTest("*`a`b!(,1;,2)", .{
        .int_list = &.{
            .{ .int = 1 },
        },
    });
    try runTest("*`a`b!(1 1;2 2)", .{
        .int_list = &.{
            .{ .int = 1 },
            .{ .int = 1 },
        },
    });
}

test "first table" {
    try runTest("*+`a`b!(();())", .{
        .dictionary = &.{
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
    try runTest("*+`a`b!(`int$();`float$())", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &.{
                .{ .int = Value.null_int },
                .{ .float = Value.null_float },
            } },
        },
    });
    try runTest("*+`a`b!(,1;,2)", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .int_list = &.{
                .{ .int = 1 },
                .{ .int = 2 },
            } },
        },
    });
    try runTest("*+`a`b!(1 1;2 2)", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .int_list = &.{
                .{ .int = 1 },
                .{ .int = 2 },
            } },
        },
    });
    try runTest("*+`a`b!(1;2 2)", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .int_list = &.{
                .{ .int = 1 },
                .{ .int = 2 },
            } },
        },
    });
}
