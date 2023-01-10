const std = @import("std");

const chunk_mod = @import("chunk.zig");
const Chunk = chunk_mod.Chunk;
const OpCode = chunk_mod.OpCode;

const debug_mod = @import("debug.zig");

const scanner_mod = @import("scanner.zig");
const Scanner = scanner_mod.Scanner;
const Token = scanner_mod.Token;
const TokenType = scanner_mod.TokenType;

const utils_mod = @import("utils.zig");
const print = utils_mod.print;

const value_mod = @import("value.zig");
const Value = value_mod.Value;

const debug_print_code = @import("builtin").mode == .Debug and !@import("builtin").is_test;

pub const Parser = struct {
    current: Token = undefined,
    previous: Token = undefined,
    had_error: bool = false,
    panic_mode: bool = false,
};

var parser: Parser = Parser{};
var scanner: Scanner = undefined;
var compiling_chunk: *Chunk = undefined;

fn currentChunk() *Chunk {
    return compiling_chunk;
}

fn err(message: []const u8) void {
    errorAt(&parser.previous, message);
}

fn errorAt(token: *Token, message: []const u8) void {
    if (parser.panic_mode) return;
    parser.panic_mode = true;
    print("[line {d}] Error", .{token.line});

    if (token.token_type == .token_eof) {
        print(" at end", .{});
    } else if (token.token_type == .token_error) {
        // Do nothing.
    } else {
        print(" at '{s}'", .{token.lexeme});
    }

    print(": {s}\n", .{message});
    parser.had_error = true;
}

fn errorAtCurrent(message: []const u8) void {
    errorAt(&parser.current, message);
}

fn advance() void {
    parser.previous = parser.current;

    while (true) {
        parser.current = scanner.scanToken();
        if (parser.current.token_type != .token_error) break;

        errorAtCurrent(parser.current.lexeme);
    }
}

fn consume(token_type: TokenType, message: []const u8) void {
    if (parser.current.token_type == token_type) {
        advance();
        return;
    }

    errorAtCurrent(message);
}

fn emitByte(byte: u8) void {
    currentChunk().write(byte, parser.previous.line);
}

fn emitBytes(byte1: u8, byte2: u8) void {
    emitByte(byte1);
    emitByte(byte2);
}

fn emitReturn() void {
    emitByte(@enumToInt(OpCode.op_return));
}

fn makeConstant(value: *Value) u8 {
    const constant = currentChunk().addConstant(value);
    if (constant > std.math.maxInt(u8)) {
        err("Too many constants in one chunk.");
        return 0;
    }

    return @intCast(u8, constant);
}

fn emitConstant(value: *Value) void {
    emitBytes(@enumToInt(OpCode.op_constant), makeConstant(value));
}

fn endCompiler() void {
    emitReturn();
    if (comptime debug_print_code) {
        if (!parser.had_error) {
            debug_mod.disassembleChunk(currentChunk(), "code");
        }
    }
}

fn number() !void {
    const float = std.fmt.parseFloat(f64, parser.previous.lexeme) catch std.debug.panic("Failed to parse float.", .{});
    const value = try Value.init(.{ .float = float }, currentChunk().allocator);
    emitConstant(value);
}

fn expression() !void {
    advance();
    print("PREVIOUS = '{s}'\n", .{parser.previous.lexeme});
    switch (parser.previous.token_type) {
        .token_float => try number(),
        else => unreachable,
    }
}

pub fn compile(source: []const u8, chunk: *Chunk) !void {
    scanner = Scanner.init(source);
    compiling_chunk = chunk;

    parser.had_error = false;
    parser.panic_mode = false;

    advance();
    try expression();
    consume(.token_eof, "Expect end of expression.");
    endCompiler();

    if (parser.had_error) return error.compile_error;
}
