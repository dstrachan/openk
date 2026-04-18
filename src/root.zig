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
pub const Type = Value.Type;
pub const Lambda = Value.Lambda;
pub const UnaryPrimitive = Value.UnaryPrimitive;
pub const Operator = Value.Operator;
pub const Iterator = Value.Iterator;
pub const Compiler = @import("k/Compiler.zig");
pub const parseNumber = @import("k/parse_number.zig").parseNumber;

pub const UnaryPrimitives = struct {
    pub const flip = @import("k/unary_primitives/flip.zig").flip;
    pub const neg = @import("k/unary_primitives/neg.zig").neg;
    pub const first = @import("k/unary_primitives/first.zig").first;
    pub const reciprocal = @import("k/unary_primitives/reciprocal.zig").reciprocal;
    pub const where = @import("k/unary_primitives/where.zig").where;
    pub const reverse = @import("k/unary_primitives/reverse.zig").reverse;
    pub const @"null" = @import("k/unary_primitives/null.zig").null;
    pub const group = @import("k/unary_primitives/group.zig").group;
    pub const asc = @import("k/unary_primitives/asc.zig").asc;
    pub const desc = @import("k/unary_primitives/desc.zig").desc;
    pub const string = @import("k/unary_primitives/string.zig").string;
    pub const list = @import("k/unary_primitives/list.zig").list;
    pub const count = @import("k/unary_primitives/count.zig").count;
    pub const lower = @import("k/unary_primitives/lower.zig").lower;
    pub const not = @import("k/unary_primitives/not.zig").not;
    pub const key = @import("k/unary_primitives/key.zig").key;
    pub const distinct = @import("k/unary_primitives/distinct.zig").distinct;
    pub const @"type" = @import("k/unary_primitives/type.zig").type;
    pub const value = @import("k/unary_primitives/value.zig").value;
    pub const read_text = @import("k/unary_primitives/read_text.zig").read_text;
    pub const read_binary = @import("k/unary_primitives/read_binary.zig").read_binary;
    pub const avg = @import("k/unary_primitives/avg.zig").avg;
    pub const last = @import("k/unary_primitives/last.zig").last;
    pub const sum = @import("k/unary_primitives/sum.zig").sum;
    pub const prd = @import("k/unary_primitives/prd.zig").prd;
    pub const min = @import("k/unary_primitives/min.zig").min;
    pub const max = @import("k/unary_primitives/max.zig").max;
    pub const exit = @import("k/unary_primitives/exit.zig").exit;
    pub const getenv = @import("k/unary_primitives/getenv.zig").getenv;
    pub const abs = @import("k/unary_primitives/abs.zig").abs;
    pub const sqrt = @import("k/unary_primitives/sqrt.zig").sqrt;
    pub const log = @import("k/unary_primitives/log.zig").log;
    pub const exp = @import("k/unary_primitives/exp.zig").exp;
    pub const sin = @import("k/unary_primitives/sin.zig").sin;
    pub const asin = @import("k/unary_primitives/asin.zig").asin;
    pub const cos = @import("k/unary_primitives/cos.zig").cos;
    pub const acos = @import("k/unary_primitives/acos.zig").acos;
    pub const tan = @import("k/unary_primitives/tan.zig").tan;
    pub const atan = @import("k/unary_primitives/atan.zig").atan;
    pub const @"var" = @import("k/unary_primitives/var.zig").@"var";
    pub const dev = @import("k/unary_primitives/dev.zig").dev;
    pub const hopen = @import("k/unary_primitives/hopen.zig").hopen;
};

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
    pub const xexp = @import("k/operators/xexp.zig").xexp;
    pub const setenv = @import("k/operators/setenv.zig").setenv;
    pub const binr = @import("k/operators/binr.zig").binr;
    pub const cov = @import("k/operators/cov.zig").cov;
    pub const cor = @import("k/operators/cor.zig").cor;
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
