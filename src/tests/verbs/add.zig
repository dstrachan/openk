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

fn add(comptime x: comptime_int, comptime y: comptime_int) comptime_int {
    return x + y;
}

test "add" {
    try verbTest(
        &[_]DataType{ .boolean, .int, .float },
        &[_]comptime_int{ 0, 1, -1 },
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
}
