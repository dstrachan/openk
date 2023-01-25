const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;
const runTestError = vm_mod.runTestError;
const TestValue = vm_mod.TestValue;

const AddError = @import("../../verbs/add.zig").AddError;

test "add boolean" {
    try runTest("1b+0b", .{ .int = 1 });
    try runTest("1b+00000b", .{
        .int_list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 1 },
        },
    });

    try runTest("1+0b", .{ .int = 1 });
    try runTest("1+00000b", .{
        .int_list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 1 },
        },
    });

    try runTest("1f+0b", .{ .float = 1 });
    try runTest("1f+00000b", .{
        .float_list = &[_]TestValue{
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .float = 1 },
            .{ .float = 1 },
        },
    });

    try runTestError("\"a\"+0b", AddError.incompatible_types);
    try runTestError("\"a\"+00000b", AddError.incompatible_types);

    try runTestError("`symbol+0b", AddError.incompatible_types);
    try runTestError("`symbol+00000b", AddError.incompatible_types);

    try runTest("()+0b", .{ .list = &[_]TestValue{} });
    try runTest("(1b;2)+0b", .{
        .int_list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 2 },
        },
    });
    try runTest("(1b;2;3f)+0b", .{
        .list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 2 },
            .{ .float = 3 },
        },
    });
    try runTestError("(1b;2;3f;`symbol)+0b", AddError.incompatible_types);
    try runTestError("()+010b", AddError.length_mismatch);
    try runTest("(1b;2;3f)+010b", .{
        .list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 3 },
            .{ .float = 3 },
        },
    });
    try runTestError("(1b;2;3f)+0101b", AddError.length_mismatch);
    try runTestError("(1b;2;3f;`symbol)+0101b", AddError.incompatible_types);

    try runTest("11111b+0b", .{
        .int_list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 1 },
        },
    });
    try runTest("11111b+00000b", .{
        .int_list = &[_]TestValue{
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 1 },
            .{ .int = 1 },
        },
    });
    try runTestError("11111b+000000b", AddError.length_mismatch);

    try runTest("5 4 3 2 1+0b", .{
        .int_list = &[_]TestValue{
            .{ .int = 5 },
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = 2 },
            .{ .int = 1 },
        },
    });
    try runTest("5 4 3 2 1+00000b", .{
        .int_list = &[_]TestValue{
            .{ .int = 5 },
            .{ .int = 4 },
            .{ .int = 3 },
            .{ .int = 2 },
            .{ .int = 1 },
        },
    });
    try runTestError("5 4 3 2 1+000000b", AddError.length_mismatch);

    try runTest("5 4 3 2 1f+0b", .{
        .float_list = &[_]TestValue{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
        },
    });
    try runTest("5 4 3 2 1f+00000b", .{
        .float_list = &[_]TestValue{
            .{ .float = 5 },
            .{ .float = 4 },
            .{ .float = 3 },
            .{ .float = 2 },
            .{ .float = 1 },
        },
    });
    try runTestError("5 4 3 2 1f+000000b", AddError.length_mismatch);

    try runTestError("\"abcde\"+0b", AddError.incompatible_types);
    try runTestError("\"abcde\"+00000b", AddError.incompatible_types);
    try runTestError("\"abcde\"+000000b", AddError.incompatible_types);

    try runTestError("`a`b`c`d`e+0b", AddError.incompatible_types);
    try runTestError("`a`b`c`d`e+00000b", AddError.incompatible_types);
    try runTestError("`a`b`c`d`e+000000b", AddError.incompatible_types);
}

test "add int" {
    return error.SkipZigTest;
    // try runTest("1b+0", .{ .int = 0 });
    // try runTest("1b+0N", .{ .int = 1 });
    // try runTest("1b+1 2 3 4 5", .{
    //     .int_list = &[_]TestValue{
    //         .{ .int = 1 },
    //         .{ .int = 2 },
    //         .{ .int = 3 },
    //         .{ .int = 4 },
    //         .{ .int = 5 },
    //     },
    // });
    // try runTest("1b+1 0N 3 0N 5", .{
    //     .int_list = &[_]TestValue{
    //         .{ .int = 1 },
    //         .{ .int = 1 },
    //         .{ .int = 3 },
    //         .{ .int = 1 },
    //         .{ .int = 5 },
    //     },
    // });

    // try runTest("1+0", .{ .int = 0 });
    // try runTest("1+0N", .{ .int = 1 });
    // try runTest("1+1 2 3 4 5", .{
    //     .int_list = &[_]TestValue{
    //         .{ .int = 1 },
    //         .{ .int = 2 },
    //         .{ .int = 3 },
    //         .{ .int = 4 },
    //         .{ .int = 5 },
    //     },
    // });
    // try runTest("1+1 0N 3 0N 5", .{
    //     .int_list = &[_]TestValue{
    //         .{ .int = 1 },
    //         .{ .int = 1 },
    //         .{ .int = 3 },
    //         .{ .int = 1 },
    //         .{ .int = 5 },
    //     },
    // });

    // try runTest("1f+0", .{ .float = 0 });
    // try runTest("1f+0N", .{ .float = 1 });
    // try runTest("1f+1 2 3 4 5", .{
    //     .float_list = &[_]TestValue{
    //         .{ .float = 1 },
    //         .{ .float = 2 },
    //         .{ .float = 3 },
    //         .{ .float = 4 },
    //         .{ .float = 5 },
    //     },
    // });
    // try runTest("1f+1 0N 3 0N 5", .{
    //     .float_list = &[_]TestValue{
    //         .{ .float = 1 },
    //         .{ .float = 1 },
    //         .{ .float = 3 },
    //         .{ .float = 1 },
    //         .{ .float = 5 },
    //     },
    // });

    // try runTest("\"a\"+0", .{ .char = 0 });
    // try runTest("\"a\"+0N", .{ .char = 0 });
    // try runTest("\"a\"+256", .{ .char = 0 });
    // try runTest("\"a\"+-256", .{ .char = 0 });
    // try runTest("\"a\"+1 2 3 256 -256", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 1 },
    //         .{ .char = 2 },
    //         .{ .char = 3 },
    //         .{ .char = 0 },
    //         .{ .char = 0 },
    //     },
    // });
    // try runTest("\"a\"+1 0N 3 0N -256", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 1 },
    //         .{ .char = 0 },
    //         .{ .char = 3 },
    //         .{ .char = 0 },
    //         .{ .char = 0 },
    //     },
    // });

    // try runTestError("`symbol+0", AddError.incompatible_types);
    // try runTestError("`symbol+0N", AddError.incompatible_types);
    // try runTestError("`symbol+1 2 3 4 5", AddError.incompatible_types);
    // try runTestError("`symbol+1 0N 3 0N 5", AddError.incompatible_types);

    // try runTestError("()+0", AddError.length_mismatch);
    // try runTestError("(1b;2;3f)+0", AddError.length_mismatch);
    // try runTestError("()+0 0N", AddError.length_mismatch);
    // try runTest("(1b;2)+0 0N", .{
    //     .int_list = &[_]TestValue{
    //         .{ .int = 0 },
    //         .{ .int = 2 },
    //     },
    // });
    // try runTest("(1b;2;3f;4;\"a\")+1 2 3 4 5", .{
    //     .list = &[_]TestValue{
    //         .{ .int = 1 },
    //         .{ .int = 2 },
    //         .{ .float = 3 },
    //         .{ .int = 4 },
    //         .{ .char = 5 },
    //     },
    // });
    // try runTest("(1b;2;3f;4;\"a\")+1 0N 3 0N 5", .{
    //     .list = &[_]TestValue{
    //         .{ .int = 1 },
    //         .{ .int = 2 },
    //         .{ .float = 3 },
    //         .{ .int = 4 },
    //         .{ .char = 5 },
    //     },
    // });
    // try runTestError("(1b;2;3f;4;\"a\")+1 0N 3 0N 5 6", AddError.length_mismatch);
    // try runTestError("(1b;2;3f;4;`symbol)+1 0N 3 0N 5", AddError.incompatible_types);

    // try runTestError("10011b+1", AddError.length_mismatch);
    // try runTest("10011b+1 2 3 4 5", .{
    //     .int_list = &[_]TestValue{
    //         .{ .int = 1 },
    //         .{ .int = 2 },
    //         .{ .int = 3 },
    //         .{ .int = 4 },
    //         .{ .int = 5 },
    //     },
    // });
    // try runTest("10011b+1 0N 3 0N 5", .{
    //     .int_list = &[_]TestValue{
    //         .{ .int = 1 },
    //         .{ .int = 0 },
    //         .{ .int = 3 },
    //         .{ .int = 1 },
    //         .{ .int = 5 },
    //     },
    // });
    // try runTestError("10011b+1 0N 3 0N 5 6", AddError.length_mismatch);

    // try runTestError("5 4 3 2 1+1", AddError.length_mismatch);
    // try runTest("5 4 3 2 1+1 2 3 4 5", .{
    //     .int_list = &[_]TestValue{
    //         .{ .int = 1 },
    //         .{ .int = 2 },
    //         .{ .int = 3 },
    //         .{ .int = 4 },
    //         .{ .int = 5 },
    //     },
    // });
    // try runTest("5 4 3 2 1+1 0N 3 0N 5", .{
    //     .int_list = &[_]TestValue{
    //         .{ .int = 1 },
    //         .{ .int = 4 },
    //         .{ .int = 3 },
    //         .{ .int = 2 },
    //         .{ .int = 5 },
    //     },
    // });
    // try runTestError("5 4 3 2 1+1 0N 3 0N 5 6", AddError.length_mismatch);

    // try runTestError("5 4 3 2 1f+1", AddError.length_mismatch);
    // try runTest("5 4 3 2 1f+1 2 3 4 5", .{
    //     .float_list = &[_]TestValue{
    //         .{ .float = 1 },
    //         .{ .float = 2 },
    //         .{ .float = 3 },
    //         .{ .float = 4 },
    //         .{ .float = 5 },
    //     },
    // });
    // try runTest("5 4 3 2 1f+1 0N 3 0N 5", .{
    //     .float_list = &[_]TestValue{
    //         .{ .float = 1 },
    //         .{ .float = 4 },
    //         .{ .float = 3 },
    //         .{ .float = 2 },
    //         .{ .float = 5 },
    //     },
    // });
    // try runTestError("5 4 3 2 1f+1 0N 3 0N 5 6", AddError.length_mismatch);

    // try runTestError("\"abcde\"+1", AddError.length_mismatch);
    // try runTest("\"abcde\"+1 2 3 256 -256", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 1 },
    //         .{ .char = 2 },
    //         .{ .char = 3 },
    //         .{ .char = 0 },
    //         .{ .char = 0 },
    //     },
    // });
    // try runTest("\"abcde\"+1 0N 3 0N -256", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 1 },
    //         .{ .char = 0 },
    //         .{ .char = 3 },
    //         .{ .char = 0 },
    //         .{ .char = 0 },
    //     },
    // });
    // try runTestError("\"abcde\"+1 0N 3 0N 5 6", AddError.length_mismatch);

    // try runTestError("`a`b`c`d`e+1", AddError.length_mismatch);
    // try runTestError("`a`b`c`d`e+1 2 3 4 5", AddError.incompatible_types);
    // try runTestError("`a`b`c`d`e+1 0N 3 0N 5", AddError.incompatible_types);
    // try runTestError("`a`b`c`d`e+1 0N 3 0N 5 6", AddError.incompatible_types);
}

test "add float" {
    return error.SkipZigTest;
    // try runTest("1b+0f", .{ .float = 0 });
    // try runTest("1b+0n", .{ .float = 1 });
    // try runTest("1b+1 2 3 4 5f", .{
    //     .float_list = &[_]TestValue{
    //         .{ .float = 1 },
    //         .{ .float = 2 },
    //         .{ .float = 3 },
    //         .{ .float = 4 },
    //         .{ .float = 5 },
    //     },
    // });
    // try runTest("1b+1 0n 3 0n 5", .{
    //     .float_list = &[_]TestValue{
    //         .{ .float = 1 },
    //         .{ .float = 1 },
    //         .{ .float = 3 },
    //         .{ .float = 1 },
    //         .{ .float = 5 },
    //     },
    // });

    // try runTest("1+0f", .{ .float = 0 });
    // try runTest("1+0n", .{ .float = 1 });
    // try runTest("1+1 2 3 4 5f", .{
    //     .float_list = &[_]TestValue{
    //         .{ .float = 1 },
    //         .{ .float = 2 },
    //         .{ .float = 3 },
    //         .{ .float = 4 },
    //         .{ .float = 5 },
    //     },
    // });
    // try runTest("1+1 0n 3 0n 5", .{
    //     .float_list = &[_]TestValue{
    //         .{ .float = 1 },
    //         .{ .float = 1 },
    //         .{ .float = 3 },
    //         .{ .float = 1 },
    //         .{ .float = 5 },
    //     },
    // });

    // try runTest("1f+0f", .{ .float = 0 });
    // try runTest("1f+0n", .{ .float = 1 });
    // try runTest("1f+1 2 3 4 5f", .{
    //     .float_list = &[_]TestValue{
    //         .{ .float = 1 },
    //         .{ .float = 2 },
    //         .{ .float = 3 },
    //         .{ .float = 4 },
    //         .{ .float = 5 },
    //     },
    // });
    // try runTest("1f+1 0n 3 0n 5", .{
    //     .float_list = &[_]TestValue{
    //         .{ .float = 1 },
    //         .{ .float = 1 },
    //         .{ .float = 3 },
    //         .{ .float = 1 },
    //         .{ .float = 5 },
    //     },
    // });

    // try runTest("\"a\"+0f", .{ .char = 0 });
    // try runTest("\"a\"+0n", .{ .char = 0 });
    // try runTest("\"a\"+256f", .{ .char = 0 });
    // try runTest("\"a\"+-256f", .{ .char = 0 });
    // try runTest("\"a\"+1.4", .{ .char = 1 });
    // try runTest("\"a\"+1.5", .{ .char = 2 });
    // try runTest("\"a\"+-1.4", .{ .char = 255 });
    // try runTest("\"a\"+-1.5", .{ .char = 254 });
    // try runTest("\"a\"+0 256 -256 1.4 1.5 -1.4 -1.5", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 0 },
    //         .{ .char = 0 },
    //         .{ .char = 0 },
    //         .{ .char = 1 },
    //         .{ .char = 2 },
    //         .{ .char = 255 },
    //         .{ .char = 254 },
    //     },
    // });
    // try runTest("\"a\"+0n 256 -256 1.4 1.5 -1.4 -1.5", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 0 },
    //         .{ .char = 0 },
    //         .{ .char = 0 },
    //         .{ .char = 1 },
    //         .{ .char = 2 },
    //         .{ .char = 255 },
    //         .{ .char = 254 },
    //     },
    // });

    // try runTestError("`symbol+0f", AddError.incompatible_types);
    // try runTestError("`symbol+0n", AddError.incompatible_types);
    // try runTestError("`symbol+1 2 3 4 5f", AddError.incompatible_types);
    // try runTestError("`symbol+1 0n 3 0n 5", AddError.incompatible_types);

    // try runTestError("()+0f", AddError.length_mismatch);
    // try runTestError("(1b;2;3f)+0f", AddError.length_mismatch);
    // try runTestError("()+0 0n", AddError.length_mismatch);
    // try runTest("(1b;2)+0 0n", .{
    //     .float_list = &[_]TestValue{
    //         .{ .float = 0 },
    //         .{ .float = 2 },
    //     },
    // });
    // try runTest("(1b;2;3f;4;\"a\")+1 2 3 4 5f", .{
    //     .list = &[_]TestValue{
    //         .{ .float = 1 },
    //         .{ .float = 2 },
    //         .{ .float = 3 },
    //         .{ .float = 4 },
    //         .{ .char = 5 },
    //     },
    // });
    // try runTest("(1b;2;3f;4;\"a\")+1 0n 3 0n 5", .{
    //     .list = &[_]TestValue{
    //         .{ .float = 1 },
    //         .{ .float = 2 },
    //         .{ .float = 3 },
    //         .{ .float = 4 },
    //         .{ .char = 5 },
    //     },
    // });
    // try runTestError("(1b;2;3f;4;\"a\")+1 0n 3 0n 5 6", AddError.length_mismatch);
    // try runTestError("(1b;2;3f;4;`symbol)+1 0n 3 0n 5", AddError.incompatible_types);

    // try runTestError("10011b+1", AddError.length_mismatch);
    // try runTest("10011b+1 2 3 4 5f", .{
    //     .float_list = &[_]TestValue{
    //         .{ .float = 1 },
    //         .{ .float = 2 },
    //         .{ .float = 3 },
    //         .{ .float = 4 },
    //         .{ .float = 5 },
    //     },
    // });
    // try runTest("10011b+1 0n 3 0n 5", .{
    //     .float_list = &[_]TestValue{
    //         .{ .float = 1 },
    //         .{ .float = 0 },
    //         .{ .float = 3 },
    //         .{ .float = 1 },
    //         .{ .float = 5 },
    //     },
    // });
    // try runTestError("10011b+1 0n 3 0n 5 6", AddError.length_mismatch);

    // try runTestError("5 4 3 2 1+1f", AddError.length_mismatch);
    // try runTest("5 4 3 2 1+1 2 3 4 5f", .{
    //     .float_list = &[_]TestValue{
    //         .{ .float = 1 },
    //         .{ .float = 2 },
    //         .{ .float = 3 },
    //         .{ .float = 4 },
    //         .{ .float = 5 },
    //     },
    // });
    // try runTest("5 4 3 2 1+1 0n 3 0n 5", .{
    //     .float_list = &[_]TestValue{
    //         .{ .float = 1 },
    //         .{ .float = 4 },
    //         .{ .float = 3 },
    //         .{ .float = 2 },
    //         .{ .float = 5 },
    //     },
    // });
    // try runTestError("5 4 3 2 1+1 0n 3 0n 5 6", AddError.length_mismatch);

    // try runTestError("5 4 3 2 1f+1f", AddError.length_mismatch);
    // try runTest("5 4 3 2 1f+1 2 3 4 5f", .{
    //     .float_list = &[_]TestValue{
    //         .{ .float = 1 },
    //         .{ .float = 2 },
    //         .{ .float = 3 },
    //         .{ .float = 4 },
    //         .{ .float = 5 },
    //     },
    // });
    // try runTest("5 4 3 2 1f+1 0n 3 0n 5", .{
    //     .float_list = &[_]TestValue{
    //         .{ .float = 1 },
    //         .{ .float = 4 },
    //         .{ .float = 3 },
    //         .{ .float = 2 },
    //         .{ .float = 5 },
    //     },
    // });
    // try runTestError("5 4 3 2 1f+1 0n 3 0n 5 6", AddError.length_mismatch);

    // try runTestError("\"abcde\"+1f", AddError.length_mismatch);
    // try runTest("\"abcdefg\"+0 256 -256 1.4 1.5 -1.4 -1.5", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 0 },
    //         .{ .char = 0 },
    //         .{ .char = 0 },
    //         .{ .char = 1 },
    //         .{ .char = 2 },
    //         .{ .char = 255 },
    //         .{ .char = 254 },
    //     },
    // });
    // try runTest("\"abcdefg\"+0n 256 -256 1.4 1.5 -1.4 -1.5", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 0 },
    //         .{ .char = 0 },
    //         .{ .char = 0 },
    //         .{ .char = 1 },
    //         .{ .char = 2 },
    //         .{ .char = 255 },
    //         .{ .char = 254 },
    //     },
    // });
    // try runTestError("\"abcdefg\"+0n 256 -256 1.4 1.5 -1.4 -1.5 6", AddError.length_mismatch);

    // try runTestError("`a`b`c`d`e+1f", AddError.length_mismatch);
    // try runTestError("`a`b`c`d`e+1 2 3 4 5f", AddError.incompatible_types);
    // try runTestError("`a`b`c`d`e+1 0n 3 0n 5", AddError.incompatible_types);
    // try runTestError("`a`b`c`d`e+1 0n 3 0n 5 6", AddError.incompatible_types);
}

test "add char" {
    return error.SkipZigTest;
    // try runTest("1b+\"a\"", .{ .char = 'a' });
    // try runTest("1b+\" \"", .{ .char = 1 });
    // try runTest("1b+\"abcde\"", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 'a' },
    //         .{ .char = 'b' },
    //         .{ .char = 'c' },
    //         .{ .char = 'd' },
    //         .{ .char = 'e' },
    //     },
    // });
    // try runTest("1b+\"a c e\"", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 'a' },
    //         .{ .char = 1 },
    //         .{ .char = 'c' },
    //         .{ .char = 1 },
    //         .{ .char = 'e' },
    //     },
    // });

    // try runTest("1+\"a\"", .{ .char = 'a' });
    // try runTest("1+\" \"", .{ .char = 1 });
    // try runTest("-1+\"a\"", .{ .char = 'a' });
    // try runTest("-1+\" \"", .{ .char = 255 });
    // try runTest("256+\"a\"", .{ .char = 'a' });
    // try runTest("256+\" \"", .{ .char = 0 });
    // try runTest("1+\"abcde\"", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 'a' },
    //         .{ .char = 'b' },
    //         .{ .char = 'c' },
    //         .{ .char = 'd' },
    //         .{ .char = 'e' },
    //     },
    // });
    // try runTest("1+\"a c e\"", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 'a' },
    //         .{ .char = 1 },
    //         .{ .char = 'c' },
    //         .{ .char = 1 },
    //         .{ .char = 'e' },
    //     },
    // });
    // try runTest("-1+\"abcde\"", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 'a' },
    //         .{ .char = 'b' },
    //         .{ .char = 'c' },
    //         .{ .char = 'd' },
    //         .{ .char = 'e' },
    //     },
    // });
    // try runTest("-1+\"a c e\"", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 'a' },
    //         .{ .char = 255 },
    //         .{ .char = 'c' },
    //         .{ .char = 255 },
    //         .{ .char = 'e' },
    //     },
    // });
    // try runTest("256+\"abcde\"", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 'a' },
    //         .{ .char = 'b' },
    //         .{ .char = 'c' },
    //         .{ .char = 'd' },
    //         .{ .char = 'e' },
    //     },
    // });
    // try runTest("256+\"a c e\"", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 'a' },
    //         .{ .char = 0 },
    //         .{ .char = 'c' },
    //         .{ .char = 0 },
    //         .{ .char = 'e' },
    //     },
    // });

    // try runTest("1f+\"a\"", .{ .char = 'a' });
    // try runTest("1f+\" \"", .{ .char = 1 });
    // try runTest("1.4+\"a\"", .{ .char = 'a' });
    // try runTest("1.4+\" \"", .{ .char = 1 });
    // try runTest("1.5+\"a\"", .{ .char = 'a' });
    // try runTest("1.5+\" \"", .{ .char = 2 });
    // try runTest("-1.4+\"a\"", .{ .char = 'a' });
    // try runTest("-1.4+\" \"", .{ .char = 255 });
    // try runTest("-1.5+\"a\"", .{ .char = 'a' });
    // try runTest("-1.5+\" \"", .{ .char = 254 });
    // try runTest("-1f+\"a\"", .{ .char = 'a' });
    // try runTest("-1f+\" \"", .{ .char = 255 });
    // try runTest("256f+\"a\"", .{ .char = 'a' });
    // try runTest("256f+\" \"", .{ .char = 0 });
    // try runTest("1f+\"abcde\"", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 'a' },
    //         .{ .char = 'b' },
    //         .{ .char = 'c' },
    //         .{ .char = 'd' },
    //         .{ .char = 'e' },
    //     },
    // });
    // try runTest("1f+\"a c e\"", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 'a' },
    //         .{ .char = 1 },
    //         .{ .char = 'c' },
    //         .{ .char = 1 },
    //         .{ .char = 'e' },
    //     },
    // });
    // try runTest("-1f+\"abcde\"", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 'a' },
    //         .{ .char = 'b' },
    //         .{ .char = 'c' },
    //         .{ .char = 'd' },
    //         .{ .char = 'e' },
    //     },
    // });
    // try runTest("-1f+\"a c e\"", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 'a' },
    //         .{ .char = 255 },
    //         .{ .char = 'c' },
    //         .{ .char = 255 },
    //         .{ .char = 'e' },
    //     },
    // });
    // try runTest("256f+\"abcde\"", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 'a' },
    //         .{ .char = 'b' },
    //         .{ .char = 'c' },
    //         .{ .char = 'd' },
    //         .{ .char = 'e' },
    //     },
    // });
    // try runTest("256f+\"a c e\"", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 'a' },
    //         .{ .char = 0 },
    //         .{ .char = 'c' },
    //         .{ .char = 0 },
    //         .{ .char = 'e' },
    //     },
    // });

    // try runTest("\"1\"+\"a\"", .{ .char = 'a' });
    // try runTest("\"1\"+\" \"", .{ .char = '1' });
    // try runTest("\"1\"+\"abcde\"", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 'a' },
    //         .{ .char = 'b' },
    //         .{ .char = 'c' },
    //         .{ .char = 'd' },
    //         .{ .char = 'e' },
    //     },
    // });
    // try runTest("\"1\"+\"a c e\"", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 'a' },
    //         .{ .char = '1' },
    //         .{ .char = 'c' },
    //         .{ .char = '1' },
    //         .{ .char = 'e' },
    //     },
    // });

    // try runTestError("`symbol+\"a\"", AddError.incompatible_types);
    // try runTestError("`symbol+\" \"", AddError.incompatible_types);
    // try runTestError("`symbol+\"abcde\"", AddError.incompatible_types);
    // try runTestError("`symbol+\"a c e\"", AddError.incompatible_types);

    // try runTestError("()+\"a\"", AddError.length_mismatch);
    // try runTestError("(1b;2;3f)+\"a\"", AddError.length_mismatch);
    // try runTestError("()+\"abcde\"", AddError.length_mismatch);
    // try runTest("(1b;2;3f;4;5f)+\"abcde\"", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 'a' },
    //         .{ .char = 'b' },
    //         .{ .char = 'c' },
    //         .{ .char = 'd' },
    //         .{ .char = 'e' },
    //     },
    // });
    // try runTest("(1b;2;3f;4;5f)+\"a c e\"", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 'a' },
    //         .{ .char = 2 },
    //         .{ .char = 'c' },
    //         .{ .char = 4 },
    //         .{ .char = 'e' },
    //     },
    // });
    // try runTestError("(1b;2;3f;4;5f)+\"a c ef\"", AddError.length_mismatch);
    // try runTest("(1b;2;3f;4;\"a\")+\"a c e\"", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 'a' },
    //         .{ .char = 2 },
    //         .{ .char = 'c' },
    //         .{ .char = 4 },
    //         .{ .char = 'e' },
    //     },
    // });
    // try runTestError("(1b;2;3f;4;`symbol)+\"a c e\"", AddError.incompatible_types);

    // try runTestError("10011b+\"a\"", AddError.length_mismatch);
    // try runTest("10011b+\"abcde\"", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 'a' },
    //         .{ .char = 'b' },
    //         .{ .char = 'c' },
    //         .{ .char = 'd' },
    //         .{ .char = 'e' },
    //     },
    // });
    // try runTest("10011b+\"a c e\"", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 'a' },
    //         .{ .char = 0 },
    //         .{ .char = 'c' },
    //         .{ .char = 1 },
    //         .{ .char = 'e' },
    //     },
    // });
    // try runTestError("10011b+\"a c ef\"", AddError.length_mismatch);

    // try runTestError("5 4 3 2 1+\"a\"", AddError.length_mismatch);
    // try runTest("5 4 3 2 1+\"abcde\"", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 'a' },
    //         .{ .char = 'b' },
    //         .{ .char = 'c' },
    //         .{ .char = 'd' },
    //         .{ .char = 'e' },
    //     },
    // });
    // try runTest("5 4 3 2 1+\"a c e\"", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 'a' },
    //         .{ .char = 4 },
    //         .{ .char = 'c' },
    //         .{ .char = 2 },
    //         .{ .char = 'e' },
    //     },
    // });
    // try runTest("-1 256 256 -1 -1+\"abcde\"", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 'a' },
    //         .{ .char = 'b' },
    //         .{ .char = 'c' },
    //         .{ .char = 'd' },
    //         .{ .char = 'e' },
    //     },
    // });
    // try runTest("-1 256 256 -1 -1+\"a c e\"", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 'a' },
    //         .{ .char = 0 },
    //         .{ .char = 'c' },
    //         .{ .char = 255 },
    //         .{ .char = 'e' },
    //     },
    // });
    // try runTestError("5 4 3 2 1+\"a c ef\"", AddError.length_mismatch);

    // try runTestError("5 4 3 2 1f+\"a\"", AddError.length_mismatch);
    // try runTest("5 4 3 2 1f+\"abcde\"", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 'a' },
    //         .{ .char = 'b' },
    //         .{ .char = 'c' },
    //         .{ .char = 'd' },
    //         .{ .char = 'e' },
    //     },
    // });
    // try runTest("5 4 3 2 1f+\"a c e\"", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 'a' },
    //         .{ .char = 4 },
    //         .{ .char = 'c' },
    //         .{ .char = 2 },
    //         .{ .char = 'e' },
    //     },
    // });
    // try runTest("-1 256 256 -1 -1f+\"abcde\"", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 'a' },
    //         .{ .char = 'b' },
    //         .{ .char = 'c' },
    //         .{ .char = 'd' },
    //         .{ .char = 'e' },
    //     },
    // });
    // try runTest("-1 256 256 -1 -1f+\"a c e\"", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 'a' },
    //         .{ .char = 0 },
    //         .{ .char = 'c' },
    //         .{ .char = 255 },
    //         .{ .char = 'e' },
    //     },
    // });
    // try runTestError("-1 256 256 -1 -1f+\"a c ef\"", AddError.length_mismatch);

    // try runTestError("\"54321\"+\"a\"", AddError.length_mismatch);
    // try runTest("\"54321\"+\"abcde\"", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 'a' },
    //         .{ .char = 'b' },
    //         .{ .char = 'c' },
    //         .{ .char = 'd' },
    //         .{ .char = 'e' },
    //     },
    // });
    // try runTest("\"54321\"+\"a c e\"", .{
    //     .char_list = &[_]TestValue{
    //         .{ .char = 'a' },
    //         .{ .char = '4' },
    //         .{ .char = 'c' },
    //         .{ .char = '2' },
    //         .{ .char = 'e' },
    //     },
    // });
    // try runTestError("\"54321\"+\"a c ef\"", AddError.length_mismatch);

    // try runTestError("`a`b`c`d`e+\"a\"", AddError.length_mismatch);
    // try runTestError("`a`b`c`d`e+\"abcde\"", AddError.incompatible_types);
    // try runTestError("`a`b`c`d`e+\"a c e\"", AddError.incompatible_types);
    // try runTestError("`a`b`c`d`e+\"a c ef\"", AddError.incompatible_types);
}

test "add symbol" {
    return error.SkipZigTest;
    // try runTestError("1b+`symbol", AddError.incompatible_types);
    // try runTestError("1b+`", AddError.incompatible_types);
    // try runTestError("1b+`a`b`c`d`e", AddError.incompatible_types);
    // try runTestError("1b+`a``c``e", AddError.incompatible_types);

    // try runTestError("1+`symbol", AddError.incompatible_types);
    // try runTestError("1+`", AddError.incompatible_types);
    // try runTestError("1+`a`b`c`d`e", AddError.incompatible_types);
    // try runTestError("1+`a``c``e", AddError.incompatible_types);

    // try runTestError("1f+`symbol", AddError.incompatible_types);
    // try runTestError("1f+`", AddError.incompatible_types);
    // try runTestError("1f+`a`b`c`d`e", AddError.incompatible_types);
    // try runTestError("1f+`a``c``e", AddError.incompatible_types);

    // try runTestError("\"a\"+`symbol", AddError.incompatible_types);
    // try runTestError("\"a\"+`", AddError.incompatible_types);
    // try runTestError("\"a\"+`a`b`c`d`e", AddError.incompatible_types);
    // try runTestError("\"a\"+`a``c``e", AddError.incompatible_types);

    // try runTest("`symbol+`a", .{ .symbol = "a" });
    // try runTest("`symbol+`", .{ .symbol = "symbol" });
    // try runTest("`symbol+`a`b`c`d`e", .{
    //     .symbol_list = &[_]TestValue{
    //         .{ .symbol = "a" },
    //         .{ .symbol = "b" },
    //         .{ .symbol = "c" },
    //         .{ .symbol = "d" },
    //         .{ .symbol = "e" },
    //     },
    // });
    // try runTest("`symbol+`a``c``e", .{
    //     .symbol_list = &[_]TestValue{
    //         .{ .symbol = "a" },
    //         .{ .symbol = "symbol" },
    //         .{ .symbol = "c" },
    //         .{ .symbol = "symbol" },
    //         .{ .symbol = "e" },
    //     },
    // });

    // try runTestError("()+`symbol", AddError.length_mismatch);
    // try runTestError("(1b;2;3f;4;5f)+`symbol", AddError.length_mismatch);
    // try runTestError("()+`a`b`c`d`e", AddError.incompatible_types);
    // try runTestError("(1b;2;3f;4;5f)+`a`b`c`d`e", AddError.incompatible_types);
    // try runTestError("(1b;2;3f;4;5f)+`a``c``e", AddError.incompatible_types);
    // try runTestError("(1b;2;3f;4;\"a\")+`a``c``e", AddError.incompatible_types);
    // try runTestError("(1b;2;3f;4;`symbol)+`a``c``e", AddError.incompatible_types);

    // try runTestError("10011b+`symbol", AddError.length_mismatch);
    // try runTestError("10011b+`a`b`c`d`e", AddError.incompatible_types);
    // try runTestError("10011b+`a``c``e", AddError.incompatible_types);
    // try runTestError("10011b+`a``c``e`f", AddError.incompatible_types);

    // try runTestError("5 4 3 2 1+`symbol", AddError.length_mismatch);
    // try runTestError("5 4 3 2 1+`a`b`c`d`e", AddError.incompatible_types);
    // try runTestError("5 4 3 2 1+`a``c``e", AddError.incompatible_types);
    // try runTestError("5 4 3 2 1+`a``c``e`f", AddError.incompatible_types);

    // try runTestError("5 4 3 2 1f+`symbol", AddError.length_mismatch);
    // try runTestError("5 4 3 2 1f+`a`b`c`d`e", AddError.incompatible_types);
    // try runTestError("5 4 3 2 1f+`a``c``e", AddError.incompatible_types);
    // try runTestError("5 4 3 2 1f+`a``c``e`f", AddError.incompatible_types);

    // try runTestError("\"54321\"+`symbol", AddError.length_mismatch);
    // try runTestError("\"54321\"+`a`b`c`d`e", AddError.incompatible_types);
    // try runTestError("\"54321\"+`a``c``e", AddError.incompatible_types);
    // try runTestError("\"54321\"+`a``c``e`f", AddError.incompatible_types);

    // try runTestError("`5`4`3`2`1+`symbol", AddError.length_mismatch);
    // try runTest("`5`4`3`2`1+`a`b`c`d`e", .{
    //     .symbol_list = &[_]TestValue{
    //         .{ .symbol = "a" },
    //         .{ .symbol = "b" },
    //         .{ .symbol = "c" },
    //         .{ .symbol = "d" },
    //         .{ .symbol = "e" },
    //     },
    // });
    // try runTest("`5`4`3`2`1+`a``c``e", .{
    //     .symbol_list = &[_]TestValue{
    //         .{ .symbol = "a" },
    //         .{ .symbol = "4" },
    //         .{ .symbol = "c" },
    //         .{ .symbol = "2" },
    //         .{ .symbol = "e" },
    //     },
    // });
    // try runTestError("`5`4`3`2`1+`a``c``e`f", AddError.length_mismatch);
}

test "add list" {
    return error.SkipZigTest;
    // try runTest("1b+(0b;1;0N;1f;0n;\"a\";\" \")", .{
    //     .list = &[_]TestValue{
    //         .{ .boolean = false },
    //         .{ .int = 1 },
    //         .{ .int = 1 },
    //         .{ .float = 1 },
    //         .{ .float = 1 },
    //         .{ .char = 'a' },
    //         .{ .char = 1 },
    //     },
    // });
    // try runTestError("1b+(0b;1;0N;1f;0n;\"a\";\" \";`symbol;`)", AddError.incompatible_types);
    // try runTestError("1b+(`;`symbol;\" \";\"a\";0n;1f;0N;1;0b)", AddError.incompatible_types);

    // try runTest("1+(0b;1;0N;1f;0n;\"a\";\" \")", .{
    //     .list = &[_]TestValue{
    //         .{ .int = 0 },
    //         .{ .int = 1 },
    //         .{ .int = 1 },
    //         .{ .float = 1 },
    //         .{ .float = 1 },
    //         .{ .char = 'a' },
    //         .{ .char = 1 },
    //     },
    // });
    // try runTest("1+(0b;0N)", .{
    //     .int_list = &[_]TestValue{
    //         .{ .int = 0 },
    //         .{ .int = 1 },
    //     },
    // });
    // try runTestError("1+(0b;1;0N;1f;0n;\"a\";\" \";`symbol;`)", AddError.incompatible_types);
    // try runTestError("1+(`;`symbol;\" \";\"a\";0n;1f;0N;1;0b)", AddError.incompatible_types);

    // try runTest("1f+(0b;1;0N;1f;0n;\"a\";\" \")", .{
    //     .list = &[_]TestValue{
    //         .{ .float = 0 },
    //         .{ .float = 1 },
    //         .{ .float = 1 },
    //         .{ .float = 1 },
    //         .{ .float = 1 },
    //         .{ .char = 'a' },
    //         .{ .char = 1 },
    //     },
    // });
    // try runTest("1f+(0b;0N)", .{
    //     .float_list = &[_]TestValue{
    //         .{ .float = 0 },
    //         .{ .float = 1 },
    //     },
    // });
    // try runTestError("1f+(0b;1;0N;1f;0n;\"a\";\" \";`symbol;`)", AddError.incompatible_types);
    // try runTestError("1f+(`;`symbol;\" \";\"a\";0n;1f;0N;1;0b)", AddError.incompatible_types);

    // try runTest("\"a\"+(\" \";\"b \")", .{
    //     .list = &[_]TestValue{
    //         .{ .char = 'a' },
    //         .{ .char_list = &[_]TestValue{
    //             .{ .char = 'b' },
    //             .{ .char = 'a' },
    //         } },
    //     },
    // });
    // try runTestError("\"a\"+(0b;1;0N;1f;0n;\"a\";\" \";`symbol;`)", AddError.incompatible_types);
    // try runTestError("\"a\"+(`;`symbol;\" \";\"a\";0n;1f;0N;1;0b)", AddError.incompatible_types);

    // try runTest("`test+(`;`symbol`)", .{
    //     .list = &[_]TestValue{
    //         .{ .symbol = "test" },
    //         .{ .symbol_list = &[_]TestValue{
    //             .{ .symbol = "symbol" },
    //             .{ .symbol = "test" },
    //         } },
    //     },
    // });
    // try runTestError("`test+(0b;1;0N;1f;0n;\"a\";\" \";`symbol;`)", AddError.incompatible_types);
    // try runTestError("`test+(`;`symbol;\" \";\"a\";0n;1f;0N;1;0b)", AddError.incompatible_types);

    // try runTest("()+()", .{ .list = &[_]TestValue{} });
    // try runTestError("(2;3f)+()", AddError.length_mismatch);
    // try runTestError("()+(0n;0N)", AddError.length_mismatch);
    // try runTest("(2;3f)+(0n;0N)", .{
    //     .float_list = &[_]TestValue{
    //         .{ .float = 2 },
    //         .{ .float = 3 },
    //     },
    // });
    // try runTest("(1b;(2;3f);(\"a\";`a`b`c`d`e))+(0N;(0n;0N);(\" \";`a``c``e))", .{
    //     .list = &[_]TestValue{
    //         .{ .int = 1 },
    //         .{ .float_list = &[_]TestValue{
    //             .{ .float = 2 },
    //             .{ .float = 3 },
    //         } },
    //         .{ .list = &[_]TestValue{
    //             .{ .char = 'a' },
    //             .{ .symbol_list = &[_]TestValue{
    //                 .{ .symbol = "a" },
    //                 .{ .symbol = "b" },
    //                 .{ .symbol = "c" },
    //                 .{ .symbol = "d" },
    //                 .{ .symbol = "e" },
    //             } },
    //         } },
    //     },
    // });
    // try runTestError("(0b;1;2;3;4;5;6;7;8)+(0b;1;0N;1f;0n;\"a\";\" \";`symbol;`)", AddError.incompatible_types);
    // try runTestError("(0b;1;2;3;4;5;6;7;8)+(`;`symbol;\" \";\"a\";0n;1f;0N;1;0b)", AddError.incompatible_types);

    // try runTestError("010b+()", AddError.length_mismatch);
    // try runTest("010b+(0b;0N;0n)", .{
    //     .list = &[_]TestValue{
    //         .{ .boolean = false },
    //         .{ .int = 1 },
    //         .{ .float = 0 },
    //     },
    // });
    // try runTestError("010101010b+(0b;1;0N;1f;0n;\"a\";\" \";`symbol;`)", AddError.incompatible_types);
    // try runTestError("010101010b+(`;`symbol;\" \";\"a\";0n;1f;0N;1;0b)", AddError.incompatible_types);

    // try runTestError("0 1 2+()", AddError.length_mismatch);
    // try runTest("0 1 2+(0b;0N;0n)", .{
    //     .list = &[_]TestValue{
    //         .{ .int = 0 },
    //         .{ .int = 1 },
    //         .{ .float = 2 },
    //     },
    // });
    // try runTestError("0 1 2 3 4 5 6 7 8+(0b;1;0N;1f;0n;\"a\";\" \";`symbol;`)", AddError.incompatible_types);
    // try runTestError("0 1 2 3 4 5 6 7 8+(`;`symbol;\" \";\"a\";0n;1f;0N;1;0b)", AddError.incompatible_types);

    // try runTestError("0 1 2f+()", AddError.length_mismatch);
    // try runTest("0 1 2f+(0b;0N;0n)", .{
    //     .float_list = &[_]TestValue{
    //         .{ .float = 0 },
    //         .{ .float = 1 },
    //         .{ .float = 2 },
    //     },
    // });
    // try runTestError("0 1 2 3 4 5 6 7 8f+(0b;1;0N;1f;0n;\"a\";\" \";`symbol;`)", AddError.incompatible_types);
    // try runTestError("0 1 2 3 4 5 6 7 8f+(`;`symbol;\" \";\"a\";0n;1f;0N;1;0b)", AddError.incompatible_types);

    // try runTestError("\"abcde\"+()", AddError.length_mismatch);
    // try runTest("\"ab\"+(\" \";\"  \")", .{
    //     .list = &[_]TestValue{
    //         .{ .char = 'a' },
    //         .{ .char_list = &[_]TestValue{
    //             .{ .char = 'b' },
    //             .{ .char = 'b' },
    //         } },
    //     },
    // });
    // try runTestError("\"abcdefghi\"+(0b;1;0N;1f;0n;\"a\";\" \";`symbol;`)", AddError.incompatible_types);
    // try runTestError("\"abcdefghi\"+(`;`symbol;\" \";\"a\";0n;1f;0N;1;0b)", AddError.incompatible_types);

    // try runTestError("`a`b`c`d`e+()", AddError.length_mismatch);
    // try runTest("`a`b+(`;``)", .{
    //     .list = &[_]TestValue{
    //         .{ .symbol = "a" },
    //         .{ .symbol_list = &[_]TestValue{
    //             .{ .symbol = "b" },
    //             .{ .symbol = "b" },
    //         } },
    //     },
    // });
    // try runTestError("`a`b`c`d`e`f`g`h`i+(0b;1;0N;1f;0n;\"a\";\" \";`symbol;`)", AddError.incompatible_types);
    // try runTestError("`a`b`c`d`e`f`g`h`i+(`;`symbol;\" \";\"a\";0n;1f;0N;1;0b)", AddError.incompatible_types);
}
