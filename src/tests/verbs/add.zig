const vm_mod = @import("../vm.zig");
const verbTest = vm_mod.verbTest;
const runTest = vm_mod.runTest;
const DataType = vm_mod.DataType;
const TestValue = vm_mod.TestValue;

const value_mod = @import("../../value.zig");
const Value = value_mod.Value;

fn getDataType(comptime x: DataType, comptime y: DataType) DataType {
    return switch (x) {
        .boolean => switch (y) {
            .boolean => .int,
            .int => .int,
            .float => .float,
        },
        .int => switch (y) {
            .boolean => .int,
            .int => .int,
            .float => .float,
        },
        .float => .float,
    };
}

fn add(comptime x: comptime_int, comptime y: comptime_int) comptime_float {
    return x + y;
}

test "add" {
    try verbTest(
        &[_]DataType{ .boolean, .int, .float },
        &[_]comptime_int{ 0, 1, -1 },
        null,
        getDataType,
        add,
        "+",
    );
}

test "add with null/inf" {
    try runTest("0W+1", .{ .int = Value.null_int });
    try runTest("0N+1", .{ .int = Value.null_int });
    try runTest("0W+2", .{ .int = -Value.inf_int });

    try runTest("0w+1", .{ .float = Value.inf_float });
    try runTest("0n+1", .{ .float = Value.null_float });
    try runTest("-0w+1", .{ .float = -Value.inf_float });

    try runTest("0N+0N", .{ .int = Value.null_int });
    try runTest("0N+0W", .{ .int = Value.null_int });
    try runTest("0N+-0W", .{ .int = Value.null_int });
    try runTest("0N+0n", .{ .float = Value.null_float });
    try runTest("0N+0w", .{ .float = Value.null_float });
    try runTest("0N+-0w", .{ .float = Value.null_float });

    try runTest("0W+0N", .{ .int = Value.null_int });
    try runTest("0W+0W", .{ .int = -2 });
    try runTest("0W+-0W", .{ .int = 0 });
    try runTest("0W+0n", .{ .float = Value.null_float });
    try runTest("0W+0w", .{ .float = Value.inf_float });
    try runTest("0W+-0w", .{ .float = -Value.inf_float });

    try runTest("-0W+0N", .{ .int = Value.null_int });
    try runTest("-0W+0W", .{ .int = 0 });
    try runTest("-0W+-0W", .{ .int = 2 });
    try runTest("-0W+0n", .{ .float = Value.null_float });
    try runTest("-0W+0w", .{ .float = Value.inf_float });
    try runTest("-0W+-0w", .{ .float = -Value.inf_float });

    try runTest("0n+0N", .{ .float = Value.null_float });
    try runTest("0n+0W", .{ .float = Value.null_float });
    try runTest("0n+-0W", .{ .float = Value.null_float });
    try runTest("0n+0n", .{ .float = Value.null_float });
    try runTest("0n+0w", .{ .float = Value.null_float });
    try runTest("0n+-0w", .{ .float = Value.null_float });

    try runTest("0w+0N", .{ .float = Value.null_float });
    try runTest("0w+0W", .{ .float = Value.inf_float });
    try runTest("0w+-0W", .{ .float = Value.inf_float });
    try runTest("0w+0n", .{ .float = Value.null_float });
    try runTest("0w+0w", .{ .float = Value.inf_float });
    try runTest("0w+-0w", .{ .float = Value.null_float });

    try runTest("-0w+0N", .{ .float = Value.null_float });
    try runTest("-0w+0W", .{ .float = -Value.inf_float });
    try runTest("-0w+-0W", .{ .float = -Value.inf_float });
    try runTest("-0w+0n", .{ .float = Value.null_float });
    try runTest("-0w+0w", .{ .float = Value.null_float });
    try runTest("-0w+-0w", .{ .float = -Value.inf_float });
}
