const value_mod = @import("../../value.zig");
const Value = value_mod.Value;

const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;
const runTestError = vm_mod.runTestError;
const TestValue = vm_mod.TestValue;

const EqualError = @import("../../verbs/equal.zig").EqualError;

test "equal boolean" {
    try runTest("1b=0b", .{ .boolean = false });
    try runTest("1b=`boolean$()", .{ .boolean_list = &[_]TestValue{} });
    try runTest("1b=00000b", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });

    try runTest("1=0b", .{ .boolean = false });
    try runTest("1=`boolean$()", .{ .boolean_list = &[_]TestValue{} });
    try runTest("1=00000b", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });

    try runTest("1f=0b", .{ .boolean = false });
    try runTest("1f=`boolean$()", .{ .boolean_list = &[_]TestValue{} });
    try runTest("1f=00000b", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });

    try runTestError("\"a\"=0b", EqualError.incompatible_types);
    try runTestError("\"a\"=`boolean$()", EqualError.incompatible_types);
    try runTestError("\"a\"=00000b", EqualError.incompatible_types);

    try runTestError("`symbol=0b", EqualError.incompatible_types);
    try runTestError("`symbol=`boolean$()", EqualError.incompatible_types);
    try runTestError("`symbol=00000b", EqualError.incompatible_types);

    try runTest("()=0b", .{ .list = &[_]TestValue{} });
    try runTest("(1b;2)=0b", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTest("(1b;2;3f)=0b", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTest("(1b;2;3f;(0b;1))=0b", .{
        .list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = true },
                .{ .boolean = false },
            } },
        },
    });
    try runTestError("(1b;2;3f;`symbol)=0b", EqualError.incompatible_types);
    try runTest("()=`boolean$()", .{ .list = &[_]TestValue{} });
    try runTestError("()=010b", EqualError.length_mismatch);
    try runTestError("(1b;2)=`boolean$()", EqualError.length_mismatch);
    try runTest("(1b;2)=01b", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTest("(1b;2;3f)=010b", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTestError("(1b;2;3f)=0101b", EqualError.length_mismatch);
    try runTestError("(1b;2;3f;\"a\")=0101b", EqualError.incompatible_types);
    try runTestError("(1b;2;3f;`symbol)=0101b", EqualError.incompatible_types);

    try runTest("11111b=0b", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTestError("11111b=`boolean$()", EqualError.length_mismatch);
    try runTest("11111b=00000b", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTestError("11111b=000000b", EqualError.length_mismatch);

    try runTest("5 4 3 2 1=0b", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTestError("5 4 3 2 1=`boolean$()", EqualError.length_mismatch);
    try runTest("5 4 3 2 1=00000b", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTestError("5 4 3 2 1=000000b", EqualError.length_mismatch);

    try runTest("5 4 3 2 1f=0b", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTestError("5 4 3 2 1f=`boolean$()", EqualError.length_mismatch);
    try runTest("5 4 3 2 1f=00000b", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTestError("5 4 3 2 1f=000000b", EqualError.length_mismatch);

    try runTestError("\"abcde\"=0b", EqualError.incompatible_types);
    try runTestError("\"abcde\"=`boolean$()", EqualError.incompatible_types);
    try runTestError("\"abcde\"=00000b", EqualError.incompatible_types);
    try runTestError("\"abcde\"=000000b", EqualError.incompatible_types);

    try runTestError("`a`b`c`d`e=0b", EqualError.incompatible_types);
    try runTestError("`a`b`c`d`e=`boolean$()", EqualError.incompatible_types);
    try runTestError("`a`b`c`d`e=00000b", EqualError.incompatible_types);
    try runTestError("`a`b`c`d`e=000000b", EqualError.incompatible_types);

    try runTest("(()!())=0b", .{
        .dictionary = &[_]TestValue{
            .{ .list = &[_]TestValue{} },
            .{ .list = &[_]TestValue{} },
        },
    });
    try runTest("(()!())=`boolean$()", .{
        .dictionary = &[_]TestValue{
            .{ .list = &[_]TestValue{} },
            .{ .list = &[_]TestValue{} },
        },
    });
    try runTestError("(()!())=01b", EqualError.length_mismatch);
    try runTest("(`a`b!1 2)=0b", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = false },
                .{ .boolean = false },
            } },
        },
    });
    try runTestError("(`a`b!1 2)=`boolean$()", EqualError.length_mismatch);
    try runTest("(`a`b!1 2)=01b", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = false },
                .{ .boolean = false },
            } },
        },
    });
    try runTestError("(`a`b!1 2)=010b", EqualError.length_mismatch);

    try runTest("(+`a`b!(();()))=0b", .{
        .table = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .list = &[_]TestValue{} },
                .{ .list = &[_]TestValue{} },
            } },
        },
    });
    try runTestError("(+`a`b!(();()))=`boolean$()", EqualError.incompatible_types);
    try runTestError("(+`a`b!(();()))=010b", EqualError.incompatible_types);
    try runTest("(+`a`b!(`int$();`float$()))=0b", .{
        .table = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .boolean_list = &[_]TestValue{} },
                .{ .boolean_list = &[_]TestValue{} },
            } },
        },
    });
    try runTestError("(+`a`b!(`int$();`float$()))=`boolean$()", EqualError.incompatible_types);
    try runTestError("(+`a`b!(`int$();`float$()))=010b", EqualError.incompatible_types);
    try runTest("(+`a`b!(,1;,2))=0b", .{
        .table = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .boolean_list = &[_]TestValue{
                    .{ .boolean = false },
                } },
                .{ .boolean_list = &[_]TestValue{
                    .{ .boolean = false },
                } },
            } },
        },
    });
    try runTestError("(+`a`b!(,1;,`symbol))=0b", EqualError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))=`boolean$()", EqualError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))=01b", EqualError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))=010b", EqualError.incompatible_types);
}

test "equal int" {
    try runTest("1b=0", .{ .boolean = false });
    try runTest("1b=`int$()", .{ .boolean_list = &[_]TestValue{} });
    try runTest("1b=0 1 2 3 4", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });

    try runTest("1=0", .{ .boolean = false });
    try runTest("1=`int$()", .{ .boolean_list = &[_]TestValue{} });
    try runTest("1=0 1 2 3 4", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });

    try runTest("1f=0", .{ .boolean = false });
    try runTest("1f=`int$()", .{ .boolean_list = &[_]TestValue{} });
    try runTest("1f=0 1 2 3 4", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });

    try runTestError("\"a\"=0", EqualError.incompatible_types);
    try runTestError("\"a\"=`int$()", EqualError.incompatible_types);
    try runTestError("\"a\"=0 1 2 3 4", EqualError.incompatible_types);

    try runTestError("`symbol=0", EqualError.incompatible_types);
    try runTestError("`symbol=`int$()", EqualError.incompatible_types);
    try runTestError("`symbol=0 1 2 3 4", EqualError.incompatible_types);

    try runTest("()=0", .{ .list = &[_]TestValue{} });
    try runTest("(1b;2)=0", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTest("(1b;2;3f)=0", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTest("(1b;2;3f;(0b;1))=0", .{
        .list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = true },
                .{ .boolean = false },
            } },
        },
    });
    try runTestError("(1b;2;3f;`symbol)=0", EqualError.incompatible_types);
    try runTest("()=`int$()", .{ .list = &[_]TestValue{} });
    try runTestError("()=0 1 2", EqualError.length_mismatch);
    try runTestError("(1b;2)=`int$()", EqualError.length_mismatch);
    try runTest("(1b;2)=0 1", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTest("(1b;2;3f)=0 1 2", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTestError("(1b;2;3f)=0 1 2 3", EqualError.length_mismatch);
    try runTestError("(1b;2;3f;\"a\")=0 1 2 3", EqualError.incompatible_types);
    try runTestError("(1b;2;3f;`symbol)=0 1 2 3", EqualError.incompatible_types);

    try runTest("11111b=0", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTestError("11111b=`int$()", EqualError.length_mismatch);
    try runTest("11111b=0 1 2 3 4", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTestError("11111b=0 1 2 3 4 5", EqualError.length_mismatch);

    try runTest("5 4 3 2 1=0", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTestError("5 4 3 2 1=`int$()", EqualError.length_mismatch);
    try runTest("5 4 3 2 1=0 1 2 3 4", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTestError("5 4 3 2 1=0 1 2 3 4 5", EqualError.length_mismatch);

    try runTest("5 4 3 2 1f=0", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTestError("5 4 3 2 1f=`int$()", EqualError.length_mismatch);
    try runTest("5 4 3 2 1f=0 1 2 3 4", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTestError("5 4 3 2 1f=0 1 2 3 4 5", EqualError.length_mismatch);

    try runTestError("\"abcde\"=0", EqualError.incompatible_types);
    try runTestError("\"abcde\"=`int$()", EqualError.incompatible_types);
    try runTestError("\"abcde\"=0 1 2 3 4", EqualError.incompatible_types);
    try runTestError("\"abcde\"=0 1 2 3 4 5", EqualError.incompatible_types);

    try runTestError("`a`b`c`d`e=0", EqualError.incompatible_types);
    try runTestError("`a`b`c`d`e=`int$()", EqualError.incompatible_types);
    try runTestError("`a`b`c`d`e=0 1 2 3 4", EqualError.incompatible_types);
    try runTestError("`a`b`c`d`e=0 1 2 3 4 5", EqualError.incompatible_types);

    try runTest("(()!())=0", .{
        .dictionary = &[_]TestValue{
            .{ .list = &[_]TestValue{} },
            .{ .list = &[_]TestValue{} },
        },
    });
    try runTest("(`a`b!1 2)=0", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = false },
                .{ .boolean = false },
            } },
        },
    });
    try runTestError("(`a`b!1 2)=`int$()", EqualError.length_mismatch);
    try runTest("(`a`b!1 2)=0 1", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = false },
                .{ .boolean = false },
            } },
        },
    });
    try runTestError("(`a`b!1 2)=0 1 2", EqualError.length_mismatch);

    try runTest("(+`a`b!(,1;,2))=0", .{
        .table = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .boolean_list = &[_]TestValue{
                    .{ .boolean = false },
                } },
                .{ .boolean_list = &[_]TestValue{
                    .{ .boolean = false },
                } },
            } },
        },
    });
    try runTestError("(+`a`b!(,1;,`symbol))=0", EqualError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))=`int$()", EqualError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))=0 1", EqualError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))=0 1 2", EqualError.incompatible_types);
}

test "equal float" {
    try runTest("1b=0f", .{ .boolean = false });
    try runTest("1b=`float$()", .{ .boolean_list = &[_]TestValue{} });
    try runTest("1b=0 1 2 3 4f", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });

    try runTest("1=0f", .{ .boolean = false });
    try runTest("1=`float$()", .{ .boolean_list = &[_]TestValue{} });
    try runTest("1=0 1 2 3 4f", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });

    try runTest("1f=0f", .{ .boolean = false });
    try runTest("1f=`float$()", .{ .boolean_list = &[_]TestValue{} });
    try runTest("1f=0 1 2 3 4f", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });

    try runTestError("\"a\"=0f", EqualError.incompatible_types);
    try runTestError("\"a\"=`float$()", EqualError.incompatible_types);
    try runTestError("\"a\"=0 1 2 3 4f", EqualError.incompatible_types);

    try runTestError("`symbol=0f", EqualError.incompatible_types);
    try runTestError("`symbol=`float$()", EqualError.incompatible_types);
    try runTestError("`symbol=0 1 2 3 4f", EqualError.incompatible_types);

    try runTest("()=0f", .{ .list = &[_]TestValue{} });
    try runTest("(1b;2)=0f", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTest("(1b;2;3f)=0f", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTest("(1b;2;3f;(0b;1))=0f", .{
        .list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = true },
                .{ .boolean = false },
            } },
        },
    });
    try runTestError("(1b;2;3f;`symbol)=0f", EqualError.incompatible_types);
    try runTest("()=`float$()", .{ .list = &[_]TestValue{} });
    try runTestError("()=0 1 2f", EqualError.length_mismatch);
    try runTestError("(1b;2)=`float$()", EqualError.length_mismatch);
    try runTest("(1b;2)=0 1f", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTest("(1b;2;3f)=0 1 2f", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTestError("(1b;2;3f)=0 1 2 3f", EqualError.length_mismatch);
    try runTestError("(1b;2;3f;\"a\")=0 1 2 3f", EqualError.incompatible_types);
    try runTestError("(1b;2;3f;`symbol)=0 1 2 3f", EqualError.incompatible_types);

    try runTest("11111b=0f", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTestError("11111b=`float$()", EqualError.length_mismatch);
    try runTest("11111b=0 1 2 3 4f", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTestError("11111b=0 1 2 3 4 5f", EqualError.length_mismatch);

    try runTest("5 4 3 2 1=0f", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTestError("5 4 3 2 1=`float$()", EqualError.length_mismatch);
    try runTest("5 4 3 2 1=0 1 2 3 4f", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTestError("5 4 3 2 1=0 1 2 3 4 5f", EqualError.length_mismatch);

    try runTest("5 4 3 2 1f=0f", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTestError("5 4 3 2 1f=`float$()", EqualError.length_mismatch);
    try runTest("5 4 3 2 1f=0 1 2 3 4f", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTestError("5 4 3 2 1f=0 1 2 3 4 5f", EqualError.length_mismatch);

    try runTestError("\"abcde\"=0f", EqualError.incompatible_types);
    try runTestError("\"abcde\"=`float$()", EqualError.incompatible_types);
    try runTestError("\"abcde\"=0 1 2 3 4f", EqualError.incompatible_types);
    try runTestError("\"abcde\"=0 1 2 3 4 5f", EqualError.incompatible_types);

    try runTestError("`a`b`c`d`e=0f", EqualError.incompatible_types);
    try runTestError("`a`b`c`d`e=`float$()", EqualError.incompatible_types);
    try runTestError("`a`b`c`d`e=0 1 2 3 4f", EqualError.incompatible_types);
    try runTestError("`a`b`c`d`e=0 1 2 3 4 5f", EqualError.incompatible_types);

    try runTest("(()!())=0f", .{
        .dictionary = &[_]TestValue{
            .{ .list = &[_]TestValue{} },
            .{ .list = &[_]TestValue{} },
        },
    });
    try runTest("(`a`b!1 2)=0f", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = false },
                .{ .boolean = false },
            } },
        },
    });
    try runTestError("(`a`b!1 2)=`float$()", EqualError.length_mismatch);
    try runTest("(`a`b!1 2)=0 1f", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = false },
                .{ .boolean = false },
            } },
        },
    });
    try runTestError("(`a`b!1 2)=0 1 2f", EqualError.length_mismatch);

    try runTest("(+`a`b!(,1;,2))=0f", .{
        .table = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .boolean_list = &[_]TestValue{
                    .{ .boolean = false },
                } },
                .{ .boolean_list = &[_]TestValue{
                    .{ .boolean = false },
                } },
            } },
        },
    });
    try runTestError("(+`a`b!(,1;,`symbol))=0f", EqualError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))=`float$()", EqualError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))=0 1f", EqualError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))=0 1 2f", EqualError.incompatible_types);
}

test "equal char" {
    try runTestError("1b=\"a\"", EqualError.incompatible_types);
    try runTestError("1b=\"\"", EqualError.incompatible_types);
    try runTestError("1b=\"abcde\"", EqualError.incompatible_types);

    try runTestError("1=\"a\"", EqualError.incompatible_types);
    try runTestError("1=\"\"", EqualError.incompatible_types);
    try runTestError("1=\"abcde\"", EqualError.incompatible_types);

    try runTestError("1f=\"a\"", EqualError.incompatible_types);
    try runTestError("1f=\"\"", EqualError.incompatible_types);
    try runTestError("1f=\"abcde\"", EqualError.incompatible_types);

    try runTestError("\"1\"=\"a\"", EqualError.incompatible_types);
    try runTestError("\"1\"=\"\"", EqualError.incompatible_types);
    try runTestError("\"1\"=\"abcde\"", EqualError.incompatible_types);

    try runTestError("`symbol=\"a\"", EqualError.incompatible_types);
    try runTestError("`symbol=\"\"", EqualError.incompatible_types);
    try runTestError("`symbol=\"abcde\"", EqualError.incompatible_types);

    try runTestError("()=\"a\"", EqualError.incompatible_types);
    try runTestError("()=\"\"", EqualError.incompatible_types);
    try runTestError("()=\"abcde\"", EqualError.incompatible_types);

    try runTestError("10011b=\"a\"", EqualError.incompatible_types);
    try runTestError("10011b=\"\"", EqualError.incompatible_types);
    try runTestError("10011b=\"abcde\"", EqualError.incompatible_types);

    try runTestError("5 4 3 2 1=\"a\"", EqualError.incompatible_types);
    try runTestError("5 4 3 2 1=\"\"", EqualError.incompatible_types);
    try runTestError("5 4 3 2 1=\"abcde\"", EqualError.incompatible_types);

    try runTestError("5 4 3 2 1f=\"a\"", EqualError.incompatible_types);
    try runTestError("5 4 3 2 1f=\"\"", EqualError.incompatible_types);
    try runTestError("5 4 3 2 1f=\"abcde\"", EqualError.incompatible_types);

    try runTestError("\"54321\"=\"a\"", EqualError.incompatible_types);
    try runTestError("\"54321\"=\"\"", EqualError.incompatible_types);
    try runTestError("\"54321\"=\"abcde\"", EqualError.incompatible_types);

    try runTestError("`a`b`c`d`e=\"a\"", EqualError.incompatible_types);
    try runTestError("`a`b`c`d`e=\"\"", EqualError.incompatible_types);
    try runTestError("`a`b`c`d`e=\"abcde\"", EqualError.incompatible_types);

    try runTestError("(`a`b!1 2)=\"a\"", EqualError.incompatible_types);
    try runTestError("(`a`b!1 2)=\"\"", EqualError.incompatible_types);
    try runTestError("(`a`b!1 2)=\"ab\"", EqualError.incompatible_types);

    try runTestError("(+`a`b!(,1;,2))=\"a\"", EqualError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))=\"\"", EqualError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))=\"ab\"", EqualError.incompatible_types);
}

test "equal symbol" {
    try runTestError("1b=`symbol", EqualError.incompatible_types);
    try runTestError("1b=`$()", EqualError.incompatible_types);
    try runTestError("1b=`a`b`c`d`e", EqualError.incompatible_types);

    try runTestError("1=`symbol", EqualError.incompatible_types);
    try runTestError("1=`$()", EqualError.incompatible_types);
    try runTestError("1=`a`b`c`d`e", EqualError.incompatible_types);

    try runTestError("1f=`symbol", EqualError.incompatible_types);
    try runTestError("1f=`$()", EqualError.incompatible_types);
    try runTestError("1f=`a`b`c`d`e", EqualError.incompatible_types);

    try runTestError("\"a\"=`symbol", EqualError.incompatible_types);
    try runTestError("\"a\"=`$()", EqualError.incompatible_types);
    try runTestError("\"a\"=`a`b`c`d`e", EqualError.incompatible_types);

    try runTestError("`symbol=`a", EqualError.incompatible_types);
    try runTestError("`symbol=`$()", EqualError.incompatible_types);
    try runTestError("`symbol=`a`b`c`d`e", EqualError.incompatible_types);

    try runTestError("()=`symbol", EqualError.incompatible_types);
    try runTestError("()=`$()", EqualError.incompatible_types);
    try runTestError("()=`a`b`c`d`e", EqualError.incompatible_types);

    try runTestError("10011b=`symbol", EqualError.incompatible_types);
    try runTestError("10011b=`$()", EqualError.incompatible_types);
    try runTestError("10011b=`a`b`c`d`e", EqualError.incompatible_types);

    try runTestError("5 4 3 2 1=`symbol", EqualError.incompatible_types);
    try runTestError("5 4 3 2 1=`$()", EqualError.incompatible_types);
    try runTestError("5 4 3 2 1=`a`b`c`d`e", EqualError.incompatible_types);

    try runTestError("5 4 3 2 1f=`symbol", EqualError.incompatible_types);
    try runTestError("5 4 3 2 1f=`$()", EqualError.incompatible_types);
    try runTestError("5 4 3 2 1f=`a`b`c`d`e", EqualError.incompatible_types);

    try runTestError("\"54321\"=`symbol", EqualError.incompatible_types);
    try runTestError("\"54321\"=`$()", EqualError.incompatible_types);
    try runTestError("\"54321\"=`a`b`c`d`e", EqualError.incompatible_types);

    try runTestError("`5`4`3`2`1=`symbol", EqualError.incompatible_types);
    try runTestError("`5`4`3`2`1=`$()", EqualError.incompatible_types);
    try runTestError("`5`4`3`2`1=`a`b`c`d`e", EqualError.incompatible_types);

    try runTestError("(`a`b!1 2)=`symbol", EqualError.incompatible_types);
    try runTestError("(`a`b!1 2)=`$()", EqualError.incompatible_types);
    try runTestError("(`a`b!1 2)=`a`b", EqualError.incompatible_types);

    try runTestError("(+`a`b!(,1;,2))=`symbol", EqualError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))=`$()", EqualError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))=`a`b", EqualError.incompatible_types);
}

test "equal list" {
    if (true) return error.SkipZigTest;
    try runTest("1b=()", .{ .list = &[_]TestValue{} });
    try runTest("1b=(0b;1;0N;0W;-0W)", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTest("1b=(0b;1;0N;0W;-0W;1f;0n;0w;-0w)", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTestError("1b=(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", EqualError.incompatible_types);
    try runTestError("1b=(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", EqualError.incompatible_types);

    try runTest("1=()", .{ .list = &[_]TestValue{} });
    try runTest("1=(0b;1;0N;0W;-0W)", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
        },
    });
    try runTest("1=(0b;1;0N;0W;-0W;1f;0n;0w;-0w)", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
        },
    });
    try runTestError("1=(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", EqualError.incompatible_types);
    try runTestError("1=(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", EqualError.incompatible_types);

    try runTest("1f=()", .{ .list = &[_]TestValue{} });
    try runTest("1f=(0b;1;0N;0W;-0W;1f;0n;0w;-0w)", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = true },
            .{ .boolean = false },
        },
    });
    try runTestError("1f=(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", EqualError.incompatible_types);
    try runTestError("1f=(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", EqualError.incompatible_types);

    try runTestError("\"a\"=()", EqualError.incompatible_types);

    try runTestError("`symbol=()", EqualError.incompatible_types);

    try runTest("()=()", .{ .list = &[_]TestValue{} });
    try runTestError("(0N;0n)=()", EqualError.length_mismatch);
    try runTestError("()=(0N;0n)", EqualError.length_mismatch);
    try runTest("(1b;2)=(1b;2)", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTest("(1b;2f)=(2f;1b)", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = true },
            .{ .boolean = false },
        },
    });
    try runTest("(2;3f)=(2;3f)", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTest("(1b;(2;3f))=(0N;(0n;0N))", .{
        .list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = false },
                .{ .boolean = false },
            } },
        },
    });
    try runTestError("(0b;1;2;3;4;5;6;7;8;9)=(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", EqualError.incompatible_types);
    try runTestError("(0b;1;2;3;4;5;6;7;8;9)=(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", EqualError.incompatible_types);

    try runTestError("010b=()", EqualError.length_mismatch);
    try runTest("01b=(0b;0N)", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTest("010b=(0b;0N;0n)", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTestError("0101010101b=(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", EqualError.incompatible_types);
    try runTestError("0101010101b=(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", EqualError.incompatible_types);

    try runTestError("0 1 2=()", EqualError.length_mismatch);
    try runTest("0 1=(0b;0N)", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTest("0 1 2=(0b;0N;0n)", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTestError("0 1 2 3 4 5 6 7 8 9=(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", EqualError.incompatible_types);
    try runTestError("0 1 2 3 4 5 6 7 8 9=(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", EqualError.incompatible_types);

    try runTestError("0 1 2f=()", EqualError.length_mismatch);
    try runTest("0 1 2f=(0b;0N;0n)", .{
        .boolean_list = &[_]TestValue{
            .{ .boolean = false },
            .{ .boolean = false },
            .{ .boolean = false },
        },
    });
    try runTestError("0 1 2 3 4 5 6 7 8 9f=(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", EqualError.incompatible_types);
    try runTestError("0 1 2 3 4 5 6 7 8 9f=(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", EqualError.incompatible_types);

    try runTestError("\"abcde\"=()", EqualError.incompatible_types);

    try runTestError("`a`b`c`d`e=()", EqualError.incompatible_types);

    try runTestError("(`a`b!1 2)=()", EqualError.length_mismatch);
    try runTest("(`a`b!1 2)=(1;2f)", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = false },
                .{ .boolean = false },
            } },
        },
    });
    try runTestError("(`a`b!1 2)=(0b;1;2f)", EqualError.length_mismatch);

    try runTestError("(+`a`b!(,1;,2))=()", EqualError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))=(1;2f)", EqualError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))=(0b;1;2f)", EqualError.incompatible_types);
}

test "equal dictionary" {
    if (true) return error.SkipZigTest;
    try runTest("1b=()!()", .{
        .dictionary = &[_]TestValue{
            .{ .list = &[_]TestValue{} },
            .{ .list = &[_]TestValue{} },
        },
    });
    try runTest("1b=`a`b!1 2", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = false },
                .{ .boolean = true },
            } },
        },
    });

    try runTest("1=()!()", .{
        .dictionary = &[_]TestValue{
            .{ .list = &[_]TestValue{} },
            .{ .list = &[_]TestValue{} },
        },
    });
    try runTest("1=`a`b!1 2", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = false },
                .{ .boolean = true },
            } },
        },
    });

    try runTest("1f=()!()", .{
        .dictionary = &[_]TestValue{
            .{ .list = &[_]TestValue{} },
            .{ .list = &[_]TestValue{} },
        },
    });
    try runTest("1f=`a`b!1 2", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = false },
                .{ .boolean = true },
            } },
        },
    });

    try runTestError("\"a\"=`a`b!1 2", EqualError.incompatible_types);

    try runTestError("`symbol=`a`b!1 2", EqualError.incompatible_types);

    try runTest("()=()!()", .{
        .dictionary = &[_]TestValue{
            .{ .list = &[_]TestValue{} },
            .{ .list = &[_]TestValue{} },
        },
    });
    try runTestError("()=`a`b!1 2", EqualError.length_mismatch);
    try runTest("(1;2f)=`a`b!1 2", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = false },
                .{ .boolean = false },
            } },
        },
    });
    try runTestError("(0b;1;2f)=`a`b!1 2", EqualError.length_mismatch);

    try runTest("(`boolean$())=()!()", .{
        .dictionary = &[_]TestValue{
            .{ .list = &[_]TestValue{} },
            .{ .list = &[_]TestValue{} },
        },
    });
    try runTestError("(`boolean$())=`a`b!1 2", EqualError.length_mismatch);
    try runTest("10b=`a`b!1 2", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = false },
                .{ .boolean = true },
            } },
        },
    });
    try runTestError("101b=`a`b!1 2", EqualError.length_mismatch);

    try runTest("(`int$())=()!()", .{
        .dictionary = &[_]TestValue{
            .{ .list = &[_]TestValue{} },
            .{ .list = &[_]TestValue{} },
        },
    });
    try runTestError("(`int$())=`a`b!1 2", EqualError.length_mismatch);
    try runTest("1 2=`a`b!1 2", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = false },
                .{ .boolean = false },
            } },
        },
    });
    try runTestError("1 2 3=`a`b!1 2", EqualError.length_mismatch);

    try runTest("(`float$())=()!()", .{
        .dictionary = &[_]TestValue{
            .{ .list = &[_]TestValue{} },
            .{ .list = &[_]TestValue{} },
        },
    });
    try runTestError("(`float$())=`a`b!1 2", EqualError.length_mismatch);
    try runTest("1 2f=`a`b!1 2", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = false },
                .{ .boolean = false },
            } },
        },
    });
    try runTestError("1 2 3f=`a`b!1 2", EqualError.length_mismatch);

    try runTestError("\"\"=`a`b!1 2", EqualError.incompatible_types);
    try runTestError("\"12\"=`a`b!1 2", EqualError.incompatible_types);
    try runTestError("\"123\"=`a`b!1 2", EqualError.incompatible_types);

    try runTestError("(`$())=`a`b!1 2", EqualError.incompatible_types);
    try runTestError("`5`4=`a`b!1 2", EqualError.incompatible_types);
    try runTestError("`5`4`3=`a`b!1 2", EqualError.incompatible_types);

    try runTest("(()!())=()!()", .{
        .dictionary = &[_]TestValue{
            .{ .list = &[_]TestValue{} },
            .{ .list = &[_]TestValue{} },
        },
    });
    try runTest("(()!())=`a`b!1 2", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .list = &[_]TestValue{} },
                .{ .list = &[_]TestValue{} },
            } },
        },
    });
    try runTest("(`a`b!1 2)=()!()", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .list = &[_]TestValue{} },
                .{ .list = &[_]TestValue{} },
            } },
        },
    });
    try runTest("(`a`b!1 2)=`a`b!1 2", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = false },
                .{ .boolean = false },
            } },
        },
    });
    try runTest("(`b`a!1 2)=`a`b!1 2", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "b" },
                .{ .symbol = "a" },
            } },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = true },
                .{ .boolean = false },
            } },
        },
    });
    try runTest("(`a`b!1 2)=`b`a!1 2", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = true },
                .{ .boolean = false },
            } },
        },
    });
    try runTest("(`a`b!1 2)=`c`d!1 2", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
                .{ .symbol = "c" },
                .{ .symbol = "d" },
            } },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = false },
                .{ .boolean = false },
                .{ .boolean = true },
                .{ .boolean = true },
            } },
        },
    });
    try runTest("(`a`b!0N 0W)=`c`d!0N 0W", .{
        .dictionary = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
                .{ .symbol = "c" },
                .{ .symbol = "d" },
            } },
            .{ .boolean_list = &[_]TestValue{
                .{ .boolean = false },
                .{ .boolean = false },
                .{ .boolean = false },
                .{ .boolean = true },
            } },
        },
    });
    try runTestError("(`a`b!1 2)=`a`b!(1;\"2\")", EqualError.incompatible_types);

    try runTestError("(+`a`b!(,1;,2))=`a`b!1 2", EqualError.incompatible_types);
}

test "equal table" {
    if (true) return error.SkipZigTest;
    try runTest("1b=+`a`b!(,1;,2)", .{
        .table = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .boolean_list = &[_]TestValue{
                    .{ .boolean = false },
                } },
                .{ .boolean_list = &[_]TestValue{
                    .{ .boolean = true },
                } },
            } },
        },
    });

    try runTest("1=+`a`b!(,1;,2)", .{
        .table = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .boolean_list = &[_]TestValue{
                    .{ .boolean = false },
                } },
                .{ .boolean_list = &[_]TestValue{
                    .{ .boolean = true },
                } },
            } },
        },
    });

    try runTest("1f=+`a`b!(,1;,2)", .{
        .table = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .boolean_list = &[_]TestValue{
                    .{ .boolean = false },
                } },
                .{ .boolean_list = &[_]TestValue{
                    .{ .boolean = true },
                } },
            } },
        },
    });

    try runTestError("\"a\"=+`a`b!(,1;,2)", EqualError.incompatible_types);

    try runTestError("`symbol=+`a`b!(,1;,2)", EqualError.incompatible_types);

    try runTestError("()=+`a`b!(,1;,2)", EqualError.incompatible_types);
    try runTestError("(1;2f)=+`a`b!(,1;,2)", EqualError.incompatible_types);
    try runTestError("(0b;1;2f)=+`a`b!(,1;,2)", EqualError.incompatible_types);

    try runTestError("(`boolean$())=+`a`b!(,1;,2)", EqualError.incompatible_types);
    try runTestError("10b=+`a`b!(,1;,2)", EqualError.incompatible_types);
    try runTestError("101b=+`a`b!(,1;,2)", EqualError.incompatible_types);

    try runTestError("(`int$())=+`a`b!(,1;,2)", EqualError.incompatible_types);
    try runTestError("1 2=+`a`b!(,1;,2)", EqualError.incompatible_types);
    try runTestError("1 2 3=+`a`b!(,1;,2)", EqualError.incompatible_types);

    try runTestError("(`float$())=+`a`b!(,1;,2)", EqualError.incompatible_types);
    try runTestError("1 2f=+`a`b!(,1;,2)", EqualError.incompatible_types);
    try runTestError("1 2 3f=+`a`b!(,1;,2)", EqualError.incompatible_types);

    try runTestError("\"\"=+`a`b!(,1;,2)", EqualError.incompatible_types);
    try runTestError("\"12\"=+`a`b!(,1;,2)", EqualError.incompatible_types);
    try runTestError("\"123\"=+`a`b!(,1;,2)", EqualError.incompatible_types);

    try runTestError("(`$())=+`a`b!(,1;,2)", EqualError.incompatible_types);
    try runTestError("`5`4=+`a`b!(,1;,2)", EqualError.incompatible_types);
    try runTestError("`5`4`3=+`a`b!(,1;,2)", EqualError.incompatible_types);

    try runTestError("(`a`b!1 2)=+`a`b!(,1;,2)", EqualError.incompatible_types);

    try runTest("(+`a`b!(,1;,2))=+`a`b!(,1;,2)", .{
        .table = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .boolean_list = &[_]TestValue{
                    .{ .boolean = false },
                } },
                .{ .boolean_list = &[_]TestValue{
                    .{ .boolean = false },
                } },
            } },
        },
    });
    try runTest("(+`b`a!(,1;,2))=+`a`b!(,1;,2)", .{
        .table = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "b" },
                .{ .symbol = "a" },
            } },
            .{ .list = &[_]TestValue{
                .{ .boolean_list = &[_]TestValue{
                    .{ .boolean = true },
                } },
                .{ .boolean_list = &[_]TestValue{
                    .{ .boolean = false },
                } },
            } },
        },
    });
    try runTest("(+`a`b!(,1;,2))=+`b`a!(,1;,2)", .{
        .table = &[_]TestValue{
            .{ .symbol_list = &[_]TestValue{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .list = &[_]TestValue{
                .{ .boolean_list = &[_]TestValue{
                    .{ .boolean = true },
                } },
                .{ .boolean_list = &[_]TestValue{
                    .{ .boolean = false },
                } },
            } },
        },
    });
    try runTestError("(+`a`b!(,1;,2))=+`a`b!(,1;,`symbol)", EqualError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))=+`a`b!(1 1;2 2)", EqualError.length_mismatch);
    try runTestError("(+`a`b!(,1;,2))=+`a`b`c!(,1;,2;,3)", EqualError.length_mismatch);
    try runTestError("(+`a`b`c!(,1;,2;,3))=+`a`b!(,1;,2)", EqualError.length_mismatch);
}
