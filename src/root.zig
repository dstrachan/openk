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

const Type = enum(i8) {
    byte = -4,
    short = -5,
    int = -6,
    long = -7,
    real = -8,
    float = -9,
    char = -10,
    symbol = -11,
};

const Union = union(Type) {
    byte: u8,
    short: i16,
    int: i32,
    long: i64,
    real: f32,
    float: f64,
    char: u8,
    symbol: [*:0]const u8,
};

pub const Value = struct {
    ref_count: u32 = 0,
    as: Union,

    pub fn ref(self: *Value) *Value {
        self.ref_count += 1;
        return self;
    }

    pub fn deref(self: *Value, gpa: Allocator) void {
        if (self.ref_count > 0) {
            self.ref_count -= 1;
        } else {
            switch (self.as) {
                .byte, .short, .int, .long => {},
                .real, .float => {},
                .char => {},
                .symbol => {},
            }
            gpa.destroy(self);
        }
    }

    pub fn format(self: Value, w: *Io.Writer) !void {
        switch (self.as) {
            .byte => |v| try w.print("0x{x:02}", .{v}),
            .short => |v| try w.print("{d}h", .{v}),
            .int => |v| try w.print("{d}i", .{v}),
            .long => |v| try w.print("{d}j", .{v}),
            .real => |v| try w.print("{d}e", .{v}),
            .float => |v| try w.print("{d}f", .{v}),
            .char => |v| try w.print("\"{c}\"", .{v}),
            .symbol => |v| try w.print("`{s}", .{v}),
        }
    }

    pub fn byte(gpa: Allocator, value: u8) !*Value {
        const self = try gpa.create(Value);
        errdefer comptime unreachable;
        self.* = .{ .as = .{ .byte = value } };
        return self;
    }

    pub fn short(gpa: Allocator, value: i16) !*Value {
        const self = try gpa.create(Value);
        errdefer comptime unreachable;
        self.* = .{ .as = .{ .short = value } };
        return self;
    }

    pub fn int(gpa: Allocator, value: i32) !*Value {
        const self = try gpa.create(Value);
        errdefer comptime unreachable;
        self.* = .{ .as = .{ .int = value } };
        return self;
    }

    pub fn long(gpa: Allocator, value: i64) !*Value {
        const self = try gpa.create(Value);
        errdefer comptime unreachable;
        self.* = .{ .as = .{ .long = value } };
        return self;
    }

    pub fn real(gpa: Allocator, value: f32) !*Value {
        const self = try gpa.create(Value);
        errdefer comptime unreachable;
        self.* = .{ .as = .{ .real = value } };
        return self;
    }

    pub fn float(gpa: Allocator, value: f64) !*Value {
        const self = try gpa.create(Value);
        errdefer comptime unreachable;
        self.* = .{ .as = .{ .float = value } };
        return self;
    }

    pub fn char(gpa: Allocator, value: u8) !*Value {
        const self = try gpa.create(Value);
        errdefer comptime unreachable;
        self.* = .{ .as = .{ .char = value } };
        return self;
    }
};

test {
    std.testing.refAllDecls(@This());
}
