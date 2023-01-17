const std = @import("std");

const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;
const TestValue = vm_mod.TestValue;

test "boolean division" {
    try runTest("0b%0b", .{ .float = -std.math.nan(f64) });
    try runTest("0b%1b", .{ .float = 0 });
    try runTest("1b%0b", .{ .float = std.math.inf(f64) });
    try runTest("1b%1b", .{ .float = 1 });

    try runTest("0b%0", .{ .float = -std.math.nan(f64) });
    try runTest("0b%1", .{ .float = 0 });
    try runTest("0b%-1", .{ .float = 0 });
    try runTest("1b%0", .{ .float = std.math.inf(f64) });
    try runTest("1b%1", .{ .float = 1 });
    try runTest("1b%-1", .{ .float = -1 });

    try runTest("0b%0f", .{ .float = -std.math.nan(f64) });
    try runTest("0b%1f", .{ .float = 0 });
    try runTest("0b%-1f", .{ .float = 0 });
    try runTest("1b%0f", .{ .float = std.math.inf(f64) });
    try runTest("1b%1f", .{ .float = 1 });
    try runTest("1b%-1f", .{ .float = -1 });
}

test "int division" {
    try runTest("0%0b", .{ .float = -std.math.nan(f64) });
    try runTest("0%1b", .{ .float = 0 });
    try runTest("1%0b", .{ .float = std.math.inf(f64) });
    try runTest("1%1b", .{ .float = 1 });
    try runTest("-1%0b", .{ .float = -std.math.inf(f64) });
    try runTest("-1%1b", .{ .float = -1 });

    try runTest("0%0", .{ .float = -std.math.nan(f64) });
    try runTest("0%1", .{ .float = 0 });
    try runTest("0%-1", .{ .float = 0 });
    try runTest("1%0", .{ .float = std.math.inf(f64) });
    try runTest("1%1", .{ .float = 1 });
    try runTest("1%-1", .{ .float = -1 });
    try runTest("-1%0", .{ .float = -std.math.inf(f64) });
    try runTest("-1%1", .{ .float = -1 });
    try runTest("-1%-1", .{ .float = 1 });

    try runTest("0%0f", .{ .float = -std.math.nan(f64) });
    try runTest("0%1f", .{ .float = 0 });
    try runTest("0%-1f", .{ .float = 0 });
    try runTest("1%0f", .{ .float = std.math.inf(f64) });
    try runTest("1%1f", .{ .float = 1 });
    try runTest("1%-1f", .{ .float = -1 });
    try runTest("-1%0f", .{ .float = -std.math.inf(f64) });
    try runTest("-1%1f", .{ .float = -1 });
    try runTest("-1%-1f", .{ .float = 1 });
}

test "float division" {
    try runTest("0f%0b", .{ .float = -std.math.nan(f64) });
    try runTest("0f%1b", .{ .float = 0 });
    try runTest("1f%0b", .{ .float = std.math.inf(f64) });
    try runTest("1f%1b", .{ .float = 1 });
    try runTest("-1f%0b", .{ .float = -std.math.inf(f64) });
    try runTest("-1f%1b", .{ .float = -1 });

    try runTest("0f%0", .{ .float = -std.math.nan(f64) });
    try runTest("0f%1", .{ .float = 0 });
    try runTest("0f%-1", .{ .float = 0 });
    try runTest("1f%0", .{ .float = std.math.inf(f64) });
    try runTest("1f%1", .{ .float = 1 });
    try runTest("1f%-1", .{ .float = -1 });
    try runTest("-1f%0", .{ .float = -std.math.inf(f64) });
    try runTest("-1f%1", .{ .float = -1 });
    try runTest("-1f%-1", .{ .float = 1 });

    try runTest("0f%0f", .{ .float = -std.math.nan(f64) });
    try runTest("0f%1f", .{ .float = 0 });
    try runTest("0f%-1f", .{ .float = 0 });
    try runTest("1f%0f", .{ .float = std.math.inf(f64) });
    try runTest("1f%1f", .{ .float = 1 });
    try runTest("1f%-1f", .{ .float = -1 });
    try runTest("-1f%0f", .{ .float = -std.math.inf(f64) });
    try runTest("-1f%1f", .{ .float = -1 });
    try runTest("-1f%-1f", .{ .float = 1 });
}
