const std = @import("std");

const chunk_mod = @import("chunk.zig");
const Chunk = chunk_mod.Chunk;
const OpCode = chunk_mod.OpCode;

const debug_mod = @import("debug.zig");

const node_mod = @import("node.zig");
const Node = node_mod.Node;

const scanner_mod = @import("scanner.zig");
const Scanner = scanner_mod.Scanner;
const Token = scanner_mod.Token;
const TokenType = scanner_mod.TokenType;

const utils_mod = @import("utils.zig");
const print = utils_mod.print;

const value_mod = @import("value.zig");
const Value = value_mod.Value;
const ValueFn = value_mod.ValueFunction;

const vm_mod = @import("vm.zig");
const VM = vm_mod.VM;

const debug_print_code = @import("builtin").mode == .Debug and !@import("builtin").is_test;

const u8_count = std.math.maxInt(u8) + 1;

pub const Parser = struct {
    current: Token = undefined,
    previous: Token = undefined,
    had_error: bool = false,
    panic_mode: bool = false,
};

const Precedence = enum {
    prec_none,
    prec_secondary,
    prec_primary,
};

const CompilerError = error{
    compile_error,
};

const PrefixParseFn = *const fn () CompilerError!*Node;
const InfixParseFn = *const fn (*Node) CompilerError!*Node;

const ParseRule = struct {
    prefix: ?PrefixParseFn,
    infix: ?InfixParseFn,
    precedence: Precedence,
};

const FunctionType = enum {
    function_script,
    function_lambda,
};

var parser: Parser = Parser{};
var scanner: Scanner = undefined;
var current: *Compiler = undefined;

pub const Compiler = struct {
    const Self = @This();

    vm: *VM,
    enclosing: ?*Self,
    func: *ValueFn,
    function_type: FunctionType,
    locals: [u8_count]Token = undefined,
    local_count: u8,

    pub fn init(enclosing: ?*Self, function_type: FunctionType, vm: *VM) Self {
        var compiler = Self{
            .vm = vm,
            .enclosing = enclosing,
            .func = ValueFn.init(vm.allocator),
            .function_type = function_type,
            .local_count = 0,
        };

        return compiler;
    }
};

fn currentChunk() *Chunk {
    return current.func.chunk;
}

fn errorAtCurrent(message: []const u8) void {
    errorAt(&parser.current, message);
}

fn errorAtPrevious(message: []const u8) void {
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

fn check(token_type: TokenType) bool {
    return parser.current.token_type == token_type;
}

fn match(token_type: TokenType) bool {
    if (!check(token_type)) return false;
    advance();
    return true;
}

pub fn emitByte(byte: u8) void {
    currentChunk().write(byte, parser.previous);
}

fn emitBytes(byte1: u8, byte2: u8) void {
    emitByte(byte1);
    emitByte(byte2);
}

pub fn emitInstruction(instruction: OpCode) void {
    emitByte(@enumToInt(instruction));
}

fn emitReturn() void {
    emitByte(@enumToInt(OpCode.op_return));
}

fn makeConstant(value: *Value) u8 {
    const constant = currentChunk().addConstant(value);
    if (constant > std.math.maxInt(u8)) {
        errorAtPrevious("Too many constants in one chunk.");
        return 0;
    }

    return @intCast(u8, constant);
}

fn endCompiler(node: *Node) *ValueFn {
    const top_node = Node.init(.{ .op_code = .op_return }, current.vm.allocator);
    top_node.rhs = node;
    if (node.op_code == .op_pop) {
        top_node.lhs = Node.init(.{ .op_code = .op_nil }, current.vm.allocator);
    }
    top_node.traverse();
    top_node.deinit(current.vm.allocator);

    const func = current.func;
    func.local_count = current.local_count;
    if (current.enclosing) |enclosing| {
        current = enclosing;
    }

    return func;
}

pub fn identifierConstant(name: Token) u8 {
    const value = current.vm.copySymbol(name.lexeme);
    return makeConstant(value);
}

pub fn resolveLocal(name: Token) ?u8 {
    var i = current.local_count;
    while (i > 0) {
        i -= 1;
        if (std.mem.eql(u8, name.lexeme, current.locals[i].lexeme)) {
            return i;
        }
    }

    return null;
}

fn addLocal(name: Token) void {
    if (current.local_count == u8_count) {
        errorAtPrevious("Too many local variables in function.");
        return;
    }

    current.locals[current.local_count] = name;
    current.local_count += 1;
}

fn number() CompilerError!*Node {
    const float = std.fmt.parseFloat(f64, parser.previous.lexeme) catch std.debug.panic("Failed to parse float", .{});
    const value = current.vm.initValue(.{ .float = float });
    return Node.init(.{ .op_code = .op_constant, .byte = makeConstant(value) }, current.vm.allocator);
}

fn symbol() CompilerError!*Node {
    const value = current.vm.copySymbol(parser.previous.lexeme[1..parser.previous.lexeme.len]);
    return Node.init(.{ .op_code = .op_constant, .byte = makeConstant(value) }, current.vm.allocator);
}

fn variable() CompilerError!*Node {
    const name = parser.previous;

    if (match(.token_double_colon)) {
        const arg = identifierConstant(name);
        const node = Node.init(.{ .op_code = .op_set_global, .byte = arg }, current.vm.allocator);
        node.rhs = try expression();
        return node;
    }

    if (current.function_type == .function_script) {
        const arg = identifierConstant(name);
        if (match(.token_colon)) {
            const node = Node.init(.{ .op_code = .op_set_global, .byte = arg }, current.vm.allocator);
            node.rhs = try expression();
            return node;
        } else {
            return Node.init(.{ .op_code = .op_get_global, .byte = arg }, current.vm.allocator);
        }
    } else {
        if (match(.token_colon)) {
            const arg = resolveLocal(name) orelse blk: {
                addLocal(name);
                break :blk current.local_count - 1;
            };
            const node = Node.init(.{ .op_code = .op_set_local, .byte = arg }, current.vm.allocator);
            node.rhs = try expression();
            return node;
        } else {
            return Node.init(.{ .op_code = .op_get_global, .name = name }, current.vm.allocator);
        }
    }
}

fn call(node: *Node) CompilerError!*Node {
    const call_node = Node.init(.{ .op_code = .op_call, .byte = 0b0 }, current.vm.allocator);
    call_node.lhs = node;

    if (!check(.token_right_bracket)) {
        var arg_count: u8 = 0;
        var arg_indices = std.bit_set.IntegerBitSet(8).initEmpty();
        while (match(.token_semicolon)) {
            arg_count += 1;
        }

        if (!check(.token_right_bracket)) {
            arg_indices.set(arg_count);
            arg_count += 1;
            var top_node = try expression();
            var rhs = &top_node.*.rhs;
            var should_continue = match(.token_semicolon);
            while (should_continue) {
                if (check(.token_right_bracket)) break;

                arg_count += 1;
                if (arg_count > 8) {
                    errorAtCurrent("Can't have more than 8 arguments.");
                    return CompilerError.compile_error;
                }

                if (match(.token_semicolon)) continue;
                arg_indices.set(arg_count - 1);

                const arg_node = try expression();
                while (rhs.* != null) {
                    rhs = &rhs.*.?.rhs;
                }
                rhs.* = arg_node;

                should_continue = match(.token_semicolon);
            }

            call_node.byte = arg_indices.mask;
            call_node.rhs = top_node;
        }
    }
    consume(.token_right_bracket, "Expect ']' after arguments.");

    return call_node;
}

fn binary(node: *Node) CompilerError!*Node {
    const current_node = Node.init(.{
        .op_code = switch (parser.previous.token_type) {
            .token_plus => .op_add,
            else => unreachable,
        },
    }, current.vm.allocator);
    errdefer current_node.deinit(current.vm.allocator);

    current_node.lhs = node;
    current_node.rhs = try parsePrecedence(getRule(parser.previous.token_type).precedence, true);
    return current_node;
}

fn grouping() CompilerError!*Node {
    defer consume(.token_right_paren, "Expect ')' after expression.");
    return try expression();
}

fn block() CompilerError!*Node {
    var top_node = try expression();
    {
        errdefer top_node.deinit(current.vm.allocator);
        while (!check(.token_right_brace) and !check(.token_eof)) {
            const node = try expression();
            var rhs = &node.rhs;
            while (rhs.* != null) {
                rhs = &rhs.*.?.rhs;
            }
            rhs.* = top_node;
            top_node = node;
        }
    }

    consume(.token_right_brace, "Expect '}' after block.");

    return top_node;
}

fn function() CompilerError!*Node {
    var compiler = Compiler.init(current, .function_lambda, current.vm);
    errdefer compiler.func.deinit(current.vm.allocator);
    current = &compiler;

    const start_index = @ptrToInt(scanner.start) - @ptrToInt(scanner.source.ptr) - 1;

    if (match(.token_left_bracket)) {
        var should_continue = !check(.token_right_bracket);
        while (should_continue) {
            current.func.arity += 1;
            if (current.func.arity > 8) {
                errorAtCurrent("Can't have more than 8 parameters.");
                return CompilerError.compile_error;
            }

            consume(.token_identifier, "Expect parameter name.");

            var i = current.local_count;
            while (i > 0) {
                i -= 1;
                const local = current.locals[i];
                if (std.mem.eql(u8, parser.previous.lexeme, local.lexeme)) {
                    errorAtPrevious("Duplicate parameter name.");
                    return CompilerError.compile_error;
                }
            }

            addLocal(parser.previous);

            should_continue = match(.token_semicolon);
        }
        consume(.token_right_bracket, "Expect ']' after parameters.");
    }

    const node = try block();

    const end_index = std.math.min(@ptrToInt(scanner.start) - @ptrToInt(scanner.source.ptr), scanner.source.len);
    current.func.name = current.vm.allocator.dupe(u8, scanner.source[start_index..end_index]) catch std.debug.panic("Failed to create function", .{});

    const func = endCompiler(node);
    const value = current.vm.initValue(.{ .function = func });
    return Node.init(.{ .op_code = .op_constant, .byte = makeConstant(value) }, current.vm.allocator);
}

fn pop() CompilerError!*Node {
    return Node.init(.{ .op_code = .op_pop }, current.vm.allocator);
}

fn parsePrecedence(precedence: Precedence, should_advance: bool) CompilerError!*Node {
    if (should_advance) advance();
    const prefixRule = getRule(parser.previous.token_type).prefix orelse {
        errorAtPrevious("Expect prefix expression.");
        return CompilerError.compile_error;
    };
    var node = try prefixRule();

    while (@enumToInt(precedence) <= @enumToInt(getRule(parser.current.token_type).precedence)) {
        advance();
        const infixRule = getRule(parser.previous.token_type).infix orelse {
            errorAtPrevious("Expect infix expression.");
            return CompilerError.compile_error;
        };
        node = try infixRule(node);
    }

    return node;
}

fn getRule(token_type: TokenType) ParseRule {
    return switch (token_type) {
        // zig fmt: off
        .token_left_paren    => ParseRule{ .prefix = grouping, .infix = null,   .precedence = .prec_none      },
        .token_right_paren   => ParseRule{ .prefix = null,     .infix = null,   .precedence = .prec_none      },
        .token_left_brace    => ParseRule{ .prefix = function, .infix = null,   .precedence = .prec_none      },
        .token_right_brace   => ParseRule{ .prefix = null,     .infix = null,   .precedence = .prec_none      },
        .token_left_bracket  => ParseRule{ .prefix = null,     .infix = call,   .precedence = .prec_primary   },
        .token_right_bracket => ParseRule{ .prefix = null,     .infix = null,   .precedence = .prec_none      },
        .token_semicolon     => ParseRule{ .prefix = pop,      .infix = null,   .precedence = .prec_none      },
        .token_colon         => ParseRule{ .prefix = null,     .infix = null,   .precedence = .prec_none      },
        .token_double_colon  => ParseRule{ .prefix = null,     .infix = null,   .precedence = .prec_none      },
        .token_plus          => ParseRule{ .prefix = null,     .infix = binary, .precedence = .prec_secondary },
        .token_minus         => ParseRule{ .prefix = null,     .infix = null,   .precedence = .prec_none      },
        .token_star          => ParseRule{ .prefix = null,     .infix = null,   .precedence = .prec_none      },
        .token_percent       => ParseRule{ .prefix = null,     .infix = null,   .precedence = .prec_none      },
        .token_ampersand     => ParseRule{ .prefix = null,     .infix = null,   .precedence = .prec_none      },
        .token_pipe          => ParseRule{ .prefix = null,     .infix = null,   .precedence = .prec_none      },
        .token_less          => ParseRule{ .prefix = null,     .infix = null,   .precedence = .prec_none      },
        .token_greater       => ParseRule{ .prefix = null,     .infix = null,   .precedence = .prec_none      },
        .token_equal         => ParseRule{ .prefix = null,     .infix = null,   .precedence = .prec_none      },
        .token_tilde         => ParseRule{ .prefix = null,     .infix = null,   .precedence = .prec_none      },
        .token_bang          => ParseRule{ .prefix = null,     .infix = null,   .precedence = .prec_none      },
        .token_comma         => ParseRule{ .prefix = null,     .infix = null,   .precedence = .prec_none      },
        .token_at            => ParseRule{ .prefix = null,     .infix = null,   .precedence = .prec_none      },
        .token_question      => ParseRule{ .prefix = null,     .infix = null,   .precedence = .prec_none      },
        .token_caret         => ParseRule{ .prefix = null,     .infix = null,   .precedence = .prec_none      },
        .token_hash          => ParseRule{ .prefix = null,     .infix = null,   .precedence = .prec_none      },
        .token_underscore    => ParseRule{ .prefix = null,     .infix = null,   .precedence = .prec_none      },
        .token_dollar        => ParseRule{ .prefix = null,     .infix = null,   .precedence = .prec_none      },
        .token_dot           => ParseRule{ .prefix = null,     .infix = null,   .precedence = .prec_none      },
        .token_bool          => ParseRule{ .prefix = null,     .infix = null,   .precedence = .prec_none      },
        .token_int           => ParseRule{ .prefix = null,     .infix = null,   .precedence = .prec_none      },
        .token_float         => ParseRule{ .prefix = number,   .infix = null,   .precedence = .prec_none      },
        .token_symbol        => ParseRule{ .prefix = symbol,   .infix = null,   .precedence = .prec_none      },
        .token_char          => ParseRule{ .prefix = null,     .infix = null,   .precedence = .prec_none      },
        .token_string        => ParseRule{ .prefix = null,     .infix = null,   .precedence = .prec_none      },
        .token_identifier    => ParseRule{ .prefix = variable, .infix = null,   .precedence = .prec_none      },
        .token_error         => ParseRule{ .prefix = null,     .infix = null,   .precedence = .prec_none      },
        .token_eof           => ParseRule{ .prefix = null,     .infix = null,   .precedence = .prec_none      },
        // zig fmt: on
    };
}

fn expression() CompilerError!*Node {
    return try parsePrecedence(.prec_secondary, true);
}

pub fn compile(source: []const u8, vm: *VM) CompilerError!*Value {
    scanner = Scanner.init(source);
    var compiler = Compiler.init(null, .function_script, vm);
    errdefer compiler.func.deinit(vm.allocator);
    current = &compiler;

    parser.had_error = false;
    parser.panic_mode = false;

    advance();

    var top_node = try expression();
    {
        errdefer top_node.deinit(vm.allocator);
        while (!check(.token_eof)) {
            const node = try expression();
            var rhs = &node.rhs;
            while (rhs.* != null) {
                rhs = &rhs.*.?.rhs;
            }
            rhs.* = top_node;
            top_node = node;
        }
    }

    consume(.token_eof, "Expect eof.");

    const func = endCompiler(top_node);
    return if (parser.had_error) CompilerError.compile_error else current.vm.initValue(.{ .function = func });
}
