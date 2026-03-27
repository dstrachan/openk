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

gpa: Allocator,
frames: std.ArrayList(CallFrame),
stack: std.ArrayList(*Value),
stdout: *Io.Writer,
stderr: *Io.Writer,
string_bytes: std.ArrayList(u8) = .empty,
string_table: std.HashMapUnmanaged(
    u32,
    void,
    std.hash_map.StringIndexContext,
    std.hash_map.default_max_load_percentage,
) = .empty,
globals: std.AutoHashMapUnmanaged([*:0]const u8, *Value) = .empty,

pub const Error = Compiler.Error || error{
    RuntimeError,
};

pub const frames_max = 64;
pub const stack_max = frames_max * (std.math.maxInt(u8) + 1);

const CallFrame = struct {
    lambda: Lambda,
    ip: [*]u8,
    slots: [*]*Value,
};

pub fn init(vm: *Vm, gpa: Allocator, stdout: *Io.Writer, stderr: *Io.Writer) !void {
    var frames: std.ArrayList(CallFrame) = try .initCapacity(gpa, frames_max);
    errdefer frames.deinit(gpa);
    const stack: std.ArrayList(*Value) = try .initCapacity(gpa, stack_max);
    errdefer comptime unreachable;
    vm.* = .{
        .gpa = gpa,
        .frames = frames,
        .stack = stack,
        .stdout = stdout,
        .stderr = stderr,
    };
}

pub fn deinit(vm: *Vm) void {
    assert(vm.frames.items.len == 0);
    assert(vm.stack.items.len == 0);
    vm.string_bytes.deinit(vm.gpa);
    vm.string_table.deinit(vm.gpa);
    var it = vm.globals.valueIterator();
    while (it.next()) |value| value.*.deref(vm.gpa);
    vm.globals.deinit(vm.gpa);
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
    try vm.stderr.print(fmt ++ "\n", args);

    const frame = &vm.frames.items[vm.frames.items.len - 1];
    const instruction = frame.ip - frame.lambda.chunk.data.items(.code).ptr - 1;
    const line = frame.lambda.chunk.data.items(.line)[instruction];
    try vm.stderr.print("[line {d}] in script\n", .{line});
    try vm.stderr.flush();
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

pub fn interpret(vm: *Vm, tree: Ast) Error!void {
    var compiler: Compiler = undefined;
    try compiler.init(vm, tree);
    defer compiler.deinit();

    const lambda = try compiler.compile();
    defer lambda.deref(vm.gpa);

    vm.push(lambda);
    defer _ = vm.pop();
    vm.frames.appendAssumeCapacity(.{
        .lambda = lambda.as.lambda,
        .ip = lambda.as.lambda.chunk.data.items(.code).ptr,
        .slots = vm.stack.items[vm.stack.items.len..].ptr,
    });
    defer vm.frames.shrinkRetainingCapacity(0);

    vm.run() catch return error.RuntimeError;
}

fn run(vm: *Vm) !void {
    const frame = &vm.frames.items[vm.frames.items.len - 1];
    const chunk = frame.lambda.chunk;
    while (true) {
        if (trace_execution) {
            try vm.stdout.writeAll("          ");
            for (vm.stack.items[1..]) |slot| {
                try vm.stdout.print("[ {f} ]", .{slot});
            }
            try vm.stdout.writeByte('\n');
            _ = try chunk.disassembleInstruction(vm.stdout, frame.ip - chunk.data.items(.code).ptr);
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

            .get_local => vm.push(frame.slots[vm.readByte()].ref()),
            .set_local => frame.slots[vm.readByte()] = vm.peek().ref(),

            .@"return" => return,
            .pop => vm.pop().deref(vm.gpa),
            .print => {
                const value = vm.pop();
                defer value.deref(vm.gpa);
                try vm.stdout.print("{f}\n", .{value});
                try vm.stdout.flush();
            },

            .apply => {
                const callee = vm.pop();
                defer callee.deref(vm.gpa);

                const args_len = switch (callee.as) {
                    .lambda => |lambda| lambda.arity,
                    .unary_primitive => 1,
                    .operator => 2,
                    inline else => |_, t| std.debug.panic("{t}", .{t}),
                };
                const args = args: {
                    var args: [8]*Value = undefined;
                    for (0..args_len) |i| args[i] = vm.pop();
                    break :args args[0..args_len];
                };
                defer for (args) |v| v.deref(vm.gpa);

                vm.push(try vm.apply(callee, args));
            },
        }
    }
}

inline fn readByte(vm: *Vm) u8 {
    const frame = &vm.frames.items[vm.frames.items.len - 1];
    const byte = frame.ip[0];
    frame.ip += 1;
    return byte;
}

inline fn readShort(vm: *Vm) u16 {
    const frame = &vm.frames.items[vm.frames.items.len - 1];
    const short: u16 = @intCast((frame.ip[0] << 8) | frame.ip[1]);
    frame.ip += 2;
    return short;
}

inline fn readConstant(vm: *Vm) *Value {
    const frame = &vm.frames.items[vm.frames.items.len - 1];
    return frame.lambda.chunk.constants.items[vm.readByte()];
}

fn apply(vm: *Vm, callee: *Value, args: []*Value) !*Value {
    return switch (callee.as) {
        .unary_primitive => |unary_primitive| vm.applyUnaryPrimitive(unary_primitive, args[0]),
        .operator => |operator| vm.applyOperator(operator, args[0], args[1]),
        inline else => |_, t| std.debug.panic("NYI: {t}", .{t}),
    };
}

fn applyUnaryPrimitive(vm: *Vm, unary_primitive: UnaryPrimitive, x: *Value) !*Value {
    return switch (unary_primitive) {
        inline .neg,
        => |t| @call(.auto, @field(Vm, @tagName(t)), .{ vm, x }),
        inline else => |t| std.debug.panic("NYI: {t}", .{t}),
    };
}

fn applyOperator(vm: *Vm, operator: Operator, x: *Value, y: *Value) !*Value {
    return switch (operator) {
        inline .add,
        .subtract,
        .multiply,
        .divide,
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

fn neg(vm: *Vm, x: *Value) !*Value {
    return .float(vm.gpa, -x.as.float);
}

test {
    std.testing.refAllDecls(@This());
}
