const utils_mod = @import("utils.zig");
const print = utils_mod.print;

const debug_print_chars = @import("builtin").mode == .Debug and !@import("builtin").is_test;

pub const Token = struct {
    token_type: TokenType,
    lexeme: []const u8,
    line: usize,
    follows_whitespace: bool,
};

pub const TokenType = enum {
    // Punctuation.
    token_left_paren,
    token_right_paren,
    token_left_brace,
    token_right_brace,
    token_left_bracket,
    token_right_bracket,
    token_semicolon,
    token_colon,
    token_double_colon,

    // Verbs.
    token_plus,
    token_minus,
    token_star,
    token_percent,
    token_bang,
    token_ampersand,
    token_pipe,
    token_less,
    token_greater,
    token_equal,
    token_tilde,
    token_comma,
    token_caret,
    token_hash,
    token_underscore,
    token_dollar,
    token_question,
    token_at,
    token_dot,

    // Literals.
    token_bool,
    token_int,
    token_float,
    token_symbol,
    token_char,
    token_string,
    token_identifier,

    token_error,
    token_eof,
};

pub const Scanner = struct {
    const Self = @This();

    source: []const u8,
    start: [*]const u8,
    current: [*]const u8,
    line: usize,
    prev_token: Token,
    skipped_whitespace: bool,

    pub fn init(source: []const u8) Self {
        return Self{
            .source = source,
            .start = source.ptr,
            .current = source.ptr,
            .line = 1,
            .prev_token = Token{
                .token_type = .token_error,
                .lexeme = "",
                .line = 1,
                .follows_whitespace = false,
            },
            .skipped_whitespace = true,
        };
    }

    pub fn scanToken(self: *Self) Token {
        self.skipWhitespace();
        self.start = self.current;

        if (self.isAtEnd()) return self.makeToken(.token_eof);

        const c = self.advance();
        if (comptime debug_print_chars) print("c = '{s}'\n", .{&[_]u8{c}});

        if (isAlpha(c)) return self.identifier();
        if (isDigit(c)) return self.number(c);
        if (c == '.' and isDigit(self.peek())) return self.float();
        if (c == '-') {
            const p = self.peek();
            if (p == '.' or isDigit(p)) {
                if (self.skipped_whitespace) {
                    return self.negativeNumber();
                }
                return switch (self.prev_token.token_type) {
                    .token_identifier,
                    .token_bool,
                    .token_int,
                    .token_float,
                    .token_char,
                    .token_string,
                    .token_right_bracket,
                    .token_right_paren,
                    => self.makeToken(.token_minus),
                    else => self.negativeNumber(),
                };
            }
        }

        return switch (c) {
            '(' => self.makeToken(.token_left_paren),
            ')' => self.makeToken(.token_right_paren),
            '{' => self.makeToken(.token_left_brace),
            '}' => self.makeToken(.token_right_brace),
            '[' => self.makeToken(.token_left_bracket),
            ']' => self.makeToken(.token_right_bracket),
            ';' => self.makeToken(.token_semicolon),
            ':' => if (self.match(':')) self.makeToken(.token_double_colon) else self.makeToken(.token_colon),
            '+' => self.makeToken(.token_plus),
            '-' => self.makeToken(.token_minus),
            '*' => self.makeToken(.token_star),
            '%' => self.makeToken(.token_percent),
            '!' => self.makeToken(.token_bang),
            '&' => self.makeToken(.token_ampersand),
            '|' => self.makeToken(.token_pipe),
            '<' => self.makeToken(.token_less),
            '>' => self.makeToken(.token_greater),
            '=' => self.makeToken(.token_equal),
            '~' => self.makeToken(.token_tilde),
            ',' => self.makeToken(.token_comma),
            '^' => self.makeToken(.token_caret),
            '#' => self.makeToken(.token_hash),
            '_' => self.makeToken(.token_underscore),
            '$' => self.makeToken(.token_dollar),
            '?' => self.makeToken(.token_question),
            '@' => self.makeToken(.token_at),
            '.' => self.makeToken(.token_dot),
            '"' => self.string(),
            '`' => self.symbol(),
            else => self.errorToken("Unexpected character."),
        };
    }

    fn advance(self: *Self) u8 {
        defer self.current += 1;
        return self.current[0];
    }

    fn match(self: *Self, expected: u8) bool {
        if (self.isAtEnd()) return false;
        if (self.current[0] != expected) return false;
        self.current += 1;
        return true;
    }

    fn skipWhitespace(self: *Self) void {
        while (true) {
            const c = self.peek();
            switch (c) {
                ' ', '\r', '\t' => _ = self.advance(),
                '\n' => {
                    self.line += 1;
                    _ = self.advance();
                },
                '/' => {
                    if (self.peekNext() == '/') {
                        while (self.peek() != '\n' and !self.isAtEnd()) _ = self.advance();
                    } else {
                        return;
                    }
                },
                else => return,
            }
            self.skipped_whitespace = true;
        }
    }

    fn identifier(self: *Self) Token {
        while (isAlpha(self.peek()) or isDigit(self.peek())) _ = self.advance();
        return self.makeToken(.token_identifier);
    }

    fn negativeNumber(self: *Self) Token {
        while (isDigit(self.peek())) _ = self.advance();

        if (self.peek() == '.') {
            _ = self.advance();
            return self.float();
        }

        const next = self.peek();
        if (next == 'W') {
            _ = self.advance();
        } else if (next == 'w') {
            _ = self.advance();
            if (self.peek() == 'f') {
                defer _ = self.advance();
                return self.makeToken(.token_float);
            }
            return self.makeToken(.token_float);
        }

        if (self.peek() == 'f') {
            defer _ = self.advance();
            return self.makeToken(.token_float);
        }

        return self.makeToken(.token_int);
    }

    fn number(self: *Self, c: u8) Token {
        var token_type: TokenType = if (c > '1') .token_int else .token_bool;
        while (isDigit(self.peek())) {
            if (self.peek() > '1') token_type = .token_int;
            _ = self.advance();
        }

        if (self.peek() == '.') {
            _ = self.advance();
            return self.float();
        }

        if (self.peek() == 'b') {
            _ = self.advance();
            return if (token_type == .token_bool) self.makeToken(.token_bool) else self.errorToken("Invalid boolean value.");
        }

        const next = self.peek();
        if (next == 'W' or next == 'N') {
            _ = self.advance();
        } else if (next == 'w' or next == 'n') {
            _ = self.advance();
            if (self.peek() == 'f') {
                defer _ = self.advance();
                return self.makeToken(.token_float);
            }
            return self.makeToken(.token_float);
        }

        if (self.peek() == 'f') {
            defer _ = self.advance();
            return self.makeToken(.token_float);
        }

        return self.makeToken(.token_int);
    }

    fn float(self: *Self) Token {
        while (isDigit(self.peek())) _ = self.advance();

        if (self.peek() == '.') {
            _ = self.advance();
            var p = self.peek();
            while (isDigit(p) or 0 == '.' or p == 'f') : (p = self.peek()) _ = self.advance();
            return self.errorToken("Too many decimal points.");
        }

        if (self.peek() == 'f') {
            defer _ = self.advance();
            return self.makeToken(.token_float);
        }

        return self.makeToken(.token_float);
    }

    fn string(self: *Self) Token {
        var len: usize = 0;
        while (self.peek() != '"' and !self.isAtEnd()) {
            switch (self.peek()) {
                '\n' => self.line += 1,
                '\\' => _ = self.advance(),
                else => {},
            }
            _ = self.advance();
            len += 1;
        }

        if (self.isAtEnd()) return self.errorToken("Unterminated string.");

        _ = self.advance();
        return self.makeToken(if (len == 1) .token_char else .token_string);
    }

    fn symbol(self: *Self) Token {
        while (isSymbolChar(self.peek())) _ = self.advance();

        return self.makeToken(.token_symbol);
    }

    fn isAtEnd(self: *Self) bool {
        const current_len = @ptrToInt(self.current) - @ptrToInt(self.source.ptr);
        return current_len >= self.source.len;
    }

    fn peek(self: *Self) u8 {
        if (self.isAtEnd()) return 0;
        return self.current[0];
    }

    fn peekNext(self: *Self) u8 {
        if (self.isAtEnd()) return 0;
        return self.current[1];
    }

    fn makeToken(self: *Self, token_type: TokenType) Token {
        return self.token(token_type, self.start[0..(@ptrToInt(self.current) - @ptrToInt(self.start))]);
    }

    fn errorToken(self: *Self, message: []const u8) Token {
        return self.token(.token_error, message);
    }

    fn token(self: *Self, token_type: TokenType, lexeme: []const u8) Token {
        self.prev_token = Token{
            .token_type = token_type,
            .lexeme = lexeme,
            .line = self.line,
            .follows_whitespace = self.skipped_whitespace,
        };
        self.skipped_whitespace = false;
        return self.prev_token;
    }
};

fn isAlpha(c: u8) bool {
    return switch (c) {
        'a'...'z', 'A'...'Z', '_' => true,
        else => false,
    };
}

fn isSymbolChar(c: u8) bool {
    return switch (c) {
        'a'...'z', 'A'...'Z', '0'...'9', '.', '_' => true,
        else => false,
    };
}

fn isDigit(c: u8) bool {
    return c >= '0' and c <= '9';
}
