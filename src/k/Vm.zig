const std = @import("std");
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
stdout: *Writer,
stderr: *Writer,

pub const Error = error{ CompileError, RuntimeError };

pub const stack_max = 256;

pub fn init(vm: *Vm, gpa: Allocator, stdout: *Writer, stderr: *Writer) !void {
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

            .add => {
                const b = vm.pop();
                const a = vm.pop();
                vm.push(a + b);
            },
            .subtract => {
                const b = vm.pop();
                const a = vm.pop();
                vm.push(a - b);
            },
            .multiply => {
                const b = vm.pop();
                const a = vm.pop();
                vm.push(a * b);
            },
            .divide => {
                const b = vm.pop();
                const a = vm.pop();
                vm.push(a / b);
            },
            .negate => vm.push(-vm.pop()),

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
