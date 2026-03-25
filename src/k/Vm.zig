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
string_bytes: std.ArrayList(u8) = .empty,
string_table: std.HashMapUnmanaged(
    u32,
    void,
    std.hash_map.StringIndexContext,
    std.hash_map.default_max_load_percentage,
) = .empty,

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
    vm.string_bytes.deinit(vm.gpa);
    vm.string_table.deinit(vm.gpa);
}

fn push(vm: *Vm, value: *Value) void {
    vm.stack.appendAssumeCapacity(value);
}

fn pop(vm: *Vm) *Value {
    return vm.stack.pop().?;
}

pub fn createSymbol(vm: *Vm, bytes: []const u8) !*Value {
    const value = try vm.intern(bytes);
    const self = try vm.gpa.create(Value);
    errdefer comptime unreachable;
    self.* = .{ .as = .{ .symbol = value } };
    return self;
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
