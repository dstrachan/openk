const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;
const Writer = std.Io.Writer;

const k = @import("../root.zig");
const Chunk = k.Chunk;
const OpCode = k.OpCode;
const Value = k.Value;
const trace_execution = k.trace_execution;

const Vm = @This();

gpa: Allocator,
chunk: *Chunk,
ip: [*]u8,
stack: std.ArrayList(Value),
stdout: *Io.Writer,
stderr: *Io.Writer,

pub const Error = error{ CompileError, RuntimeError };

pub const stack_max = 256;

pub fn init(vm: *Vm, gpa: Allocator, stdout: *Io.Writer, stderr: *Io.Writer) !void {
    const stack_buf = try gpa.alloc(Value, stack_max);
    errdefer gpa.free(stack_buf);
    vm.* = .{
        .gpa = gpa,
        .chunk = undefined,
        .ip = undefined,
        .stack = .initBuffer(stack_buf),
        .stdout = stdout,
        .stderr = stderr,
    };
}

pub fn deinit(vm: *Vm) void {
    vm.stack.deinit(vm.gpa);
}

fn push(vm: *Vm, value: Value) void {
    vm.stack.appendAssumeCapacity(value);
}

fn pop(vm: *Vm) Value {
    return vm.stack.pop().?;
}

pub fn interpret(vm: *Vm, chunk: *Chunk) Error!void {
    vm.chunk = chunk;
    vm.ip = vm.chunk.data.items(.code).ptr;

    vm.run() catch return error.RuntimeError;
}

fn run(vm: *Vm) !void {
    while (true) {
        if (trace_execution) {
            try vm.stdout.writeAll("          ");
            for (vm.stack.items) |slot| {
                try vm.stdout.print("[ {d} ]", .{slot});
            }
            try vm.stdout.writeByte('\n');
            _ = try vm.chunk.disassembleInstruction(vm.stdout, vm.ip - vm.chunk.data.items(.code).ptr);
            try vm.stdout.flush();
        }

        const instruction: OpCode = @enumFromInt(vm.readByte());
        switch (instruction) {
            .constant => {
                const constant = vm.readConstant();
                vm.push(constant);
            },

            .add => vm.binary(add),
            .subtract => vm.binary(subtract),
            .multiply => vm.binary(multiply),
            .divide => vm.binary(divide),
            .negate => vm.unary(negate),

            .@"return" => {
                try vm.stdout.print("{d}\n", .{vm.pop()});
                try vm.stdout.flush();
                return;
            },
        }
    }
}

inline fn readByte(vm: *Vm) u8 {
    const byte = vm.ip[0];
    vm.ip += 1;
    return byte;
}

inline fn readConstant(vm: *Vm) Value {
    return vm.chunk.constants.items[vm.readByte()];
}

inline fn unary(vm: *Vm, f: *const fn (*Vm, Value) Value) void {
    const x = vm.pop();
    vm.push(f(vm, x));
}

inline fn binary(vm: *Vm, f: *const fn (*Vm, Value, Value) Value) void {
    const y = vm.pop();
    const x = vm.pop();
    vm.push(f(vm, x, y));
}

fn add(_: *Vm, x: Value, y: Value) Value {
    return x + y;
}

fn subtract(_: *Vm, x: Value, y: Value) Value {
    return x - y;
}

fn multiply(_: *Vm, x: Value, y: Value) Value {
    return x * y;
}

fn divide(_: *Vm, x: Value, y: Value) Value {
    return x / y;
}

fn negate(_: *Vm, x: Value) Value {
    return -x;
}

test {
    std.testing.refAllDecls(@This());
}
