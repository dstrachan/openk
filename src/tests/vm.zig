const std = @import("std");

const value_mod = @import("../value.zig");
const Value = value_mod.Value;
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

    dictionary: []const Self,
    table: []const Self,

    function: *ValueFunction,
    projection: *ValueProjection,
};

fn compareValues(expected: TestValue, actual: ValueUnion) !void {
    const value_type = @as(ValueType, expected);
    try std.testing.expectEqual(value_type, actual);
    switch (value_type) {
        .nil => try std.testing.expectEqual(expected.nil, actual.nil),
        .boolean => try std.testing.expectEqual(expected.boolean, actual.boolean),
        .int => try std.testing.expectEqual(expected.int, actual.int),
        .float => {
            if (!std.math.isNan(expected.float) or !std.math.isNan(actual.float)) {
                if (std.math.isInf(expected.float) or std.math.isInf(actual.float)) {
                    try std.testing.expectEqual(expected.float, actual.float);
                } else if (!std.math.approxEqRel(f64, expected.float, actual.float, std.math.sqrt(std.math.floatEps(f64))) and !std.math.approxEqAbs(f64, expected.float, actual.float, std.math.floatEps(f64))) {
                    std.debug.print("actual {}, not within absolute or relative tolerance of expected {}\n", .{ actual.float, expected.float });
                    return error.TestExpectedApproxEq;
                }
            }
        },
        .char => try std.testing.expectEqualSlices(u8, &[_]u8{expected.char}, &[_]u8{actual.char}),
        .symbol => try std.testing.expectEqualSlices(u8, expected.symbol, actual.symbol),
        .list => {
            try std.testing.expectEqual(expected.list.len, actual.list.len);
            for (expected.list, actual.list) |expected_value, actual_value| try compareValues(expected_value, actual_value.as);
        },
        .boolean_list => {
            try std.testing.expectEqual(expected.boolean_list.len, actual.boolean_list.len);
            for (expected.boolean_list, actual.boolean_list) |expected_value, actual_value| try compareValues(expected_value, actual_value.as);
        },
        .int_list => {
            try std.testing.expectEqual(expected.int_list.len, actual.int_list.len);
            for (expected.int_list, actual.int_list) |expected_value, actual_value| try compareValues(expected_value, actual_value.as);
        },
        .float_list => {
            try std.testing.expectEqual(expected.float_list.len, actual.float_list.len);
            for (expected.float_list, actual.float_list) |expected_value, actual_value| try compareValues(expected_value, actual_value.as);
        },
        .char_list => {
            const expected_list = std.testing.allocator.alloc(u8, expected.char_list.len) catch std.debug.panic("Failed to create list.", .{});
            defer std.testing.allocator.free(expected_list);
            for (expected.char_list, 0..) |value, i| expected_list[i] = value.char;

            const actual_list = std.testing.allocator.alloc(u8, actual.char_list.len) catch std.debug.panic("Failed to create list.", .{});
            defer std.testing.allocator.free(actual_list);
            for (actual.char_list, 0..) |value, i| actual_list[i] = value.as.char;

            try std.testing.expectEqualSlices(u8, expected_list, actual_list);
        },
        .symbol_list => {
            try std.testing.expectEqual(expected.symbol_list.len, actual.symbol_list.len);
            for (expected.symbol_list, actual.symbol_list) |expected_value, actual_value| try compareValues(expected_value, actual_value.as);
        },
        .dictionary => {
            try std.testing.expectEqual(@as(usize, 2), expected.dictionary.len);
            try compareValues(expected.dictionary[0], actual.dictionary.keys.as);
            try compareValues(expected.dictionary[1], actual.dictionary.values.as);
        },
        .table => {
            try std.testing.expectEqual(@as(usize, 2), expected.table.len);
            try compareValues(expected.table[0], actual.table.columns.as);
            try compareValues(expected.table[1], actual.table.values.as);
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

    compareValues(expected, result.as) catch |e| {
        std.debug.print("result: '{}'\n", .{result.as});
        return e;
    };
}

pub fn runTestError(input: []const u8, expected: anyerror) !void {
    var vm = VM.init(std.testing.allocator);
    defer vm.deinit();

    const result = vm.interpret(input) catch |err| {
        try std.testing.expectEqual(expected, err);
        return;
    };
    result.deref(std.testing.allocator);
    try std.testing.expectEqual(expected, error.no_error);
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

test "list" {
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

    try runTest("(10+10;10-10;10*10)", .{ .int_list = &[_]TestValue{
        .{ .int = 20 },
        .{ .int = 0 },
        .{ .int = 100 },
    } });
    try runTest("(10+10;(10-10;10*10))", .{ .list = &[_]TestValue{
        .{ .int = 20 },
        .{ .int_list = &[_]TestValue{
            .{ .int = 0 },
            .{ .int = 100 },
        } },
    } });

    try runTest("(,10;,20;,30)", .{
        .list = &[_]TestValue{
            .{ .int_list = &[_]TestValue{
                .{ .int = 10 },
            } },
            .{ .int_list = &[_]TestValue{
                .{ .int = 20 },
            } },
            .{ .int_list = &[_]TestValue{
                .{ .int = 30 },
            } },
        },
    });
    try runTest("(,,10),(,20;,30)", .{
        .list = &[_]TestValue{
            .{ .int_list = &[_]TestValue{
                .{ .int = 10 },
            } },
            .{ .int_list = &[_]TestValue{
                .{ .int = 20 },
            } },
            .{ .int_list = &[_]TestValue{
                .{ .int = 30 },
            } },
        },
    });

    try runTest("(,10),(,20;,30)", .{
        .list = &[_]TestValue{
            .{ .int = 10 },
            .{ .int_list = &[_]TestValue{
                .{ .int = 20 },
            } },
            .{ .int_list = &[_]TestValue{
                .{ .int = 30 },
            } },
        },
    });

    try runTest("(0b;`a`b!1 2)", .{
        .list = &[_]TestValue{
            .{ .boolean = false },
            .{ .dictionary = &[_]TestValue{
                .{ .symbol_list = &[_]TestValue{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
            } },
        },
    });
    try runTest("(0;`a`b!1 2)", .{
        .list = &[_]TestValue{
            .{ .int = 0 },
            .{ .dictionary = &[_]TestValue{
                .{ .symbol_list = &[_]TestValue{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
            } },
        },
    });
    try runTest("(0f;`a`b!1 2)", .{
        .list = &[_]TestValue{
            .{ .float = 0 },
            .{ .dictionary = &[_]TestValue{
                .{ .symbol_list = &[_]TestValue{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
            } },
        },
    });
    try runTest("(\"a\";`a`b!1 2)", .{
        .list = &[_]TestValue{
            .{ .char = 'a' },
            .{ .dictionary = &[_]TestValue{
                .{ .symbol_list = &[_]TestValue{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
            } },
        },
    });
    try runTest("(`a;`a`b!1 2)", .{
        .list = &[_]TestValue{
            .{ .symbol = "a" },
            .{ .dictionary = &[_]TestValue{
                .{ .symbol_list = &[_]TestValue{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
            } },
        },
    });
    try runTest("(();`a`b!1 2)", .{
        .list = &[_]TestValue{
            .{ .list = &.{} },
            .{ .dictionary = &[_]TestValue{
                .{ .symbol_list = &[_]TestValue{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
            } },
        },
    });
    try runTest("(01b;`a`b!1 2)", .{
        .list = &[_]TestValue{
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = false },
                .{ .boolean = true },
            } },
            .{ .dictionary = &[_]TestValue{
                .{ .symbol_list = &[_]TestValue{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
            } },
        },
    });
    try runTest("(0 1;`a`b!1 2)", .{
        .list = &[_]TestValue{
            .{ .int_list = &[_]TestValue{
                .{ .int = 0 },
                .{ .int = 1 },
            } },
            .{ .dictionary = &[_]TestValue{
                .{ .symbol_list = &[_]TestValue{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
            } },
        },
    });
    try runTest("(0 1f;`a`b!1 2)", .{
        .list = &[_]TestValue{
            .{ .float_list = &[_]TestValue{
                .{ .float = 0 },
                .{ .float = 1 },
            } },
            .{ .dictionary = &[_]TestValue{
                .{ .symbol_list = &[_]TestValue{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
            } },
        },
    });
    try runTest("(\"ab\";`a`b!1 2)", .{
        .list = &[_]TestValue{
            .{ .char_list = &[_]TestValue{
                .{ .char = 'a' },
                .{ .char = 'b' },
            } },
            .{ .dictionary = &[_]TestValue{
                .{ .symbol_list = &[_]TestValue{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
            } },
        },
    });
    try runTest("(`a`b;`a`b!1 2)", .{
        .list = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .dictionary = &[_]TestValue{
                .{ .symbol_list = &[_]TestValue{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
            } },
        },
    });

    try runTest("(`a`b!1 2;`c`d!3 4)", .{
        .list = &[_]TestValue{
            .{ .dictionary = &[_]TestValue{
                .{ .symbol_list = &[_]TestValue{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                    .{ .int = 2 },
                } },
            } },
            .{ .dictionary = &[_]TestValue{
                .{ .symbol_list = &[_]TestValue{
                    .{ .symbol = "c" },
                    .{ .symbol = "d" },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 3 },
                    .{ .int = 4 },
                } },
            } },
        },
    });

    try runTest("(`a`b!1 2;`a`b!1 2)", .{
        .table = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                    .{ .int = 1 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 2 },
                    .{ .int = 2 },
                } },
            } },
        },
    });

    try runTest("(`a`b!1 2;`a`b!1 2;`a`b!1 2)", .{
        .table = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .int_list = &[_]TestValue{
                    .{ .int = 1 },
                    .{ .int = 1 },
                    .{ .int = 1 },
                } },
                .{ .int_list = &[_]TestValue{
                    .{ .int = 2 },
                    .{ .int = 2 },
                    .{ .int = 2 },
                } },
            } },
        },
    });
}

test "null int" {
    try runTest("0N", .{ .int = Value.null_int });
}

test "inf int" {
    try runTest("0W", .{ .int = Value.inf_int });
    try runTest("-0W", .{ .int = -Value.inf_int });
}

test "null float" {
    try runTest("0n", .{ .float = Value.null_float });
    try runTest("0nf", .{ .float = Value.null_float });
    try runTest("0Nf", .{ .float = Value.null_float });
}

test "inf float" {
    try runTest("0w", .{ .float = Value.inf_float });
    try runTest("0wf", .{ .float = Value.inf_float });
    try runTest("0Wf", .{ .float = Value.inf_float });
    try runTest("-0w", .{ .float = -Value.inf_float });
    try runTest("-0wf", .{ .float = -Value.inf_float });
    try runTest("-0Wf", .{ .float = -Value.inf_float });
}

test "function errors don't leak memory" {
    try runTestError("{[x;y]x-y}[1;`symbol]", error.incompatible_types);
}

test "projections don't leak memory" {
    try runTest("{[x;y]x-y}[1];", TestValue.nil);
    try runTest("a:{[x;y]x-y}[1];", TestValue.nil);
}

test "dictionaries" {
    try runTest("()!()", .{
        .dictionary = &[_]TestValue{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("`a`b`c!1 2 3", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
                .{ .symbol = "c" },
            } },
            .{ .int_list = &[_]TestValue{
                .{ .int = 1 },
                .{ .int = 2 },
                .{ .int = 3 },
            } },
        },
    });
    // try runTest("`a`b!(`a`b!1 2;`c`d!3 4)", .{
    //     .dictionary = &[_]TestValue{
    //         .{ .symbol_list = &[_]TestValue{
    //             .{ .symbol = "a" },
    //             .{ .symbol = "b" },
    //         } },
    //         .{ .list = &[_]TestValue{
    //             .{ .dictionary = &[_]TestValue{
    //                 .{ .symbol_list = &[_]TestValue{
    //                     .{ .symbol = "a" },
    //                     .{ .symbol = "b" },
    //                 } },
    //                 .{ .int_list = &[_]TestValue{
    //                     .{ .int = 1 },
    //                     .{ .int = 2 },
    //                 } },
    //             } },
    //             .{ .dictionary = &[_]TestValue{
    //                 .{ .symbol_list = &[_]TestValue{
    //                     .{ .symbol = "a" },
    //                     .{ .symbol = "b" },
    //                 } },
    //                 .{ .int_list = &[_]TestValue{
    //                     .{ .int = 1 },
    //                     .{ .int = 2 },
    //                 } },
    //             } },
    //         } },
    //     },
    // });
}

test "stress" {
    try runTest("*&!1000", .{ .int = 1 });
    // try runTest("#&!1000", .{ .int = 499500 });
}

test "null/inf min" {
    try runTest("0N&0N", .{ .int = Value.null_int });
    try runTest("0N&0W", .{ .int = Value.null_int });
    try runTest("0N&-0W", .{ .int = Value.null_int });
    try runTest("0W&0N", .{ .int = Value.null_int });
    try runTest("0W&0W", .{ .int = Value.inf_int });
    try runTest("0W&-0W", .{ .int = -Value.inf_int });
    try runTest("-0W&0N", .{ .int = Value.null_int });
    try runTest("-0W&0W", .{ .int = -Value.inf_int });
    try runTest("-0W&-0W", .{ .int = -Value.inf_int });

    try runTest("0N&0n", .{ .float = Value.null_float });
    try runTest("0N&0w", .{ .float = Value.null_float });
    try runTest("0N&-0w", .{ .float = Value.null_float });
    try runTest("0W&0n", .{ .float = Value.null_float });
    try runTest("0W&0w", .{ .float = Value.inf_int });
    try runTest("0W&-0w", .{ .float = -Value.inf_float });
    try runTest("-0W&0n", .{ .float = Value.null_float });
    try runTest("-0W&0w", .{ .float = -Value.inf_int });
    try runTest("-0W&-0w", .{ .float = -Value.inf_float });

    try runTest("0n&0N", .{ .float = Value.null_float });
    try runTest("0n&0W", .{ .float = Value.null_float });
    try runTest("0n&-0W", .{ .float = Value.null_float });
    try runTest("0w&0N", .{ .float = Value.null_float });
    try runTest("0w&0W", .{ .float = Value.inf_int });
    try runTest("0w&-0W", .{ .float = -Value.inf_int });
    try runTest("-0w&0N", .{ .float = Value.null_float });
    try runTest("-0w&0W", .{ .float = -Value.inf_float });
    try runTest("-0w&-0W", .{ .float = -Value.inf_float });

    try runTest("0n&0n", .{ .float = Value.null_float });
    try runTest("0n&0w", .{ .float = Value.null_float });
    try runTest("0n&-0w", .{ .float = Value.null_float });
    try runTest("0w&0n", .{ .float = Value.null_float });
    try runTest("0w&0w", .{ .float = Value.inf_float });
    try runTest("0w&-0w", .{ .float = -Value.inf_float });
    try runTest("-0w&0n", .{ .float = Value.null_float });
    try runTest("-0w&0w", .{ .float = -Value.inf_float });
    try runTest("-0w&-0w", .{ .float = -Value.inf_float });
}

test "null/inf max" {
    try runTest("0N|0N", .{ .int = Value.null_int });
    try runTest("0N|0W", .{ .int = Value.inf_int });
    try runTest("0N|-0W", .{ .int = -Value.inf_int });
    try runTest("0W|0N", .{ .int = Value.inf_int });
    try runTest("0W|0W", .{ .int = Value.inf_int });
    try runTest("0W|-0W", .{ .int = Value.inf_int });
    try runTest("-0W|0N", .{ .int = -Value.inf_int });
    try runTest("-0W|0W", .{ .int = Value.inf_int });
    try runTest("-0W|-0W", .{ .int = -Value.inf_int });

    try runTest("0N|0n", .{ .float = Value.null_float });
    try runTest("0N|0w", .{ .float = Value.inf_float });
    try runTest("0N|-0w", .{ .float = -Value.inf_float });
    try runTest("0W|0n", .{ .float = Value.inf_int });
    try runTest("0W|0w", .{ .float = Value.inf_float });
    try runTest("0W|-0w", .{ .float = Value.inf_int });
    try runTest("-0W|0n", .{ .float = -Value.inf_int });
    try runTest("-0W|0w", .{ .float = Value.inf_float });
    try runTest("-0W|-0w", .{ .float = -Value.inf_int });

    try runTest("0n|0N", .{ .float = Value.null_float });
    try runTest("0n|0W", .{ .float = Value.inf_int });
    try runTest("0n|-0W", .{ .float = -Value.inf_int });
    try runTest("0w|0N", .{ .float = Value.inf_float });
    try runTest("0w|0W", .{ .float = Value.inf_float });
    try runTest("0w|-0W", .{ .float = Value.inf_float });
    try runTest("-0w|0N", .{ .float = -Value.inf_float });
    try runTest("-0w|0W", .{ .float = Value.inf_int });
    try runTest("-0w|-0W", .{ .float = -Value.inf_int });

    try runTest("0n|0n", .{ .float = Value.null_float });
    try runTest("0n|0w", .{ .float = Value.inf_float });
    try runTest("0n|-0w", .{ .float = -Value.inf_float });
    try runTest("0w|0n", .{ .float = Value.inf_float });
    try runTest("0w|0w", .{ .float = Value.inf_float });
    try runTest("0w|-0w", .{ .float = Value.inf_float });
    try runTest("-0w|0n", .{ .float = -Value.inf_float });
    try runTest("-0w|0w", .{ .float = Value.inf_float });
    try runTest("-0w|-0w", .{ .float = -Value.inf_float });
}

test "null/inf less" {
    try runTest("0N<0N", .{ .boolean = false });
    try runTest("0N<0W", .{ .boolean = true });
    try runTest("0N<-0W", .{ .boolean = true });
    try runTest("0W<0N", .{ .boolean = false });
    try runTest("0W<0W", .{ .boolean = false });
    try runTest("0W<-0W", .{ .boolean = false });
    try runTest("-0W<0N", .{ .boolean = false });
    try runTest("-0W<0W", .{ .boolean = true });
    try runTest("-0W<-0W", .{ .boolean = false });

    try runTest("0N<0n", .{ .boolean = false });
    try runTest("0N<0w", .{ .boolean = true });
    try runTest("0N<-0w", .{ .boolean = true });
    try runTest("0W<0n", .{ .boolean = false });
    try runTest("0W<0w", .{ .boolean = true });
    try runTest("0W<-0w", .{ .boolean = false });
    try runTest("-0W<0n", .{ .boolean = false });
    try runTest("-0W<0w", .{ .boolean = true });
    try runTest("-0W<-0w", .{ .boolean = false });

    try runTest("0n<0N", .{ .boolean = false });
    try runTest("0n<0W", .{ .boolean = true });
    try runTest("0n<-0W", .{ .boolean = true });
    try runTest("0w<0N", .{ .boolean = false });
    try runTest("0w<0W", .{ .boolean = false });
    try runTest("0w<-0W", .{ .boolean = false });
    try runTest("-0w<0N", .{ .boolean = false });
    try runTest("-0w<0W", .{ .boolean = true });
    try runTest("-0w<-0W", .{ .boolean = true });

    try runTest("0n<0n", .{ .boolean = false });
    try runTest("0n<0w", .{ .boolean = true });
    try runTest("0n<-0w", .{ .boolean = true });
    try runTest("0w<0n", .{ .boolean = false });
    try runTest("0w<0w", .{ .boolean = false });
    try runTest("0w<-0w", .{ .boolean = false });
    try runTest("-0w<0n", .{ .boolean = false });
    try runTest("-0w<0w", .{ .boolean = true });
    try runTest("-0w<-0w", .{ .boolean = false });
}

test "null/inf more" {
    try runTest("0N>0N", .{ .boolean = false });
    try runTest("0N>0W", .{ .boolean = false });
    try runTest("0N>-0W", .{ .boolean = false });
    try runTest("0W>0N", .{ .boolean = true });
    try runTest("0W>0W", .{ .boolean = false });
    try runTest("0W>-0W", .{ .boolean = true });
    try runTest("-0W>0N", .{ .boolean = true });
    try runTest("-0W>0W", .{ .boolean = false });
    try runTest("-0W>-0W", .{ .boolean = false });

    try runTest("0N>0n", .{ .boolean = false });
    try runTest("0N>0w", .{ .boolean = false });
    try runTest("0N>-0w", .{ .boolean = false });
    try runTest("0W>0n", .{ .boolean = true });
    try runTest("0W>0w", .{ .boolean = false });
    try runTest("0W>-0w", .{ .boolean = true });
    try runTest("-0W>0n", .{ .boolean = true });
    try runTest("-0W>0w", .{ .boolean = false });
    try runTest("-0W>-0w", .{ .boolean = true });

    try runTest("0n>0N", .{ .boolean = false });
    try runTest("0n>0W", .{ .boolean = false });
    try runTest("0n>-0W", .{ .boolean = false });
    try runTest("0w>0N", .{ .boolean = true });
    try runTest("0w>0W", .{ .boolean = true });
    try runTest("0w>-0W", .{ .boolean = true });
    try runTest("-0w>0N", .{ .boolean = true });
    try runTest("-0w>0W", .{ .boolean = false });
    try runTest("-0w>-0W", .{ .boolean = false });

    try runTest("0n>0n", .{ .boolean = false });
    try runTest("0n>0w", .{ .boolean = false });
    try runTest("0n>-0w", .{ .boolean = false });
    try runTest("0w>0n", .{ .boolean = true });
    try runTest("0w>0w", .{ .boolean = false });
    try runTest("0w>-0w", .{ .boolean = true });
    try runTest("-0w>0n", .{ .boolean = true });
    try runTest("-0w>0w", .{ .boolean = false });
    try runTest("-0w>-0w", .{ .boolean = false });
}

// test "tests csv" {
//     const file = std.fs.cwd().openFile("./tests/tests.csv", .{ .mode = .read_only }) catch std.debug.panic("Failed to open file", .{});
//     defer file.close();

//     const reader = file.reader();

//     var buffer: [1024]u8 = undefined;
//     var expression_buffer: [1024]u8 = undefined;
//     _ = try reader.readUntilDelimiterOrEof(&buffer, '\n') orelse unreachable;

//     while (true) {
//         const line = try reader.readUntilDelimiterOrEof(&buffer, '\n') orelse break;
//         var prev_index: usize = 0;
//         var values: [4][]const u8 = undefined;
//         var values_index: usize = 0;
//         for (line, 0..) |c, i| {
//             if (c == ',') {
//                 values[values_index] = std.mem.trim(u8, line[prev_index..i], &[_]u8{ ' ', '\t' });
//                 values_index += 1;
//                 prev_index = i + 1;
//             }
//         }
//         values[values_index] = std.mem.trim(u8, line[prev_index..], &[_]u8{ ' ', '\t' });

//         const expression = try std.fmt.bufPrint(&expression_buffer, "(({s}){s}{s})~{s}\n", .{ values[1], values[0], values[2], values[3] });
//         runTest(expression, .{ .boolean = true }) catch |e| {
//             std.debug.print("{s}\n", .{expression});
//             return e;
//         };
//     }
// }
