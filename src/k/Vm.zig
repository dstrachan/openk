const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

const k = @import("../root.zig");
const Chunk = k.Chunk;
const OpCode = k.OpCode;
const Value = k.Value;
const Ast = k.Ast;
const Compiler = k.Compiler;
const Lambda = k.Lambda;
const UnaryPrimitive = k.UnaryPrimitive;
const Operator = k.Operator;
const trace_execution = k.trace_execution;

const Vm = @This();

io: Io,
gpa: Allocator,
frames: std.ArrayList(CallFrame),
stack: std.ArrayList(*Value),
stdout: *Io.Writer,
color: std.zig.Color,
unary_primitives: [std.meta.fields(UnaryPrimitive).len]*Value = undefined,
operators: [std.meta.fields(Operator).len]*Value = undefined,
string_bytes: std.ArrayList(u8) = .empty,
string_table: std.HashMapUnmanaged(
    u32,
    void,
    std.hash_map.StringIndexContext,
    std.hash_map.default_max_load_percentage,
) = .empty,
globals: std.AutoHashMapUnmanaged([*:0]const u8, *Value) = .empty,

pub const Error = Allocator.Error || Io.Writer.Error || Io.Cancelable || error{ RuntimeError, CompilerError };

pub const frames_max = 64;
pub const stack_max = frames_max * (std.math.maxInt(u8) + 1);

const CallFrame = struct {
    lambda: Lambda,
    ip: [*]u8,
    slots: [*]*Value,
};

pub fn init(vm: *Vm, io: Io, gpa: Allocator, stdout: *Io.Writer, color: std.zig.Color) !void {
    var frames: std.ArrayList(CallFrame) = try .initCapacity(gpa, frames_max);
    errdefer frames.deinit(gpa);
    var stack: std.ArrayList(*Value) = try .initCapacity(gpa, stack_max);
    errdefer stack.deinit(gpa);

    vm.* = .{
        .io = io,
        .gpa = gpa,
        .frames = frames,
        .stack = stack,
        .stdout = stdout,
        .color = color,
    };

    var unary_primitives: usize = 0;
    errdefer for (0..unary_primitives) |i| vm.unary_primitives[i].deref(gpa);
    for (&vm.unary_primitives, 0..) |*v, i| {
        v.* = try .unaryPrimitive(gpa, @enumFromInt(i));
        unary_primitives += 1;
    }
    var operators: usize = 0;
    errdefer for (0..operators) |i| vm.operators[i].deref(gpa);
    for (&vm.operators, 0..) |*v, i| {
        v.* = try .operator(gpa, @enumFromInt(i));
        operators += 1;
    }
}

pub fn deinit(vm: *Vm) void {
    assert(vm.frames.items.len == 0);
    assert(vm.stack.items.len == 0);

    var it = vm.globals.valueIterator();
    while (it.next()) |value| value.*.deref(vm.gpa);
    vm.globals.deinit(vm.gpa);
    vm.string_table.deinit(vm.gpa);
    vm.string_bytes.deinit(vm.gpa);
    for (vm.operators) |v| v.deref(vm.gpa);
    for (vm.unary_primitives) |v| v.deref(vm.gpa);
    vm.stack.deinit(vm.gpa);
    vm.frames.deinit(vm.gpa);
}

fn push(vm: *Vm, value: *Value) void {
    vm.stack.appendAssumeCapacity(value);
}

fn peek(vm: *Vm) *Value {
    return vm.stack.getLast();
}

fn pop(vm: *Vm) *Value {
    return vm.stack.pop().?;
}

fn runtimeError(vm: *Vm, comptime fmt: []const u8, args: anytype) Error {
    var buffer: [256]u8 = undefined;
    const locked_stderr = try vm.io.lockStderr(&buffer, vm.color.terminalMode());
    defer vm.io.unlockStderr();

    const stderr = &locked_stderr.file_writer.interface;

    try stderr.print(fmt ++ "\n", args);

    var it = std.mem.reverseIterator(vm.frames.items);
    while (it.next()) |frame| {
        const instruction = frame.ip - frame.lambda.chunk.data.items(.code).ptr - 1;
        try stderr.print("[line {d}] in ", .{frame.lambda.chunk.data.items(.line)[instruction]});
        if (std.mem.span(frame.lambda.source).len > 0) {
            try stderr.print("{s}()\n", .{frame.lambda.source});
        } else {
            try stderr.writeAll("script\n");
        }
    }

    try stderr.flush();
    vm.stack.shrinkRetainingCapacity(0);
    return error.RuntimeError;
}

pub fn internSymbol(vm: *Vm, value: []const u8) !*Value {
    return .symbol(vm.gpa, try vm.intern(value));
}

pub fn internSymbolList(vm: *Vm, value: []const []const u8) !*Value {
    const list = try vm.gpa.alloc([*:0]const u8, value.len);
    errdefer vm.gpa.free(value);
    for (list, value) |*v, bytes| v.* = try vm.intern(bytes);
    return .symbolList(vm.gpa, list);
}

pub fn intern(vm: *Vm, bytes: []const u8) ![*:0]const u8 {
    const str_index: u32 = @intCast(vm.string_bytes.items.len);
    try vm.string_bytes.appendSlice(vm.gpa, bytes);
    const gop = try vm.string_table.getOrPutContextAdapted(
        vm.gpa,
        bytes,
        std.hash_map.StringIndexAdapter{ .bytes = &vm.string_bytes },
        std.hash_map.StringIndexContext{ .bytes = &vm.string_bytes },
    );
    if (gop.found_existing) {
        vm.string_bytes.shrinkRetainingCapacity(str_index);
    } else {
        gop.key_ptr.* = str_index;
        try vm.string_bytes.append(vm.gpa, 0);
    }

    const slice = vm.string_bytes.items[gop.key_ptr.*..];
    return slice[0..std.mem.findScalar(u8, slice, 0).? :0];
}

pub fn interpret(vm: *Vm, tree: Ast, src_path: []const u8) Error!void {
    var compiler: Compiler = undefined;
    try compiler.init(vm, tree, src_path);
    defer compiler.deinit();

    const lambda: *Value = lambda: {
        errdefer compiler.lambda.deref(vm.gpa);
        break :lambda compiler.compile() catch |err| switch (err) {
            error.OutOfMemory => return error.OutOfMemory,
            else => return error.CompilerError,
        };
    };
    errdefer lambda.deref(vm.gpa);

    if (compiler.hasErrors()) {
        var eb = try compiler.eb.toOwnedBundle("");
        defer eb.deinit(compiler.gpa);
        eb.renderToStderr(vm.io, .{}, vm.color) catch return error.CompilerError;
        return error.CompilerError;
    }

    try vm.applyLambda(lambda, 0);
    vm.run() catch return error.RuntimeError;
}

fn run(vm: *Vm) Error!void {
    var frame = &vm.frames.items[vm.frames.items.len - 1];
    while (true) {
        if (trace_execution) {
            try vm.stdout.writeAll("          ");
            for (vm.stack.items) |slot| {
                try vm.stdout.print("[ {f} ]", .{slot});
            }
            try vm.stdout.writeByte('\n');
            _ = try frame.lambda.chunk.disassembleInstruction(vm.stdout, frame.ip - frame.lambda.chunk.data.items(.code).ptr);
            try vm.stdout.flush();
        }

        const instruction: OpCode = @enumFromInt(vm.readByte());
        switch (instruction) {
            .constant => vm.push(vm.readConstant().ref()),
            .get_global => {
                const name = vm.readConstant();
                if (vm.globals.get(name.as.symbol)) |global| {
                    vm.push(global.ref());
                } else return vm.runtimeError("Undefined variable '{s}'.", .{name.as.symbol});
            },
            .set_global => {
                const name = vm.readConstant();
                const gop = try vm.globals.getOrPut(vm.gpa, name.as.symbol);
                if (gop.found_existing) {
                    gop.value_ptr.*.deref(vm.gpa);
                }
                gop.value_ptr.* = vm.peek().ref();
            },

            .unary_primitive => vm.push(vm.readUnaryPrimitive().ref()),
            .operator => vm.push(vm.readOperator().ref()),

            .get_local => vm.push(frame.slots[vm.readByte()].ref()),
            .set_local => frame.slots[vm.readByte()] = vm.peek().ref(),

            .@"return" => {
                const result = vm.pop();
                defer result.deref(vm.gpa);
                defer vm.frames.shrinkRetainingCapacity(vm.frames.items.len - 1);
                if (vm.frames.items.len == 1) {
                    vm.pop().deref(vm.gpa);
                    return;
                }

                while (vm.stack.items.len > frame.slots - vm.stack.items.ptr) {
                    vm.pop().deref(vm.gpa);
                }

                vm.push(result.ref());
                frame = &vm.frames.items[vm.frames.items.len - 2];
            },
            .pop => vm.pop().deref(vm.gpa),
            .print => {
                try vm.stdout.print("{f}\n", .{vm.peek()});
                try vm.stdout.flush();
            },

            .apply => {
                const arg_count = vm.readByte();
                assert(arg_count > 0 and arg_count <= 8);
                if (vm.peek().as == .lambda) {
                    const lambda = vm.pop();
                    errdefer lambda.deref(vm.gpa);
                    try vm.applyLambda(lambda, arg_count);
                    frame = &vm.frames.items[vm.frames.items.len - 1];
                } else {
                    vm.push(try vm.apply(arg_count));
                }
            },
        }
    }
}

inline fn readByte(vm: *Vm) u8 {
    const frame = &vm.frames.items[vm.frames.items.len - 1];
    defer frame.ip += 1;
    return frame.ip[0];
}

inline fn readConstant(vm: *Vm) *Value {
    const frame = &vm.frames.items[vm.frames.items.len - 1];
    return frame.lambda.chunk.constants.items[vm.readByte()];
}

inline fn readUnaryPrimitive(vm: *Vm) *Value {
    return vm.unary_primitives[vm.readByte()];
}

inline fn readOperator(vm: *Vm) *Value {
    return vm.operators[vm.readByte()];
}

fn apply(vm: *Vm, arg_count: u8) !*Value {
    const callee = vm.pop();
    defer callee.deref(vm.gpa);

    const args = args: {
        var args: [8]*Value = undefined;
        for (0..arg_count) |i| args[i] = vm.pop();
        break :args args[0..arg_count];
    };
    defer for (args) |v| v.deref(vm.gpa);

    return switch (callee.as) {
        .lambda => unreachable,
        .unary_primitive => |unary_primitive| blk: {
            if (args.len != 1) return vm.runtimeError("expected 1 argument, found: {d}", .{args.len});
            break :blk vm.applyUnaryPrimitive(unary_primitive, args[0]);
        },
        .operator => |operator| blk: {
            if (args.len != 2) return vm.runtimeError("expected 2 arguments, found: {d}", .{args.len});
            break :blk vm.applyOperator(operator, args[0], args[1]);
        },
        inline else => |_, t| std.debug.panic("NYI: {t}", .{t}),
    };
}

fn applyLambda(vm: *Vm, lambda: *Value, arg_count: u8) !void {
    const args = args: {
        var args: [8]*Value = undefined;
        for (0..arg_count) |i| args[i] = vm.pop();
        break :args args[0..arg_count];
    };
    errdefer for (args) |v| v.deref(vm.gpa);

    if (lambda.as.lambda.arity != arg_count) {
        return vm.runtimeError("expected {d} argument(s), found: {d}", .{ lambda.as.lambda.arity, arg_count });
    }

    if (vm.frames.items.len == frames_max) {
        return vm.runtimeError("stack overflow", .{});
    }

    errdefer comptime unreachable;

    const stack_len = vm.stack.items.len;

    vm.push(lambda);
    for (args) |v| vm.push(v);

    vm.frames.appendAssumeCapacity(.{
        .lambda = lambda.as.lambda,
        .ip = lambda.as.lambda.chunk.data.items(.code).ptr,
        .slots = vm.stack.items[stack_len..].ptr,
    });
}

fn applyUnaryPrimitive(vm: *Vm, unary_primitive: UnaryPrimitive, x: *Value) !*Value {
    return switch (unary_primitive) {
        inline .neg,
        => |t| @call(.auto, @field(Vm, @tagName(t)), .{ vm, x }),
        inline else => |t| std.debug.panic("NYI: {t}", .{t}),
    };
}

fn neg(vm: *Vm, x: *Value) !*Value {
    return .float(vm.gpa, -x.as.float);
}

fn applyOperator(vm: *Vm, operator: Operator, x: *Value, y: *Value) !*Value {
    return switch (operator) {
        inline .add,
        .subtract,
        .multiply,
        .divide,
        .match,
        => |t| @call(.auto, @field(Vm, @tagName(t)), .{ vm, x, y }),
        inline else => |t| std.debug.panic("NYI: {t}", .{t}),
    };
}

fn add(vm: *Vm, x: *Value, y: *Value) !*Value {
    return .float(vm.gpa, x.as.float + y.as.float);
}

fn subtract(vm: *Vm, x: *Value, y: *Value) !*Value {
    return .float(vm.gpa, x.as.float - y.as.float);
}

fn multiply(vm: *Vm, x: *Value, y: *Value) !*Value {
    return .float(vm.gpa, x.as.float * y.as.float);
}

fn divide(vm: *Vm, x: *Value, y: *Value) !*Value {
    return .float(vm.gpa, x.as.float / y.as.float);
}

fn match(vm: *Vm, x: *Value, y: *Value) !*Value {
    return .boolean(vm.gpa, x.match(y));
}

test {
    std.testing.refAllDecls(@This());
}
