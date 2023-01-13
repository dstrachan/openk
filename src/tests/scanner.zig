const std = @import("std");

const scanner_mod = @import("../scanner.zig");
const Scanner = scanner_mod.Scanner;
const TokenType = scanner_mod.TokenType;

fn runTest(input: []const u8, expected: []const TokenType) !void {
    var scanner = Scanner.init(input);
    var actual = std.ArrayList(TokenType).init(std.testing.allocator);
    defer actual.deinit();
    while (true) {
        const token = scanner.scanToken();
        if (token.token_type == .token_eof) break;
        try actual.append(token.token_type);
    }

    try std.testing.expectEqual(expected.len, actual.items.len);
    var i: usize = 0;
    while (i < expected.len) : (i += 1) {
        try std.testing.expectEqual(expected[i], actual.items[i]);
    }
}

test "bool" {
    try runTest("0b", &[_]TokenType{.token_bool});
    try runTest("1b", &[_]TokenType{.token_bool});

    try runTest("2b", &[_]TokenType{.token_error});

    try runTest("-1b", &[_]TokenType{ .token_int, .token_identifier });
}

test "int" {
    try runTest("0", &[_]TokenType{.token_int});
    try runTest("1", &[_]TokenType{.token_int});

    try runTest("-1", &[_]TokenType{.token_int});

    try runTest("- 1", &[_]TokenType{ .token_minus, .token_int });
}

test "float" {
    try runTest("1f", &[_]TokenType{.token_float});
    try runTest("1.", &[_]TokenType{.token_float});
    try runTest("1.f", &[_]TokenType{.token_float});
    try runTest("1.0", &[_]TokenType{.token_float});
    try runTest("1.0f", &[_]TokenType{.token_float});
    try runTest(".0", &[_]TokenType{.token_float});
    try runTest(".0f", &[_]TokenType{.token_float});

    try runTest("-1f", &[_]TokenType{.token_float});
    try runTest("-1.", &[_]TokenType{.token_float});
    try runTest("-1.f", &[_]TokenType{.token_float});
    try runTest("-1.0", &[_]TokenType{.token_float});
    try runTest("-1.0f", &[_]TokenType{.token_float});
    try runTest("-.0", &[_]TokenType{.token_float});
    try runTest("-.0f", &[_]TokenType{.token_float});

    try runTest("0.0.0", &[_]TokenType{.token_error});
}
