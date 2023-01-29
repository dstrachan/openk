const std = @import("std");

const vm_mod = @import("vm.zig");
const VM = vm_mod.VM;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const vm = VM.init(allocator);
    defer vm.deinit();

    switch (args.len) {
        1 => try repl(vm),
        2 => runFile(vm, args[1], allocator),
        else => {
            try std.io.getStdErr().writer().print("Usage: {s} [path]\n", .{args[0]});
            std.process.exit(1);
        },
    }
}

fn repl(vm: *VM) !void {
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    var bufferedReader = std.io.bufferedReader(stdin);
    const reader = bufferedReader.reader();
    var buf: [2048]u8 = undefined;
    while (true) {
        stdout.writeAll("> ") catch std.process.exit(1);
        const line = reader.readUntilDelimiterOrEof(&buf, '\n') catch std.process.exit(1) orelse {
            stdout.writeAll("\n") catch std.process.exit(1);
            break;
        };

        if (std.mem.eql(u8, line[0 .. line.len - 1], "\\\\")) {
            break;
        }

        var i = line.len;
        while (i > 0) {
            switch (line[i - 1]) {
                ' ', '\t', '\r', '\n' => i -= 1,
                else => break,
            }
        }

        const result = vm.interpret(line[0..i]) catch continue;
        defer result.deref(vm.allocator);
        try stdout.print("{}\n", .{result.as});
    }
}

fn runFile(vm: *VM, file: []const u8, allocator: std.mem.Allocator) void {
    const source = readFile(file, allocator);
    defer allocator.free(source);

    var i = source.len;
    while (i > 0) {
        switch (source[i - 1]) {
            ' ', '\t', '\r', '\n' => i -= 1,
            else => break,
        }
    }

    _ = vm.interpret(source[0..i]) catch std.process.exit(1);
}

fn readFile(path: []const u8, allocator: std.mem.Allocator) []const u8 {
    const stderr = std.io.getStdErr().writer();
    const file = std.fs.cwd().openFile(path, .{ .mode = .read_only }) catch |err| {
        stderr.print("Could not open file \"{s}\", error: {any}.\n", .{ path, err }) catch {};
        std.process.exit(1);
    };
    defer file.close();

    file.seekFromEnd(0) catch |err| {
        stderr.print("Could not seek file \"{s}\", error: {any}.\n", .{ path, err }) catch {};
        std.process.exit(1);
    };
    const fileSize = file.getPos() catch |err| {
        stderr.print("Could not seek file \"{s}\", error: {any}.\n", .{ path, err }) catch {};
        std.process.exit(1);
    };
    file.seekTo(0) catch |err| {
        stderr.print("Could not seek file \"{s}\", error: {any}.\n", .{ path, err }) catch {};
        std.process.exit(1);
    };

    return file.readToEndAlloc(allocator, fileSize) catch |err| {
        stderr.print("Could not read file \"{s}\", error: {any}.\n", .{ path, err }) catch {};
        std.process.exit(1);
    };
}

test {
    _ = @import("tests/compiler.zig");
    _ = @import("tests/scanner.zig");
    _ = @import("tests/vm.zig");

    // _ = @import("tests/verbs/concat/_imports.zig");
    // _ = @import("tests/verbs/divide/_imports.zig");
    // _ = @import("tests/verbs/equal/_imports.zig");
    // _ = @import("tests/verbs/less/_imports.zig");
    // _ = @import("tests/verbs/match/_imports.zig");
    // _ = @import("tests/verbs/max/_imports.zig");
    // _ = @import("tests/verbs/min/_imports.zig");
    // _ = @import("tests/verbs/more/_imports.zig");

    _ = @import("tests/verbs/add.zig");
    _ = @import("tests/verbs/enum.zig");
    _ = @import("tests/verbs/fill.zig");
    _ = @import("tests/verbs/first.zig");
    _ = @import("tests/verbs/flip.zig");
    _ = @import("tests/verbs/negate.zig");
    _ = @import("tests/verbs/sqrt.zig");
    _ = @import("tests/verbs/subtract.zig");
}
