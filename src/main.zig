const std = @import("std");

const utils_mod = @import("utils.zig");
const print = utils_mod.print;

const vm_mod = @import("vm.zig");
const VM = vm_mod.VM;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var vm = VM.init(allocator);
    defer vm.deinit();

    switch (args.len) {
        1 => repl(&vm),
        2 => runFile(&vm, args[1], allocator),
        else => {
            print("Usage: z [path]\n", .{});
            std.process.exit(1);
        },
    }
}

fn repl(vm: *VM) void {
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

        const result = vm.interpret(line) catch continue;
        defer result.deinit(vm.allocator);
        print("{}\n", .{result});
    }
}

fn runFile(vm: *VM, file: []const u8, allocator: std.mem.Allocator) void {
    const source = readFile(file, allocator);
    defer allocator.free(source);
    _ = vm.interpret(source) catch std.process.exit(1);
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
}
