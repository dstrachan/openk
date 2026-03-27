const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

pub const build_options = @import("build_options");
pub const version = build_options.version;
pub const trace_execution = build_options.trace_execution;

pub const tokenizer = @import("k/tokenizer.zig");
pub const Token = tokenizer.Token;
pub const Tokenizer = tokenizer.Tokenizer;
pub const Ast = @import("k/Ast.zig");
pub const Node = Ast.Node;
pub const Parse = @import("k/Parse.zig");
pub const Chunk = @import("k/Chunk.zig");
pub const OpCode = Chunk.OpCode;
pub const Vm = @import("k/Vm.zig");
pub const Value = @import("k/Value.zig");
pub const Lambda = Value.Lambda;
pub const UnaryPrimitive = Value.UnaryPrimitive;
pub const Operator = Value.Operator;
pub const Compiler = @import("k/Compiler.zig");

pub fn putAstErrorsIntoBundle(tree: Ast, src_path: []const u8, eb: *std.zig.ErrorBundle.Wip) !void {
    assert(tree.errors.len > 0);

    for (tree.errors) |err| {
        const err_span: Ast.Span = blk: {
            const start = tree.tokenStart(err.token);
            const end = start + @as(u32, @intCast(tree.tokenSlice(err.token).len));
            break :blk .{ .start = start, .end = end, .main = start };
        };
        const err_loc = std.zig.findLineColumn(tree.source, err_span.main);

        {
            try eb.addRootErrorMessage(.{
                .msg = try eb.addString(@tagName(err.tag)),
                .src_loc = try eb.addSourceLocation(.{
                    .src_path = try eb.addString(src_path),
                    .span_start = err_span.start,
                    .span_main = err_span.main,
                    .span_end = err_span.end,
                    .line = @intCast(err_loc.line),
                    .column = @intCast(err_loc.column),
                    .source_line = try eb.addString(err_loc.source_line),
                }),
                .notes_len = 0,
            });
        }
    }
}

test {
    std.testing.refAllDecls(@This());
}
