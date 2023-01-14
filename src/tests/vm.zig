const std = @import("std");

const value_mod = @import("../value.zig");
const ValueType = value_mod.ValueType;
const ValueUnion = value_mod.ValueUnion;

const vm_mod = @import("../vm.zig");
const VM = vm_mod.VM;

fn runTest(input: []const u8, expected: ValueUnion) !void {
    var vm = VM.init(std.testing.allocator);
    defer vm.deinit();

    const result = try vm.interpret(input);
    defer result.deref(std.testing.allocator);

    const value_type = @as(ValueType, expected);
    try std.testing.expectEqual(value_type, result.as);
    if (value_type == .float and std.math.isNan(expected.float) and std.math.isNan(result.as.float)) {
        return;
    }
    try std.testing.expectEqual(expected, result.as);
}

test "top-level script returns result" {
    var vm = VM.init(std.testing.allocator);
    defer vm.deinit();

    const result = try vm.interpret("1");
    defer result.deref(std.testing.allocator);

    try std.testing.expectEqual(ValueType.int, result.as);
    try std.testing.expectEqual(@intCast(i64, 1), result.as.int);
}

test "chained add operations do not leak intermediate results" {
    var vm = VM.init(std.testing.allocator);
    defer vm.deinit();

    const result = try vm.interpret("1+2+3+4+5");
    defer result.deref(std.testing.allocator);

    try std.testing.expectEqual(ValueType.int, result.as);
    try std.testing.expectEqual(@intCast(i64, 15), result.as.int);
}

test "chained global set operations" {
    var vm = VM.init(std.testing.allocator);
    defer vm.deinit();

    const result = try vm.interpret("a:b:c:1+2+3+4+5");
    defer result.deref(std.testing.allocator);

    try std.testing.expectEqual(ValueType.int, result.as);
    try std.testing.expectEqual(@intCast(i64, 15), result.as.int);
}

test "simple function call" {
    var vm = VM.init(std.testing.allocator);
    defer vm.deinit();

    const result = try vm.interpret("{[x]a:x}[1]");
    defer result.deref(std.testing.allocator);

    try std.testing.expectEqual(ValueType.int, result.as);
    try std.testing.expectEqual(@intCast(i64, 1), result.as.int);
}

test "nested function calls" {
    var vm = VM.init(std.testing.allocator);
    defer vm.deinit();

    const result = try vm.interpret("{[x;y;z]{[x;y]{[x]a:x}[x]}[x;y]}[1;2;3]");
    defer result.deref(std.testing.allocator);

    try std.testing.expectEqual(ValueType.int, result.as);
    try std.testing.expectEqual(@intCast(i64, 1), result.as.int);
}

test "projection call" {
    var vm = VM.init(std.testing.allocator);
    defer vm.deinit();

    const result = try vm.interpret("{[x;y]x+y}[;1][2]");
    defer result.deref(std.testing.allocator);

    try std.testing.expectEqual(ValueType.int, result.as);
    try std.testing.expectEqual(@intCast(i64, 3), result.as.int);
}

test "vm - boolean addition" {
    try runTest("0b+0b", .{ .int = 0 });
    try runTest("0b+1b", .{ .int = 1 });
    try runTest("1b+0b", .{ .int = 1 });
    try runTest("1b+1b", .{ .int = 2 });

    try runTest("0b+0", .{ .int = 0 });
    try runTest("0b+1", .{ .int = 1 });
    try runTest("0b+-1", .{ .int = -1 });
    try runTest("1b+0", .{ .int = 1 });
    try runTest("1b+1", .{ .int = 2 });
    try runTest("1b+-1", .{ .int = 0 });

    try runTest("0b+0f", .{ .float = 0 });
    try runTest("0b+1f", .{ .float = 1 });
    try runTest("0b+-1f", .{ .float = -1 });
    try runTest("1b+0f", .{ .float = 1 });
    try runTest("1b+1f", .{ .float = 2 });
    try runTest("1b+-1f", .{ .float = 0 });
}

test "vm - int addition" {
    try runTest("0+0b", .{ .int = 0 });
    try runTest("0+1b", .{ .int = 1 });
    try runTest("1+0b", .{ .int = 1 });
    try runTest("1+1b", .{ .int = 2 });
    try runTest("-1+0b", .{ .int = -1 });
    try runTest("-1+1b", .{ .int = 0 });

    try runTest("0+0", .{ .int = 0 });
    try runTest("0+1", .{ .int = 1 });
    try runTest("0+-1", .{ .int = -1 });
    try runTest("1+0", .{ .int = 1 });
    try runTest("1+1", .{ .int = 2 });
    try runTest("1+-1", .{ .int = 0 });
    try runTest("-1+0", .{ .int = -1 });
    try runTest("-1+1", .{ .int = 0 });
    try runTest("-1+-1", .{ .int = -2 });

    try runTest("0+0f", .{ .float = 0 });
    try runTest("0+1f", .{ .float = 1 });
    try runTest("0+-1f", .{ .float = -1 });
    try runTest("1+0f", .{ .float = 1 });
    try runTest("1+1f", .{ .float = 2 });
    try runTest("1+-1f", .{ .float = 0 });
    try runTest("-1+0f", .{ .float = -1 });
    try runTest("-1+1f", .{ .float = 0 });
    try runTest("-1+-1f", .{ .float = -2 });
}

test "vm - float addition" {
    try runTest("0f+0b", .{ .float = 0 });
    try runTest("0f+1b", .{ .float = 1 });
    try runTest("1f+0b", .{ .float = 1 });
    try runTest("1f+1b", .{ .float = 2 });
    try runTest("-1f+0b", .{ .float = -1 });
    try runTest("-1f+1b", .{ .float = 0 });

    try runTest("0f+0", .{ .float = 0 });
    try runTest("0f+1", .{ .float = 1 });
    try runTest("0f+-1", .{ .float = -1 });
    try runTest("1f+0", .{ .float = 1 });
    try runTest("1f+1", .{ .float = 2 });
    try runTest("1f+-1", .{ .float = 0 });
    try runTest("-1f+0", .{ .float = -1 });
    try runTest("-1f+1", .{ .float = 0 });
    try runTest("-1f+-1", .{ .float = -2 });

    try runTest("0f+0f", .{ .float = 0 });
    try runTest("0f+1f", .{ .float = 1 });
    try runTest("0f+-1f", .{ .float = -1 });
    try runTest("1f+0f", .{ .float = 1 });
    try runTest("1f+1f", .{ .float = 2 });
    try runTest("1f+-1f", .{ .float = 0 });
    try runTest("-1f+0f", .{ .float = -1 });
    try runTest("-1f+1f", .{ .float = 0 });
    try runTest("-1f+-1f", .{ .float = -2 });
}

test "vm - boolean subtraction" {
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

test "vm - int subtraction" {
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

test "vm - float subtraction" {
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

test "vm - boolean multiplication" {
    try runTest("0b*0b", .{ .int = 0 });
    try runTest("0b*1b", .{ .int = 0 });
    try runTest("1b*0b", .{ .int = 0 });
    try runTest("1b*1b", .{ .int = 1 });

    try runTest("0b*0", .{ .int = 0 });
    try runTest("0b*1", .{ .int = 0 });
    try runTest("0b*-1", .{ .int = 0 });
    try runTest("1b*0", .{ .int = 0 });
    try runTest("1b*1", .{ .int = 1 });
    try runTest("1b*-1", .{ .int = -1 });

    try runTest("0b*0f", .{ .float = 0 });
    try runTest("0b*1f", .{ .float = 0 });
    try runTest("0b*-1f", .{ .float = 0 });
    try runTest("1b*0f", .{ .float = 0 });
    try runTest("1b*1f", .{ .float = 1 });
    try runTest("1b*-1f", .{ .float = -1 });
}

test "vm - int multiplication" {
    try runTest("0*0b", .{ .int = 0 });
    try runTest("0*1b", .{ .int = 0 });
    try runTest("1*0b", .{ .int = 0 });
    try runTest("1*1b", .{ .int = 1 });
    try runTest("-1*0b", .{ .int = 0 });
    try runTest("-1*1b", .{ .int = -1 });

    try runTest("0*0", .{ .int = 0 });
    try runTest("0*1", .{ .int = 0 });
    try runTest("0*-1", .{ .int = 0 });
    try runTest("1*0", .{ .int = 0 });
    try runTest("1*1", .{ .int = 1 });
    try runTest("1*-1", .{ .int = -1 });
    try runTest("-1*0", .{ .int = 0 });
    try runTest("-1*1", .{ .int = -1 });
    try runTest("-1*-1", .{ .int = 1 });

    try runTest("0*0f", .{ .float = 0 });
    try runTest("0*1f", .{ .float = 0 });
    try runTest("0*-1f", .{ .float = 0 });
    try runTest("1*0f", .{ .float = 0 });
    try runTest("1*1f", .{ .float = 1 });
    try runTest("1*-1f", .{ .float = -1 });
    try runTest("-1*0f", .{ .float = 0 });
    try runTest("-1*1f", .{ .float = -1 });
    try runTest("-1*-1f", .{ .float = 1 });
}

test "vm - float multiplication" {
    try runTest("0f*0b", .{ .float = 0 });
    try runTest("0f*1b", .{ .float = 0 });
    try runTest("1f*0b", .{ .float = 0 });
    try runTest("1f*1b", .{ .float = 1 });
    try runTest("-1f*0b", .{ .float = 0 });
    try runTest("-1f*1b", .{ .float = -1 });

    try runTest("0f*0", .{ .float = 0 });
    try runTest("0f*1", .{ .float = 0 });
    try runTest("0f*-1", .{ .float = 0 });
    try runTest("1f*0", .{ .float = 0 });
    try runTest("1f*1", .{ .float = 1 });
    try runTest("1f*-1", .{ .float = -1 });
    try runTest("-1f*0", .{ .float = 0 });
    try runTest("-1f*1", .{ .float = -1 });
    try runTest("-1f*-1", .{ .float = 1 });

    try runTest("0f*0f", .{ .float = 0 });
    try runTest("0f*1f", .{ .float = 0 });
    try runTest("0f*-1f", .{ .float = 0 });
    try runTest("1f*0f", .{ .float = 0 });
    try runTest("1f*1f", .{ .float = 1 });
    try runTest("1f*-1f", .{ .float = -1 });
    try runTest("-1f*0f", .{ .float = 0 });
    try runTest("-1f*1f", .{ .float = -1 });
    try runTest("-1f*-1f", .{ .float = 1 });
}

test "vm - boolean division" {
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

test "vm - int division" {
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

test "vm - float division" {
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
