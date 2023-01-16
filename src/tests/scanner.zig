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

test "scanner - bool" {
    try runTest("0b", &[_]TokenType{.token_bool});
    try runTest("1b", &[_]TokenType{.token_bool});
    try runTest("00b", &[_]TokenType{.token_bool});
    try runTest("11b", &[_]TokenType{.token_bool});

    try runTest("2b", &[_]TokenType{.token_error});
    try runTest("22b", &[_]TokenType{.token_error});

    try runTest("-1b", &[_]TokenType{ .token_int, .token_identifier });
}

test "scanner - int" {
    try runTest("0", &[_]TokenType{.token_int});
    try runTest("1", &[_]TokenType{.token_int});

    try runTest("-1", &[_]TokenType{.token_int});

    try runTest("1 2", &[_]TokenType{ .token_int, .token_int });
    try runTest("-1 2", &[_]TokenType{ .token_int, .token_int });
    try runTest("1 -2", &[_]TokenType{ .token_int, .token_int });
    try runTest("-1 -2", &[_]TokenType{ .token_int, .token_int });

    try runTest("- 1", &[_]TokenType{ .token_minus, .token_int });
}

test "scanner - float" {
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

    try runTest("1 2f", &[_]TokenType{ .token_int, .token_float });
    try runTest("-1 2f", &[_]TokenType{ .token_int, .token_float });
    try runTest("1 -2f", &[_]TokenType{ .token_int, .token_float });
    try runTest("-1 -2f", &[_]TokenType{ .token_int, .token_float });

    try runTest("- 1f", &[_]TokenType{ .token_minus, .token_float });

    try runTest("0.0.0", &[_]TokenType{.token_error});
}

test "scanner - char" {
    try runTest("\" \"", &[_]TokenType{.token_char});
    try runTest("\"a\"", &[_]TokenType{.token_char});
    try runTest("\"\\\"\"", &[_]TokenType{.token_char});
}

test "scanner - string" {
    try runTest("\"\"", &[_]TokenType{.token_string});
    try runTest("\"  \"", &[_]TokenType{.token_string});
    try runTest("\"aa\"", &[_]TokenType{.token_string});
    try runTest("\"\\\"\\\"\"", &[_]TokenType{.token_string});

    try runTest("\"", &[_]TokenType{.token_error});
    try runTest("\"\"\"", &[_]TokenType{ .token_string, .token_error });
}

test "scanner - symbol" {
    try runTest("`", &[_]TokenType{.token_symbol});
    try runTest("`a", &[_]TokenType{.token_symbol});

    try runTest("`a-b", &[_]TokenType{ .token_symbol, .token_minus, .token_identifier });

    try runTest("``", &[_]TokenType{ .token_symbol, .token_symbol });
    try runTest("``a", &[_]TokenType{ .token_symbol, .token_symbol });
    try runTest("`a`", &[_]TokenType{ .token_symbol, .token_symbol });
    try runTest("`a`a", &[_]TokenType{ .token_symbol, .token_symbol });
}

test "scanner - list" {
    try runTest("(0;1)", &[_]TokenType{ .token_left_paren, .token_int, .token_semicolon, .token_int, .token_right_paren });
}

test "scanner - boolean addition" {
    try runTest("0b+0b", &[_]TokenType{ .token_bool, .token_plus, .token_bool });
    try runTest("0b+1b", &[_]TokenType{ .token_bool, .token_plus, .token_bool });
    try runTest("1b+0b", &[_]TokenType{ .token_bool, .token_plus, .token_bool });
    try runTest("1b+1b", &[_]TokenType{ .token_bool, .token_plus, .token_bool });

    try runTest("0b+0", &[_]TokenType{ .token_bool, .token_plus, .token_int });
    try runTest("0b+1", &[_]TokenType{ .token_bool, .token_plus, .token_int });
    try runTest("0b+-1", &[_]TokenType{ .token_bool, .token_plus, .token_int });
    try runTest("1b+0", &[_]TokenType{ .token_bool, .token_plus, .token_int });
    try runTest("1b+1", &[_]TokenType{ .token_bool, .token_plus, .token_int });
    try runTest("1b+-1", &[_]TokenType{ .token_bool, .token_plus, .token_int });

    try runTest("0b+0f", &[_]TokenType{ .token_bool, .token_plus, .token_float });
    try runTest("0b+1f", &[_]TokenType{ .token_bool, .token_plus, .token_float });
    try runTest("0b+-1f", &[_]TokenType{ .token_bool, .token_plus, .token_float });
    try runTest("1b+0f", &[_]TokenType{ .token_bool, .token_plus, .token_float });
    try runTest("1b+1f", &[_]TokenType{ .token_bool, .token_plus, .token_float });
    try runTest("1b+-1f", &[_]TokenType{ .token_bool, .token_plus, .token_float });
}

test "scanner - int addition" {
    try runTest("0+0b", &[_]TokenType{ .token_int, .token_plus, .token_bool });
    try runTest("0+1b", &[_]TokenType{ .token_int, .token_plus, .token_bool });
    try runTest("1+0b", &[_]TokenType{ .token_int, .token_plus, .token_bool });
    try runTest("1+1b", &[_]TokenType{ .token_int, .token_plus, .token_bool });
    try runTest("-1+0b", &[_]TokenType{ .token_int, .token_plus, .token_bool });
    try runTest("-1+1b", &[_]TokenType{ .token_int, .token_plus, .token_bool });

    try runTest("0+0", &[_]TokenType{ .token_int, .token_plus, .token_int });
    try runTest("0+1", &[_]TokenType{ .token_int, .token_plus, .token_int });
    try runTest("0+-1", &[_]TokenType{ .token_int, .token_plus, .token_int });
    try runTest("1+0", &[_]TokenType{ .token_int, .token_plus, .token_int });
    try runTest("1+1", &[_]TokenType{ .token_int, .token_plus, .token_int });
    try runTest("1+-1", &[_]TokenType{ .token_int, .token_plus, .token_int });
    try runTest("-1+0", &[_]TokenType{ .token_int, .token_plus, .token_int });
    try runTest("-1+1", &[_]TokenType{ .token_int, .token_plus, .token_int });
    try runTest("-1+-1", &[_]TokenType{ .token_int, .token_plus, .token_int });

    try runTest("0+0f", &[_]TokenType{ .token_int, .token_plus, .token_float });
    try runTest("0+1f", &[_]TokenType{ .token_int, .token_plus, .token_float });
    try runTest("0+-1f", &[_]TokenType{ .token_int, .token_plus, .token_float });
    try runTest("1+0f", &[_]TokenType{ .token_int, .token_plus, .token_float });
    try runTest("1+1f", &[_]TokenType{ .token_int, .token_plus, .token_float });
    try runTest("1+-1f", &[_]TokenType{ .token_int, .token_plus, .token_float });
    try runTest("-1+0f", &[_]TokenType{ .token_int, .token_plus, .token_float });
    try runTest("-1+1f", &[_]TokenType{ .token_int, .token_plus, .token_float });
    try runTest("-1+-1f", &[_]TokenType{ .token_int, .token_plus, .token_float });
}

test "scanner - float addition" {
    try runTest("0f+0b", &[_]TokenType{ .token_float, .token_plus, .token_bool });
    try runTest("0f+1b", &[_]TokenType{ .token_float, .token_plus, .token_bool });
    try runTest("1f+0b", &[_]TokenType{ .token_float, .token_plus, .token_bool });
    try runTest("1f+1b", &[_]TokenType{ .token_float, .token_plus, .token_bool });
    try runTest("-1f+0b", &[_]TokenType{ .token_float, .token_plus, .token_bool });
    try runTest("-1f+1b", &[_]TokenType{ .token_float, .token_plus, .token_bool });

    try runTest("0f+0", &[_]TokenType{ .token_float, .token_plus, .token_int });
    try runTest("0f+1", &[_]TokenType{ .token_float, .token_plus, .token_int });
    try runTest("0f+-1", &[_]TokenType{ .token_float, .token_plus, .token_int });
    try runTest("1f+0", &[_]TokenType{ .token_float, .token_plus, .token_int });
    try runTest("1f+1", &[_]TokenType{ .token_float, .token_plus, .token_int });
    try runTest("1f+-1", &[_]TokenType{ .token_float, .token_plus, .token_int });
    try runTest("-1f+0", &[_]TokenType{ .token_float, .token_plus, .token_int });
    try runTest("-1f+1", &[_]TokenType{ .token_float, .token_plus, .token_int });
    try runTest("-1f+-1", &[_]TokenType{ .token_float, .token_plus, .token_int });

    try runTest("0f+0f", &[_]TokenType{ .token_float, .token_plus, .token_float });
    try runTest("0f+1f", &[_]TokenType{ .token_float, .token_plus, .token_float });
    try runTest("0f+-1f", &[_]TokenType{ .token_float, .token_plus, .token_float });
    try runTest("1f+0f", &[_]TokenType{ .token_float, .token_plus, .token_float });
    try runTest("1f+1f", &[_]TokenType{ .token_float, .token_plus, .token_float });
    try runTest("1f+-1f", &[_]TokenType{ .token_float, .token_plus, .token_float });
    try runTest("-1f+0f", &[_]TokenType{ .token_float, .token_plus, .token_float });
    try runTest("-1f+1f", &[_]TokenType{ .token_float, .token_plus, .token_float });
    try runTest("-1f+-1f", &[_]TokenType{ .token_float, .token_plus, .token_float });
}

test "scanner - boolean subtraction" {
    try runTest("0b-0b", &[_]TokenType{ .token_bool, .token_minus, .token_bool });
    try runTest("0b-1b", &[_]TokenType{ .token_bool, .token_minus, .token_bool });
    try runTest("1b-0b", &[_]TokenType{ .token_bool, .token_minus, .token_bool });
    try runTest("1b-1b", &[_]TokenType{ .token_bool, .token_minus, .token_bool });

    try runTest("0b-0", &[_]TokenType{ .token_bool, .token_minus, .token_int });
    try runTest("0b-1", &[_]TokenType{ .token_bool, .token_minus, .token_int });
    try runTest("0b--1", &[_]TokenType{ .token_bool, .token_minus, .token_int });
    try runTest("1b-0", &[_]TokenType{ .token_bool, .token_minus, .token_int });
    try runTest("1b-1", &[_]TokenType{ .token_bool, .token_minus, .token_int });
    try runTest("1b--1", &[_]TokenType{ .token_bool, .token_minus, .token_int });

    try runTest("0b-0f", &[_]TokenType{ .token_bool, .token_minus, .token_float });
    try runTest("0b-1f", &[_]TokenType{ .token_bool, .token_minus, .token_float });
    try runTest("0b--1f", &[_]TokenType{ .token_bool, .token_minus, .token_float });
    try runTest("1b-0f", &[_]TokenType{ .token_bool, .token_minus, .token_float });
    try runTest("1b-1f", &[_]TokenType{ .token_bool, .token_minus, .token_float });
    try runTest("1b--1f", &[_]TokenType{ .token_bool, .token_minus, .token_float });
}

test "scanner - int subtraction" {
    try runTest("0-0b", &[_]TokenType{ .token_int, .token_minus, .token_bool });
    try runTest("0-1b", &[_]TokenType{ .token_int, .token_minus, .token_bool });
    try runTest("1-0b", &[_]TokenType{ .token_int, .token_minus, .token_bool });
    try runTest("1-1b", &[_]TokenType{ .token_int, .token_minus, .token_bool });
    try runTest("-1-0b", &[_]TokenType{ .token_int, .token_minus, .token_bool });
    try runTest("-1-1b", &[_]TokenType{ .token_int, .token_minus, .token_bool });

    try runTest("0-0", &[_]TokenType{ .token_int, .token_minus, .token_int });
    try runTest("0-1", &[_]TokenType{ .token_int, .token_minus, .token_int });
    try runTest("0--1", &[_]TokenType{ .token_int, .token_minus, .token_int });
    try runTest("1-0", &[_]TokenType{ .token_int, .token_minus, .token_int });
    try runTest("1-1", &[_]TokenType{ .token_int, .token_minus, .token_int });
    try runTest("1--1", &[_]TokenType{ .token_int, .token_minus, .token_int });
    try runTest("-1-0", &[_]TokenType{ .token_int, .token_minus, .token_int });
    try runTest("-1-1", &[_]TokenType{ .token_int, .token_minus, .token_int });
    try runTest("-1--1", &[_]TokenType{ .token_int, .token_minus, .token_int });

    try runTest("0-0f", &[_]TokenType{ .token_int, .token_minus, .token_float });
    try runTest("0-1f", &[_]TokenType{ .token_int, .token_minus, .token_float });
    try runTest("0--1f", &[_]TokenType{ .token_int, .token_minus, .token_float });
    try runTest("1-0f", &[_]TokenType{ .token_int, .token_minus, .token_float });
    try runTest("1-1f", &[_]TokenType{ .token_int, .token_minus, .token_float });
    try runTest("1--1f", &[_]TokenType{ .token_int, .token_minus, .token_float });
    try runTest("-1-0f", &[_]TokenType{ .token_int, .token_minus, .token_float });
    try runTest("-1-1f", &[_]TokenType{ .token_int, .token_minus, .token_float });
    try runTest("-1--1f", &[_]TokenType{ .token_int, .token_minus, .token_float });
}

test "scanner - float subtraction" {
    try runTest("0f-0b", &[_]TokenType{ .token_float, .token_minus, .token_bool });
    try runTest("0f-1b", &[_]TokenType{ .token_float, .token_minus, .token_bool });
    try runTest("1f-0b", &[_]TokenType{ .token_float, .token_minus, .token_bool });
    try runTest("1f-1b", &[_]TokenType{ .token_float, .token_minus, .token_bool });
    try runTest("-1f-0b", &[_]TokenType{ .token_float, .token_minus, .token_bool });
    try runTest("-1f-1b", &[_]TokenType{ .token_float, .token_minus, .token_bool });

    try runTest("0f-0", &[_]TokenType{ .token_float, .token_minus, .token_int });
    try runTest("0f-1", &[_]TokenType{ .token_float, .token_minus, .token_int });
    try runTest("0f--1", &[_]TokenType{ .token_float, .token_minus, .token_int });
    try runTest("1f-0", &[_]TokenType{ .token_float, .token_minus, .token_int });
    try runTest("1f-1", &[_]TokenType{ .token_float, .token_minus, .token_int });
    try runTest("1f--1", &[_]TokenType{ .token_float, .token_minus, .token_int });
    try runTest("-1f-0", &[_]TokenType{ .token_float, .token_minus, .token_int });
    try runTest("-1f-1", &[_]TokenType{ .token_float, .token_minus, .token_int });
    try runTest("-1f--1", &[_]TokenType{ .token_float, .token_minus, .token_int });

    try runTest("0f-0f", &[_]TokenType{ .token_float, .token_minus, .token_float });
    try runTest("0f-1f", &[_]TokenType{ .token_float, .token_minus, .token_float });
    try runTest("0f--1f", &[_]TokenType{ .token_float, .token_minus, .token_float });
    try runTest("1f-0f", &[_]TokenType{ .token_float, .token_minus, .token_float });
    try runTest("1f-1f", &[_]TokenType{ .token_float, .token_minus, .token_float });
    try runTest("1f--1f", &[_]TokenType{ .token_float, .token_minus, .token_float });
    try runTest("-1f-0f", &[_]TokenType{ .token_float, .token_minus, .token_float });
    try runTest("-1f-1f", &[_]TokenType{ .token_float, .token_minus, .token_float });
    try runTest("-1f--1f", &[_]TokenType{ .token_float, .token_minus, .token_float });
}

test "scanner - boolean multiplication" {
    try runTest("0b*0b", &[_]TokenType{ .token_bool, .token_star, .token_bool });
    try runTest("0b*1b", &[_]TokenType{ .token_bool, .token_star, .token_bool });
    try runTest("1b*0b", &[_]TokenType{ .token_bool, .token_star, .token_bool });
    try runTest("1b*1b", &[_]TokenType{ .token_bool, .token_star, .token_bool });

    try runTest("0b*0", &[_]TokenType{ .token_bool, .token_star, .token_int });
    try runTest("0b*1", &[_]TokenType{ .token_bool, .token_star, .token_int });
    try runTest("0b*-1", &[_]TokenType{ .token_bool, .token_star, .token_int });
    try runTest("1b*0", &[_]TokenType{ .token_bool, .token_star, .token_int });
    try runTest("1b*1", &[_]TokenType{ .token_bool, .token_star, .token_int });
    try runTest("1b*-1", &[_]TokenType{ .token_bool, .token_star, .token_int });

    try runTest("0b*0f", &[_]TokenType{ .token_bool, .token_star, .token_float });
    try runTest("0b*1f", &[_]TokenType{ .token_bool, .token_star, .token_float });
    try runTest("0b*-1f", &[_]TokenType{ .token_bool, .token_star, .token_float });
    try runTest("1b*0f", &[_]TokenType{ .token_bool, .token_star, .token_float });
    try runTest("1b*1f", &[_]TokenType{ .token_bool, .token_star, .token_float });
    try runTest("1b*-1f", &[_]TokenType{ .token_bool, .token_star, .token_float });
}

test "scanner - int multiplication" {
    try runTest("0*0b", &[_]TokenType{ .token_int, .token_star, .token_bool });
    try runTest("0*1b", &[_]TokenType{ .token_int, .token_star, .token_bool });
    try runTest("1*0b", &[_]TokenType{ .token_int, .token_star, .token_bool });
    try runTest("1*1b", &[_]TokenType{ .token_int, .token_star, .token_bool });
    try runTest("-1*0b", &[_]TokenType{ .token_int, .token_star, .token_bool });
    try runTest("-1*1b", &[_]TokenType{ .token_int, .token_star, .token_bool });

    try runTest("0*0", &[_]TokenType{ .token_int, .token_star, .token_int });
    try runTest("0*1", &[_]TokenType{ .token_int, .token_star, .token_int });
    try runTest("0*-1", &[_]TokenType{ .token_int, .token_star, .token_int });
    try runTest("1*0", &[_]TokenType{ .token_int, .token_star, .token_int });
    try runTest("1*1", &[_]TokenType{ .token_int, .token_star, .token_int });
    try runTest("1*-1", &[_]TokenType{ .token_int, .token_star, .token_int });
    try runTest("-1*0", &[_]TokenType{ .token_int, .token_star, .token_int });
    try runTest("-1*1", &[_]TokenType{ .token_int, .token_star, .token_int });
    try runTest("-1*-1", &[_]TokenType{ .token_int, .token_star, .token_int });

    try runTest("0*0f", &[_]TokenType{ .token_int, .token_star, .token_float });
    try runTest("0*1f", &[_]TokenType{ .token_int, .token_star, .token_float });
    try runTest("0*-1f", &[_]TokenType{ .token_int, .token_star, .token_float });
    try runTest("1*0f", &[_]TokenType{ .token_int, .token_star, .token_float });
    try runTest("1*1f", &[_]TokenType{ .token_int, .token_star, .token_float });
    try runTest("1*-1f", &[_]TokenType{ .token_int, .token_star, .token_float });
    try runTest("-1*0f", &[_]TokenType{ .token_int, .token_star, .token_float });
    try runTest("-1*1f", &[_]TokenType{ .token_int, .token_star, .token_float });
    try runTest("-1*-1f", &[_]TokenType{ .token_int, .token_star, .token_float });
}

test "scanner - float multiplication" {
    try runTest("0f*0b", &[_]TokenType{ .token_float, .token_star, .token_bool });
    try runTest("0f*1b", &[_]TokenType{ .token_float, .token_star, .token_bool });
    try runTest("1f*0b", &[_]TokenType{ .token_float, .token_star, .token_bool });
    try runTest("1f*1b", &[_]TokenType{ .token_float, .token_star, .token_bool });
    try runTest("-1f*0b", &[_]TokenType{ .token_float, .token_star, .token_bool });
    try runTest("-1f*1b", &[_]TokenType{ .token_float, .token_star, .token_bool });

    try runTest("0f*0", &[_]TokenType{ .token_float, .token_star, .token_int });
    try runTest("0f*1", &[_]TokenType{ .token_float, .token_star, .token_int });
    try runTest("0f*-1", &[_]TokenType{ .token_float, .token_star, .token_int });
    try runTest("1f*0", &[_]TokenType{ .token_float, .token_star, .token_int });
    try runTest("1f*1", &[_]TokenType{ .token_float, .token_star, .token_int });
    try runTest("1f*-1", &[_]TokenType{ .token_float, .token_star, .token_int });
    try runTest("-1f*0", &[_]TokenType{ .token_float, .token_star, .token_int });
    try runTest("-1f*1", &[_]TokenType{ .token_float, .token_star, .token_int });
    try runTest("-1f*-1", &[_]TokenType{ .token_float, .token_star, .token_int });

    try runTest("0f*0f", &[_]TokenType{ .token_float, .token_star, .token_float });
    try runTest("0f*1f", &[_]TokenType{ .token_float, .token_star, .token_float });
    try runTest("0f*-1f", &[_]TokenType{ .token_float, .token_star, .token_float });
    try runTest("1f*0f", &[_]TokenType{ .token_float, .token_star, .token_float });
    try runTest("1f*1f", &[_]TokenType{ .token_float, .token_star, .token_float });
    try runTest("1f*-1f", &[_]TokenType{ .token_float, .token_star, .token_float });
    try runTest("-1f*0f", &[_]TokenType{ .token_float, .token_star, .token_float });
    try runTest("-1f*1f", &[_]TokenType{ .token_float, .token_star, .token_float });
    try runTest("-1f*-1f", &[_]TokenType{ .token_float, .token_star, .token_float });
}

test "scanner - boolean division" {
    try runTest("0b%0b", &[_]TokenType{ .token_bool, .token_percent, .token_bool });
    try runTest("0b%1b", &[_]TokenType{ .token_bool, .token_percent, .token_bool });
    try runTest("1b%0b", &[_]TokenType{ .token_bool, .token_percent, .token_bool });
    try runTest("1b%1b", &[_]TokenType{ .token_bool, .token_percent, .token_bool });

    try runTest("0b%0", &[_]TokenType{ .token_bool, .token_percent, .token_int });
    try runTest("0b%1", &[_]TokenType{ .token_bool, .token_percent, .token_int });
    try runTest("0b%-1", &[_]TokenType{ .token_bool, .token_percent, .token_int });
    try runTest("1b%0", &[_]TokenType{ .token_bool, .token_percent, .token_int });
    try runTest("1b%1", &[_]TokenType{ .token_bool, .token_percent, .token_int });
    try runTest("1b%-1", &[_]TokenType{ .token_bool, .token_percent, .token_int });

    try runTest("0b%0f", &[_]TokenType{ .token_bool, .token_percent, .token_float });
    try runTest("0b%1f", &[_]TokenType{ .token_bool, .token_percent, .token_float });
    try runTest("0b%-1f", &[_]TokenType{ .token_bool, .token_percent, .token_float });
    try runTest("1b%0f", &[_]TokenType{ .token_bool, .token_percent, .token_float });
    try runTest("1b%1f", &[_]TokenType{ .token_bool, .token_percent, .token_float });
    try runTest("1b%-1f", &[_]TokenType{ .token_bool, .token_percent, .token_float });
}

test "scanner - int division" {
    try runTest("0%0b", &[_]TokenType{ .token_int, .token_percent, .token_bool });
    try runTest("0%1b", &[_]TokenType{ .token_int, .token_percent, .token_bool });
    try runTest("1%0b", &[_]TokenType{ .token_int, .token_percent, .token_bool });
    try runTest("1%1b", &[_]TokenType{ .token_int, .token_percent, .token_bool });
    try runTest("-1%0b", &[_]TokenType{ .token_int, .token_percent, .token_bool });
    try runTest("-1%1b", &[_]TokenType{ .token_int, .token_percent, .token_bool });

    try runTest("0%0", &[_]TokenType{ .token_int, .token_percent, .token_int });
    try runTest("0%1", &[_]TokenType{ .token_int, .token_percent, .token_int });
    try runTest("0%-1", &[_]TokenType{ .token_int, .token_percent, .token_int });
    try runTest("1%0", &[_]TokenType{ .token_int, .token_percent, .token_int });
    try runTest("1%1", &[_]TokenType{ .token_int, .token_percent, .token_int });
    try runTest("1%-1", &[_]TokenType{ .token_int, .token_percent, .token_int });
    try runTest("-1%0", &[_]TokenType{ .token_int, .token_percent, .token_int });
    try runTest("-1%1", &[_]TokenType{ .token_int, .token_percent, .token_int });
    try runTest("-1%-1", &[_]TokenType{ .token_int, .token_percent, .token_int });

    try runTest("0%0f", &[_]TokenType{ .token_int, .token_percent, .token_float });
    try runTest("0%1f", &[_]TokenType{ .token_int, .token_percent, .token_float });
    try runTest("0%-1f", &[_]TokenType{ .token_int, .token_percent, .token_float });
    try runTest("1%0f", &[_]TokenType{ .token_int, .token_percent, .token_float });
    try runTest("1%1f", &[_]TokenType{ .token_int, .token_percent, .token_float });
    try runTest("1%-1f", &[_]TokenType{ .token_int, .token_percent, .token_float });
    try runTest("-1%0f", &[_]TokenType{ .token_int, .token_percent, .token_float });
    try runTest("-1%1f", &[_]TokenType{ .token_int, .token_percent, .token_float });
    try runTest("-1%-1f", &[_]TokenType{ .token_int, .token_percent, .token_float });
}

test "scanner - float division" {
    try runTest("0f%0b", &[_]TokenType{ .token_float, .token_percent, .token_bool });
    try runTest("0f%1b", &[_]TokenType{ .token_float, .token_percent, .token_bool });
    try runTest("1f%0b", &[_]TokenType{ .token_float, .token_percent, .token_bool });
    try runTest("1f%1b", &[_]TokenType{ .token_float, .token_percent, .token_bool });
    try runTest("-1f%0b", &[_]TokenType{ .token_float, .token_percent, .token_bool });
    try runTest("-1f%1b", &[_]TokenType{ .token_float, .token_percent, .token_bool });

    try runTest("0f%0", &[_]TokenType{ .token_float, .token_percent, .token_int });
    try runTest("0f%1", &[_]TokenType{ .token_float, .token_percent, .token_int });
    try runTest("0f%-1", &[_]TokenType{ .token_float, .token_percent, .token_int });
    try runTest("1f%0", &[_]TokenType{ .token_float, .token_percent, .token_int });
    try runTest("1f%1", &[_]TokenType{ .token_float, .token_percent, .token_int });
    try runTest("1f%-1", &[_]TokenType{ .token_float, .token_percent, .token_int });
    try runTest("-1f%0", &[_]TokenType{ .token_float, .token_percent, .token_int });
    try runTest("-1f%1", &[_]TokenType{ .token_float, .token_percent, .token_int });
    try runTest("-1f%-1", &[_]TokenType{ .token_float, .token_percent, .token_int });

    try runTest("0f%0f", &[_]TokenType{ .token_float, .token_percent, .token_float });
    try runTest("0f%1f", &[_]TokenType{ .token_float, .token_percent, .token_float });
    try runTest("0f%-1f", &[_]TokenType{ .token_float, .token_percent, .token_float });
    try runTest("1f%0f", &[_]TokenType{ .token_float, .token_percent, .token_float });
    try runTest("1f%1f", &[_]TokenType{ .token_float, .token_percent, .token_float });
    try runTest("1f%-1f", &[_]TokenType{ .token_float, .token_percent, .token_float });
    try runTest("-1f%0f", &[_]TokenType{ .token_float, .token_percent, .token_float });
    try runTest("-1f%1f", &[_]TokenType{ .token_float, .token_percent, .token_float });
    try runTest("-1f%-1f", &[_]TokenType{ .token_float, .token_percent, .token_float });
}
