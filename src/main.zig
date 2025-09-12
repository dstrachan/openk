const std = @import("std");
const builtin = @import("builtin");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

const k = @import("k");
const build_options = k.build_options;
const Ast = k.Ast;

const utils = @import("utils.zig");

pub const std_options: std.Options = .{
    .log_level = switch (builtin.mode) {
        .Debug => .debug,
        .ReleaseSafe, .ReleaseFast => .info,
        .ReleaseSmall => .err,
    },
};

var wasi_preopens: std.fs.wasi.Preopens = undefined;

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

var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

pub fn main() !void {
    const gpa, const is_debug = gpa: {
        if (builtin.os.tag == .wasi) break :gpa .{ std.heap.wasm_allocator, false };
        break :gpa switch (builtin.mode) {
            .Debug, .ReleaseSafe => .{ debug_allocator.allocator(), true },
            .ReleaseFast, .ReleaseSmall => .{ std.heap.smp_allocator, false },
        };
    };
    defer if (is_debug) {
        _ = debug_allocator.deinit();
    };
    var arena_instance: std.heap.ArenaAllocator = .init(gpa);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();

    const args = try std.process.argsAlloc(arena);

    if (builtin.os.tag == .wasi) {
        wasi_preopens = try std.fs.wasi.preopensAlloc(arena);
    }

    return mainArgs(gpa, arena, args);
}

fn mainArgs(gpa: Allocator, arena: Allocator, args: []const []const u8) !void {
    _ = arena; // autofix
    if (args.len < 2) return cmdRepl(gpa, &.{});

    const cmd = args[1];
    const cmd_args = args[2..];
    _ = cmd_args; // autofix
    if (std.mem.eql(u8, cmd, "help") or std.mem.eql(u8, cmd, "-h") or std.mem.eql(u8, cmd, "--help")) {
        try std.fs.File.stdout().writeAll(usage);
    } else return cmdRepl(gpa, args[1..]);
}

const usage_repl =
    \\Usage: openq [options]
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
    build_options.version,
    builtin.mode,
    builtin.cpu.arch,
    builtin.os.tag,
});

fn cmdRepl(gpa: Allocator, args: []const []const u8) !void {
    var color: std.zig.Color = .auto;

    var i: usize = 0;
    while (i < args.len) : (i += 1) {
        const arg = args[i];
        if (std.mem.startsWith(u8, arg, "-")) {
            if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
                try std.fs.File.stdout().writeAll(usage_repl);
                return cleanExit();
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

    var stdin_reader = std.fs.File.stdin().reader(&stdin_buffer);
    const stdin = &stdin_reader.interface;
    var stderr_writer = std.fs.File.stderr().writer(&.{});
    const stderr = &stderr_writer.interface;

    var buffer: std.Io.Writer.Allocating = .init(gpa);
    defer buffer.deinit();

    if (std.posix.isatty(stdin_reader.file.handle)) {
        try stderr.writeAll(banner);

        while (true) {
            try stderr.writeAll("k)");

            buffer.clearRetainingCapacity();
            _ = try stdin.streamDelimiterEnding(&buffer.writer, '\n');
            stdin.toss(1);

            const input = buffer.written();
            const trimmed_len = std.mem.trimEnd(u8, input, &std.ascii.whitespace).len;
            assert(trimmed_len < input.len);
            input[trimmed_len] = 0;
            const trimmed_input = input[0..trimmed_len :0];
            if (std.mem.eql(u8, trimmed_input, "\\\\")) break;

            var tree: Ast = try .parse(gpa, trimmed_input);
            defer tree.deinit(gpa);
            if (tree.errors.len > 0) {
                try utils.printAstErrorsToStderr(gpa, tree, "<stdin>", color);
                continue;
            }

            try stderr.print("======\n", .{});
            try stderr.print("TOKENS\n", .{});
            try stderr.print("======\n", .{});
            for (tree.tokens.items(.tag)) |tag| {
                try stderr.print("{t} ({s})\n", .{ tag, tag.symbol() });
            }

            try stderr.print("=====\n", .{});
            try stderr.print("NODES\n", .{});
            try stderr.print("=====\n", .{});
            for (tree.nodes.items(.tag)) |tag| {
                try stderr.print("{t}\n", .{tag});
            }
        }
    } else {
        _ = try stdin.streamRemaining(&buffer.writer);

        try buffer.writer.writeByte(0);
        const input = buffer.written();
        const trimmed_input = input[0 .. input.len - 1 :0];

        var tree: Ast = try .parse(gpa, trimmed_input);
        defer tree.deinit(gpa);
        if (tree.errors.len > 0) {
            try utils.printAstErrorsToStderr(gpa, tree, "<stdin>", color);
            std.process.exit(1);
        }

        try stderr.print("======\n", .{});
        try stderr.print("TOKENS\n", .{});
        try stderr.print("======\n", .{});
        for (tree.tokens.items(.tag)) |tag| {
            try stderr.print("{t} ({s})\n", .{ tag, tag.symbol() });
        }

        try stderr.print("=====\n", .{});
        try stderr.print("NODES\n", .{});
        try stderr.print("=====\n", .{});
        for (tree.nodes.items(.tag)) |tag| {
            try stderr.print("{t}\n", .{tag});
        }
    }

    return cleanExit();
}

test {
    std.testing.refAllDecls(@This());
}
