const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;
const runTestError = vm_mod.runTestError;

test "apply with undefined symbol" {
    try runTestError("`a@1", error.interpret_runtime_error);
}

test "apply with function symbol" {
    try runTest("a:{[x]x};`a@1", .{ .int = 1 });
    try runTestError("a:{[x]x+`symbol};`a@1", error.incompatible_types);
}

test "apply with projection symbol" {
    try runTest("a:{[x;y]x+y}[1];`a@1", .{ .int = 2 });
    try runTestError("a:{[x;y]x+y+`symbol}[1];`a@1", error.incompatible_types);
}

test "apply with list symbol" {
    try runTest("a:!10;`a@1", .{ .int = 1 });
    try runTestError("a:!10;`a@`symbol", error.incompatible_types);
}

test "apply with non-list symbol" {
    try runTestError("a:10;`a@1", error.incompatible_types);
    try runTestError("a:10;`a@`symbol", error.incompatible_types);
}

test "apply with function" {
    try runTest("a:{[x]x};a@1", .{ .int = 1 });
    try runTest("{[x]x}@1", .{ .int = 1 });
    try runTestError("a:{[x]x+`symbol};a@1", error.incompatible_types);
    try runTestError("{[x]x+`symbol}@1", error.incompatible_types);
}

test "apply with projection" {
    try runTest("a:{[x;y]x+y}[1];a@1", .{ .int = 2 });
    try runTest("{[x;y]x+y}[1]@1", .{ .int = 2 });
    try runTestError("a:{[x;y]x+y+`symbol}[1];a@1", error.incompatible_types);
    try runTestError("{[x;y]x+y+`symbol}[1]@1", error.incompatible_types);
}

test "apply with list" {
    try runTest("a:!10;a@1", .{ .int = 1 });
    try runTest("(!10)@1", .{ .int = 1 });
    try runTestError("a:!10;a@`symbol", error.incompatible_types);
    try runTestError("(!10)@`symbol", error.incompatible_types);
}

test "apply with non-list" {
    try runTestError("10@1", error.incompatible_types);
    try runTestError("10@`symbol", error.incompatible_types);
}

test "applyN with undefined symbol" {
    try runTestError("`a . 1 2", error.interpret_runtime_error);
}

test "applyN with function symbol" {
    try runTest("a:{[x;y]x+y};`a . 1 2", .{ .int = 3 });
    try runTestError("a:{[x;y]x+y+`symbol};`a . 1 2", error.incompatible_types);
}

test "applyN with projection symbol" {
    try runTest("a:{[x;y;z]x+y+z}[1];`a . 1 2", .{ .int = 4 });
    try runTestError("a:{[x;y;z]x+y+z+`symbol}[1];`a . 1 2", error.incompatible_types);
}

test "applyN with function" {
    try runTest("a:{[x;y]x+y};a . 1 2", .{ .int = 3 });
    try runTest("{[x;y]x+y}. 1 2", .{ .int = 3 });
    try runTestError("a:{[x;y]x+y+`symbol};a . 1 2", error.incompatible_types);
    try runTestError("{[x;y]x+y+`symbol}. 1 2", error.incompatible_types);
}

test "applyN with projection" {
    try runTest("a:{[x;y;z]x+y+z}[1];a . 1 2", .{ .int = 4 });
    try runTest("{[x;y;z]x+y+z}[1]. 1 2", .{ .int = 4 });
    try runTestError("a:{[x;y;z]x+y+z+`symbol}[1];a . 1 2", error.incompatible_types);
    try runTestError("{[x;y;z]x+y+z+`symbol}[1]. 1 2", error.incompatible_types);
}
