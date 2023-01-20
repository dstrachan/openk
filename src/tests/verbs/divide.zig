const std = @import("std");

const vm_mod = @import("../vm.zig");
const verbTest = vm_mod.verbTest;
const runTest = vm_mod.runTest;
const DataType = vm_mod.DataType;

const value_mod = @import("../../value.zig");
const Value = value_mod.Value;

fn getDataType(comptime _: DataType, comptime _: DataType) DataType {
    return .float;
}

fn divide(comptime x: comptime_int, comptime y: comptime_int) comptime_float {
    if (y == 0) {
        if (x == 0) unreachable;
        return std.math.sign(x) * std.math.inf(f64);
    }
    return x / y;
}

fn excludePredicate(comptime x: comptime_int, comptime y: comptime_int) bool {
    return x == 0 and y == 0;
}

test "divide" {
    try verbTest(
        &[_]DataType{ .boolean, .int, .float },
        &[_]comptime_int{ 0, 1, -1 },
        excludePredicate,
        getDataType,
        divide,
        "%",
    );
}

test "divide with null/inf" {
    try runTest("0W%7", .{ .float = 1317624576693539401 });
    try runTest("0N%2", .{ .float = Value.null_float });
    try runTest("-0W%7", .{ .float = -1317624576693539401 });

    try runTest("0w%2", .{ .float = Value.inf_float });
    try runTest("0n%2", .{ .float = Value.null_float });
    try runTest("-0w%2", .{ .float = -Value.inf_float });

    try runTest("0N%0N", .{ .float = Value.null_float });
    try runTest("0N%0W", .{ .float = Value.null_float });
    try runTest("0N%-0W", .{ .float = Value.null_float });
    try runTest("0N%0n", .{ .float = Value.null_float });
    try runTest("0N%0w", .{ .float = Value.null_float });
    try runTest("0N%-0w", .{ .float = Value.null_float });

    try runTest("0W%0N", .{ .float = Value.null_float });
    try runTest("0W%0W", .{ .float = 1 });
    try runTest("0W%-0W", .{ .float = -1 });
    try runTest("0W%0n", .{ .float = Value.null_float });
    try runTest("0W%0w", .{ .float = 0 });
    try runTest("0W%-0w", .{ .float = 0 });

    try runTest("-0W%0N", .{ .float = Value.null_float });
    try runTest("-0W%0W", .{ .float = -1 });
    try runTest("-0W%-0W", .{ .float = 1 });
    try runTest("-0W%0n", .{ .float = Value.null_float });
    try runTest("-0W%0w", .{ .float = 0 });
    try runTest("-0W%-0w", .{ .float = 0 });

    try runTest("0n%0N", .{ .float = Value.null_float });
    try runTest("0n%0W", .{ .float = Value.null_float });
    try runTest("0n%-0W", .{ .float = Value.null_float });
    try runTest("0n%0n", .{ .float = Value.null_float });
    try runTest("0n%0w", .{ .float = Value.null_float });
    try runTest("0n%-0w", .{ .float = Value.null_float });

    try runTest("0w%0N", .{ .float = Value.null_float });
    try runTest("0w%0W", .{ .float = Value.inf_float });
    try runTest("0w%-0W", .{ .float = -Value.inf_float });
    try runTest("0w%0n", .{ .float = Value.null_float });
    try runTest("0w%0w", .{ .float = Value.null_float });
    try runTest("0w%-0w", .{ .float = Value.null_float });

    try runTest("-0w%0N", .{ .float = Value.null_float });
    try runTest("-0w%0W", .{ .float = -Value.inf_float });
    try runTest("-0w%-0W", .{ .float = Value.inf_float });
    try runTest("-0w%0n", .{ .float = Value.null_float });
    try runTest("-0w%0w", .{ .float = Value.null_float });
    try runTest("-0w%-0w", .{ .float = Value.null_float });
}
