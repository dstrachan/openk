const std = @import("std");

pub const Token = struct {
    tag: Tag,
    loc: Loc,

    pub const Loc = struct {
        start: usize,
        end: usize,
    };

    pub const Tag = enum {
        // Punctuation
        l_paren,
        r_paren,
        l_bracket,
        r_bracket,
        l_brace,
        r_brace,
        semicolon,

        // Operators
        bang,
        bang_colon,
        hash,
        hash_colon,
        dollar,
        dollar_colon,
        percent,
        percent_colon,
        ampersand,
        ampersand_colon,
        asterisk,
        asterisk_colon,
        plus,
        plus_colon,
        comma,
        comma_colon,
        minus,
        minus_colon,
        dot,
        dot_colon,
        colon,
        colon_colon,
        l_angle_bracket,
        l_angle_bracket_colon,
        equal,
        equal_colon,
        r_angle_bracket,
        r_angle_bracket_colon,
        question_mark,
        question_mark_colon,
        at,
        at_colon,
        caret,
        caret_colon,
        underscore,
        underscore_colon,
        pipe,
        pipe_colon,
        tilde,
        tilde_colon,
        zero_colon,
        zero_colon_colon,
        one_colon,
        one_colon_colon,
        two_colon,

        // Iterators
        apostrophe,
        apostrophe_colon,
        slash,
        slash_colon,
        backslash,
        backslash_colon,

        // Literals
        number_literal,
        string_literal,
        symbol_literal,
        identifier,

        // Misc.
        system,
        invalid,
        eof,

        pub fn lexeme(tag: Tag) ?[]const u8 {
            return switch (tag) {
                .l_paren => "(",
                .r_paren => ")",
                .l_bracket => "[",
                .r_bracket => "]",
                .l_brace => "{",
                .r_brace => "}",
                .semicolon => ";",

                .bang => "!",
                .bang_colon => "!:",
                .hash => "#",
                .hash_colon => "#:",
                .dollar => "$",
                .dollar_colon => "$:",
                .percent => "%",
                .percent_colon => "%:",
                .ampersand => "&",
                .ampersand_colon => "&:",
                .asterisk => "*",
                .asterisk_colon => "*:",
                .plus => "+",
                .plus_colon => "+:",
                .comma => ",",
                .comma_colon => ",:",
                .minus => "-",
                .minus_colon => "-:",
                .dot => ".",
                .dot_colon => ".:",
                .colon => ":",
                .colon_colon => "::",
                .l_angle_bracket => "<",
                .l_angle_bracket_colon => "<:",
                .equal => "=",
                .equal_colon => "=:",
                .r_angle_bracket => ">",
                .r_angle_bracket_colon => ">:",
                .question_mark => "?",
                .question_mark_colon => "?:",
                .at => "@",
                .at_colon => "@:",
                .caret => "^",
                .caret_colon => "^:",
                .underscore => "_",
                .underscore_colon => "_:",
                .pipe => "|",
                .pipe_colon => "|:",
                .tilde => "~",
                .tilde_colon => "~:",
                .zero_colon => "0:",
                .zero_colon_colon => "0::",
                .one_colon => "1:",
                .one_colon_colon => "1::",
                .two_colon => "2:",

                .apostrophe => "'",
                .apostrophe_colon => "':",
                .slash => "/",
                .slash_colon => "/:",
                .backslash => "\\",
                .backslash_colon => "\\:",

                .number_literal,
                .string_literal,
                .symbol_literal,
                .identifier,
                => null,

                .system,
                .invalid,
                .eof,
                => null,
            };
        }

        pub fn symbol(tag: Tag) []const u8 {
            return tag.lexeme() orelse switch (tag) {
                .number_literal => "a number literal",
                .string_literal => "string literal",
                .symbol_literal => "symbol literal",
                .identifier => "identifier",
                .system => "system command",
                .invalid => "invalid token",
                .eof => "end of file",
                else => unreachable,
            };
        }
    };

    fn eof(index: usize) Token {
        return .{
            .tag = .eof,
            .loc = .{
                .start = index,
                .end = index,
            },
        };
    }
};

pub const Tokenizer = struct {
    buffer: [:0]const u8,
    index: usize,

    pub fn init(buffer: [:0]const u8) Tokenizer {
        // Skip the UTF-8 BOM if present.
        return .{
            .buffer = buffer,
            .index = if (std.mem.startsWith(u8, buffer, "\xEF\xBB\xBF")) 3 else 0,
        };
    }

    const State = enum {
        start,
        string_literal,
        string_literal_newline,
        string_literal_backslash,
        octal_char_two,
        octal_char_three,
        symbol_literal_start,
        symbol_literal,
        file_handle,
        zero,
        one,
        two,
        number_literal,
        identifier,
        bang,
        hash,
        dollar,
        percent,
        ampersand,
        apostrophe,
        asterisk,
        plus,
        comma,
        minus,
        dot,
        slash,
        colon,
        l_angle_bracket,
        equal,
        r_angle_bracket,
        question_mark,
        at,
        system,
        backslash,
        caret,
        underscore,
        pipe,
        tilde,
        skip_line,
        invalid,
    };

    pub fn next(self: *Tokenizer) Token {
        var result: Token = .{
            .tag = undefined,
            .loc = .{
                .start = self.index,
                .end = undefined,
            },
        };

        state: switch (State.start) {
            .start => switch (self.buffer[self.index]) {
                0 => if (self.index != self.buffer.len) {
                    continue :state .invalid;
                } else return .eof(self.buffer.len),
                '\r' => if (self.buffer[self.index + 1] == '\n') {
                    self.index += 2;
                    result.loc.start = self.index;
                    continue :state .start;
                } else continue :state .invalid,
                ' ', '\n', '\t' => {
                    self.index += 1;
                    result.loc.start = self.index;
                    continue :state .start;
                },
                '(' => {
                    result.tag = .l_paren;
                    self.index += 1;
                },
                ')' => {
                    result.tag = .r_paren;
                    self.index += 1;
                },
                '[' => {
                    result.tag = .l_bracket;
                    self.index += 1;
                },
                ']' => {
                    result.tag = .r_bracket;
                    self.index += 1;
                },
                '{' => {
                    result.tag = .l_brace;
                    self.index += 1;
                },
                '}' => {
                    result.tag = .r_brace;
                    self.index += 1;
                },
                ';' => {
                    result.tag = .semicolon;
                    self.index += 1;
                },
                '"' => {
                    result.tag = .string_literal;
                    continue :state .string_literal;
                },
                '`' => {
                    result.tag = .symbol_literal;
                    continue :state .symbol_literal_start;
                },
                '0' => {
                    result.tag = .number_literal;
                    continue :state .zero;
                },
                '1' => {
                    result.tag = .number_literal;
                    continue :state .one;
                },
                '2' => {
                    result.tag = .number_literal;
                    continue :state .two;
                },
                '3'...'9' => {
                    result.tag = .number_literal;
                    continue :state .number_literal;
                },
                'a'...'z', 'A'...'Z' => {
                    result.tag = .identifier;
                    continue :state .identifier;
                },
                '!' => {
                    result.tag = .bang;
                    continue :state .bang;
                },
                '#' => {
                    result.tag = .hash;
                    continue :state .hash;
                },
                '$' => {
                    result.tag = .dollar;
                    continue :state .dollar;
                },
                '%' => {
                    result.tag = .percent;
                    continue :state .percent;
                },
                '&' => {
                    result.tag = .ampersand;
                    continue :state .ampersand;
                },
                '\'' => {
                    result.tag = .apostrophe;
                    continue :state .apostrophe;
                },
                '*' => {
                    result.tag = .asterisk;
                    continue :state .asterisk;
                },
                '+' => {
                    result.tag = .plus;
                    continue :state .plus;
                },
                ',' => {
                    result.tag = .comma;
                    continue :state .comma;
                },
                '-' => {
                    result.tag = .minus;
                    continue :state .minus;
                },
                '.' => {
                    result.tag = .dot;
                    continue :state .dot;
                },
                '/' => if (self.index != 0) switch (self.buffer[self.index - 1]) {
                    ' ', '\n', '\t' => continue :state .skip_line,
                    else => {
                        result.tag = .slash;
                        continue :state .slash;
                    },
                } else continue :state .skip_line,
                ':' => {
                    result.tag = .colon;
                    continue :state .colon;
                },
                '<' => {
                    result.tag = .l_angle_bracket;
                    continue :state .l_angle_bracket;
                },
                '=' => {
                    result.tag = .equal;
                    continue :state .equal;
                },
                '>' => {
                    result.tag = .r_angle_bracket;
                    continue :state .r_angle_bracket;
                },
                '?' => {
                    result.tag = .question_mark;
                    continue :state .question_mark;
                },
                '@' => {
                    result.tag = .at;
                    continue :state .at;
                },
                '\\' => if (self.index == 0 or self.buffer[self.index - 1] == '\n') {
                    result.tag = .system;
                    continue :state .system;
                } else {
                    result.tag = .backslash;
                    continue :state .backslash;
                },
                '^' => {
                    result.tag = .caret;
                    continue :state .caret;
                },
                '_' => {
                    result.tag = .underscore;
                    continue :state .underscore;
                },
                '|' => {
                    result.tag = .pipe;
                    continue :state .pipe;
                },
                '~' => {
                    result.tag = .tilde;
                    continue :state .tilde;
                },
                else => continue :state .invalid,
            },

            .string_literal => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    0 => if (self.index == self.buffer.len) {
                        result.tag = .invalid;
                    } else continue :state .invalid,
                    '\r' => if (self.buffer[self.index + 1] == '\n') {
                        self.index += 1;
                        continue :state .string_literal_newline;
                    } else continue :state .invalid,
                    '\n' => continue :state .string_literal_newline,
                    '\\' => continue :state .string_literal_backslash,
                    '"' => self.index += 1,
                    0x01...0x08, 0x0b, 0x0c, 0x0e...0x1f, 0x7f => continue :state .invalid,
                    else => continue :state .string_literal,
                }
            },
            .string_literal_newline => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    0 => if (self.index == self.buffer.len) {
                        result.tag = .invalid;
                    } else continue :state .invalid,
                    '\r' => if (self.buffer[self.index + 1] == '\n') {
                        self.index += 1;
                        continue :state .string_literal_newline;
                    } else continue :state .invalid,
                    '\n' => continue :state .string_literal_newline,
                    ' ', '\t' => continue :state .string_literal,
                    else => continue :state .invalid,
                }
            },
            .string_literal_backslash => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    0 => if (self.index == self.buffer.len) {
                        result.tag = .invalid;
                    } else continue :state .invalid,
                    '"', '\\', 'n', 'r', 't' => continue :state .string_literal,
                    '0'...'9' => continue :state .octal_char_two,
                    else => continue :state .invalid,
                }
            },
            .octal_char_two => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    0 => if (self.index == self.buffer.len) {
                        result.tag = .invalid;
                    } else continue :state .invalid,
                    '0'...'9' => continue :state .octal_char_three,
                    else => continue :state .invalid,
                }
            },
            .octal_char_three => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    0 => if (self.index == self.buffer.len) {
                        result.tag = .invalid;
                    } else continue :state .invalid,
                    '0'...'9' => continue :state .string_literal,
                    else => continue :state .invalid,
                }
            },

            .symbol_literal_start => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    0 => if (self.index != self.buffer.len) continue :state .invalid,
                    'a'...'z', 'A'...'Z', '0'...'9', '.' => continue :state .symbol_literal,
                    ':' => continue :state .file_handle,
                    else => {},
                }
            },
            .symbol_literal => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    0 => if (self.index != self.buffer.len) continue :state .invalid,
                    'a'...'z', 'A'...'Z', '0'...'9', '.', ':' => continue :state .symbol_literal,
                    else => {},
                }
            },
            .file_handle => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    0 => if (self.index != self.buffer.len) continue :state .invalid,
                    'a'...'z', 'A'...'Z', '0'...'9', '.', ':', '/' => continue :state .file_handle,
                    else => {},
                }
            },

            .zero => switch (self.buffer[self.index + 1]) {
                ':' => switch (self.buffer[self.index + 2]) {
                    ':' => {
                        result.tag = .zero_colon_colon;
                        self.index += 3;
                    },
                    else => {
                        result.tag = .zero_colon;
                        self.index += 2;
                    },
                },
                else => continue :state .number_literal,
            },
            .one => switch (self.buffer[self.index + 1]) {
                ':' => switch (self.buffer[self.index + 2]) {
                    ':' => {
                        result.tag = .one_colon_colon;
                        self.index += 3;
                    },
                    else => {
                        result.tag = .one_colon;
                        self.index += 2;
                    },
                },
                else => continue :state .number_literal,
            },
            .two => switch (self.buffer[self.index + 1]) {
                ':' => {
                    result.tag = .two_colon;
                    self.index += 2;
                },
                else => continue :state .number_literal,
            },
            .number_literal => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    'a'...'z', 'A'...'Z', '0'...'9', '.', ':' => continue :state .number_literal,
                    else => {},
                }
            },

            .identifier => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    'a'...'z', 'A'...'Z', '0'...'9', '.' => continue :state .identifier,
                    else => {},
                }
            },

            .bang => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    ':' => {
                        result.tag = .bang_colon;
                        self.index += 1;
                    },
                    else => {},
                }
            },

            .hash => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    ':' => {
                        result.tag = .hash_colon;
                        self.index += 1;
                    },
                    else => {},
                }
            },

            .dollar => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    ':' => {
                        result.tag = .dollar_colon;
                        self.index += 1;
                    },
                    else => {},
                }
            },

            .percent => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    ':' => {
                        result.tag = .percent_colon;
                        self.index += 1;
                    },
                    else => {},
                }
            },

            .ampersand => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    ':' => {
                        result.tag = .ampersand_colon;
                        self.index += 1;
                    },
                    else => {},
                }
            },

            .apostrophe => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    ':' => {
                        result.tag = .apostrophe_colon;
                        self.index += 1;
                    },
                    else => {},
                }
            },

            .asterisk => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    ':' => {
                        result.tag = .asterisk_colon;
                        self.index += 1;
                    },
                    else => {},
                }
            },

            .plus => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    ':' => {
                        result.tag = .plus_colon;
                        self.index += 1;
                    },
                    else => {},
                }
            },

            .comma => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    ':' => {
                        result.tag = .comma_colon;
                        self.index += 1;
                    },
                    else => {},
                }
            },

            .minus => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    ':' => {
                        result.tag = .minus_colon;
                        self.index += 1;
                    },
                    else => {},
                }
            },

            .dot => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    'a'...'z', 'A'...'Z' => {
                        result.tag = .identifier;
                        continue :state .identifier;
                    },
                    '0'...'9' => {
                        result.tag = .number_literal;
                        continue :state .number_literal;
                    },
                    ':' => {
                        result.tag = .dot_colon;
                        self.index += 1;
                    },
                    else => {},
                }
            },

            .slash => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    ':' => {
                        result.tag = .slash_colon;
                        self.index += 1;
                    },
                    else => {},
                }
            },

            .colon => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    ':' => {
                        result.tag = .colon_colon;
                        self.index += 1;
                    },
                    else => {},
                }
            },

            .l_angle_bracket => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    ':' => {
                        result.tag = .l_angle_bracket_colon;
                        self.index += 1;
                    },
                    else => {},
                }
            },

            .equal => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    ':' => {
                        result.tag = .equal_colon;
                        self.index += 1;
                    },
                    else => {},
                }
            },

            .r_angle_bracket => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    ':' => {
                        result.tag = .r_angle_bracket_colon;
                        self.index += 1;
                    },
                    else => {},
                }
            },

            .question_mark => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    ':' => {
                        result.tag = .question_mark_colon;
                        self.index += 1;
                    },
                    else => {},
                }
            },

            .at => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    ':' => {
                        result.tag = .at_colon;
                        self.index += 1;
                    },
                    else => {},
                }
            },

            .system => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    0 => if (self.index != self.buffer.len) continue :state .invalid,
                    '\r' => if (self.buffer[self.index + 1] != '\n') continue :state .invalid,
                    '\n' => {},
                    0x01...0x08, 0x0b, 0x0c, 0x0e...0x1f, 0x7f => continue :state .invalid,
                    else => continue :state .system,
                }
            },
            .backslash => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    ':' => {
                        result.tag = .backslash_colon;
                        self.index += 1;
                    },
                    else => {},
                }
            },

            .caret => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    ':' => {
                        result.tag = .caret_colon;
                        self.index += 1;
                    },
                    else => {},
                }
            },

            .underscore => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    ':' => {
                        result.tag = .underscore_colon;
                        self.index += 1;
                    },
                    else => {},
                }
            },

            .pipe => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    ':' => {
                        result.tag = .pipe_colon;
                        self.index += 1;
                    },
                    else => {},
                }
            },

            .tilde => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    ':' => {
                        result.tag = .tilde_colon;
                        self.index += 1;
                    },
                    else => {},
                }
            },

            .skip_line => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    0 => if (self.index != self.buffer.len) {
                        continue :state .invalid;
                    } else return .eof(self.buffer.len),
                    '\r' => if (self.buffer[self.index + 1] == '\n') {
                        self.index += 2;
                        result.loc.start = self.index;
                        continue :state .start;
                    } else continue :state .invalid,
                    '\n' => {
                        self.index += 1;
                        result.loc.start = self.index;
                        continue :state .start;
                    },
                    0x01...0x08, 0x0b, 0x0c, 0x0e...0x1f, 0x7f => continue :state .invalid,
                    else => continue :state .skip_line,
                }
            },

            .invalid => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    0 => if (self.index == self.buffer.len) {
                        result.tag = .invalid;
                    } else continue :state .invalid,
                    '\n' => result.tag = .invalid,
                    else => continue :state .invalid,
                }
            },
        }

        result.loc.end = self.index;
        return result;
    }
};

test {
    std.testing.refAllDecls(@This());
}
