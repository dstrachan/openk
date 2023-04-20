const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;
const runTestError = vm_mod.runTestError;

const DictError = @import("../../verbs/dict.zig").DictError;

test "dict" {
    try runTestError("0b!0b", DictError.incompatible_types);
    try runTestError("0b!`boolean$()", DictError.incompatible_types);
    try runTestError("0b!01b", DictError.incompatible_types);
    try runTestError("(`boolean$())!0b", DictError.incompatible_types);
    try runTest("(`boolean$())!`boolean$()", .{
        .dictionary = &.{
            .{ .boolean_list = &.{} },
            .{ .boolean_list = &.{} },
        },
    });
    try runTestError("(`boolean$())!01b", DictError.length_mismatch);
    try runTestError("01b!0b", DictError.incompatible_types);
    try runTestError("01b!`boolean$()", DictError.length_mismatch);
    try runTest("01b!01b", .{
        .dictionary = &.{
            .{ .boolean_list = &.{
                .{ .boolean = false },
                .{ .boolean = true },
            } },
            .{ .boolean_list = &.{
                .{ .boolean = false },
                .{ .boolean = true },
            } },
        },
    });

    try runTestError("0!0", DictError.incompatible_types);
    try runTestError("0!`int$()", DictError.incompatible_types);
    try runTestError("0!0 1", DictError.incompatible_types);
    try runTestError("(`int$())!0", DictError.incompatible_types);
    try runTest("(`int$())!`int$()", .{
        .dictionary = &.{
            .{ .int_list = &.{} },
            .{ .int_list = &.{} },
        },
    });
    try runTestError("(`int$())!0 1", DictError.length_mismatch);
    try runTestError("0 1!0", DictError.incompatible_types);
    try runTestError("0 1!`int$()", DictError.length_mismatch);
    try runTest("0 1!0 1", .{
        .dictionary = &.{
            .{ .int_list = &.{
                .{ .int = 0 },
                .{ .int = 1 },
            } },
            .{ .int_list = &.{
                .{ .int = 0 },
                .{ .int = 1 },
            } },
        },
    });

    try runTestError("0f!0f", DictError.incompatible_types);
    try runTestError("0f!`float$()", DictError.incompatible_types);
    try runTestError("0f!0 1f", DictError.incompatible_types);
    try runTestError("(`float$())!0f", DictError.incompatible_types);
    try runTest("(`float$())!`float$()", .{
        .dictionary = &.{
            .{ .float_list = &.{} },
            .{ .float_list = &.{} },
        },
    });
    try runTestError("(`float$())!0 1f", DictError.length_mismatch);
    try runTestError("0 1f!0f", DictError.incompatible_types);
    try runTestError("0 1f!`float$()", DictError.length_mismatch);
    try runTest("0 1f!0 1f", .{
        .dictionary = &.{
            .{ .float_list = &.{
                .{ .float = 0 },
                .{ .float = 1 },
            } },
            .{ .float_list = &.{
                .{ .float = 0 },
                .{ .float = 1 },
            } },
        },
    });

    try runTestError("\"a\"!\"a\"", DictError.incompatible_types);
    try runTestError("\"a\"!\"\"", DictError.incompatible_types);
    try runTestError("\"a\"!\"ab\"", DictError.incompatible_types);
    try runTestError("\"\"!\"a\"", DictError.incompatible_types);
    try runTest("\"\"!\"\"", .{
        .dictionary = &.{
            .{ .char_list = &.{} },
            .{ .char_list = &.{} },
        },
    });
    try runTestError("\"\"!\"ab\"", DictError.length_mismatch);
    try runTestError("\"ab\"!\"a\"", DictError.incompatible_types);
    try runTestError("\"ab\"!\"\"", DictError.length_mismatch);
    try runTest("\"ab\"!\"ab\"", .{
        .dictionary = &.{
            .{ .char_list = &.{
                .{ .char = 'a' },
                .{ .char = 'b' },
            } },
            .{ .char_list = &.{
                .{ .char = 'a' },
                .{ .char = 'b' },
            } },
        },
    });

    try runTestError("`symbol!`symbol", DictError.incompatible_types);
    try runTestError("`symbol!`$()", DictError.incompatible_types);
    try runTestError("`symbol!`a`b", DictError.incompatible_types);
    try runTestError("(`$())!`symbol", DictError.incompatible_types);
    try runTest("(`$())!`$()", .{
        .dictionary = &.{
            .{ .symbol_list = &.{} },
            .{ .symbol_list = &.{} },
        },
    });
    try runTestError("(`$())!`a`b", DictError.length_mismatch);
    try runTestError("`a`b!`symbol", DictError.incompatible_types);
    try runTestError("`a`b!`$()", DictError.length_mismatch);
    try runTest("`a`b!`a`b", .{
        .dictionary = &.{
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
        },
    });

    try runTest("()!()", .{
        .dictionary = &.{
            .{ .list = &.{} },
            .{ .list = &.{} },
        },
    });
    try runTest("(0b;1)!()", .{
        .dictionary = &.{
            .{ .list = &.{
                .{ .boolean = false },
                .{ .int = 1 },
            } },
            .{ .list = &.{
                .{ .list = &.{} },
                .{ .list = &.{} },
            } },
        },
    });
    try runTestError("()!(0b;1)", DictError.length_mismatch);
    try runTest("(0b;1)!(0b;1)", .{
        .dictionary = &.{
            .{ .list = &.{
                .{ .boolean = false },
                .{ .int = 1 },
            } },
            .{ .list = &.{
                .{ .boolean = false },
                .{ .int = 1 },
            } },
        },
    });

    try runTestError("(`a`b!())!()", DictError.incompatible_types);
}

test "keyed table" {
    try runTestError("(+`a`b!())!0b", DictError.incompatible_types);
    try runTest("(+`a`b!())!`boolean$()", .{
        .dictionary = &.{
            .{ .table = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .list = &.{
                    .{ .list = &.{} },
                    .{ .list = &.{} },
                } },
            } },
            .{ .boolean_list = &.{} },
        },
    });
    try runTestError("(+`a`b!())!01b", DictError.length_mismatch);
    try runTestError("(+`a`b!(,1;,2))!0b", DictError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))!`boolean$()", DictError.length_mismatch);
    try runTestError("(+`a`b!(,1;,2))!01b", DictError.length_mismatch);
    try runTestError("(+`a`b!(1 2;3 4))!0b", DictError.incompatible_types);
    try runTestError("(+`a`b!(1 2;3 4))!`boolean$()", DictError.length_mismatch);
    try runTest("(+`a`b!(1 2;3 4))!01b", .{
        .dictionary = &.{
            .{ .table = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .list = &.{
                    .{ .int_list = &.{
                        .{ .int = 1 },
                        .{ .int = 2 },
                    } },
                    .{ .int_list = &.{
                        .{ .int = 3 },
                        .{ .int = 4 },
                    } },
                } },
            } },
            .{ .boolean_list = &.{
                .{ .boolean = false },
                .{ .boolean = true },
            } },
        },
    });

    try runTestError("(+`a`b!())!0", DictError.incompatible_types);
    try runTest("(+`a`b!())!`int$()", .{
        .dictionary = &.{
            .{ .table = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .list = &.{
                    .{ .list = &.{} },
                    .{ .list = &.{} },
                } },
            } },
            .{ .int_list = &.{} },
        },
    });
    try runTestError("(+`a`b!())!0 1", DictError.length_mismatch);
    try runTestError("(+`a`b!(,1;,2))!0", DictError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))!`int$()", DictError.length_mismatch);
    try runTestError("(+`a`b!(,1;,2))!0 1", DictError.length_mismatch);
    try runTestError("(+`a`b!(1 2;3 4))!0", DictError.incompatible_types);
    try runTestError("(+`a`b!(1 2;3 4))!`int$()", DictError.length_mismatch);
    try runTest("(+`a`b!(1 2;3 4))!0 1", .{
        .dictionary = &.{
            .{ .table = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .list = &.{
                    .{ .int_list = &.{
                        .{ .int = 1 },
                        .{ .int = 2 },
                    } },
                    .{ .int_list = &.{
                        .{ .int = 3 },
                        .{ .int = 4 },
                    } },
                } },
            } },
            .{ .int_list = &.{
                .{ .int = 0 },
                .{ .int = 1 },
            } },
        },
    });

    try runTestError("(+`a`b!())!0f", DictError.incompatible_types);
    try runTest("(+`a`b!())!`float$()", .{
        .dictionary = &.{
            .{ .table = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .list = &.{
                    .{ .list = &.{} },
                    .{ .list = &.{} },
                } },
            } },
            .{ .float_list = &.{} },
        },
    });
    try runTestError("(+`a`b!())!0 1f", DictError.length_mismatch);
    try runTestError("(+`a`b!(,1;,2))!0f", DictError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))!`float$()", DictError.length_mismatch);
    try runTestError("(+`a`b!(,1;,2))!0 1f", DictError.length_mismatch);
    try runTestError("(+`a`b!(1 2;3 4))!0f", DictError.incompatible_types);
    try runTestError("(+`a`b!(1 2;3 4))!`float$()", DictError.length_mismatch);
    try runTest("(+`a`b!(1 2;3 4))!0 1f", .{
        .dictionary = &.{
            .{ .table = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .list = &.{
                    .{ .int_list = &.{
                        .{ .int = 1 },
                        .{ .int = 2 },
                    } },
                    .{ .int_list = &.{
                        .{ .int = 3 },
                        .{ .int = 4 },
                    } },
                } },
            } },
            .{ .float_list = &.{
                .{ .float = 0 },
                .{ .float = 1 },
            } },
        },
    });

    try runTestError("(+`a`b!())!\"a\"", DictError.incompatible_types);
    try runTest("(+`a`b!())!\"\"", .{
        .dictionary = &.{
            .{ .table = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .list = &.{
                    .{ .list = &.{} },
                    .{ .list = &.{} },
                } },
            } },
            .{ .char_list = &.{} },
        },
    });
    try runTestError("(+`a`b!())!\"ab\"", DictError.length_mismatch);
    try runTestError("(+`a`b!(,1;,2))!\"a\"", DictError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))!\"\"", DictError.length_mismatch);
    try runTestError("(+`a`b!(,1;,2))!\"ab\"", DictError.length_mismatch);
    try runTestError("(+`a`b!(1 2;3 4))!\"a\"", DictError.incompatible_types);
    try runTestError("(+`a`b!(1 2;3 4))!\"\"", DictError.length_mismatch);
    try runTest("(+`a`b!(1 2;3 4))!\"ab\"", .{
        .dictionary = &.{
            .{ .table = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .list = &.{
                    .{ .int_list = &.{
                        .{ .int = 1 },
                        .{ .int = 2 },
                    } },
                    .{ .int_list = &.{
                        .{ .int = 3 },
                        .{ .int = 4 },
                    } },
                } },
            } },
            .{ .char_list = &.{
                .{ .char = 'a' },
                .{ .char = 'b' },
            } },
        },
    });

    try runTestError("(+`a`b!())!`symbol", DictError.incompatible_types);
    try runTest("(+`a`b!())!`$()", .{
        .dictionary = &.{
            .{ .table = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .list = &.{
                    .{ .list = &.{} },
                    .{ .list = &.{} },
                } },
            } },
            .{ .symbol_list = &.{} },
        },
    });
    try runTestError("(+`a`b!())!`a`b", DictError.length_mismatch);
    try runTestError("(+`a`b!(,1;,2))!`symbol", DictError.incompatible_types);
    try runTestError("(+`a`b!(,1;,2))!`$()", DictError.length_mismatch);
    try runTestError("(+`a`b!(,1;,2))!`a`b", DictError.length_mismatch);
    try runTestError("(+`a`b!(1 2;3 4))!`symbol", DictError.incompatible_types);
    try runTestError("(+`a`b!(1 2;3 4))!`$()", DictError.length_mismatch);
    try runTest("(+`a`b!(1 2;3 4))!`a`b", .{
        .dictionary = &.{
            .{ .table = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .list = &.{
                    .{ .int_list = &.{
                        .{ .int = 1 },
                        .{ .int = 2 },
                    } },
                    .{ .int_list = &.{
                        .{ .int = 3 },
                        .{ .int = 4 },
                    } },
                } },
            } },
            .{ .symbol_list = &.{
                .{ .symbol = "a" },
                .{ .symbol = "b" },
            } },
        },
    });

    try runTest("(+`a`b!())!()", .{
        .dictionary = &.{
            .{ .table = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .list = &.{
                    .{ .list = &.{} },
                    .{ .list = &.{} },
                } },
            } },
            .{ .list = &.{} },
        },
    });
    try runTestError("(+`a`b!())!(0b;1)", DictError.length_mismatch);
    try runTest("(+`a`b!(,1;,2))!()", .{
        .dictionary = &.{
            .{ .table = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .list = &.{
                    .{ .int_list = &.{
                        .{ .int = 1 },
                    } },
                    .{ .int_list = &.{
                        .{ .int = 2 },
                    } },
                } },
            } },
            .{ .list = &.{
                .{ .list = &.{} },
            } },
        },
    });
    try runTestError("(+`a`b!(,1;,2))!(0b;1)", DictError.length_mismatch);
    try runTest("(+`a`b!(1 2;3 4))!()", .{
        .dictionary = &.{
            .{ .table = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .list = &.{
                    .{ .int_list = &.{
                        .{ .int = 1 },
                        .{ .int = 2 },
                    } },
                    .{ .int_list = &.{
                        .{ .int = 3 },
                        .{ .int = 4 },
                    } },
                } },
            } },
            .{ .list = &.{
                .{ .list = &.{} },
                .{ .list = &.{} },
            } },
        },
    });
    try runTest("(+`a`b!(1 2;3 4))!(0b;1)", .{
        .dictionary = &.{
            .{ .table = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .list = &.{
                    .{ .int_list = &.{
                        .{ .int = 1 },
                        .{ .int = 2 },
                    } },
                    .{ .int_list = &.{
                        .{ .int = 3 },
                        .{ .int = 4 },
                    } },
                } },
            } },
            .{ .list = &.{
                .{ .boolean = false },
                .{ .int = 1 },
            } },
        },
    });

    try runTestError("(+`a`b!())!()!()", DictError.incompatible_types);

    if (true) return error.SkipZigTest;
    try runTest("(+`a`b!())!+`a`b!()", .{
        .dictionary = &.{
            .{ .table = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .list = &.{
                    .{ .list = &.{} },
                    .{ .list = &.{} },
                } },
            } },
            .{ .table = &.{
                .{ .symbol_list = &.{
                    .{ .symbol = "a" },
                    .{ .symbol = "b" },
                } },
                .{ .list = &.{
                    .{ .list = &.{} },
                    .{ .list = &.{} },
                } },
            } },
        },
    });
}
