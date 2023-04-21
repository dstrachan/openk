const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;
const runTestError = vm_mod.runTestError;

const KeyError = @import("../../verbs/key.zig").KeyError;

test "key boolean" {
    try runTest("!0b", .{ .int_list = &.{} });
    try runTest("!1b", .{
        .int_list = &.{
            .{ .int = 0 },
        },
    });
    try runTest("!`boolean$()", .{ .symbol = "boolean" });
    try runTest("!01b", .{ .symbol = "boolean" });
}

test "key int" {
    try runTestError("!-1", KeyError.enum_range);
    try runTest("!0", .{ .int_list = &.{} });
    try runTest("!5", .{ .int_list = &.{
        .{ .int = 0 },
        .{ .int = 1 },
        .{ .int = 2 },
        .{ .int = 3 },
        .{ .int = 4 },
    } });
    try runTest("!`int$()", .{ .symbol = "int" });
    try runTest("!0 1 0N 0W -0W", .{ .symbol = "int" });
}

test "key float" {
    try runTestError("!0f", KeyError.invalid_type);
    try runTest("!`float$()", .{ .symbol = "float" });
    try runTest("!0 1 0n 0w -0w", .{ .symbol = "float" });
}

test "key char" {
    try runTestError("!\"a\"", KeyError.invalid_type);
    try runTest("!\"\"", .{ .symbol = "char" });
    try runTest("!\"abcde\"", .{ .symbol = "char" });
}

test "key symbol" {
    try runTestError("!`symbol", KeyError.nyi);
    try runTest("!`$()", .{ .symbol = "symbol" });
    try runTest("!`a`b`c`d`e", .{ .symbol = "symbol" });
}

test "key list" {
    try runTestError("!()", KeyError.invalid_type);
    try runTestError("!(0b;1;2f)", KeyError.invalid_type);
}

test "key dictionary" {
    try runTest("!()!()", .{ .list = &.{} });
    try runTest("!()!`float$()", .{ .list = &.{} });
    try runTest("!(`int$())!()", .{ .int_list = &.{} });
    try runTest("!(`int$())!`float$()", .{ .int_list = &.{} });
    try runTest("!`a`b!(();())", .{
        .symbol_list = &.{
            .{ .symbol = "a" },
            .{ .symbol = "b" },
        },
    });
}

test "key table" {
    try runTestError("!+`a`b!()", KeyError.invalid_type);
    try runTestError("!+`a`b!(`int$();`float$())", KeyError.invalid_type);
    try runTestError("!+`a`b!(,1;,2)", KeyError.invalid_type);
    try runTestError("!+`a`b!(1 1;2 2)", KeyError.invalid_type);
    try runTestError("!+`a`b!(1;2 2)", KeyError.invalid_type);
}
