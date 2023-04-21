const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;
const runTestError = vm_mod.runTestError;

const WhereError = @import("../../verbs/where.zig").WhereError;

test "where boolean" {
    try runTestError("&0b", WhereError.invalid_type);
    try runTest("&`boolean$()", .{ .int_list = &.{} });
    try runTest("&01b", .{
        .int_list = &.{
            .{ .int = 1 },
        },
    });
}

test "where int" {
    try runTestError("&0", WhereError.invalid_type);
    try runTest("&`int$()", .{ .int_list = &.{} });
    try runTestError("&,0W", WhereError.list_limit);
    try runTestError("&,-1", WhereError.negative_number);
    try runTest("&0 1 2 3 4", .{
        .int_list = &.{
            .{ .int = 1 },
            .{ .int = 2 },
            .{ .int = 2 },
            .{ .int = 3 },
            .{ .int = 3 },
            .{ .int = 3 },
            .{ .int = 4 },
            .{ .int = 4 },
            .{ .int = 4 },
            .{ .int = 4 },
        },
    });
}

test "where float" {
    try runTestError("&0f", WhereError.invalid_type);
    try runTestError("&`float$()", WhereError.invalid_type);
    try runTestError("&0 1 0n 0w -0w", WhereError.invalid_type);
}

test "where char" {
    try runTestError("&\"a\"", WhereError.invalid_type);
    try runTestError("&\"\"", WhereError.invalid_type);
    try runTestError("&\"abcde\"", WhereError.invalid_type);
}

test "where symbol" {
    try runTestError("&`symbol", WhereError.invalid_type);
    try runTestError("&`$()", WhereError.invalid_type);
    try runTestError("&`a`b`c`d`e", WhereError.invalid_type);
}

test "where list" {
    try runTest("&()", .{ .int_list = &.{} });
    try runTestError("&(0b;1;2f)", WhereError.invalid_type);
    try runTestError("&(0 1;2 3)", WhereError.invalid_type);
    try runTestError("&(1 2;3;4 5)", WhereError.invalid_type);
    try runTestError("&(``;(`a`b;`symbol))", WhereError.invalid_type);
}

test "where dictionary" {
    try runTest("&()!()", .{ .list = &.{} });
    try runTestError("&`a`b!(();())", WhereError.invalid_type);
    try runTest("&`a`b!01b", .{
        .symbol_list = &.{
            .{ .symbol = "b" },
        },
    });
    try runTest("&`a`b!1 2", .{
        .symbol_list = &.{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
            .{ .symbol = "b" },
        },
    });
    try runTest("&10 20!1 2", .{
        .int_list = &.{
            .{ .int = 10 },
            .{ .int = 20 },
            .{ .int = 20 },
        },
    });
    try runTestError("&`a`b!(1;2 2)", WhereError.invalid_type);
    try runTestError("&`a`b!(`int$();`float$())", WhereError.invalid_type);
    try runTestError("&`a`b!(,1;,2)", WhereError.invalid_type);
    try runTestError("&`a`b!(1 1;2 2)", WhereError.invalid_type);
}

test "where table" {
    try runTestError("&+`a`b!()", WhereError.invalid_type);
    try runTestError("&+`a`b!(`int$();`float$())", WhereError.invalid_type);
    try runTestError("&+`a`b!(,1;,2)", WhereError.invalid_type);
    try runTestError("&+`a`b!(1 1;2 2)", WhereError.invalid_type);
    try runTestError("&+`a`b!(1;2 2)", WhereError.invalid_type);
}
