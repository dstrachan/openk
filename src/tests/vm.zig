const std = @import("std");

const value_mod = @import("../value.zig");
const ValueFunction = value_mod.ValueFunction;
const ValueProjection = value_mod.ValueProjection;
const ValueType = value_mod.ValueType;
const ValueUnion = value_mod.ValueUnion;

const vm_mod = @import("../vm.zig");
const VM = vm_mod.VM;

pub const TestValue = union(ValueType) {
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
        .char => try std.testing.expectEqualSlices(u8, &[_]u8{expected.char}, &[_]u8{actual.char}),
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
            const expected_list = std.testing.allocator.alloc(u8, expected.char_list.len) catch std.debug.panic("Failed to create list.", .{});
            defer std.testing.allocator.free(expected_list);
            for (expected.char_list) |value, i| expected_list[i] = value.char;

            const actual_list = std.testing.allocator.alloc(u8, actual.char_list.len) catch std.debug.panic("Failed to create list.", .{});
            defer std.testing.allocator.free(actual_list);
            for (actual.char_list) |value, i| actual_list[i] = value.as.char;

            try std.testing.expectEqualSlices(u8, expected_list, actual_list);
        },
        .symbol_list => {
            try std.testing.expectEqual(expected.symbol_list.len, actual.symbol_list.len);
            for (expected.symbol_list) |value, i| try compareValues(value, actual.symbol_list[i].as);
        },
        .function => try std.testing.expectEqual(expected.function, actual.function),
        .projection => try std.testing.expectEqual(expected.projection, actual.projection),
    }
}

pub fn runTest(input: []const u8, expected: TestValue) !void {
    var vm = VM.init(std.testing.allocator);
    defer vm.deinit();

    const result = try vm.interpret(input);
    defer result.deref(std.testing.allocator);

    try compareValues(expected, result.as);
}

pub const DataType = enum {
    boolean,
    int,
    float,
};

const ResultDataTypeFn = *const fn (comptime x: DataType, comptime y: DataType) DataType;
const VerbFn = *const fn (comptime x: comptime_int, comptime y: comptime_int) comptime_int;

fn getValue(comptime data_type: DataType, comptime input1: comptime_int) TestValue {
    return switch (data_type) {
        .boolean => .{ .int = if (input1 > 0) 1 else 0 },
        .int => .{ .int = input1 },
        .float => .{ .float = @intToFloat(f64, input1) },
    };
}

fn getValueList(comptime data_type: DataType, comptime input1: comptime_int, comptime input2: comptime_int) TestValue {
    return switch (data_type) {
        .boolean => .{ .int_list = &[_]TestValue{ .{ .int = if (input1 > 0) 1 else 0 }, .{ .int = if (input2 > 0) 1 else 0 } } },
        .int => .{ .int_list = &[_]TestValue{ .{ .int = input1 }, .{ .int = input2 } } },
        .float => .{ .float_list = &[_]TestValue{ .{ .float = @intToFloat(f64, input1) }, .{ .float = @intToFloat(f64, input2) } } },
    };
}

fn getValueString(comptime data_type: DataType, comptime input1: comptime_int) []const u8 {
    return switch (data_type) {
        .boolean => if (input1 > 0) "1b" else "0b",
        .int => switch (input1) {
            0 => "0",
            1 => "1",
            2 => "2",
            -1 => "-1",
            -2 => "-2",
            else => unreachable,
        },
        .float => switch (input1) {
            0 => "0f",
            1 => "1f",
            2 => "2f",
            -1 => "-1f",
            -2 => "-2f",
            else => unreachable,
        },
    };
}

fn getValueStringList(comptime data_type: DataType, comptime input1: comptime_int, comptime input2: comptime_int) []const u8 {
    return switch (data_type) {
        .boolean => (if (input1 > 0) "1" else "0") ++ (if (input2 > 0) "1b" else "0b"),
        .int => switch (input1) {
            0 => "0",
            1 => "1",
            2 => "2",
            -1 => "-1",
            -2 => "-2",
            else => unreachable,
        } ++ " " ++ switch (input2) {
            0 => "0",
            1 => "1",
            2 => "2",
            -1 => "-1",
            -2 => "-2",
            else => unreachable,
        },
        .float => switch (input1) {
            0 => "0",
            1 => "1",
            2 => "2",
            -1 => "-1",
            -2 => "-2",
            else => unreachable,
        } ++ " " ++ switch (input2) {
            0 => "0f",
            1 => "1f",
            2 => "2f",
            -1 => "-1f",
            -2 => "-2f",
            else => unreachable,
        },
    };
}

pub fn verbTest(
    comptime data_types: []const DataType,
    comptime inputs: []const comptime_int,
    comptime result_data_type_fn: ResultDataTypeFn,
    comptime verb_fn: VerbFn,
    comptime verb_str: []const u8,
) !void {
    @setEvalBranchQuota(20000);
    inline for (.{ .atom, .list }) |list_type_x| {
        inline for (.{ .atom, .list }) |list_type_y| {
            inline for (data_types) |data_type_x| {
                inline for (data_types) |data_type_y| {
                    inline for (inputs) |input_x1| {
                        inline for (inputs) |input_x2| {
                            inline for (inputs) |input_y1| {
                                inline for (inputs) |input_y2| {
                                    if (data_type_x == .boolean or data_type_y == .boolean) {
                                        if (input_x1 == -1 or input_x2 == -1 or input_y1 == -1 or input_y2 == -1) continue;
                                    }

                                    const expected_data_type = comptime result_data_type_fn(data_type_x, data_type_y);
                                    const expected = switch (list_type_x) {
                                        .atom => switch (list_type_y) {
                                            .atom => getValue(expected_data_type, verb_fn(input_x1, input_y1)),
                                            .list => getValueList(expected_data_type, verb_fn(input_x1, input_y1), verb_fn(input_x1, input_y2)),
                                            else => unreachable,
                                        },
                                        .list => switch (list_type_y) {
                                            .atom => getValueList(expected_data_type, verb_fn(input_x1, input_y1), verb_fn(input_x2, input_y1)),
                                            .list => getValueList(expected_data_type, verb_fn(input_x1, input_y1), verb_fn(input_x2, input_y2)),
                                            else => unreachable,
                                        },
                                        else => unreachable,
                                    };

                                    const x_string = comptime switch (list_type_x) {
                                        .atom => getValueString(data_type_x, input_x1),
                                        .list => getValueStringList(data_type_x, input_x1, input_x2),
                                        else => unreachable,
                                    };
                                    const y_string = comptime switch (list_type_y) {
                                        .atom => getValueString(data_type_y, input_y1),
                                        .list => getValueStringList(data_type_y, input_y1, input_y2),
                                        else => unreachable,
                                    };
                                    const input = x_string ++ verb_str ++ y_string;

                                    runTest(input, expected) catch |err| {
                                        std.debug.print("input = {s}\n", .{input});
                                        std.debug.print("expected = {}\n", .{expected});
                                        return err;
                                    };
                                }
                            }
                        }
                    }
                }
            }
        }
    }
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
