const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

const k = @import("../root.zig");
const Ast = k.Ast;
const AstError = Ast.Error;
const Node = k.Node;
const Token = k.Token;
const TokenIndex = Ast.TokenIndex;
const ExtraIndex = Ast.ExtraIndex;
const OptionalTokenIndex = Ast.OptionalTokenIndex;
const Tokenizer = k.Tokenizer;

pub const Error = error{ParseError} || Allocator.Error;

const Parse = @This();

gpa: Allocator,
source: [:0]const u8,
tokens: Ast.TokenList.Slice,
tok_i: TokenIndex,
errors: std.ArrayList(AstError),
nodes: Ast.NodeList,
extra_data: std.ArrayList(u32),
scratch: std.ArrayList(Node.Index),
allow_negation: bool,

fn tokenTag(p: *const Parse, token_index: TokenIndex) Token.Tag {
    return p.tokens.items(.tag)[token_index];
}

fn tokenStart(p: *const Parse, token_index: TokenIndex) Ast.ByteOffset {
    return p.tokens.items(.start)[token_index];
}

fn nodeTag(p: *const Parse, node: Node.Index) Node.Tag {
    return p.nodes.items(.tag)[@intFromEnum(node)];
}

fn nodeMainToken(p: *const Parse, node: Node.Index) TokenIndex {
    return p.nodes.items(.main_token)[@intFromEnum(node)];
}

fn nodeData(p: *const Parse, node: Node.Index) Node.Data {
    return p.nodes.items(.data)[@intFromEnum(node)];
}

fn tokenSlice(p: *const Parse, token_index: TokenIndex) []const u8 {
    const token_tag = p.tokenTag(token_index);

    // Many tokens can be determined entirely by their tag.
    if (token_tag.lexeme()) |lexeme| {
        return lexeme;
    }

    // For some tokens, re-tokenization is needed to find the end.
    var tokenizer: Tokenizer = .{
        .buffer = p.source,
        .index = p.tokenStart(token_index),
    };
    const token = tokenizer.next();
    assert(token.tag == token_tag);
    return p.source[token.loc.start..token.loc.end];
}

fn isNoun(p: *const Parse, node: Node.Index) bool {
    return switch (p.nodeTag(node)) {
        .grouped_expression,
        .empty_list,
        .list,
        .table_literal,
        .expr_block,
        .function,
        .negation,
        .call,
        .apply_unary,
        .apply_binary,
        .number_literal,
        .number_list_literal,
        .string_literal,
        .symbol_literal,
        .symbol_list_literal,
        .identifier,
        => true,
        else => false,
    };
}

const Exprs = struct {
    len: usize,
    data: Node.Data,

    fn toSpan(self: Exprs, p: anytype) !Node.SubRange {
        return switch (self.len) {
            0 => listToSpan(p, &.{}),
            1 => listToSpan(p, &.{self.data.opt_node_and_opt_node[0].unwrap().?}),
            2 => listToSpan(p, &.{ self.data.opt_node_and_opt_node[0].unwrap().?, self.data.opt_node_and_opt_node[1].unwrap().? }),
            else => self.data.extra_range,
        };
    }
};

fn listToSpan(p: anytype, list: []const Node.Index) !Node.SubRange {
    try p.extra_data.appendSlice(p.gpa, @ptrCast(list));
    return .{
        .start = @enumFromInt(p.extra_data.items.len - list.len),
        .end = @enumFromInt(p.extra_data.items.len),
    };
}

fn addNode(p: anytype, elem: Ast.Node) Allocator.Error!Node.Index {
    const result: Node.Index = @enumFromInt(p.nodes.len);
    try p.nodes.append(p.gpa, elem);
    return result;
}

fn setNode(p: anytype, i: usize, elem: Ast.Node) Node.Index {
    p.nodes.set(i, elem);
    return @enumFromInt(i);
}

fn reserveNode(p: anytype, tag: Ast.Node.Tag) !usize {
    try p.nodes.resize(p.gpa, p.nodes.len + 1);
    p.nodes.items(.tag)[p.nodes.len - 1] = tag;
    return p.nodes.len - 1;
}

fn unreserveNode(p: anytype, node_index: usize) void {
    if (p.nodes.len == node_index) {
        p.nodes.resize(p.gpa, p.nodes.len - 1) catch unreachable;
    } else {
        p.nodes.items(.tag)[node_index] = .no_op;
    }
}

fn addExtra(p: anytype, extra: anytype) Allocator.Error!ExtraIndex {
    const fields = std.meta.fields(@TypeOf(extra));
    try p.extra_data.ensureUnusedCapacity(p.gpa, fields.len);
    const result: ExtraIndex = @enumFromInt(p.extra_data.items.len);
    inline for (fields) |field| {
        const data: u32 = switch (field.type) {
            Node.Index,
            Node.OptionalIndex,
            OptionalTokenIndex,
            ExtraIndex,
            => @intFromEnum(@field(extra, field.name)),
            TokenIndex,
            => @field(extra, field.name),
            else => @compileError("unexpected field type: " ++ @typeName(field.type)),
        };
        p.extra_data.appendAssumeCapacity(data);
    }
    return result;
}

fn warnExpected(p: *Parse, expected_token: Token.Tag) error{OutOfMemory}!void {
    @branchHint(.cold);
    try p.warnMsg(.{
        .tag = .expected_token,
        .token = p.tok_i,
        .extra = .{ .expected_tag = expected_token },
    });
}

fn warn(p: *Parse, error_tag: AstError.Tag) error{OutOfMemory}!void {
    @branchHint(.cold);
    try p.warnMsg(.{ .tag = error_tag, .token = p.tok_i });
}

fn warnMsg(p: *Parse, msg: AstError) error{OutOfMemory}!void {
    @branchHint(.cold);
    try p.errors.append(p.gpa, msg);
}

fn fail(p: *Parse, tag: AstError.Tag) error{ ParseError, OutOfMemory } {
    @branchHint(.cold);
    return p.failMsg(.{ .tag = tag, .token = p.tok_i });
}

fn failExpected(p: *Parse, expected_token: Token.Tag) error{ ParseError, OutOfMemory } {
    @branchHint(.cold);
    return p.failMsg(.{
        .tag = .expected_token,
        .token = p.tok_i,
        .extra = .{ .expected_tag = expected_token },
    });
}

fn failMsg(p: *Parse, msg: AstError) error{ ParseError, OutOfMemory } {
    @branchHint(.cold);
    try p.warnMsg(msg);
    return error.ParseError;
}

pub fn deinit(p: *Parse) void {
    p.errors.deinit(p.gpa);
    p.nodes.deinit(p.gpa);
    p.extra_data.deinit(p.gpa);
    p.scratch.deinit(p.gpa);
}

pub fn parseRoot(p: *Parse) !void {
    // Root node must be index 0.
    p.nodes.appendAssumeCapacity(.{
        .tag = .root,
        .main_token = 0,
        .data = undefined,
    });
    const exprs = try p.parseExprs();
    if (p.tokenTag(p.tok_i) != .eof) {
        try p.warnExpected(.eof);
    }
    p.nodes.items(.data)[0] = .{ .extra_range = try exprs.toSpan(p) };
}

fn parseExprs(p: *Parse) !Exprs {
    const scratch_top = p.scratch.items.len;
    defer p.scratch.shrinkRetainingCapacity(scratch_top);

    while (p.tokenTag(p.tok_i) != .eof) {
        const expr = p.parseExpr() catch |err| switch (err) {
            error.OutOfMemory => return error.OutOfMemory,
            else => blk: {
                p.skipExpr();
                break :blk .none;
            },
        };
        if (expr.unwrap()) |node| try p.scratch.append(p.gpa, node);
        switch (p.tokenTag(p.tok_i)) {
            .semicolon => {
                _ = p.nextToken();
                continue;
            },
            .eof => break,
            else => if (!p.startsExpr()) {
                try p.warn(.expected_expr);
                p.skipExpr();
            },
        }
    }

    const items = p.scratch.items[scratch_top..];
    return .{
        .len = items.len,
        .data = switch (items.len) {
            0, 1, 2 => .{ .opt_node_and_opt_node = .{
                if (items.len > 0) items[0].toOptional() else .none,
                if (items.len > 1) items[1].toOptional() else .none,
            } },
            else => .{ .extra_range = try p.listToSpan(items) },
        },
    };
}

fn expectExpr(p: *Parse) !Node.Index {
    const expr = try p.parseExpr();
    return expr.unwrap() orelse p.fail(.expected_expr);
}

fn parseExpr(p: *Parse) Error!Node.OptionalIndex {
    const noun = try p.parseNoun();
    var node = noun.unwrap() orelse return .none;

    while (true) {
        const verb = try p.parseVerb(node);
        node = verb.unwrap() orelse break;
    }

    return node.toOptional();
}

fn endsExpr(p: *Parse) bool {
    return switch (p.tokenTag(p.tok_i)) {
        .r_paren, .r_bracket, .r_brace, .semicolon, .eof => true,
        else => blk: {
            const start = p.tokenStart(p.tok_i);
            break :blk start > 0 and p.source[start - 1] == '\n';
        },
    };
}

fn startsExpr(p: *Parse) bool {
    const start = p.tokenStart(p.tok_i);
    if (start == 0 or p.source[start - 1] == '\n') return true;

    return switch (p.tokenTag(p.tok_i - 1)) {
        .r_paren, .r_bracket, .r_brace, .semicolon => true,
        else => false,
    };
}

fn expectNoun(p: *Parse) !Node.Index {
    const noun = try p.parseNoun();
    return noun.unwrap() orelse p.fail(.expected_noun);
}

fn parseNoun(p: *Parse) Error!Node.OptionalIndex {
    const noun = switch (p.tokenTag(p.tok_i)) {
        // Punctuation
        .l_paren => try p.parseGroup(),
        .r_paren => return .none,
        .l_bracket => try p.parseBlock(),
        .r_bracket => return .none,
        .l_brace => try p.parseFunction(),
        .r_brace => return .none,
        .semicolon => return .none,

        // Operators
        .bang => try p.addNoun(.bang),
        .bang_colon => try p.addNoun(.bang_colon),
        .hash => try p.addNoun(.hash),
        .hash_colon => try p.addNoun(.hash_colon),
        .dollar => try p.addNoun(.dollar),
        .dollar_colon => try p.addNoun(.dollar_colon),
        .percent => try p.addNoun(.percent),
        .percent_colon => try p.addNoun(.percent_colon),
        .ampersand => try p.addNoun(.ampersand),
        .ampersand_colon => try p.addNoun(.ampersand_colon),
        .asterisk => try p.addNoun(.asterisk),
        .asterisk_colon => try p.addNoun(.asterisk_colon),
        .plus => try p.addNoun(.plus),
        .plus_colon => try p.addNoun(.plus_colon),
        .comma => try p.addNoun(.comma),
        .comma_colon => try p.addNoun(.comma_colon),
        .minus => try p.parseMinus(),
        .minus_colon => try p.addNoun(.minus_colon),
        .dot => try p.addNoun(.dot),
        .dot_colon => try p.addNoun(.dot_colon),
        .colon => try p.addNoun(.colon),
        .colon_colon => try p.addNoun(.colon_colon),
        .l_angle_bracket => try p.addNoun(.l_angle_bracket),
        .l_angle_bracket_colon => try p.addNoun(.l_angle_bracket_colon),
        .equal => try p.addNoun(.equal),
        .equal_colon => try p.addNoun(.equal_colon),
        .r_angle_bracket => try p.addNoun(.r_angle_bracket),
        .r_angle_bracket_colon => try p.addNoun(.r_angle_bracket_colon),
        .question_mark => try p.addNoun(.question_mark),
        .question_mark_colon => try p.addNoun(.question_mark_colon),
        .at => try p.addNoun(.at),
        .at_colon => try p.addNoun(.at_colon),
        .caret => try p.addNoun(.caret),
        .caret_colon => try p.addNoun(.caret_colon),
        .underscore => try p.addNoun(.underscore),
        .underscore_colon => try p.addNoun(.underscore_colon),
        .pipe => try p.addNoun(.pipe),
        .pipe_colon => try p.addNoun(.pipe_colon),
        .tilde => try p.addNoun(.tilde),
        .tilde_colon => try p.addNoun(.tilde_colon),
        .zero_colon => try p.addNoun(.zero_colon),
        .zero_colon_colon => try p.addNoun(.zero_colon_colon),
        .one_colon => try p.addNoun(.one_colon),
        .one_colon_colon => try p.addNoun(.one_colon_colon),
        .two_colon => try p.addNoun(.two_colon),

        // Iterators
        .apostrophe => try p.addIterator(.apostrophe, .none),
        .apostrophe_colon => try p.addIterator(.apostrophe_colon, .none),
        .slash => try p.addIterator(.slash, .none),
        .slash_colon => try p.addIterator(.slash_colon, .none),
        .backslash => try p.addIterator(.backslash, .none),
        .backslash_colon => try p.addIterator(.backslash_colon, .none),

        // Literals
        .number_literal => try p.parseNumberLiteral(),
        .string_literal => try p.addNoun(.string_literal),
        .symbol_literal => try p.parseSymbolLiteral(),
        .identifier => try p.addNoun(.identifier),

        // Misc.
        .system => try p.addNoun(.system),
        .invalid => return p.fail(.expected_expr),
        .eof => return .none,
    };
    const call = try p.parseCall(noun);
    return call.toOptional();
}

fn expectVerb(p: *Parse, lhs: Node.Index) !Node.Index {
    const verb = p.parseVerb(lhs);
    return verb.unwrap() orelse p.fail(.expected_verb);
}

fn parseVerb(p: *Parse, lhs: Node.Index) Error!Node.OptionalIndex {
    if (p.endsExpr()) return .none;

    const verb = switch (p.tokenTag(p.tok_i)) {
        // Punctuation
        .l_paren => try p.parseUnary(lhs),
        .r_paren => return .none,
        .l_bracket => unreachable,
        .r_bracket => return .none,
        .l_brace => try p.parseUnary(lhs),
        .r_brace => return .none,
        .semicolon => return .none,

        // Binary Operators
        .bang,
        .hash,
        .dollar,
        .percent,
        .ampersand,
        .asterisk,
        .plus,
        .comma,
        .minus,
        .dot,
        .colon,
        .l_angle_bracket,
        .equal,
        .r_angle_bracket,
        .question_mark,
        .at,
        .caret,
        .underscore,
        .pipe,
        .tilde,
        .zero_colon,
        .one_colon,
        .two_colon,
        => try if (p.isNoun(lhs)) p.parseBinary(lhs) else p.parseUnary(lhs),

        // Unary operators
        .bang_colon,
        .hash_colon,
        .dollar_colon,
        .percent_colon,
        .ampersand_colon,
        .asterisk_colon,
        .plus_colon,
        .comma_colon,
        .minus_colon,
        .dot_colon,
        .colon_colon,
        .l_angle_bracket_colon,
        .equal_colon,
        .r_angle_bracket_colon,
        .question_mark_colon,
        .at_colon,
        .caret_colon,
        .underscore_colon,
        .pipe_colon,
        .tilde_colon,
        .zero_colon_colon,
        .one_colon_colon,
        => try p.parseUnary(lhs),

        // Iterators
        .apostrophe => unreachable,
        .apostrophe_colon => unreachable,
        .slash => unreachable,
        .slash_colon => unreachable,
        .backslash => unreachable,
        .backslash_colon => unreachable,

        // Literals
        .number_literal,
        .string_literal,
        .symbol_literal,
        .identifier,
        => try p.parseUnary(lhs),

        // Misc.
        .system => unreachable,
        .invalid => return p.fail(.expected_expr),
        .eof => return .none,
    };
    return verb.toOptional();
}

fn parseUnary(p: *Parse, lhs: Node.Index) !Node.Index {
    const apply_index = try p.reserveNode(.apply_unary);
    errdefer p.unreserveNode(apply_index);

    const rhs = try p.expectNoun();
    switch (p.nodeTag(rhs)) {
        .apostrophe,
        .apostrophe_colon,
        .slash,
        .slash_colon,
        .backslash,
        .backslash_colon,
        => return p.setNode(apply_index, .{
            .tag = .apply_binary,
            .main_token = @intFromEnum(rhs),
            .data = .{ .node_and_opt_node = .{ lhs, try p.parseExpr() } },
        }),
        else => {
            const verb = try p.parseVerb(rhs);
            return p.setNode(apply_index, .{
                .tag = .apply_unary,
                .main_token = undefined,
                .data = .{ .node_and_node = .{ lhs, verb.unwrap() orelse rhs } },
            });
        },
    }
}

fn parseBinary(p: *Parse, lhs: Node.Index) !Node.Index {
    const apply_index = try p.reserveNode(.apply_binary);
    errdefer p.unreserveNode(apply_index);

    const op = blk: {
        const prev_allow_negation = p.allow_negation;
        defer p.allow_negation = prev_allow_negation;
        p.allow_negation = false;
        break :blk try p.expectNoun();
    };

    return p.setNode(apply_index, .{
        .tag = .apply_binary,
        .main_token = @intFromEnum(op),
        .data = .{ .node_and_opt_node = .{ lhs, try p.parseExpr() } },
    });
}

fn parseCall(p: *Parse, lhs: Node.Index) !Node.Index {
    if (p.tokenTag(p.tok_i) != .l_bracket) return p.parseIterator(lhs);

    const l_bracket = p.assertToken(.l_bracket);

    const call_index = try p.reserveNode(.call);
    errdefer p.unreserveNode(call_index);

    const scratch_top = p.scratch.items.len;
    defer p.scratch.shrinkRetainingCapacity(scratch_top);

    try p.scratch.append(p.gpa, lhs);

    if (p.tokenTag(p.tok_i) != .r_bracket) {
        while (true) {
            const expr = try p.parseExpr();
            try p.scratch.append(p.gpa, expr.unwrap() orelse try p.noOp());
            _ = p.eatToken(.semicolon) orelse break;
        }
    }
    _ = try p.expectToken(.r_bracket);

    const args = p.scratch.items[scratch_top..];
    return p.parseCall(p.setNode(call_index, .{
        .tag = .call,
        .main_token = l_bracket,
        .data = .{ .extra_range = try p.listToSpan(args) },
    }));
}

fn parseIterator(p: *Parse, lhs: Node.Index) Error!Node.Index {
    const tag: Node.Tag = switch (p.tokenTag(p.tok_i)) {
        .apostrophe => .apostrophe,
        .apostrophe_colon => .apostrophe_colon,
        .slash => .slash,
        .slash_colon => .slash_colon,
        .backslash => .backslash,
        .backslash_colon => .backslash_colon,
        else => return lhs,
    };
    const iterator = try p.addNode(.{
        .tag = tag,
        .main_token = p.nextToken(),
        .data = .{ .opt_node = lhs.toOptional() },
    });
    return p.parseCall(iterator);
}

fn parseGroup(p: *Parse) !Node.Index {
    const l_paren = p.assertToken(.l_paren);
    if (p.tokenTag(p.tok_i) == .l_bracket) return p.parseTable(l_paren);

    const group_index = try p.reserveNode(.grouped_expression);
    errdefer p.unreserveNode(group_index);

    const scratch_top = p.scratch.items.len;
    defer p.scratch.shrinkRetainingCapacity(scratch_top);

    if (p.tokenTag(p.tok_i) != .r_paren) {
        while (true) {
            const expr = try p.parseExpr();
            try p.scratch.append(p.gpa, expr.unwrap() orelse try p.noOp());
            _ = p.eatToken(.semicolon) orelse break;
        }
    }
    const r_paren = try p.expectToken(.r_paren);

    const list = p.scratch.items[scratch_top..];
    switch (list.len) {
        0 => return p.setNode(group_index, .{
            .tag = .empty_list,
            .main_token = l_paren,
            .data = .{ .token = r_paren },
        }),
        1 => return p.setNode(group_index, .{
            .tag = .grouped_expression,
            .main_token = l_paren,
            .data = .{ .node_and_token = .{ list[0], r_paren } },
        }),
        else => return p.setNode(group_index, .{
            .tag = .list,
            .main_token = l_paren,
            .data = .{ .extra_range = try p.listToSpan(list) },
        }),
    }
}

fn parseTable(p: *Parse, l_paren: TokenIndex) !Node.Index {
    _ = p.assertToken(.l_bracket);

    const table_index = try p.reserveNode(.table_literal);
    errdefer p.unreserveNode(table_index);

    const scratch_top = p.scratch.items.len;
    defer p.scratch.shrinkRetainingCapacity(scratch_top);

    const keys_top = p.scratch.items.len;
    if (p.tokenTag(p.tok_i) != .r_bracket) {
        while (true) {
            const expr = try p.expectExpr();
            try p.scratch.append(p.gpa, expr);
            _ = p.eatToken(.semicolon) orelse break;
        }
    }
    _ = try p.expectToken(.r_bracket);

    const columns_top = p.scratch.items.len;
    while (true) {
        const expr = try p.expectExpr();
        try p.scratch.append(p.gpa, expr);
        _ = p.eatToken(.semicolon) orelse break;
    }
    const r_paren = try p.expectToken(.r_paren);

    const keys = try p.listToSpan(p.scratch.items[keys_top..columns_top]);
    const columns = try p.listToSpan(p.scratch.items[columns_top..]);
    const table: Node.Table = .{
        .keys_start = keys.start,
        .columns_start = columns.start,
        .columns_end = columns.end,
    };
    return p.setNode(table_index, .{
        .tag = .table_literal,
        .main_token = l_paren,
        .data = .{ .extra_and_token = .{ try p.addExtra(table), r_paren } },
    });
}

fn parseBlock(p: *Parse) !Node.Index {
    const l_bracket = p.assertToken(.l_bracket);

    const block_index = try p.reserveNode(.expr_block);
    errdefer p.unreserveNode(block_index);

    const scratch_top = p.scratch.items.len;
    defer p.scratch.shrinkRetainingCapacity(scratch_top);

    if (p.tokenTag(p.tok_i) != .r_bracket) {
        while (true) {
            const expr = try p.parseExpr();
            if (expr.unwrap()) |node| try p.scratch.append(p.gpa, node);
            _ = p.eatToken(.semicolon) orelse break;
        }
    }
    _ = try p.expectToken(.r_bracket);

    const nodes = p.scratch.items[scratch_top..];
    return p.setNode(block_index, .{
        .tag = .expr_block,
        .main_token = l_bracket,
        .data = .{ .extra_range = try p.listToSpan(nodes) },
    });
}

fn parseFunction(p: *Parse) !Node.Index {
    const l_brace = p.assertToken(.l_brace);

    const function_index = try p.reserveNode(.function);
    errdefer p.unreserveNode(function_index);

    const scratch_top = p.scratch.items.len;
    defer p.scratch.shrinkRetainingCapacity(scratch_top);

    const params_top = p.scratch.items.len;
    if (p.eatToken(.l_bracket)) |_| {
        if (p.tokenTag(p.tok_i) != .r_bracket) {
            while (true) {
                const expr = try p.expectExpr();
                try p.scratch.append(p.gpa, expr);
                _ = p.eatToken(.semicolon) orelse break;
            }
        }
        _ = try p.expectToken(.r_bracket);
    }

    const body_top = p.scratch.items.len;
    while (true) {
        const expr = try p.parseExpr();
        if (expr.unwrap()) |node| try p.scratch.append(p.gpa, node);
        _ = p.eatToken(.semicolon) orelse break;
    }
    const r_brace = try p.expectToken(.r_brace);

    const params = try p.listToSpan(p.scratch.items[params_top..body_top]);
    const body = try p.listToSpan(p.scratch.items[body_top..]);
    const function: Node.Function = .{
        .params_start = params.start,
        .body_start = body.start,
        .body_end = body.end,
    };
    return p.setNode(function_index, .{
        .tag = .function,
        .main_token = l_brace,
        .data = .{ .extra_and_token = .{ try p.addExtra(function), r_brace } },
    });
}

fn parseMinus(p: *Parse) !Node.Index {
    // Handle negative number literals
    if (p.allow_negation and
        p.tokenTag(p.tok_i + 1) == .number_literal and
        p.tokenStart(p.tok_i) + 1 == p.tokenStart(p.tok_i + 1))
    {
        return p.addNode(.{
            .tag = .negation,
            .main_token = p.assertToken(.minus),
            .data = .{ .node = try p.expectNoun() },
        });
    }

    return p.addNoun(.minus);
}

fn parseNumberLiteral(p: *Parse) !Node.Index {
    const number_literal = p.assertToken(.number_literal);

    var maybe_last_number_literal: ?TokenIndex = null;
    while (p.tokenTag(p.tok_i) == .number_literal or
        p.tokenTag(p.tok_i) == .minus and
            p.tokenTag(p.tok_i + 1) == .number_literal and
            p.tokenStart(p.tok_i) + 1 == p.tokenStart(p.tok_i + 1) and
            p.tokenStart(p.tok_i) != p.tokenStart(p.tok_i - 1) + p.tokenSlice(p.tok_i - 1).len)
    {
        if (p.eatToken(.minus)) |token_index| {
            maybe_last_number_literal = token_index;
            _ = p.assertToken(.number_literal);
        } else {
            maybe_last_number_literal = p.assertToken(.number_literal);
        }
    }
    if (maybe_last_number_literal) |last_number_literal| {
        return p.addNode(.{
            .tag = .number_list_literal,
            .main_token = number_literal,
            .data = .{ .token = last_number_literal },
        });
    }

    return p.addNode(.{
        .tag = .number_literal,
        .main_token = number_literal,
        .data = undefined,
    });
}

fn parseSymbolLiteral(p: *Parse) !Node.Index {
    const symbol_literal = p.assertToken(.symbol_literal);

    var maybe_last_symbol_literal: ?TokenIndex = null;
    while (p.tokenTag(p.tok_i) == .symbol_literal and !std.ascii.isWhitespace(p.source[p.tokenStart(p.tok_i) - 1])) {
        maybe_last_symbol_literal = p.assertToken(.symbol_literal);
    }
    if (maybe_last_symbol_literal) |last_symbol_literal| {
        return p.addNode(.{
            .tag = .symbol_list_literal,
            .main_token = symbol_literal,
            .data = .{ .token = last_symbol_literal },
        });
    }

    return p.addNode(.{
        .tag = .symbol_literal,
        .main_token = symbol_literal,
        .data = undefined,
    });
}

fn noOp(p: *Parse) !Node.Index {
    return p.addNode(.{
        .tag = .no_op,
        .main_token = undefined,
        .data = undefined,
    });
}

fn addNoun(p: *Parse, tag: Node.Tag) !Node.Index {
    return p.addNode(.{
        .tag = tag,
        .main_token = p.nextToken(),
        .data = undefined,
    });
}

fn addIterator(p: *Parse, tag: Node.Tag, lhs: Node.OptionalIndex) !Node.Index {
    return p.addNode(.{
        .tag = tag,
        .main_token = p.nextToken(),
        .data = .{ .opt_node = lhs },
    });
}

fn eatToken(p: *Parse, tag: Token.Tag) ?TokenIndex {
    return if (p.tokenTag(p.tok_i) == tag) p.nextToken() else null;
}

fn assertToken(p: *Parse, tag: Token.Tag) TokenIndex {
    const token = p.nextToken();
    assert(p.tokenTag(token) == tag);
    return token;
}

fn expectToken(p: *Parse, tag: Token.Tag) !TokenIndex {
    return if (p.tokenTag(p.tok_i) == tag) p.nextToken() else p.failExpected(tag);
}

fn nextToken(p: *Parse) TokenIndex {
    const token = p.tok_i;
    if (p.tok_i != p.tokens.len - 1) {
        p.tok_i += 1;
    }
    return token;
}

fn skipExpr(p: *Parse) void {
    while (!p.startsExpr()) {
        if (p.tokenTag(p.tok_i) == .eof) break;
        _ = p.nextToken();
    }
}

test {
    std.testing.refAllDeclsRecursive(@This());
}
