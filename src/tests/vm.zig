const std = @import("std");

const value_mod = @import("../value.zig");
const ValueFunction = value_mod.ValueFunction;
const ValueProjection = value_mod.ValueProjection;
const ValueType = value_mod.ValueType;
const ValueUnion = value_mod.ValueUnion;

const vm_mod = @import("../vm.zig");
const VM = vm_mod.VM;

const TestValue = union(ValueType) {
    const Self = @This();

    nil,
    boolean: bool,
    int: i64,
    float: f64,
    char: u8,
    symbol: []const u8,

    list: []const Self,

    boolean_list: []const Self,
    int_list: []const Self,
    float_list: []const Self,
    char_list: []const Self,
    symbol_list: []const Self,

    function: *ValueFunction,
    projection: *ValueProjection,
};

fn compareValues(expected: TestValue, actual: ValueUnion) !void {
    const value_type = @as(ValueType, expected);
    try std.testing.expectEqual(value_type, actual);
    if (value_type == .float and std.math.isNan(expected.float) and std.math.isNan(actual.float)) {
        return;
    }
    switch (value_type) {
        .nil => try std.testing.expectEqual(expected.nil, actual.nil),
        .boolean => try std.testing.expectEqual(expected.boolean, actual.boolean),
        .int => try std.testing.expectEqual(expected.int, actual.int),
        .float => try std.testing.expectEqual(expected.float, actual.float),
        .char => try std.testing.expectEqual(expected.char, actual.char),
        .symbol => try std.testing.expectEqualSlices(u8, expected.symbol, actual.symbol),
        .list => {
            try std.testing.expectEqual(expected.list.len, actual.list.len);
            for (expected.list) |value, i| try compareValues(value, actual.list[i].as);
        },
        .boolean_list => {
            try std.testing.expectEqual(expected.boolean_list.len, actual.boolean_list.len);
            for (expected.boolean_list) |value, i| try compareValues(value, actual.boolean_list[i].as);
        },
        .int_list => {
            try std.testing.expectEqual(expected.int_list.len, actual.int_list.len);
            for (expected.int_list) |value, i| try compareValues(value, actual.int_list[i].as);
        },
        .float_list => {
            try std.testing.expectEqual(expected.float_list.len, actual.float_list.len);
            for (expected.float_list) |value, i| try compareValues(value, actual.float_list[i].as);
        },
        .char_list => {
            try std.testing.expectEqual(expected.char_list.len, actual.char_list.len);
            for (expected.char_list) |value, i| try compareValues(value, actual.char_list[i].as);
        },
        .symbol_list => {
            try std.testing.expectEqual(expected.symbol_list.len, actual.symbol_list.len);
            for (expected.symbol_list) |value, i| try compareValues(value, actual.symbol_list[i].as);
        },
        .function => try std.testing.expectEqual(expected.function, actual.function),
        .projection => try std.testing.expectEqual(expected.projection, actual.projection),
    }
}

fn runTest(input: []const u8, expected: TestValue) !void {
    var vm = VM.init(std.testing.allocator);
    defer vm.deinit();

    const result = try vm.interpret(input);
    defer result.deref(std.testing.allocator);

    try compareValues(expected, result.as);
}

test "top-level script returns result" {
    try runTest("1", .{ .int = 1 });
}

test "chained add operations do not leak intermediate results" {
    try runTest("1+2+3+4+5", .{ .int = 15 });
}

test "chained global set operations" {
    try runTest("a:b:c:1+2+3+4+5", .{ .int = 15 });
}

test "simple function call" {
    try runTest("{[x]a:x}[1]", .{ .int = 1 });
}

test "nested function calls" {
    try runTest("{[x;y;z]{[x;y]{[x]a:x}[x]}[x;y]}[1;2;3]", .{ .int = 1 });
}

test "projection call" {
    try runTest("{[x;y]x+y}[;1][2]", .{ .int = 3 });
}

test "vm - list" {
    try runTest("01b", .{ .boolean_list = &[_]TestValue{ .{ .boolean = false }, .{ .boolean = true } } });
    try runTest("(0b;1b)", .{ .boolean_list = &[_]TestValue{ .{ .boolean = false }, .{ .boolean = true } } });
    try runTest("0 1", .{ .int_list = &[_]TestValue{ .{ .int = 0 }, .{ .int = 1 } } });
    try runTest("(0;1)", .{ .int_list = &[_]TestValue{ .{ .int = 0 }, .{ .int = 1 } } });
    try runTest("0 1f", .{ .float_list = &[_]TestValue{ .{ .float = 0 }, .{ .float = 1 } } });
    try runTest("(0f;1f)", .{ .float_list = &[_]TestValue{ .{ .float = 0 }, .{ .float = 1 } } });
    try runTest("(\" \";\" \")", .{ .char_list = &[_]TestValue{ .{ .char = ' ' }, .{ .char = ' ' } } });
    try runTest("\"  \"", .{ .char_list = &[_]TestValue{ .{ .char = ' ' }, .{ .char = ' ' } } });
    try runTest("`symbol`symbol", .{ .symbol_list = &[_]TestValue{ .{ .symbol = "symbol" }, .{ .symbol = "symbol" } } });
    try runTest("(`symbol;`symbol)", .{ .symbol_list = &[_]TestValue{ .{ .symbol = "symbol" }, .{ .symbol = "symbol" } } });

    try runTest("(0b;1;2f)", .{ .list = &[_]TestValue{ .{ .boolean = false }, .{ .int = 1 }, .{ .float = 2 } } });
    try runTest("(0b;(1;2f))", .{ .list = &[_]TestValue{
        .{ .boolean = false },
        .{ .list = &[_]TestValue{ .{ .int = 1 }, .{ .float = 2 } } },
    } });

    try runTest("(10+10;10-10;10*10)", .{ .int_list = &[_]TestValue{ .{ .int = 20 }, .{ .int = 0 }, .{ .int = 100 } } });
    try runTest("(10+10;(10-10;10*10))", .{ .list = &[_]TestValue{
        .{ .int = 20 },
        .{ .int_list = &[_]TestValue{ .{ .int = 0 }, .{ .int = 100 } } },
    } });
}

test "vm - concat" {
    try runTest(",1", .{ .int_list = &[_]TestValue{.{ .int = 1 }} });
    try runTest(",,1", .{ .list = &[_]TestValue{.{ .int_list = &[_]TestValue{.{ .int = 1 }} }} });
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
