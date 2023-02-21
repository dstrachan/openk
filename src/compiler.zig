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
const ValueType = value_mod.ValueType;
const ValueUnion = value_mod.ValueUnion;

const vm_mod = @import("vm.zig");
const VM = vm_mod.VM;

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

pub const CompilerError = error{
    compile_error,
};

const PrefixParseFn = *const fn (*Compiler) CompilerError!*Node;
const InfixParseFn = *const fn (*Compiler, *Node) CompilerError!*Node;

const ParseRule = struct {
    prefix: ?PrefixParseFn,
    infix: ?InfixParseFn,
    precedence: Precedence,
};

const FunctionType = enum {
    function_script,
    function_lambda,
};

pub fn compile(source: []const u8, vm: *VM) CompilerError!*Value {
    const scanner = Scanner.init(source);
    var compiler = Compiler.init(null, .function_script, vm, scanner);
    errdefer compiler.func.deinit(vm.allocator);
    compiler.current = &compiler;

    compiler.parser.had_error = false;
    compiler.parser.panic_mode = false;

    compiler.advance();

    var top_node = try compiler.expression();
    {
        errdefer top_node.deinit(vm.allocator);
        while (!compiler.check(.token_eof)) {
            const node = try compiler.expression();
            var rhs = &node.rhs;
            while (rhs.* != null) {
                rhs = &rhs.*.?.rhs;
            }
            rhs.* = top_node;
            top_node = node;
        }
    }

    compiler.consume(.token_eof, "Expect eof.");

    const func = compiler.endCompiler(top_node);
    return if (compiler.parser.had_error) CompilerError.compile_error else compiler.current.vm.initValue(.{ .function = func });
}

pub const Compiler = struct {
    const Self = @This();

    current: *Self = undefined,

    vm: *VM,
    scanner: Scanner,
    parser: Parser,
    enclosing: ?*Self,
    func: *ValueFn,
    function_type: FunctionType,
    locals: [u8_count]Token = undefined,
    local_count: u8,

    pub fn init(enclosing: ?*Self, function_type: FunctionType, vm: *VM, scanner: Scanner) Self {
        var compiler = Self{
            .vm = vm,
            .scanner = scanner,
            .parser = Parser{},
            .enclosing = enclosing,
            .func = ValueFn.init(vm.allocator),
            .function_type = function_type,
            .local_count = 0,
        };

        return compiler;
    }

    fn currentChunk(self: *Self) *Chunk {
        return self.current.func.chunk;
    }

    fn errorAtCurrent(self: *Self, message: []const u8) void {
        self.errorAt(&self.parser.current, message);
    }

    fn errorAtPrevious(self: *Self, message: []const u8) void {
        self.errorAt(&self.parser.previous, message);
    }

    fn errorAt(self: *Self, token: *Token, message: []const u8) void {
        if (self.parser.panic_mode) return;
        self.parser.panic_mode = true;
        print("[line {d}] Error", .{token.line});

        if (token.token_type == .token_eof) {
            print(" at end", .{});
        } else if (token.token_type == .token_error) {
            // Do nothing.
        } else {
            print(" at '{s}'", .{token.lexeme});
        }

        print(": {s}\n", .{message});
        self.parser.had_error = true;
    }

    fn advance(self: *Self) void {
        self.parser.previous = self.parser.current;

        while (true) {
            self.parser.current = self.scanner.scanToken();
            if (self.parser.current.token_type != .token_error) break;

            self.errorAtCurrent(self.parser.current.lexeme);
        }
    }

    fn consume(self: *Self, token_type: TokenType, message: []const u8) void {
        if (self.parser.current.token_type == token_type) {
            self.advance();
            return;
        }

        self.errorAtCurrent(message);
    }

    fn check(self: *Self, token_type: TokenType) bool {
        return self.parser.current.token_type == token_type;
    }

    fn match(self: *Self, token_type: TokenType) bool {
        if (!self.check(token_type)) return false;
        self.advance();
        return true;
    }

    pub fn emitByte(self: *Self, byte: u8) void {
        self.currentChunk().write(byte, self.parser.previous);
    }

    fn emitBytes(_: *Self, byte1: u8, byte2: u8) void {
        emitByte(byte1);
        emitByte(byte2);
    }

    pub fn emitInstruction(self: *Self, instruction: OpCode) void {
        self.emitByte(@enumToInt(instruction));
    }

    fn emitReturn(_: *Self) void {
        emitByte(@enumToInt(OpCode.op_return));
    }

    fn makeConstant(self: *Self, value: *Value) u8 {
        const constant = self.currentChunk().addConstant(value);
        if (constant > std.math.maxInt(u8)) {
            self.errorAtPrevious("Too many constants in one chunk.");
            return 0;
        }

        return @intCast(u8, constant);
    }

    fn getValue(self: *Self, constant: u8) *Value {
        return self.currentChunk().constants.items[constant];
    }

    fn endCompiler(self: *Self, node: *Node) *ValueFn {
        const top_node = Node.init(.{ .op_code = .op_return }, self.current.vm.allocator);
        top_node.rhs = node;
        if (node.op_code == .op_pop) {
            top_node.lhs = Node.init(.{ .op_code = .op_nil }, self.current.vm.allocator);
        }
        top_node.traverse(self);
        top_node.deinit(self.current.vm.allocator);

        const func = self.current.func;
        func.local_count = self.current.local_count;
        if (self.current.enclosing) |enclosing| {
            self.current = enclosing;
        }

        return func;
    }

    pub fn identifierConstant(self: *Self, name: Token) u8 {
        const value = self.current.vm.copySymbol(name.lexeme);
        return self.makeConstant(value);
    }

    pub fn resolveLocal(self: *Self, name: Token) ?u8 {
        var i = self.current.local_count;
        while (i > 0) {
            i -= 1;
            if (std.mem.eql(u8, name.lexeme, self.current.locals[i].lexeme)) {
                return i;
            }
        }

        return null;
    }

    fn addLocal(self: *Self, name: Token) void {
        if (self.current.local_count == u8_count) {
            errorAtPrevious("Too many local variables in function.");
            return;
        }

        self.current.locals[self.current.local_count] = name;
        self.current.local_count += 1;
    }

    fn number(self: *Self) CompilerError!*Node {
        const value = switch (self.parser.previous.token_type) {
            .token_bool => self.parseBool(self.parser.previous.lexeme),
            .token_int => blk: {
                switch (self.parser.current.token_type) {
                    .token_int => {
                        var list = std.ArrayList(*Value).init(self.current.vm.allocator);
                        defer list.deinit();
                        list.append(self.parseInt(self.parser.previous.lexeme)) catch std.debug.panic("Failed to append item.", .{});

                        while (self.parser.current.token_type == .token_int or self.parser.current.token_type == .token_float) {
                            if (self.parser.current.token_type == .token_float) { // switch to parsing floats
                                for (list.items, 0..) |value, i| {
                                    list.items[i] = self.current.vm.initValue(.{ .float = utils_mod.intToFloat(value.as.int) });
                                    value.deref(self.current.vm.allocator);
                                }

                                list.append(self.parseFloat(self.parser.current.lexeme)) catch std.debug.panic("Failed to append item.", .{});
                                self.advance();

                                while (self.parser.current.token_type == .token_int or self.parser.current.token_type == .token_float) {
                                    list.append(self.parseFloat(self.parser.current.lexeme)) catch std.debug.panic("Failed to append item.", .{});
                                    self.advance();
                                }

                                const slice = list.toOwnedSlice() catch std.debug.panic("Failed to create list.", .{});
                                break :blk self.current.vm.initValue(.{ .float_list = slice });
                            }

                            list.append(self.parseInt(self.parser.current.lexeme)) catch std.debug.panic("Failed to append item.", .{});
                            self.advance();
                        }

                        const slice = list.toOwnedSlice() catch std.debug.panic("Failed to create list.", .{});
                        break :blk self.current.vm.initValue(.{ .int_list = slice });
                    },
                    .token_float => {
                        var list = std.ArrayList(*Value).init(self.current.vm.allocator);
                        defer list.deinit();
                        list.append(self.parseFloat(self.parser.previous.lexeme)) catch std.debug.panic("Failed to append item.", .{});

                        while (self.parser.current.token_type == .token_int or self.parser.current.token_type == .token_float) {
                            list.append(self.parseFloat(self.parser.current.lexeme)) catch std.debug.panic("Failed to append item.", .{});
                            self.advance();
                        }

                        const slice = list.toOwnedSlice() catch std.debug.panic("Failed to create list.", .{});
                        break :blk self.current.vm.initValue(.{ .float_list = slice });
                    },
                    else => break :blk self.parseInt(self.parser.previous.lexeme),
                }
            },
            .token_float => blk: {
                switch (self.parser.current.token_type) {
                    .token_int, .token_float => {
                        var list = std.ArrayList(*Value).init(self.current.vm.allocator);
                        defer list.deinit();
                        list.append(self.parseFloat(self.parser.previous.lexeme)) catch std.debug.panic("Failed to append item.", .{});

                        while (self.parser.current.token_type == .token_int or self.parser.current.token_type == .token_float) {
                            list.append(self.parseFloat(self.parser.current.lexeme)) catch std.debug.panic("Failed to append item.", .{});
                            self.advance();
                        }

                        const slice = list.toOwnedSlice() catch std.debug.panic("Failed to create list.", .{});
                        break :blk self.current.vm.initValue(.{ .float_list = slice });
                    },
                    else => break :blk self.parseFloat(self.parser.previous.lexeme),
                }
            },
            else => unreachable,
        };
        return Node.init(.{ .op_code = .op_constant, .byte = self.makeConstant(value) }, self.current.vm.allocator);
    }

    fn parseBool(self: *Self, str: []const u8) *Value {
        if (str.len > 2) {
            const list = self.current.vm.allocator.alloc(*Value, str.len - 1) catch std.debug.panic("Failed to create list", .{});
            for (str[0 .. str.len - 1], 0..) |c, i| {
                list[i] = self.current.vm.initValue(.{ .boolean = c == '1' });
            }
            return self.current.vm.initValue(.{ .boolean_list = list });
        }
        return self.current.vm.initValue(.{ .boolean = str[0] == '1' });
    }

    fn parseInt(self: *Self, str: []const u8) *Value {
        if (str.len == 2) {
            if (str[0] == '0') {
                if (str[1] == 'N') {
                    return self.current.vm.initValue(.{ .int = Value.null_int });
                } else if (str[1] == 'W') {
                    return self.current.vm.initValue(.{ .int = Value.inf_int });
                }
            }
        } else if (str.len == 3 and str[0] == '-' and str[1] == '0' and str[2] == 'W') {
            return self.current.vm.initValue(.{ .int = -Value.inf_int });
        }
        const int = std.fmt.parseInt(i64, str, 10) catch std.debug.panic("Failed to parse int", .{});
        return self.current.vm.initValue(.{ .int = int });
    }

    fn parseFloat(self: *Self, str: []const u8) *Value {
        if (str.len == 2) {
            if (str[0] == '0') {
                if (str[1] == 'N' or str[1] == 'n') {
                    return self.current.vm.initValue(.{ .float = Value.null_float });
                } else if (str[1] == 'W' or str[1] == 'w') {
                    return self.current.vm.initValue(.{ .float = Value.inf_float });
                }
            }
        } else if (str.len == 3 and str[0] == '-' and str[1] == '0' and (str[2] == 'W' or str[2] == 'w')) {
            return self.current.vm.initValue(.{ .float = -Value.inf_float });
        }
        const float = std.fmt.parseFloat(f64, str) catch std.debug.panic("Failed to parse float", .{});
        return self.current.vm.initValue(.{ .float = float });
    }

    fn symbol(self: *Self) CompilerError!*Node {
        const value = switch (self.parser.current.token_type) {
            .token_symbol => blk: {
                if (self.parser.current.follows_whitespace) break :blk self.current.vm.copySymbol(self.parser.previous.lexeme[1..self.parser.previous.lexeme.len]);

                var list = std.ArrayList(*Value).init(self.current.vm.allocator);
                defer list.deinit();
                list.append(self.current.vm.copySymbol(self.parser.previous.lexeme[1..self.parser.previous.lexeme.len])) catch std.debug.panic("Failed to append item.", .{});

                while (self.parser.current.token_type == .token_symbol and !self.parser.current.follows_whitespace) {
                    list.append(self.current.vm.copySymbol(self.parser.current.lexeme[1..self.parser.current.lexeme.len])) catch std.debug.panic("Failed to append item.", .{});
                    self.advance();
                }

                const slice = list.toOwnedSlice() catch std.debug.panic("Failed to create list.", .{});
                break :blk self.current.vm.initValue(.{ .symbol_list = slice });
            },
            else => self.current.vm.copySymbol(self.parser.previous.lexeme[1..self.parser.previous.lexeme.len]),
        };
        return Node.init(.{ .op_code = .op_constant, .byte = self.makeConstant(value) }, self.current.vm.allocator);
    }

    fn char(self: *Self) CompilerError!*Node {
        const value = self.current.vm.initValue(.{ .char = self.parser.previous.lexeme[self.parser.previous.lexeme.len - 2] });
        return Node.init(.{ .op_code = .op_constant, .byte = self.makeConstant(value) }, self.current.vm.allocator);
    }

    fn string(self: *Self) CompilerError!*Node {
        var list = std.ArrayList(*Value).init(self.current.vm.allocator);
        defer list.deinit();

        var is_escaped = false;
        for (self.parser.previous.lexeme[1 .. self.parser.previous.lexeme.len - 1]) |c| {
            if (c == '\\' and !is_escaped) {
                is_escaped = true;
                continue;
            }
            is_escaped = false;
            list.append(self.current.vm.initValue(.{ .char = c })) catch std.debug.panic("Failed to append item", .{});
        }

        const slice = list.toOwnedSlice() catch std.debug.panic("Failed to create string", .{});
        const value = self.current.vm.initValue(.{ .char_list = slice });
        return Node.init(.{ .op_code = .op_constant, .byte = self.makeConstant(value) }, self.current.vm.allocator);
    }

    fn variable(self: *Self) CompilerError!*Node {
        const name = self.parser.previous;

        if (self.match(.token_double_colon)) {
            const arg = self.identifierConstant(name);
            const node = Node.init(.{ .op_code = .op_set_global, .byte = arg }, self.current.vm.allocator);
            node.rhs = try self.expression();
            return node;
        }

        if (self.current.function_type == .function_script) {
            const arg = self.identifierConstant(name);
            if (self.match(.token_colon)) {
                const node = Node.init(.{ .op_code = .op_set_global, .byte = arg }, self.current.vm.allocator);
                node.rhs = try self.expression();
                return node;
            } else {
                return Node.init(.{ .op_code = .op_get_global, .byte = arg }, self.current.vm.allocator);
            }
        } else {
            if (self.match(.token_colon)) {
                const arg = self.resolveLocal(name) orelse blk: {
                    self.addLocal(name);
                    break :blk self.current.local_count - 1;
                };
                const node = Node.init(.{ .op_code = .op_set_local, .byte = arg }, self.current.vm.allocator);
                node.rhs = try self.expression();
                return node;
            } else {
                return Node.init(.{ .op_code = .op_get_global, .name = name }, self.current.vm.allocator);
            }
        }
    }

    fn call(self: *Self, node: *Node) CompilerError!*Node {
        const call_node = Node.init(.{ .op_code = .op_call, .byte = 0b0 }, self.current.vm.allocator);
        call_node.lhs = node;

        if (!self.check(.token_right_bracket)) {
            var arg_count: u8 = 0;
            var arg_indices = std.bit_set.IntegerBitSet(8).initEmpty();
            while (self.match(.token_semicolon)) {
                arg_count += 1;
            }

            if (!self.check(.token_right_bracket)) {
                arg_indices.set(arg_count);
                arg_count += 1;
                var top_node = try self.expression();
                var rhs = &top_node.*.rhs;
                var should_continue = self.match(.token_semicolon);
                while (should_continue) {
                    if (self.check(.token_right_bracket)) break;

                    arg_count += 1;
                    if (arg_count > 8) {
                        self.errorAtCurrent("Can't have more than 8 arguments.");
                        return CompilerError.compile_error;
                    }

                    if (self.match(.token_semicolon)) continue;
                    arg_indices.set(arg_count - 1);

                    const arg_node = try self.expression();
                    while (rhs.* != null) {
                        rhs = &rhs.*.?.rhs;
                    }
                    rhs.* = arg_node;

                    should_continue = self.match(.token_semicolon);
                }

                call_node.byte = arg_indices.mask;
                call_node.rhs = top_node;
            }
        }
        self.consume(.token_right_bracket, "Expect ']' after arguments.");

        return call_node;
    }

    fn binary(self: *Self, node: *Node) CompilerError!*Node {
        const current_node = Node.init(.{
            .op_code = switch (self.parser.previous.token_type) {
                .token_plus => .op_add,
                .token_minus => .op_subtract,
                .token_star => .op_multiply,
                .token_percent => .op_divide,
                .token_bang => .op_dict,
                .token_ampersand => .op_min,
                .token_pipe => .op_max,
                .token_less => .op_less,
                .token_greater => .op_more,
                .token_equal => .op_equal,
                .token_tilde => .op_match,
                .token_comma => .op_merge,
                .token_caret => .op_fill,
                .token_hash => .op_take,
                .token_underscore => .op_drop,
                .token_dollar => .op_cast,
                .token_question => .op_find,
                .token_at => .op_apply_1,
                .token_dot => .op_apply_n,
                else => unreachable,
            },
        }, self.current.vm.allocator);
        errdefer current_node.deinit(self.current.vm.allocator);

        var prev_token = self.parser.previous;

        current_node.lhs = node;
        current_node.rhs = try self.parsePrecedence(self.getRule(self.parser.previous.token_type).precedence, true);

        // TODO: Reuse constant slot
        if (current_node.op_code == .op_cast and current_node.lhs.?.op_code == .op_constant and current_node.rhs.?.op_code == .op_constant) {
            const rhs = self.getValue(current_node.rhs.?.byte.?);
            if (rhs.as == .list and rhs.as.list.len == 0) {
                const lhs = self.getValue(current_node.lhs.?.byte.?);
                if (lhs.as != .symbol) {
                    self.errorAt(&prev_token, "Expected symbol as left-hand argument to cast.");
                    return CompilerError.compile_error;
                }

                const list = &[_]*Value{};
                const value_union: ?ValueUnion = switch (lhs.as.symbol.len) {
                    0 => .{ .symbol_list = list },
                    else => switch (lhs.as.symbol[0]) {
                        'b' => if (std.mem.eql(u8, lhs.as.symbol, "boolean")) .{ .boolean_list = list } else null,
                        'i' => if (std.mem.eql(u8, lhs.as.symbol, "int")) .{ .int_list = list } else null,
                        'f' => if (std.mem.eql(u8, lhs.as.symbol, "float")) .{ .float_list = list } else null,
                        'c' => if (std.mem.eql(u8, lhs.as.symbol, "char")) .{ .char_list = list } else null,
                        's' => if (std.mem.eql(u8, lhs.as.symbol, "symbol")) .{ .symbol_list = list } else null,
                        else => null,
                    },
                };
                if (value_union == null) {
                    self.errorAt(&prev_token, "Invalid cast type.");
                    return CompilerError.compile_error;
                }

                current_node.op_code = .op_constant;
                current_node.byte = self.makeConstant(self.vm.initValue(value_union.?));
                current_node.lhs.?.deinit(self.current.vm.allocator);
                current_node.lhs = null;
                current_node.rhs.?.deinit(self.current.vm.allocator);
                current_node.rhs = null;
            }
        }

        return current_node;
    }

    fn grouping(self: *Self) CompilerError!*Node {
        if (self.match(.token_right_paren)) {
            const value = self.current.vm.initValue(.{ .list = &[_]*Value{} });
            return Node.init(.{ .op_code = .op_constant, .byte = self.makeConstant(value) }, self.current.vm.allocator);
        }

        const first_node = try self.expression();
        if (self.match(.token_right_paren)) {
            return first_node;
        }

        if (self.check(.token_semicolon)) {
            var list = std.ArrayList(*Node).init(self.current.vm.allocator);
            defer list.deinit();
            errdefer for (list.items) |node| node.deinit(self.current.vm.allocator);

            var all_constants = first_node.op_code == .op_constant;
            var value_type: ValueType = if (all_constants) self.getValue(first_node.byte.?).as else .list;

            list.append(first_node) catch std.debug.panic("Failed to append item.", .{});
            while (self.match(.token_semicolon)) {
                const node = try self.expression();
                all_constants = if (all_constants and node.op_code == .op_constant) true else false;
                if (all_constants and value_type != self.getValue(node.byte.?).as) {
                    value_type = .list;
                }
                list.append(node) catch std.debug.panic("Failed to append item.", .{});
            }
            self.consume(.token_right_paren, "Expect ')' after list.");

            return self.createList(list, value_type, all_constants);
        }

        self.errorAtCurrent("Expect ')' after expression.");
        return CompilerError.compile_error;
    }

    // TODO: Reuse constant slots
    fn createList(self: *Self, nodes: std.ArrayList(*Node), value_type: ValueType, all_constants: bool) *Node {
        if (all_constants) {
            const list_type: ValueType = switch (value_type) {
                .boolean => .boolean_list,
                .int => .int_list,
                .float => .float_list,
                .char => .char_list,
                .symbol => .symbol_list,
                else => .list,
            };
            const list = self.current.vm.allocator.alloc(*Value, nodes.items.len) catch std.debug.panic("Failed to create list.", .{});
            for (nodes.items, 0..) |node, i| {
                list[i] = self.getValue(node.byte.?).ref();
                node.deinit(self.current.vm.allocator);
            }
            const value = switch (list_type) {
                .boolean_list => self.current.vm.initValue(.{ .boolean_list = list }),
                .int_list => self.current.vm.initValue(.{ .int_list = list }),
                .float_list => self.current.vm.initValue(.{ .float_list = list }),
                .char_list => self.current.vm.initValue(.{ .char_list = list }),
                .symbol_list => self.current.vm.initValue(.{ .symbol_list = list }),
                .list => self.current.vm.initValue(.{ .list = list }),
                else => unreachable,
            };
            return Node.init(.{ .op_code = .op_constant, .byte = self.makeConstant(value) }, self.current.vm.allocator);
        }

        const bottom_node = Node.init(.{ .op_code = .op_concat }, self.current.vm.allocator);
        bottom_node.rhs = nodes.items[nodes.items.len - 1];
        bottom_node.lhs = nodes.items[nodes.items.len - 2];
        var prev_node = bottom_node;

        var i = nodes.items.len - 2;
        while (i > 0) : (i -= 1) {
            const node = Node.init(.{ .op_code = .op_merge }, self.current.vm.allocator);
            const temp_node = Node.init(.{ .op_code = .op_enlist }, self.current.vm.allocator);
            temp_node.rhs = nodes.items[i - 1];
            node.lhs = temp_node;
            node.rhs = prev_node;
            prev_node = node;
        }

        return prev_node;
    }

    fn block(self: *Self) CompilerError!*Node {
        var top_node = try self.expression();
        {
            errdefer top_node.deinit(self.current.vm.allocator);
            while (!self.check(.token_right_brace) and !self.check(.token_eof)) {
                const node = try self.expression();
                var rhs = &node.rhs;
                while (rhs.* != null) {
                    rhs = &rhs.*.?.rhs;
                }
                rhs.* = top_node;
                top_node = node;
            }
        }

        self.consume(.token_right_brace, "Expect '}' after block.");

        return top_node;
    }

    fn function(self: *Self) CompilerError!*Node {
        var compiler = Compiler.init(self.current, .function_lambda, self.current.vm, self.scanner);
        errdefer compiler.func.deinit(self.current.vm.allocator);
        self.current = &compiler;

        const start_index = @ptrToInt(self.scanner.start) - @ptrToInt(self.scanner.source.ptr) - 1;

        if (self.match(.token_left_bracket)) {
            var should_continue = !self.check(.token_right_bracket);
            while (should_continue) {
                self.current.func.arity += 1;
                if (self.current.func.arity > 8) {
                    self.errorAtCurrent("Can't have more than 8 parameters.");
                    return CompilerError.compile_error;
                }

                self.consume(.token_identifier, "Expect parameter name.");

                var i = self.current.local_count;
                while (i > 0) {
                    i -= 1;
                    const local = self.current.locals[i];
                    if (std.mem.eql(u8, self.parser.previous.lexeme, local.lexeme)) {
                        self.errorAtPrevious("Duplicate parameter name.");
                        return CompilerError.compile_error;
                    }
                }

                self.addLocal(self.parser.previous);

                should_continue = self.match(.token_semicolon);
            }
            self.consume(.token_right_bracket, "Expect ']' after parameters.");
        }

        const node = try self.block();

        const end_index = std.math.min(@ptrToInt(self.scanner.start) - @ptrToInt(self.scanner.source.ptr), self.scanner.source.len);
        self.current.func.name = self.current.vm.allocator.dupe(u8, self.scanner.source[start_index..end_index]) catch std.debug.panic("Failed to create function", .{});

        const func = self.endCompiler(node);
        const value = self.current.vm.initValue(.{ .function = func });
        return Node.init(.{ .op_code = .op_constant, .byte = self.makeConstant(value) }, self.current.vm.allocator);
    }

    fn pop(self: *Self) CompilerError!*Node {
        return Node.init(.{ .op_code = .op_pop }, self.current.vm.allocator);
    }

    fn unary(self: *Self) CompilerError!*Node {
        const node = Node.init(.{
            .op_code = switch (self.parser.previous.token_type) {
                .token_plus => .op_flip,
                .token_minus => .op_negate,
                .token_star => .op_first,
                .token_percent => .op_sqrt,
                .token_bang => .op_key,
                .token_ampersand => .op_where,
                .token_pipe => .op_reverse,
                .token_less => .op_ascend,
                .token_greater => .op_descend,
                .token_equal => .op_group,
                .token_tilde => .op_not,
                .token_comma => .op_enlist,
                .token_caret => .op_null,
                .token_hash => .op_length,
                .token_underscore => .op_floor,
                .token_dollar => .op_string,
                .token_question => .op_unique,
                .token_at => .op_type,
                .token_dot => .op_value,
                else => unreachable,
            },
        }, self.current.vm.allocator);
        node.rhs = try self.parsePrecedence(self.getRule(self.parser.previous.token_type).precedence, true);
        return node;
    }

    fn parsePrecedence(self: *Self, precedence: Precedence, should_advance: bool) CompilerError!*Node {
        if (should_advance) self.advance();
        const prefixRule = self.getRule(self.parser.previous.token_type).prefix orelse {
            self.errorAtPrevious("Expect prefix expression.");
            return CompilerError.compile_error;
        };
        var node = try prefixRule(self);

        while (@enumToInt(precedence) <= @enumToInt(self.getRule(self.parser.current.token_type).precedence)) {
            self.advance();
            const infixRule = self.getRule(self.parser.previous.token_type).infix orelse {
                self.errorAtPrevious("Expect infix expression.");
                return CompilerError.compile_error;
            };
            node = try infixRule(self, node);
        }

        switch (self.parser.previous.token_type) {
            .token_right_paren,
            .token_right_brace,
            .token_right_bracket,
            .token_identifier,
            .token_bool,
            .token_int,
            .token_float,
            .token_char,
            .token_string,
            .token_symbol,
            => switch (self.parser.current.token_type) {
                .token_left_paren,
                .token_left_brace,
                .token_left_bracket,
                .token_identifier,
                .token_bool,
                .token_int,
                .token_float,
                .token_char,
                .token_string,
                .token_symbol,
                => {
                    const temp_node = Node.init(.{ .op_code = .op_apply_1 }, self.current.vm.allocator);
                    temp_node.lhs = node;
                    temp_node.rhs = try self.parsePrecedence(.prec_secondary, true);
                    node = temp_node;
                },
                else => {},
            },
            else => {},
        }

        return node;
    }

    fn getRule(_: *Self, token_type: TokenType) ParseRule {
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
        .token_plus          => ParseRule{ .prefix = unary,    .infix = binary, .precedence = .prec_secondary },
        .token_minus         => ParseRule{ .prefix = unary,    .infix = binary, .precedence = .prec_secondary },
        .token_star          => ParseRule{ .prefix = unary,    .infix = binary, .precedence = .prec_secondary },
        .token_percent       => ParseRule{ .prefix = unary,    .infix = binary, .precedence = .prec_secondary },
        .token_bang          => ParseRule{ .prefix = unary,    .infix = binary, .precedence = .prec_secondary },
        .token_ampersand     => ParseRule{ .prefix = unary,    .infix = binary, .precedence = .prec_secondary },
        .token_pipe          => ParseRule{ .prefix = unary,    .infix = binary, .precedence = .prec_secondary },
        .token_less          => ParseRule{ .prefix = unary,    .infix = binary, .precedence = .prec_secondary },
        .token_greater       => ParseRule{ .prefix = unary,    .infix = binary, .precedence = .prec_secondary },
        .token_equal         => ParseRule{ .prefix = unary,    .infix = binary, .precedence = .prec_secondary },
        .token_tilde         => ParseRule{ .prefix = unary,    .infix = binary, .precedence = .prec_secondary },
        .token_comma         => ParseRule{ .prefix = unary,    .infix = binary, .precedence = .prec_secondary },
        .token_caret         => ParseRule{ .prefix = unary,    .infix = binary, .precedence = .prec_secondary },
        .token_hash          => ParseRule{ .prefix = unary,    .infix = binary, .precedence = .prec_secondary },
        .token_underscore    => ParseRule{ .prefix = unary,    .infix = binary, .precedence = .prec_secondary },
        .token_dollar        => ParseRule{ .prefix = unary,    .infix = binary, .precedence = .prec_secondary },
        .token_question      => ParseRule{ .prefix = unary,    .infix = binary, .precedence = .prec_secondary },
        .token_at            => ParseRule{ .prefix = unary,    .infix = binary, .precedence = .prec_secondary },
        .token_dot           => ParseRule{ .prefix = unary,    .infix = binary, .precedence = .prec_secondary },
        .token_bool          => ParseRule{ .prefix = number,   .infix = null,   .precedence = .prec_none      },
        .token_int           => ParseRule{ .prefix = number,   .infix = null,   .precedence = .prec_none      },
        .token_float         => ParseRule{ .prefix = number,   .infix = null,   .precedence = .prec_none      },
        .token_char          => ParseRule{ .prefix = char,     .infix = null,   .precedence = .prec_none      },
        .token_string        => ParseRule{ .prefix = string,   .infix = null,   .precedence = .prec_none      },
        .token_symbol        => ParseRule{ .prefix = symbol,   .infix = null,   .precedence = .prec_none      },
        .token_identifier    => ParseRule{ .prefix = variable, .infix = null,   .precedence = .prec_none      },
        .token_error         => ParseRule{ .prefix = null,     .infix = null,   .precedence = .prec_none      },
        .token_eof           => ParseRule{ .prefix = null,     .infix = null,   .precedence = .prec_none      },
        // zig fmt: on
        };
    }

    fn expression(self: *Self) CompilerError!*Node {
        return try self.parsePrecedence(.prec_secondary, true);
    }
};
