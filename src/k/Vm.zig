const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const ErrorBundle = std.zig.ErrorBundle;

const k = @import("../root.zig");
const Chunk = k.Chunk;
const OpCode = k.OpCode;
const Value = k.Value;
const Ast = k.Ast;
const Compiler = k.Compiler;
const Lambda = k.Lambda;
const UnaryPrimitive = k.UnaryPrimitive;
const Operator = k.Operator;

const Vm = @This();

io: Io,
gpa: Allocator,
trace_execution: bool = k.trace_execution,
print_code: bool = k.print_code,
frames: std.ArrayList(CallFrame),
stack: std.ArrayList(*Value),
stack_lens: std.ArrayList(usize),
stdout: *Io.Writer,
color: std.zig.Color,
constants: [6]*Value = undefined,
unary_primitives: [std.meta.fields(UnaryPrimitive).len]*Value = undefined,
operators: [std.meta.fields(Operator).len]*Value = undefined,
string_bytes: std.ArrayList(u8) = .empty,
string_table: std.HashMapUnmanaged(
    u32,
    void,
    std.hash_map.StringIndexContext,
    std.hash_map.default_max_load_percentage,
) = .empty,
globals: std.AutoHashMapUnmanaged(NullTerminatedString, *Value) = .empty,

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
    var stack_lens: std.ArrayList(usize) = try .initCapacity(gpa, stack_max);
    errdefer stack_lens.deinit(gpa);

    vm.* = .{
        .io = io,
        .gpa = gpa,
        .frames = frames,
        .stack = stack,
        .stack_lens = stack_lens,
        .stdout = stdout,
        .color = color,
    };

    var constants: usize = 0;
    errdefer for (0..constants) |i| vm.constants[i].deref(gpa);
    vm.constants[0] = try .list(gpa, 0);
    constants += 1;
    vm.constants[1] = try .float(gpa, 0);
    constants += 1;
    vm.constants[2] = try .float(gpa, 1);
    constants += 1;
    vm.constants[3] = try .operator(gpa, .join);
    constants += 1;
    vm.constants[4] = try .symbol(gpa, .empty);
    constants += 1;
    vm.constants[5] = try .unaryPrimitive(gpa, .identity);
    constants += 1;

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

    assert(.empty == try vm.intern(""));
    assert(.x == try vm.intern("x"));
    assert(.y == try vm.intern("y"));
    assert(.z == try vm.intern("z"));
}

pub fn deinit(vm: *Vm) void {
    assert(vm.frames.items.len == 0);
    assert(vm.stack.items.len == 0);

    var it = vm.globals.valueIterator();
    while (it.next()) |value| value.*.deref(vm.gpa);
    vm.globals.deinit(vm.gpa);
    vm.string_table.deinit(vm.gpa);
    vm.string_bytes.deinit(vm.gpa);
    for (vm.constants) |v| v.deref(vm.gpa);
    for (vm.operators) |v| v.deref(vm.gpa);
    for (vm.unary_primitives) |v| v.deref(vm.gpa);
    vm.stack_lens.deinit(vm.gpa);
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
        try stderr.writeAll(vm.nullTerminatedString(frame.lambda.source));
        try stderr.writeByte('\n');
    }

    try stderr.flush();
    while (vm.stack.items.len > 1) vm.pop().deref(vm.gpa);
    vm.stack.shrinkRetainingCapacity(0);
    vm.frames.shrinkRetainingCapacity(0);
    return error.RuntimeError;
}

pub const NullTerminatedString = enum(u32) {
    empty = 0,
    x = 1,
    y = 3,
    z = 5,
    _,
};

/// Given an index into `string_bytes` returns the null-terminated string found there.
pub fn nullTerminatedString(vm: *Vm, index: NullTerminatedString) [:0]const u8 {
    const slice = vm.string_bytes.items[@intFromEnum(index)..];
    return slice[0..std.mem.findScalar(u8, slice, 0).? :0];
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

pub fn intern(vm: *Vm, bytes: []const u8) !NullTerminatedString {
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
        return @enumFromInt(gop.key_ptr.*);
    } else {
        gop.key_ptr.* = str_index;
        try vm.string_bytes.append(vm.gpa, 0);
        return @enumFromInt(str_index);
    }
}

pub fn interpret(vm: *Vm, tree: Ast, src_path: []const u8) Error!*Value {
    var wip: ErrorBundle.Wip = undefined;
    try wip.init(vm.gpa);
    defer wip.deinit();

    var compiler: Compiler = undefined;
    try compiler.init(vm, tree, &wip, src_path);

    const lambda: *Value = lambda: {
        errdefer compiler.lambda.deref(vm.gpa);
        break :lambda compiler.compile() catch |err| switch (err) {
            error.OutOfMemory => return error.OutOfMemory,
            else => {
                assert(compiler.hasErrors());
                break :lambda compiler.lambda;
            },
        };
    };
    defer lambda.deref(vm.gpa);

    if (compiler.hasErrors()) {
        var eb = try wip.toOwnedBundle("");
        defer eb.deinit(vm.gpa);
        eb.renderToStderr(vm.io, .{}, vm.color) catch return error.CompilerError;
        return error.CompilerError;
    }

    try vm.applyValue(lambda, 0);
    return vm.run() catch return error.RuntimeError;
}

fn run(vm: *Vm) Error!*Value {
    const initial_frame_count = vm.frames.items.len;
    var frame = &vm.frames.items[vm.frames.items.len - 1];
    while (true) {
        if (vm.trace_execution) {
            try vm.stdout.writeAll("          ");
            for (vm.stack.items) |slot| {
                try vm.stdout.print("[ {f} ]", .{slot.alt(vm)});
            }
            try vm.stdout.writeByte('\n');
            _ = try frame.lambda.chunk.disassembleInstruction(vm, vm.stdout, frame.ip - frame.lambda.chunk.data.items(.code).ptr);
            try vm.stdout.flush();
        }

        const instruction: OpCode = @enumFromInt(vm.readByte());
        switch (instruction) {
            .@"return" => {
                const result = vm.pop();
                while (vm.stack.items.len > frame.slots - vm.stack.items.ptr) {
                    vm.pop().deref(vm.gpa);
                }
                vm.frames.shrinkRetainingCapacity(vm.frames.items.len - 1);

                if (vm.frames.items.len < initial_frame_count) return result;

                vm.push(result);
                frame = &vm.frames.items[vm.frames.items.len - 1];
            },
            .print => {
                try vm.stdout.print("{f}\n", .{vm.peek().alt(vm)});
                try vm.stdout.flush();
            },
            .pop => vm.pop().deref(vm.gpa),
            .assign => {
                const value = &frame.slots[vm.readByte()];
                value.*.deref(vm.gpa);
                value.* = vm.peek().ref();
            },
            .amend => {
                const name = vm.readGlobal();
                const operator: Operator = @enumFromInt(vm.readByte());
                switch (operator) {
                    .assign => {
                        const depth = vm.pop();
                        defer depth.deref(vm.gpa);
                        if (depth.as == .list and depth.as.list.len == 0) {
                            const gop = try vm.globals.getOrPut(vm.gpa, name);
                            if (gop.found_existing) {
                                gop.value_ptr.*.deref(vm.gpa);
                            }
                            gop.value_ptr.* = vm.peek().ref();
                        } else {
                            unreachable;
                        }
                    },
                    inline else => |t| @panic("NYI: " ++ @tagName(t)),
                }
            },
            .call => {
                const arg_count = vm.readByte();

                const x = vm.pop();
                defer x.deref(vm.gpa);

                try vm.applyValue(x, arg_count);
                if (x.as == .lambda) frame = &vm.frames.items[vm.frames.items.len - 1];
            },

            .empty_list => vm.push(vm.constants[0].ref()),
            .zero => vm.push(vm.constants[1].ref()),
            .one => vm.push(vm.constants[2].ref()),
            .comma => vm.push(vm.constants[3].ref()),
            .null_symbol => vm.push(vm.constants[4].ref()),
            .nil => vm.push(vm.constants[5].ref()),
            .empty => unreachable,

            .identity => {},

            inline .add,
            .subtract,
            .multiply,
            .divide,
            .@"and",
            .@"or",
            .fill,
            .equals,
            .less_than,
            .greater_than,
            .cast,
            .join,
            .take,
            .drop,
            .match,
            .dict,
            .find,
            .apply_at,
            .apply,
            .file_text,
            .file_binary,
            .dynamic_load,
            .in,
            .within,
            .like,
            .bin,
            .ss,
            .insert,
            .wsum,
            .wavg,
            .div,
            => |t| {
                const x = vm.pop();
                defer x.deref(vm.gpa);

                switch (t) {
                    .apply_at => {
                        try vm.applyValue(x, 1);
                        if (x.as == .lambda) frame = &vm.frames.items[vm.frames.items.len - 1];
                    },
                    else => {
                        const y = vm.pop();
                        defer y.deref(vm.gpa);
                        vm.push(try @call(.auto, @field(Vm, @tagName(t)), .{ vm, x, y }));
                    },
                }
            },

            .local => vm.push(frame.slots[vm.readByte()].ref()),

            .global => {
                const name = vm.readGlobal();
                if (vm.globals.get(name)) |global| {
                    vm.push(global.ref());
                } else return vm.runtimeError("Undefined variable '{s}'.", .{vm.nullTerminatedString(name)});
            },

            .constant => vm.push(vm.readConstant().ref()),
        }
    }
}

inline fn readByte(vm: *Vm) u8 {
    const frame = &vm.frames.items[vm.frames.items.len - 1];
    defer frame.ip += 1;
    return frame.ip[0];
}

inline fn readGlobal(vm: *Vm) NullTerminatedString {
    const frame = &vm.frames.items[vm.frames.items.len - 1];
    return frame.lambda.chunk.globals.items[vm.readByte()];
}

inline fn readConstant(vm: *Vm) *Value {
    const frame = &vm.frames.items[vm.frames.items.len - 1];
    return frame.lambda.chunk.constants.items[vm.readByte()];
}

fn applyValue(vm: *Vm, x: *Value, arg_count: usize) !void {
    switch (x.as) {
        .lambda => |lambda| {
            if (lambda.arity != arg_count) {
                return vm.runtimeError("expected {d} argument(s), found: {d}", .{ lambda.arity, arg_count });
            }

            if (vm.frames.items.len == frames_max) {
                return vm.runtimeError("stack overflow", .{});
            }

            const args = args: {
                var args: [8]*Value = undefined;
                for (0..arg_count) |i| args[i] = vm.pop();
                break :args args[0..arg_count];
            };
            errdefer comptime unreachable;

            const stack_len = vm.stack.items.len;

            vm.push(x.ref());
            for (args) |v| vm.push(v);
            for (lambda.chunk.locals.items) |_| {
                vm.push(vm.constants[0].ref());
            }

            vm.frames.appendAssumeCapacity(.{
                .lambda = lambda,
                .ip = lambda.chunk.data.items(.code).ptr,
                .slots = vm.stack.items[stack_len..].ptr,
            });
        },
        inline else => |_, t| @panic("NYI: " ++ @tagName(t)),
    }
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

fn @"and"(vm: *Vm, x: *Value, y: *Value) !*Value {
    _ = vm; // autofix
    _ = x; // autofix
    _ = y; // autofix
    @panic("NYI");
}

fn @"or"(vm: *Vm, x: *Value, y: *Value) !*Value {
    _ = vm; // autofix
    _ = x; // autofix
    _ = y; // autofix
    @panic("NYI");
}

fn fill(vm: *Vm, x: *Value, y: *Value) !*Value {
    _ = vm; // autofix
    _ = x; // autofix
    _ = y; // autofix
    @panic("NYI");
}

fn equals(vm: *Vm, x: *Value, y: *Value) !*Value {
    _ = vm; // autofix
    _ = x; // autofix
    _ = y; // autofix
    @panic("NYI");
}

fn less_than(vm: *Vm, x: *Value, y: *Value) !*Value {
    _ = vm; // autofix
    _ = x; // autofix
    _ = y; // autofix
    @panic("NYI");
}

fn greater_than(vm: *Vm, x: *Value, y: *Value) !*Value {
    _ = vm; // autofix
    _ = x; // autofix
    _ = y; // autofix
    @panic("NYI");
}

fn cast(vm: *Vm, x: *Value, y: *Value) !*Value {
    _ = vm; // autofix
    _ = x; // autofix
    _ = y; // autofix
    @panic("NYI");
}

fn join(vm: *Vm, x: *Value, y: *Value) !*Value {
    _ = vm; // autofix
    _ = x; // autofix
    _ = y; // autofix
    @panic("NYI");
}

fn take(vm: *Vm, x: *Value, y: *Value) !*Value {
    _ = vm; // autofix
    _ = x; // autofix
    _ = y; // autofix
    @panic("NYI");
}

fn drop(vm: *Vm, x: *Value, y: *Value) !*Value {
    _ = vm; // autofix
    _ = x; // autofix
    _ = y; // autofix
    @panic("NYI");
}

fn match(vm: *Vm, x: *Value, y: *Value) !*Value {
    return .boolean(vm.gpa, x.match(y));
}

fn dict(vm: *Vm, x: *Value, y: *Value) !*Value {
    _ = vm; // autofix
    _ = x; // autofix
    _ = y; // autofix
    @panic("NYI");
}

fn find(vm: *Vm, x: *Value, y: *Value) !*Value {
    _ = vm; // autofix
    _ = x; // autofix
    _ = y; // autofix
    @panic("NYI");
}

fn apply(vm: *Vm, x: *Value, y: *Value) !*Value {
    _ = vm; // autofix
    _ = x; // autofix
    _ = y; // autofix
    @panic("NYI");
}

fn file_text(vm: *Vm, x: *Value, y: *Value) !*Value {
    _ = vm; // autofix
    _ = x; // autofix
    _ = y; // autofix
    @panic("NYI");
}

fn file_binary(vm: *Vm, x: *Value, y: *Value) !*Value {
    _ = vm; // autofix
    _ = x; // autofix
    _ = y; // autofix
    @panic("NYI");
}

fn dynamic_load(vm: *Vm, x: *Value, y: *Value) !*Value {
    _ = vm; // autofix
    _ = x; // autofix
    _ = y; // autofix
    @panic("NYI");
}

fn in(vm: *Vm, x: *Value, y: *Value) !*Value {
    _ = vm; // autofix
    _ = x; // autofix
    _ = y; // autofix
    @panic("NYI");
}

fn within(vm: *Vm, x: *Value, y: *Value) !*Value {
    _ = vm; // autofix
    _ = x; // autofix
    _ = y; // autofix
    @panic("NYI");
}

fn like(vm: *Vm, x: *Value, y: *Value) !*Value {
    _ = vm; // autofix
    _ = x; // autofix
    _ = y; // autofix
    @panic("NYI");
}

fn bin(vm: *Vm, x: *Value, y: *Value) !*Value {
    _ = vm; // autofix
    _ = x; // autofix
    _ = y; // autofix
    @panic("NYI");
}

fn ss(vm: *Vm, x: *Value, y: *Value) !*Value {
    _ = vm; // autofix
    _ = x; // autofix
    _ = y; // autofix
    @panic("NYI");
}

fn insert(vm: *Vm, x: *Value, y: *Value) !*Value {
    _ = vm; // autofix
    _ = x; // autofix
    _ = y; // autofix
    @panic("NYI");
}

fn wsum(vm: *Vm, x: *Value, y: *Value) !*Value {
    _ = vm; // autofix
    _ = x; // autofix
    _ = y; // autofix
    @panic("NYI");
}

fn wavg(vm: *Vm, x: *Value, y: *Value) !*Value {
    _ = vm; // autofix
    _ = x; // autofix
    _ = y; // autofix
    @panic("NYI");
}

fn div(vm: *Vm, x: *Value, y: *Value) !*Value {
    _ = vm; // autofix
    _ = x; // autofix
    _ = y; // autofix
    @panic("NYI");
}

fn testVm(source: [:0]const u8, expected: []const u8) !void {
    const gpa = std.testing.allocator;

    var stdout_writer: std.Io.Writer.Allocating = .init(gpa);
    defer stdout_writer.deinit();
    const stdout = &stdout_writer.writer;

    var vm: Vm = undefined;
    try vm.init(std.testing.io, gpa, stdout, .on);
    defer vm.deinit();
    vm.trace_execution = false;
    vm.print_code = false;

    var tree: Ast = try .parse(gpa, source);
    defer tree.deinit(gpa);

    const result = try vm.interpret(tree, "<test>");
    defer result.deref(gpa);

    try std.testing.expectEqualStrings(
        std.mem.trim(u8, expected, &std.ascii.whitespace),
        std.mem.trim(u8, stdout_writer.written(), &std.ascii.whitespace),
    );
}

test {
    try testVm("{[]x:1}", "{[]x:1}");
    if (true) return error.SkipZigTest;
    try testVm("{[]x}[]", "");
}
