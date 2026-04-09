const std = @import("std");
const builtin = @import("builtin");
const Io = std.Io;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

const k = @import("k");
const version = k.version;
const Ast = k.Ast;
const Chunk = k.Chunk;
const OpCode = k.OpCode;
const Vm = k.Vm;
const Compiler = k.Compiler;

const utils = @import("utils.zig");

pub const std_options: std.Options = .{
    .log_level = .debug,
};
pub const std_options_cwd = if (builtin.os.tag == .wasi) wasi_cwd else null;

var preopens: std.process.Preopens = .empty;
pub fn wasi_cwd() Io.Dir {
    // Expect the first preopen to be current working directory.
    const cwd_fd: std.posix.fd_t = 3;
    if (!builtin.is_test) assert(std.mem.eql(u8, preopens.map.keys()[cwd_fd], "."));
    return .{ .handle = cwd_fd };
}

const fatal = std.process.fatal;
const cleanExit = std.process.cleanExit;

var stdin_buffer: [4096]u8 align(std.heap.page_size_min) = undefined;
var stdout_buffer: [4096]u8 align(std.heap.page_size_min) = undefined;

const usage =
    \\Usage: openk
    \\
    \\Commands:
    \\
    \\Options:
    \\
    \\  -h, --help Print command-specific usage
    \\
;

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const gpa = init.gpa;
    const arena = init.arena.allocator();

    const args = try init.minimal.args.toSlice(arena);

    const environ_map = init.environ_map;

    if (builtin.os.tag == .wasi) {
        preopens = try .init(arena);
    }

    return mainArgs(io, gpa, arena, args, environ_map);
}

fn mainArgs(
    io: Io,
    gpa: Allocator,
    arena: Allocator,
    args: []const []const u8,
    environ_map: *std.process.Environ.Map,
) !void {
    _ = arena; // autofix
    _ = environ_map; // autofix
    if (args.len < 2) return cmdRepl(io, gpa, &.{});

    const cmd = args[1];
    const cmd_args = args[2..];
    if (std.mem.eql(u8, cmd, "help") or std.mem.eql(u8, cmd, "-h") or std.mem.eql(u8, cmd, "--help")) {
        try Io.File.stdout().writeStreamingAll(io, usage);
    } else return cmdFile(io, gpa, cmd, cmd_args);
}

const usage_repl =
    \\Usage: openk [options]
    \\
    \\  Start an interactive REPL.
    \\
    \\Options:
    \\
    \\  -h, --help            Print this help and exit
    \\  --color [auto|off|on] Enable or disable colored error messages
    \\
;

const banner = std.fmt.comptimePrint("OpenK {s} {t} {t}-{t}\n\n", .{
    version,
    builtin.mode,
    builtin.cpu.arch,
    builtin.os.tag,
});

fn cmdRepl(io: Io, gpa: Allocator, args: []const []const u8) !void {
    var color: std.zig.Color = .auto;

    var i: usize = 0;
    while (i < args.len) : (i += 1) {
        const arg = args[i];
        if (std.mem.startsWith(u8, arg, "-")) {
            if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
                try Io.File.stdout().writeStreamingAll(io, usage_repl);
                return cleanExit(io);
            } else if (std.mem.eql(u8, arg, "--color")) {
                if (i + 1 >= args.len) {
                    fatal("expected [auto|off|on] after --color", .{});
                }
                i += 1;
                const next_arg = args[i];
                color = std.meta.stringToEnum(std.zig.Color, next_arg) orelse {
                    fatal("expected [auto|off|on] after --color, found '{s}'", .{next_arg});
                };
            } else {
                fatal("unrecognized parameter: '{s}'", .{arg});
            }
        } else {
            fatal("extra positional parameter: '{s}'", .{arg});
        }
    }

    var stdin_reader = Io.File.stdin().reader(io, &stdin_buffer);
    const stdin = &stdin_reader.interface;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;
    var stderr_buffer: [1024]u8 = undefined;
    var stderr_writer = Io.File.stderr().writer(io, &stderr_buffer);
    const stderr = &stderr_writer.interface;

    var vm: Vm = undefined;
    try vm.init(io, gpa, stdout, color);
    defer vm.deinit();

    if (try Io.File.stdin().isTty(io)) {
        try stderr.writeAll(banner);

        while (true) {
            try stderr.writeAll("k)");
            try stderr.flush();

            const line = try stdin.takeDelimiterInclusive('\n');
            const trimmed = std.mem.trimEnd(u8, line, " \t\r\n");
            line[trimmed.len] = 0;
            const slice = line[0..trimmed.len :0];

            if (slice.len == 0) continue;

            if (std.mem.eql(u8, slice, "\\\\")) break;

            var tree: Ast = try .parse(gpa, slice);
            defer tree.deinit(gpa);
            if (tree.errors.len > 0) {
                try utils.printAstErrorsToStderr(io, gpa, tree, "<stdin>", color);
                continue;
            }

            vm.interpret(tree, "<stdin>") catch |err| switch (err) {
                error.CompilerError => {},
                else => return err,
            };
        }
    } else {
        var buffer: Io.Writer.Allocating = .init(gpa);
        defer buffer.deinit();

        _ = try stdin.streamRemaining(&buffer.writer);

        try buffer.writer.writeByte(0);
        const input = buffer.written();
        const slice = input[0 .. input.len - 1 :0];

        var tree: Ast = try .parse(gpa, slice);
        defer tree.deinit(gpa);
        if (tree.errors.len > 0) {
            try utils.printAstErrorsToStderr(io, gpa, tree, "<stdin>", color);
            std.process.exit(1);
        }

        try vm.interpret(tree, "<stdin>");
    }

    return cleanExit(io);
}

const usage_file =
    \\Usage: openk <file> [options]
    \\
    \\  Interpret a k file.
    \\
    \\Options:
    \\
    \\  -h, --help            Print this help and exit
    \\  --color [auto|off|on] Enable or disable colored error messages
    \\
;

fn cmdFile(io: Io, gpa: Allocator, file: []const u8, args: []const []const u8) !void {
    var color: std.zig.Color = .auto;

    var i: usize = 0;
    while (i < args.len) : (i += 1) {
        const arg = args[i];
        if (std.mem.startsWith(u8, arg, "-")) {
            if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
                try Io.File.stdout().writeStreamingAll(io, usage_file);
                return cleanExit(io);
            } else if (std.mem.eql(u8, arg, "--color")) {
                if (i + 1 >= args.len) {
                    fatal("expected [auto|off|on] after --color", .{});
                }
                i += 1;
                const next_arg = args[i];
                color = std.meta.stringToEnum(std.zig.Color, next_arg) orelse {
                    fatal("expected [auto|off|on] after --color, found '{s}'", .{next_arg});
                };
            } else {
                fatal("unrecognized parameter: '{s}'", .{arg});
            }
        } else {
            fatal("extra positional parameter: '{s}'", .{arg});
        }
    }

    var f = try Io.Dir.openFile(.cwd(), io, file, .{});
    defer f.close(io);
    var file_reader = f.reader(io, &.{});
    const source = try std.zig.readSourceFileToEndAlloc(gpa, &file_reader);
    defer gpa.free(source);

    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;
    var stderr_buffer: [1024]u8 = undefined;
    var stderr_writer = Io.File.stderr().writer(io, &stderr_buffer);
    const stderr = &stderr_writer.interface;

    var vm: Vm = undefined;
    try vm.init(io, gpa, stdout, color);
    defer vm.deinit();

    if (try Io.File.stdin().isTty(io)) {
        try stderr.writeAll(banner);
        try stderr.flush();
    }

    var tree: Ast = try .parse(gpa, source);
    defer tree.deinit(gpa);
    if (tree.errors.len > 0) {
        try utils.printAstErrorsToStderr(io, gpa, tree, file, color);
        std.process.exit(1);
    }

    try vm.interpret(tree, file);

    return cleanExit(io);
}

test {
    std.testing.refAllDecls(@This());
}
