const vm_mod = @import("../vm.zig");
const verbTest = vm_mod.verbTest;
const runTest = vm_mod.runTest;
const DataType = vm_mod.DataType;

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

fn multiply(comptime x: comptime_int, comptime y: comptime_int) comptime_float {
    return x * y;
}

test "multiply" {
    try verbTest(
        &[_]DataType{ .boolean, .int, .float },
        &[_]comptime_int{ 0, 1, -1 },
        null,
        getDataType,
        multiply,
        "*",
    );
}

test "multiply with null/inf" {
    try runTest("0W*2", .{ .int = -2 });
    try runTest("0N*2", .{ .int = Value.null_int });
    try runTest("-0W*2", .{ .int = 2 });
    try runTest("1317624576693539401*7", .{ .int = Value.inf_int });
    try runTest("-1317624576693539401*7", .{ .int = -Value.inf_int });
    try runTest("4611686018427387904*2", .{ .int = Value.null_int });
    try runTest("-4611686018427387904*2", .{ .int = Value.null_int });

    try runTest("0w*2", .{ .float = Value.inf_float });
    try runTest("0n*2", .{ .float = Value.null_float });
    try runTest("-0w*2", .{ .float = -Value.inf_float });

    try runTest("0N*0N", .{ .int = Value.null_int });
    try runTest("0N*0W", .{ .int = Value.null_int });
    try runTest("0N*-0W", .{ .int = Value.null_int });
    try runTest("0N*0n", .{ .float = Value.null_float });
    try runTest("0N*0w", .{ .float = Value.null_float });
    try runTest("0N*-0w", .{ .float = Value.null_float });

    try runTest("0W*0N", .{ .int = Value.null_int });
    try runTest("0W*0W", .{ .int = 1 });
    try runTest("0W*-0W", .{ .int = -1 });
    try runTest("0W*0n", .{ .float = Value.null_float });
    try runTest("0W*0w", .{ .float = Value.inf_float });
    try runTest("0W*-0w", .{ .float = -Value.inf_float });

    try runTest("-0W*0N", .{ .int = Value.null_int });
    try runTest("-0W*0W", .{ .int = -1 });
    try runTest("-0W*-0W", .{ .int = 1 });
    try runTest("-0W*0n", .{ .float = Value.null_float });
    try runTest("-0W*0w", .{ .float = -Value.inf_float });
    try runTest("-0W*-0w", .{ .float = Value.inf_float });

    try runTest("0n*0N", .{ .float = Value.null_float });
    try runTest("0n*0W", .{ .float = Value.null_float });
    try runTest("0n*-0W", .{ .float = Value.null_float });
    try runTest("0n*0n", .{ .float = Value.null_float });
    try runTest("0n*0w", .{ .float = Value.null_float });
    try runTest("0n*-0w", .{ .float = Value.null_float });

    try runTest("0w*0N", .{ .float = Value.null_float });
    try runTest("0w*0W", .{ .float = Value.inf_float });
    try runTest("0w*-0W", .{ .float = -Value.inf_float });
    try runTest("0w*0n", .{ .float = Value.null_float });
    try runTest("0w*0w", .{ .float = Value.inf_float });
    try runTest("0w*-0w", .{ .float = -Value.inf_float });

    try runTest("-0w*0N", .{ .float = Value.null_float });
    try runTest("-0w*0W", .{ .float = -Value.inf_float });
    try runTest("-0w*-0W", .{ .float = Value.inf_float });
    try runTest("-0w*0n", .{ .float = Value.null_float });
    try runTest("-0w*0w", .{ .float = -Value.inf_float });
    try runTest("-0w*-0w", .{ .float = Value.inf_float });
}
