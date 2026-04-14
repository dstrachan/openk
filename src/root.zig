const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

pub const build_options = @import("build_options");
pub const version = build_options.version;
pub const trace_execution = build_options.trace_execution;
pub const print_code = build_options.print_code;

pub const tokenizer = @import("k/tokenizer.zig");
pub const Token = tokenizer.Token;
pub const Tokenizer = tokenizer.Tokenizer;
pub const Ast = @import("k/Ast.zig");
pub const Node = Ast.Node;
pub const Parse = @import("k/Parse.zig");
pub const Chunk = @import("k/Chunk.zig");
pub const OpCode = Chunk.OpCode;
pub const Vm = @import("k/Vm.zig");
pub const NullTerminatedString = Vm.NullTerminatedString;
pub const Value = @import("k/Value.zig");
pub const Lambda = Value.Lambda;
pub const UnaryPrimitive = Value.UnaryPrimitive;
pub const Operator = Value.Operator;
pub const Compiler = @import("k/Compiler.zig");
pub const parseNumber = @import("k/parse_number.zig").parseNumber;

pub const Operators = struct {
    pub const add = @import("k/operators/add.zig").add;
    pub const subtract = @import("k/operators/subtract.zig").subtract;
    pub const multiply = @import("k/operators/multiply.zig").multiply;
    pub const divide = @import("k/operators/divide.zig").divide;
    pub const @"and" = @import("k/operators/and.zig").@"and";
    pub const @"or" = @import("k/operators/or.zig").@"or";
    pub const fill = @import("k/operators/fill.zig").fill;
    pub const equals = @import("k/operators/equals.zig").equals;
    pub const less_than = @import("k/operators/less_than.zig").less_than;
    pub const greater_than = @import("k/operators/greater_than.zig").greater_than;
    pub const cast = @import("k/operators/cast.zig").cast;
    pub const join = @import("k/operators/join.zig").join;
    pub const take = @import("k/operators/take.zig").take;
    pub const drop = @import("k/operators/drop.zig").drop;
    pub const match = @import("k/operators/match.zig").match;
    pub const dict = @import("k/operators/dict.zig").dict;
    pub const find = @import("k/operators/find.zig").find;
    pub const apply = @import("k/operators/apply.zig").apply;
    pub const file_text = @import("k/operators/file_text.zig").file_text;
    pub const file_binary = @import("k/operators/file_binary.zig").file_binary;
    pub const dynamic_load = @import("k/operators/dynamic_load.zig").dynamic_load;
    pub const in = @import("k/operators/in.zig").in;
    pub const within = @import("k/operators/within.zig").within;
    pub const like = @import("k/operators/like.zig").like;
    pub const bin = @import("k/operators/bin.zig").bin;
    pub const ss = @import("k/operators/ss.zig").ss;
    pub const insert = @import("k/operators/insert.zig").insert;
    pub const wsum = @import("k/operators/wsum.zig").wsum;
    pub const wavg = @import("k/operators/wavg.zig").wavg;
    pub const div = @import("k/operators/div.zig").div;
};

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
