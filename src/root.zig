const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

pub const build_options = @import("build_options");

pub const tokenizer = @import("k/tokenizer.zig");
pub const Token = tokenizer.Token;
pub const Tokenizer = tokenizer.Tokenizer;
pub const Ast = @import("k/Ast.zig");
pub const Node = Ast.Node;
pub const Parse = @import("k/Parse.zig");
pub const Chunk = @import("k/Chunk.zig");
pub const OpCode = Chunk.OpCode;
pub const Value = f64;

pub fn putAstErrorsIntoBundle(gpa: Allocator, tree: Ast, src_path: []const u8, eb: *std.zig.ErrorBundle.Wip) !void {
    _ = gpa; // autofix
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
