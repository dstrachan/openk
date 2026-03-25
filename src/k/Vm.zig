const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

const k = @import("../root.zig");
const Chunk = k.Chunk;
const OpCode = k.OpCode;
const Value = k.Value;
const trace_execution = k.trace_execution;

const Vm = @This();

gpa: Allocator,
chunk: *Chunk,
ip: [*]u8,
stack: std.ArrayList(*Value),
stdout: *Io.Writer,
stderr: *Io.Writer,

pub const Error = error{ CompileError, RuntimeError };

pub const stack_max = 256;
var stack_buf: [stack_max]*Value = undefined;

pub fn init(vm: *Vm, gpa: Allocator, stdout: *Io.Writer, stderr: *Io.Writer) !void {
    vm.* = .{
        .gpa = gpa,
        .chunk = undefined,
        .ip = undefined,
        .stack = .initBuffer(&stack_buf),
        .stdout = stdout,
        .stderr = stderr,
    };
}

pub fn deinit(vm: *Vm) void {
    assert(vm.stack.items.len == 0);
}

fn push(vm: *Vm, value: *Value) void {
    vm.stack.appendAssumeCapacity(value);
}

fn pop(vm: *Vm) *Value {
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
                try vm.stdout.print("[ {f} ]", .{slot});
            }
            try vm.stdout.writeByte('\n');
            _ = try vm.chunk.disassembleInstruction(vm.stdout, vm.ip - vm.chunk.data.items(.code).ptr);
            try vm.stdout.flush();
        }

        const instruction: OpCode = @enumFromInt(vm.readByte());
        switch (instruction) {
            .constant => {
                const constant = vm.readConstant();
                vm.push(constant.ref());
            },

            .add => try vm.binary(add),
            .subtract => try vm.binary(subtract),
            .multiply => try vm.binary(multiply),
            .divide => try vm.binary(divide),
            .negate => try vm.unary(negate),

            .@"return" => {
                const value = vm.pop();
                defer value.deref(vm.gpa);
                try vm.stdout.print("{f}\n", .{value});
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

inline fn readConstant(vm: *Vm) *Value {
    return vm.chunk.constants.items[vm.readByte()];
}

inline fn unary(vm: *Vm, f: *const fn (*Vm, *Value) anyerror!*Value) !void {
    const x = vm.pop();
    defer x.deref(vm.gpa);
    vm.push(try f(vm, x));
}

inline fn binary(vm: *Vm, f: *const fn (*Vm, *Value, *Value) anyerror!*Value) !void {
    const y = vm.pop();
    defer y.deref(vm.gpa);
    const x = vm.pop();
    defer x.deref(vm.gpa);
    vm.push(try f(vm, x, y));
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

fn negate(vm: *Vm, x: *Value) !*Value {
    return .float(vm.gpa, -x.as.float);
}

test {
    std.testing.refAllDecls(@This());
}
