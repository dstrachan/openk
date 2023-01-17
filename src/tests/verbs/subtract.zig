const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;
const TestValue = vm_mod.TestValue;

test "boolean subtraction" {
    try runTest("0b-0b", .{ .int = 0 });
    try runTest("0b-1b", .{ .int = -1 });
    try runTest("1b-0b", .{ .int = 1 });
    try runTest("1b-1b", .{ .int = 0 });

    try runTest("0b-0", .{ .int = 0 });
    try runTest("0b-1", .{ .int = -1 });
    try runTest("0b--1", .{ .int = 1 });
    try runTest("1b-0", .{ .int = 1 });
    try runTest("1b-1", .{ .int = 0 });
    try runTest("1b--1", .{ .int = 2 });

    try runTest("0b-0f", .{ .float = 0 });
    try runTest("0b-1f", .{ .float = -1 });
    try runTest("0b--1f", .{ .float = 1 });
    try runTest("1b-0f", .{ .float = 1 });
    try runTest("1b-1f", .{ .float = 0 });
    try runTest("1b--1f", .{ .float = 2 });
}

test "int subtraction" {
    try runTest("0-0b", .{ .int = 0 });
    try runTest("0-1b", .{ .int = -1 });
    try runTest("1-0b", .{ .int = 1 });
    try runTest("1-1b", .{ .int = 0 });
    try runTest("-1-0b", .{ .int = -1 });
    try runTest("-1-1b", .{ .int = -2 });

    try runTest("0-0", .{ .int = 0 });
    try runTest("0-1", .{ .int = -1 });
    try runTest("0--1", .{ .int = 1 });
    try runTest("1-0", .{ .int = 1 });
    try runTest("1-1", .{ .int = 0 });
    try runTest("1--1", .{ .int = 2 });
    try runTest("-1-0", .{ .int = -1 });
    try runTest("-1-1", .{ .int = -2 });
    try runTest("-1--1", .{ .int = 0 });

    try runTest("0-0f", .{ .float = 0 });
    try runTest("0-1f", .{ .float = -1 });
    try runTest("0--1f", .{ .float = 1 });
    try runTest("1-0f", .{ .float = 1 });
    try runTest("1-1f", .{ .float = 0 });
    try runTest("1--1f", .{ .float = 2 });
    try runTest("-1-0f", .{ .float = -1 });
    try runTest("-1-1f", .{ .float = -2 });
    try runTest("-1--1f", .{ .float = 0 });
}

test "float subtraction" {
    try runTest("0f-0b", .{ .float = 0 });
    try runTest("0f-1b", .{ .float = -1 });
    try runTest("1f-0b", .{ .float = 1 });
    try runTest("1f-1b", .{ .float = 0 });
    try runTest("-1f-0b", .{ .float = -1 });
    try runTest("-1f-1b", .{ .float = -2 });

    try runTest("0f-0", .{ .float = 0 });
    try runTest("0f-1", .{ .float = -1 });
    try runTest("0f--1", .{ .float = 1 });
    try runTest("1f-0", .{ .float = 1 });
    try runTest("1f-1", .{ .float = 0 });
    try runTest("1f--1", .{ .float = 2 });
    try runTest("-1f-0", .{ .float = -1 });
    try runTest("-1f-1", .{ .float = -2 });
    try runTest("-1f--1", .{ .float = 0 });

    try runTest("0f-0f", .{ .float = 0 });
    try runTest("0f-1f", .{ .float = -1 });
    try runTest("0f--1f", .{ .float = 1 });
    try runTest("1f-0f", .{ .float = 1 });
    try runTest("1f-1f", .{ .float = 0 });
    try runTest("1f--1f", .{ .float = 2 });
    try runTest("-1f-0f", .{ .float = -1 });
    try runTest("-1f-1f", .{ .float = -2 });
    try runTest("-1f--1f", .{ .float = 0 });
}
