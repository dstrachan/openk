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
    token_ampersand,
    token_pipe,
    token_less,
    token_greater,
    token_equal,
    token_tilde,
    token_bang,
    token_comma,
    token_at,
    token_question,
    token_caret,
    token_hash,
    token_underscore,
    token_dollar,
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
    skipped_whitespace: bool,

    pub fn init(source: []const u8) Self {
        return Self{
            .source = source,
            .start = source.ptr,
            .current = source.ptr,
            .line = 1,
            .skipped_whitespace = false,
        };
    }

    pub fn scanToken(self: *Self) Token {
        self.skipWhitespace();
        self.start = self.current;

        if (self.isAtEnd()) return self.makeToken(.token_eof);

        const c = self.advance();
        if (isAlpha(c)) return self.identifier();
        if (isDigit(c)) return self.number();

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
            '&' => self.makeToken(.token_ampersand),
            '|' => self.makeToken(.token_pipe),
            '<' => self.makeToken(.token_less),
            '>' => self.makeToken(.token_greater),
            '=' => self.makeToken(.token_equal),
            '~' => self.makeToken(.token_tilde),
            '!' => self.makeToken(.token_bang),
            ',' => self.makeToken(.token_comma),
            '@' => self.makeToken(.token_at),
            '?' => self.makeToken(.token_question),
            '^' => self.makeToken(.token_caret),
            '#' => self.makeToken(.token_hash),
            '_' => self.makeToken(.token_underscore),
            '$' => self.makeToken(.token_dollar),
            '.' => self.makeToken(.token_dot),
            // '"' => self.string(),
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
        self.skipped_whitespace = self.start == self.source.ptr;

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

    fn number(self: *Self) Token {
        while (isDigit(self.peek())) _ = self.advance();

        if (self.peek() == '.' and isDigit(self.peekNext())) {
            _ = self.advance();

            while (isDigit(self.peek())) _ = self.advance();
        }

        return self.makeToken(.token_float);
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
        return Token{
            .token_type = token_type,
            .lexeme = lexeme,
            .line = self.line,
            .follows_whitespace = self.skipped_whitespace,
        };
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
