const std = @import("std");

const compiler_mod = @import("../compiler.zig");
const CompilerError = compiler_mod.CompilerError;

const value_mod = @import("../value.zig");
const Value = value_mod.Value;
const ValueType = value_mod.ValueType;
const ValueUnion = value_mod.ValueUnion;

const vm_mod = @import("../vm.zig");
const VM = vm_mod.VM;

fn runTest(input: []const u8, expected_constants: ?[]const ValueUnion) !void {
    const vm = VM.init(std.testing.allocator);
    defer vm.deinit();

    const value = try compiler_mod.compile(input, vm);
    defer value.deref(std.testing.allocator);

    try std.testing.expectEqual(ValueType.function, value.as);

    if (expected_constants) |expected| {
        const actual = value.as.function.chunk.constants.items;
        try std.testing.expectEqual(expected.len, actual.len);
        var i: usize = 0;
        while (i < expected.len) : (i += 1) {
            try std.testing.expectEqual(expected[i], actual[i].as);
        }
    }
}

fn runTestError(input: []const u8) !void {
    const vm = VM.init(std.testing.allocator);
    defer vm.deinit();

    const value = compiler_mod.compile(input, vm) catch |err| return std.testing.expectEqual(CompilerError.compile_error, err);
    value.deref(std.testing.allocator);
}

test "compiler bool" {
    try runTest("0b", &[_]ValueUnion{.{ .boolean = false }});
    try runTest("1b", &[_]ValueUnion{.{ .boolean = true }});

    try runTestError("2b");
    try runTestError("-1b");
}

test "compiler int" {
    try runTest("0", &[_]ValueUnion{.{ .int = 0 }});
    try runTest("1", &[_]ValueUnion{.{ .int = 1 }});

    try runTest("-1", &[_]ValueUnion{.{ .int = -1 }});

    try runTestError("- 1");
}

test "compiler float" {
    try runTest("1f", &[_]ValueUnion{.{ .float = 1 }});
    try runTest("1.", &[_]ValueUnion{.{ .float = 1 }});
    try runTest("1.f", &[_]ValueUnion{.{ .float = 1 }});
    try runTest("1.0", &[_]ValueUnion{.{ .float = 1 }});
    try runTest("1.0f", &[_]ValueUnion{.{ .float = 1 }});
    try runTest(".0", &[_]ValueUnion{.{ .float = 0 }});
    try runTest(".0f", &[_]ValueUnion{.{ .float = 0 }});

    try runTest("-1f", &[_]ValueUnion{.{ .float = -1 }});
    try runTest("-1.", &[_]ValueUnion{.{ .float = -1 }});
    try runTest("-1.f", &[_]ValueUnion{.{ .float = -1 }});
    try runTest("-1.0", &[_]ValueUnion{.{ .float = -1 }});
    try runTest("-1.0f", &[_]ValueUnion{.{ .float = -1 }});
    try runTest("-.0", &[_]ValueUnion{.{ .float = 0 }});
    try runTest("-.0f", &[_]ValueUnion{.{ .float = 0 }});

    try runTestError("0.0.0");
}
