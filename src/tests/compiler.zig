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

test "compiler - bool" {
    try runTest("0b", &.{.{ .boolean = false }});
    try runTest("1b", &.{.{ .boolean = true }});

    try runTestError("2b");
    try runTestError("-1b");
}

test "compiler - int" {
    try runTest("0", &.{.{ .int = 0 }});
    try runTest("1", &.{.{ .int = 1 }});

    try runTest("-1", &.{.{ .int = -1 }});

    try runTestError("- 1");
}

test "compiler - float" {
    try runTest("1f", &.{.{ .float = 1 }});
    try runTest("1.", &.{.{ .float = 1 }});
    try runTest("1.f", &.{.{ .float = 1 }});
    try runTest("1.0", &.{.{ .float = 1 }});
    try runTest("1.0f", &.{.{ .float = 1 }});
    try runTest(".0", &.{.{ .float = 0 }});
    try runTest(".0f", &.{.{ .float = 0 }});

    try runTest("-1f", &.{.{ .float = -1 }});
    try runTest("-1.", &.{.{ .float = -1 }});
    try runTest("-1.f", &.{.{ .float = -1 }});
    try runTest("-1.0", &.{.{ .float = -1 }});
    try runTest("-1.0f", &.{.{ .float = -1 }});
    try runTest("-.0", &.{.{ .float = 0 }});
    try runTest("-.0f", &.{.{ .float = 0 }});

    try runTestError("0.0.0");
}

test "compiler - char" {}

test "compiler - symbol" {}

test "compiler - list" {}

test "compiler - boolean addition" {
    try runTest("0b+0b", &.{ .{ .boolean = false }, .{ .boolean = false } });
    try runTest("0b+1b", &.{ .{ .boolean = false }, .{ .boolean = true } });
    try runTest("1b+0b", &.{ .{ .boolean = true }, .{ .boolean = false } });
    try runTest("1b+1b", &.{ .{ .boolean = true }, .{ .boolean = true } });

    try runTest("0b+0", &.{ .{ .boolean = false }, .{ .int = 0 } });
    try runTest("0b+1", &.{ .{ .boolean = false }, .{ .int = 1 } });
    try runTest("0b+-1", &.{ .{ .boolean = false }, .{ .int = -1 } });
    try runTest("1b+0", &.{ .{ .boolean = true }, .{ .int = 0 } });
    try runTest("1b+1", &.{ .{ .boolean = true }, .{ .int = 1 } });
    try runTest("1b+-1", &.{ .{ .boolean = true }, .{ .int = -1 } });

    try runTest("0b+0f", &.{ .{ .boolean = false }, .{ .float = 0 } });
    try runTest("0b+1f", &.{ .{ .boolean = false }, .{ .float = 1 } });
    try runTest("0b+-1f", &.{ .{ .boolean = false }, .{ .float = -1 } });
    try runTest("1b+0f", &.{ .{ .boolean = true }, .{ .float = 0 } });
    try runTest("1b+1f", &.{ .{ .boolean = true }, .{ .float = 1 } });
    try runTest("1b+-1f", &.{ .{ .boolean = true }, .{ .float = -1 } });
}

test "compiler - int addition" {
    try runTest("0+0b", &.{ .{ .int = 0 }, .{ .boolean = false } });
    try runTest("0+1b", &.{ .{ .int = 0 }, .{ .boolean = true } });
    try runTest("1+0b", &.{ .{ .int = 1 }, .{ .boolean = false } });
    try runTest("1+1b", &.{ .{ .int = 1 }, .{ .boolean = true } });
    try runTest("-1+0b", &.{ .{ .int = -1 }, .{ .boolean = false } });
    try runTest("-1+1b", &.{ .{ .int = -1 }, .{ .boolean = true } });

    try runTest("0+0", &.{ .{ .int = 0 }, .{ .int = 0 } });
    try runTest("0+1", &.{ .{ .int = 0 }, .{ .int = 1 } });
    try runTest("0+-1", &.{ .{ .int = 0 }, .{ .int = -1 } });
    try runTest("1+0", &.{ .{ .int = 1 }, .{ .int = 0 } });
    try runTest("1+1", &.{ .{ .int = 1 }, .{ .int = 1 } });
    try runTest("1+-1", &.{ .{ .int = 1 }, .{ .int = -1 } });
    try runTest("-1+0", &.{ .{ .int = -1 }, .{ .int = 0 } });
    try runTest("-1+1", &.{ .{ .int = -1 }, .{ .int = 1 } });
    try runTest("-1+-1", &.{ .{ .int = -1 }, .{ .int = -1 } });

    try runTest("0+0f", &.{ .{ .int = 0 }, .{ .float = 0 } });
    try runTest("0+1f", &.{ .{ .int = 0 }, .{ .float = 1 } });
    try runTest("0+-1f", &.{ .{ .int = 0 }, .{ .float = -1 } });
    try runTest("1+0f", &.{ .{ .int = 1 }, .{ .float = 0 } });
    try runTest("1+1f", &.{ .{ .int = 1 }, .{ .float = 1 } });
    try runTest("1+-1f", &.{ .{ .int = 1 }, .{ .float = -1 } });
    try runTest("-1+0f", &.{ .{ .int = -1 }, .{ .float = 0 } });
    try runTest("-1+1f", &.{ .{ .int = -1 }, .{ .float = 1 } });
    try runTest("-1+-1f", &.{ .{ .int = -1 }, .{ .float = -1 } });
}

test "compiler - float addition" {
    try runTest("0f+0b", &.{ .{ .float = 0 }, .{ .boolean = false } });
    try runTest("0f+1b", &.{ .{ .float = 0 }, .{ .boolean = true } });
    try runTest("1f+0b", &.{ .{ .float = 1 }, .{ .boolean = false } });
    try runTest("1f+1b", &.{ .{ .float = 1 }, .{ .boolean = true } });
    try runTest("-1f+0b", &.{ .{ .float = -1 }, .{ .boolean = false } });
    try runTest("-1f+1b", &.{ .{ .float = -1 }, .{ .boolean = true } });

    try runTest("0f+0", &.{ .{ .float = 0 }, .{ .int = 0 } });
    try runTest("0f+1", &.{ .{ .float = 0 }, .{ .int = 1 } });
    try runTest("0f+-1", &.{ .{ .float = 0 }, .{ .int = -1 } });
    try runTest("1f+0", &.{ .{ .float = 1 }, .{ .int = 0 } });
    try runTest("1f+1", &.{ .{ .float = 1 }, .{ .int = 1 } });
    try runTest("1f+-1", &.{ .{ .float = 1 }, .{ .int = -1 } });
    try runTest("-1f+0", &.{ .{ .float = -1 }, .{ .int = 0 } });
    try runTest("-1f+1", &.{ .{ .float = -1 }, .{ .int = 1 } });
    try runTest("-1f+-1", &.{ .{ .float = -1 }, .{ .int = -1 } });

    try runTest("0f+0f", &.{ .{ .float = 0 }, .{ .float = 0 } });
    try runTest("0f+1f", &.{ .{ .float = 0 }, .{ .float = 1 } });
    try runTest("0f+-1f", &.{ .{ .float = 0 }, .{ .float = -1 } });
    try runTest("1f+0f", &.{ .{ .float = 1 }, .{ .float = 0 } });
    try runTest("1f+1f", &.{ .{ .float = 1 }, .{ .float = 1 } });
    try runTest("1f+-1f", &.{ .{ .float = 1 }, .{ .float = -1 } });
    try runTest("-1f+0f", &.{ .{ .float = -1 }, .{ .float = 0 } });
    try runTest("-1f+1f", &.{ .{ .float = -1 }, .{ .float = 1 } });
    try runTest("-1f+-1f", &.{ .{ .float = -1 }, .{ .float = -1 } });
}

test "compiler - boolean subtraction" {
    try runTest("0b-0b", &.{ .{ .boolean = false }, .{ .boolean = false } });
    try runTest("0b-1b", &.{ .{ .boolean = false }, .{ .boolean = true } });
    try runTest("1b-0b", &.{ .{ .boolean = true }, .{ .boolean = false } });
    try runTest("1b-1b", &.{ .{ .boolean = true }, .{ .boolean = true } });

    try runTest("0b-0", &.{ .{ .boolean = false }, .{ .int = 0 } });
    try runTest("0b-1", &.{ .{ .boolean = false }, .{ .int = 1 } });
    try runTest("0b--1", &.{ .{ .boolean = false }, .{ .int = -1 } });
    try runTest("1b-0", &.{ .{ .boolean = true }, .{ .int = 0 } });
    try runTest("1b-1", &.{ .{ .boolean = true }, .{ .int = 1 } });
    try runTest("1b--1", &.{ .{ .boolean = true }, .{ .int = -1 } });

    try runTest("0b-0f", &.{ .{ .boolean = false }, .{ .float = 0 } });
    try runTest("0b-1f", &.{ .{ .boolean = false }, .{ .float = 1 } });
    try runTest("0b--1f", &.{ .{ .boolean = false }, .{ .float = -1 } });
    try runTest("1b-0f", &.{ .{ .boolean = true }, .{ .float = 0 } });
    try runTest("1b-1f", &.{ .{ .boolean = true }, .{ .float = 1 } });
    try runTest("1b--1f", &.{ .{ .boolean = true }, .{ .float = -1 } });
}

test "compiler - int subtraction" {
    try runTest("0-0b", &.{ .{ .int = 0 }, .{ .boolean = false } });
    try runTest("0-1b", &.{ .{ .int = 0 }, .{ .boolean = true } });
    try runTest("1-0b", &.{ .{ .int = 1 }, .{ .boolean = false } });
    try runTest("1-1b", &.{ .{ .int = 1 }, .{ .boolean = true } });
    try runTest("-1-0b", &.{ .{ .int = -1 }, .{ .boolean = false } });
    try runTest("-1-1b", &.{ .{ .int = -1 }, .{ .boolean = true } });

    try runTest("0-0", &.{ .{ .int = 0 }, .{ .int = 0 } });
    try runTest("0-1", &.{ .{ .int = 0 }, .{ .int = 1 } });
    try runTest("0--1", &.{ .{ .int = 0 }, .{ .int = -1 } });
    try runTest("1-0", &.{ .{ .int = 1 }, .{ .int = 0 } });
    try runTest("1-1", &.{ .{ .int = 1 }, .{ .int = 1 } });
    try runTest("1--1", &.{ .{ .int = 1 }, .{ .int = -1 } });
    try runTest("-1-0", &.{ .{ .int = -1 }, .{ .int = 0 } });
    try runTest("-1-1", &.{ .{ .int = -1 }, .{ .int = 1 } });
    try runTest("-1--1", &.{ .{ .int = -1 }, .{ .int = -1 } });

    try runTest("0-0f", &.{ .{ .int = 0 }, .{ .float = 0 } });
    try runTest("0-1f", &.{ .{ .int = 0 }, .{ .float = 1 } });
    try runTest("0--1f", &.{ .{ .int = 0 }, .{ .float = -1 } });
    try runTest("1-0f", &.{ .{ .int = 1 }, .{ .float = 0 } });
    try runTest("1-1f", &.{ .{ .int = 1 }, .{ .float = 1 } });
    try runTest("1--1f", &.{ .{ .int = 1 }, .{ .float = -1 } });
    try runTest("-1-0f", &.{ .{ .int = -1 }, .{ .float = 0 } });
    try runTest("-1-1f", &.{ .{ .int = -1 }, .{ .float = 1 } });
    try runTest("-1--1f", &.{ .{ .int = -1 }, .{ .float = -1 } });
}

test "compiler - float subtraction" {
    try runTest("0f-0b", &.{ .{ .float = 0 }, .{ .boolean = false } });
    try runTest("0f-1b", &.{ .{ .float = 0 }, .{ .boolean = true } });
    try runTest("1f-0b", &.{ .{ .float = 1 }, .{ .boolean = false } });
    try runTest("1f-1b", &.{ .{ .float = 1 }, .{ .boolean = true } });
    try runTest("-1f-0b", &.{ .{ .float = -1 }, .{ .boolean = false } });
    try runTest("-1f-1b", &.{ .{ .float = -1 }, .{ .boolean = true } });

    try runTest("0f-0", &.{ .{ .float = 0 }, .{ .int = 0 } });
    try runTest("0f-1", &.{ .{ .float = 0 }, .{ .int = 1 } });
    try runTest("0f--1", &.{ .{ .float = 0 }, .{ .int = -1 } });
    try runTest("1f-0", &.{ .{ .float = 1 }, .{ .int = 0 } });
    try runTest("1f-1", &.{ .{ .float = 1 }, .{ .int = 1 } });
    try runTest("1f--1", &.{ .{ .float = 1 }, .{ .int = -1 } });
    try runTest("-1f-0", &.{ .{ .float = -1 }, .{ .int = 0 } });
    try runTest("-1f-1", &.{ .{ .float = -1 }, .{ .int = 1 } });
    try runTest("-1f--1", &.{ .{ .float = -1 }, .{ .int = -1 } });

    try runTest("0f-0f", &.{ .{ .float = 0 }, .{ .float = 0 } });
    try runTest("0f-1f", &.{ .{ .float = 0 }, .{ .float = 1 } });
    try runTest("0f--1f", &.{ .{ .float = 0 }, .{ .float = -1 } });
    try runTest("1f-0f", &.{ .{ .float = 1 }, .{ .float = 0 } });
    try runTest("1f-1f", &.{ .{ .float = 1 }, .{ .float = 1 } });
    try runTest("1f--1f", &.{ .{ .float = 1 }, .{ .float = -1 } });
    try runTest("-1f-0f", &.{ .{ .float = -1 }, .{ .float = 0 } });
    try runTest("-1f-1f", &.{ .{ .float = -1 }, .{ .float = 1 } });
    try runTest("-1f--1f", &.{ .{ .float = -1 }, .{ .float = -1 } });
}

test "compiler - boolean multiplication" {
    try runTest("0b*0b", &.{ .{ .boolean = false }, .{ .boolean = false } });
    try runTest("0b*1b", &.{ .{ .boolean = false }, .{ .boolean = true } });
    try runTest("1b*0b", &.{ .{ .boolean = true }, .{ .boolean = false } });
    try runTest("1b*1b", &.{ .{ .boolean = true }, .{ .boolean = true } });

    try runTest("0b*0", &.{ .{ .boolean = false }, .{ .int = 0 } });
    try runTest("0b*1", &.{ .{ .boolean = false }, .{ .int = 1 } });
    try runTest("0b*-1", &.{ .{ .boolean = false }, .{ .int = -1 } });
    try runTest("1b*0", &.{ .{ .boolean = true }, .{ .int = 0 } });
    try runTest("1b*1", &.{ .{ .boolean = true }, .{ .int = 1 } });
    try runTest("1b*-1", &.{ .{ .boolean = true }, .{ .int = -1 } });

    try runTest("0b*0f", &.{ .{ .boolean = false }, .{ .float = 0 } });
    try runTest("0b*1f", &.{ .{ .boolean = false }, .{ .float = 1 } });
    try runTest("0b*-1f", &.{ .{ .boolean = false }, .{ .float = -1 } });
    try runTest("1b*0f", &.{ .{ .boolean = true }, .{ .float = 0 } });
    try runTest("1b*1f", &.{ .{ .boolean = true }, .{ .float = 1 } });
    try runTest("1b*-1f", &.{ .{ .boolean = true }, .{ .float = -1 } });
}

test "compiler - int multiplication" {
    try runTest("0*0b", &.{ .{ .int = 0 }, .{ .boolean = false } });
    try runTest("0*1b", &.{ .{ .int = 0 }, .{ .boolean = true } });
    try runTest("1*0b", &.{ .{ .int = 1 }, .{ .boolean = false } });
    try runTest("1*1b", &.{ .{ .int = 1 }, .{ .boolean = true } });
    try runTest("-1*0b", &.{ .{ .int = -1 }, .{ .boolean = false } });
    try runTest("-1*1b", &.{ .{ .int = -1 }, .{ .boolean = true } });

    try runTest("0*0", &.{ .{ .int = 0 }, .{ .int = 0 } });
    try runTest("0*1", &.{ .{ .int = 0 }, .{ .int = 1 } });
    try runTest("0*-1", &.{ .{ .int = 0 }, .{ .int = -1 } });
    try runTest("1*0", &.{ .{ .int = 1 }, .{ .int = 0 } });
    try runTest("1*1", &.{ .{ .int = 1 }, .{ .int = 1 } });
    try runTest("1*-1", &.{ .{ .int = 1 }, .{ .int = -1 } });
    try runTest("-1*0", &.{ .{ .int = -1 }, .{ .int = 0 } });
    try runTest("-1*1", &.{ .{ .int = -1 }, .{ .int = 1 } });
    try runTest("-1*-1", &.{ .{ .int = -1 }, .{ .int = -1 } });

    try runTest("0*0f", &.{ .{ .int = 0 }, .{ .float = 0 } });
    try runTest("0*1f", &.{ .{ .int = 0 }, .{ .float = 1 } });
    try runTest("0*-1f", &.{ .{ .int = 0 }, .{ .float = -1 } });
    try runTest("1*0f", &.{ .{ .int = 1 }, .{ .float = 0 } });
    try runTest("1*1f", &.{ .{ .int = 1 }, .{ .float = 1 } });
    try runTest("1*-1f", &.{ .{ .int = 1 }, .{ .float = -1 } });
    try runTest("-1*0f", &.{ .{ .int = -1 }, .{ .float = 0 } });
    try runTest("-1*1f", &.{ .{ .int = -1 }, .{ .float = 1 } });
    try runTest("-1*-1f", &.{ .{ .int = -1 }, .{ .float = -1 } });
}

test "compiler - float multiplication" {
    try runTest("0f*0b", &.{ .{ .float = 0 }, .{ .boolean = false } });
    try runTest("0f*1b", &.{ .{ .float = 0 }, .{ .boolean = true } });
    try runTest("1f*0b", &.{ .{ .float = 1 }, .{ .boolean = false } });
    try runTest("1f*1b", &.{ .{ .float = 1 }, .{ .boolean = true } });
    try runTest("-1f*0b", &.{ .{ .float = -1 }, .{ .boolean = false } });
    try runTest("-1f*1b", &.{ .{ .float = -1 }, .{ .boolean = true } });

    try runTest("0f*0", &.{ .{ .float = 0 }, .{ .int = 0 } });
    try runTest("0f*1", &.{ .{ .float = 0 }, .{ .int = 1 } });
    try runTest("0f*-1", &.{ .{ .float = 0 }, .{ .int = -1 } });
    try runTest("1f*0", &.{ .{ .float = 1 }, .{ .int = 0 } });
    try runTest("1f*1", &.{ .{ .float = 1 }, .{ .int = 1 } });
    try runTest("1f*-1", &.{ .{ .float = 1 }, .{ .int = -1 } });
    try runTest("-1f*0", &.{ .{ .float = -1 }, .{ .int = 0 } });
    try runTest("-1f*1", &.{ .{ .float = -1 }, .{ .int = 1 } });
    try runTest("-1f*-1", &.{ .{ .float = -1 }, .{ .int = -1 } });

    try runTest("0f*0f", &.{ .{ .float = 0 }, .{ .float = 0 } });
    try runTest("0f*1f", &.{ .{ .float = 0 }, .{ .float = 1 } });
    try runTest("0f*-1f", &.{ .{ .float = 0 }, .{ .float = -1 } });
    try runTest("1f*0f", &.{ .{ .float = 1 }, .{ .float = 0 } });
    try runTest("1f*1f", &.{ .{ .float = 1 }, .{ .float = 1 } });
    try runTest("1f*-1f", &.{ .{ .float = 1 }, .{ .float = -1 } });
    try runTest("-1f*0f", &.{ .{ .float = -1 }, .{ .float = 0 } });
    try runTest("-1f*1f", &.{ .{ .float = -1 }, .{ .float = 1 } });
    try runTest("-1f*-1f", &.{ .{ .float = -1 }, .{ .float = -1 } });
}

test "compiler - boolean division" {
    try runTest("0b%0b", &.{ .{ .boolean = false }, .{ .boolean = false } });
    try runTest("0b%1b", &.{ .{ .boolean = false }, .{ .boolean = true } });
    try runTest("1b%0b", &.{ .{ .boolean = true }, .{ .boolean = false } });
    try runTest("1b%1b", &.{ .{ .boolean = true }, .{ .boolean = true } });

    try runTest("0b%0", &.{ .{ .boolean = false }, .{ .int = 0 } });
    try runTest("0b%1", &.{ .{ .boolean = false }, .{ .int = 1 } });
    try runTest("0b%-1", &.{ .{ .boolean = false }, .{ .int = -1 } });
    try runTest("1b%0", &.{ .{ .boolean = true }, .{ .int = 0 } });
    try runTest("1b%1", &.{ .{ .boolean = true }, .{ .int = 1 } });
    try runTest("1b%-1", &.{ .{ .boolean = true }, .{ .int = -1 } });

    try runTest("0b%0f", &.{ .{ .boolean = false }, .{ .float = 0 } });
    try runTest("0b%1f", &.{ .{ .boolean = false }, .{ .float = 1 } });
    try runTest("0b%-1f", &.{ .{ .boolean = false }, .{ .float = -1 } });
    try runTest("1b%0f", &.{ .{ .boolean = true }, .{ .float = 0 } });
    try runTest("1b%1f", &.{ .{ .boolean = true }, .{ .float = 1 } });
    try runTest("1b%-1f", &.{ .{ .boolean = true }, .{ .float = -1 } });
}

test "compiler - int division" {
    try runTest("0%0b", &.{ .{ .int = 0 }, .{ .boolean = false } });
    try runTest("0%1b", &.{ .{ .int = 0 }, .{ .boolean = true } });
    try runTest("1%0b", &.{ .{ .int = 1 }, .{ .boolean = false } });
    try runTest("1%1b", &.{ .{ .int = 1 }, .{ .boolean = true } });
    try runTest("-1%0b", &.{ .{ .int = -1 }, .{ .boolean = false } });
    try runTest("-1%1b", &.{ .{ .int = -1 }, .{ .boolean = true } });

    try runTest("0%0", &.{ .{ .int = 0 }, .{ .int = 0 } });
    try runTest("0%1", &.{ .{ .int = 0 }, .{ .int = 1 } });
    try runTest("0%-1", &.{ .{ .int = 0 }, .{ .int = -1 } });
    try runTest("1%0", &.{ .{ .int = 1 }, .{ .int = 0 } });
    try runTest("1%1", &.{ .{ .int = 1 }, .{ .int = 1 } });
    try runTest("1%-1", &.{ .{ .int = 1 }, .{ .int = -1 } });
    try runTest("-1%0", &.{ .{ .int = -1 }, .{ .int = 0 } });
    try runTest("-1%1", &.{ .{ .int = -1 }, .{ .int = 1 } });
    try runTest("-1%-1", &.{ .{ .int = -1 }, .{ .int = -1 } });

    try runTest("0%0f", &.{ .{ .int = 0 }, .{ .float = 0 } });
    try runTest("0%1f", &.{ .{ .int = 0 }, .{ .float = 1 } });
    try runTest("0%-1f", &.{ .{ .int = 0 }, .{ .float = -1 } });
    try runTest("1%0f", &.{ .{ .int = 1 }, .{ .float = 0 } });
    try runTest("1%1f", &.{ .{ .int = 1 }, .{ .float = 1 } });
    try runTest("1%-1f", &.{ .{ .int = 1 }, .{ .float = -1 } });
    try runTest("-1%0f", &.{ .{ .int = -1 }, .{ .float = 0 } });
    try runTest("-1%1f", &.{ .{ .int = -1 }, .{ .float = 1 } });
    try runTest("-1%-1f", &.{ .{ .int = -1 }, .{ .float = -1 } });
}

test "compiler - float division" {
    try runTest("0f%0b", &.{ .{ .float = 0 }, .{ .boolean = false } });
    try runTest("0f%1b", &.{ .{ .float = 0 }, .{ .boolean = true } });
    try runTest("1f%0b", &.{ .{ .float = 1 }, .{ .boolean = false } });
    try runTest("1f%1b", &.{ .{ .float = 1 }, .{ .boolean = true } });
    try runTest("-1f%0b", &.{ .{ .float = -1 }, .{ .boolean = false } });
    try runTest("-1f%1b", &.{ .{ .float = -1 }, .{ .boolean = true } });

    try runTest("0f%0", &.{ .{ .float = 0 }, .{ .int = 0 } });
    try runTest("0f%1", &.{ .{ .float = 0 }, .{ .int = 1 } });
    try runTest("0f%-1", &.{ .{ .float = 0 }, .{ .int = -1 } });
    try runTest("1f%0", &.{ .{ .float = 1 }, .{ .int = 0 } });
    try runTest("1f%1", &.{ .{ .float = 1 }, .{ .int = 1 } });
    try runTest("1f%-1", &.{ .{ .float = 1 }, .{ .int = -1 } });
    try runTest("-1f%0", &.{ .{ .float = -1 }, .{ .int = 0 } });
    try runTest("-1f%1", &.{ .{ .float = -1 }, .{ .int = 1 } });
    try runTest("-1f%-1", &.{ .{ .float = -1 }, .{ .int = -1 } });

    try runTest("0f%0f", &.{ .{ .float = 0 }, .{ .float = 0 } });
    try runTest("0f%1f", &.{ .{ .float = 0 }, .{ .float = 1 } });
    try runTest("0f%-1f", &.{ .{ .float = 0 }, .{ .float = -1 } });
    try runTest("1f%0f", &.{ .{ .float = 1 }, .{ .float = 0 } });
    try runTest("1f%1f", &.{ .{ .float = 1 }, .{ .float = 1 } });
    try runTest("1f%-1f", &.{ .{ .float = 1 }, .{ .float = -1 } });
    try runTest("-1f%0f", &.{ .{ .float = -1 }, .{ .float = 0 } });
    try runTest("-1f%1f", &.{ .{ .float = -1 }, .{ .float = 1 } });
    try runTest("-1f%-1f", &.{ .{ .float = -1 }, .{ .float = -1 } });
}
