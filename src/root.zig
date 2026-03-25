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
    boolean = -1,
    boolean_list = 1,
    byte = -4,
    byte_list = 4,
    short = -5,
    short_list = 5,
    int = -6,
    int_list = 6,
    long = -7,
    long_list = 7,
    real = -8,
    real_list = 8,
    float = -9,
    float_list = 9,
    char = -10,
    char_list = 10,
    symbol = -11,
    symbol_list = 11,
};

const Union = union(Type) {
    boolean: bool,
    boolean_list: []const bool,
    byte: u8,
    byte_list: []const u8,
    short: i16,
    short_list: []const i16,
    int: i32,
    int_list: []const i32,
    long: i64,
    long_list: []const i64,
    real: f32,
    real_list: []const f32,
    float: f64,
    float_list: []const f64,
    char: u8,
    char_list: []const u8,
    symbol: [*:0]const u8,
    symbol_list: []const [*:0]const u8,
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
                .boolean => {},
                .boolean_list => |v| gpa.free(v),
                .byte => {},
                .byte_list => |v| gpa.free(v),
                .short => {},
                .short_list => |v| gpa.free(v),
                .int => {},
                .int_list => |v| gpa.free(v),
                .long => {},
                .long_list => |v| gpa.free(v),
                .real => {},
                .real_list => |v| gpa.free(v),
                .float => {},
                .float_list => |v| gpa.free(v),
                .char => {},
                .char_list => |v| gpa.free(v),
                .symbol => {},
                .symbol_list => |v| gpa.free(v),
            }
            gpa.destroy(self);
        }
    }

    pub fn format(self: Value, w: *Io.Writer) !void {
        switch (self.as) {
            .boolean => |v| try w.print("{d}b", .{@intFromBool(v)}),
            .boolean_list => |value| {
                for (value) |v| try w.print("{d}", .{@intFromBool(v)});
                try w.writeByte('b');
            },
            .byte => |v| try w.print("0x{x:02}", .{v}),
            .byte_list => |value| {
                try w.writeAll("0x");
                for (value) |v| try w.print("{x:02}", .{v});
            },
            .short => |v| try w.print("{d}h", .{v}),
            .short_list => |value| {
                try w.print("{d}", .{value[0]});
                for (value[1..]) |v| {
                    try w.print(" {d}", .{v});
                }
                try w.writeByte('h');
            },
            .int => |v| try w.print("{d}i", .{v}),
            .int_list => |value| {
                try w.print("{d}", .{value[0]});
                for (value[1..]) |v| {
                    try w.print(" {d}", .{v});
                }
                try w.writeByte('i');
            },
            .long => |v| try w.print("{d}j", .{v}),
            .long_list => |value| {
                try w.print("{d}", .{value[0]});
                for (value[1..]) |v| {
                    try w.print(" {d}", .{v});
                }
                try w.writeByte('j');
            },
            .real => |v| try w.print("{d}e", .{v}),
            .real_list => |value| {
                try w.print("{d}", .{value[0]});
                for (value[1..]) |v| {
                    try w.print(" {d}", .{v});
                }
                try w.writeByte('e');
            },
            .float => |v| try w.print("{d}f", .{v}),
            .float_list => |value| {
                try w.print("{d}", .{value[0]});
                for (value[1..]) |v| {
                    try w.print(" {d}", .{v});
                }
                try w.writeByte('f');
            },
            .char => |v| try w.print("\"{c}\"", .{v}),
            .char_list => |v| try w.print("\"{s}\"", .{v}),
            .symbol => |v| try w.print("`{s}", .{v}),
            .symbol_list => |value| {
                for (value) |v| try w.print("`{s}", .{v});
            },
        }
    }

    pub fn boolean(gpa: Allocator, value: bool) !*Value {
        const self = try gpa.create(Value);
        errdefer comptime unreachable;
        self.* = .{ .as = .{ .boolean = value } };
        return self;
    }

    pub fn booleanList(gpa: Allocator, value: []const bool) !*Value {
        const self = try gpa.create(Value);
        errdefer comptime unreachable;
        self.* = .{ .as = .{ .boolean_list = value } };
        return self;
    }

    pub fn copyBooleanList(gpa: Allocator, value: []const bool) !*Value {
        const list = try gpa.dupe(bool, value);
        errdefer gpa.free(list);
        const self = try gpa.create(Value);
        errdefer comptime unreachable;
        self.* = .{ .as = .{ .boolean_list = list } };
        return self;
    }

    pub fn byte(gpa: Allocator, value: u8) !*Value {
        const self = try gpa.create(Value);
        errdefer comptime unreachable;
        self.* = .{ .as = .{ .byte = value } };
        return self;
    }

    pub fn byteList(gpa: Allocator, value: []const u8) !*Value {
        const self = try gpa.create(Value);
        errdefer comptime unreachable;
        self.* = .{ .as = .{ .byte_list = value } };
        return self;
    }

    pub fn copyByteList(gpa: Allocator, value: []const u8) !*Value {
        const list = try gpa.dupe(u8, value);
        errdefer gpa.free(list);
        const self = try gpa.create(Value);
        errdefer comptime unreachable;
        self.* = .{ .as = .{ .byte_list = list } };
        return self;
    }

    pub fn short(gpa: Allocator, value: i16) !*Value {
        const self = try gpa.create(Value);
        errdefer comptime unreachable;
        self.* = .{ .as = .{ .short = value } };
        return self;
    }

    pub fn shortList(gpa: Allocator, value: []const i16) !*Value {
        const self = try gpa.create(Value);
        errdefer comptime unreachable;
        self.* = .{ .as = .{ .short_list = value } };
        return self;
    }

    pub fn copyShortList(gpa: Allocator, value: []const i16) !*Value {
        const list = try gpa.dupe(i16, value);
        errdefer gpa.free(list);
        const self = try gpa.create(Value);
        errdefer comptime unreachable;
        self.* = .{ .as = .{ .short_list = list } };
        return self;
    }

    pub fn int(gpa: Allocator, value: i32) !*Value {
        const self = try gpa.create(Value);
        errdefer comptime unreachable;
        self.* = .{ .as = .{ .int = value } };
        return self;
    }

    pub fn intList(gpa: Allocator, value: []const i32) !*Value {
        const self = try gpa.create(Value);
        errdefer comptime unreachable;
        self.* = .{ .as = .{ .int_list = value } };
        return self;
    }

    pub fn copyIntList(gpa: Allocator, value: []const i32) !*Value {
        const list = try gpa.dupe(i32, value);
        errdefer gpa.free(list);
        const self = try gpa.create(Value);
        errdefer comptime unreachable;
        self.* = .{ .as = .{ .int_list = list } };
        return self;
    }

    pub fn long(gpa: Allocator, value: i64) !*Value {
        const self = try gpa.create(Value);
        errdefer comptime unreachable;
        self.* = .{ .as = .{ .long = value } };
        return self;
    }

    pub fn longList(gpa: Allocator, value: []const i64) !*Value {
        const self = try gpa.create(Value);
        errdefer comptime unreachable;
        self.* = .{ .as = .{ .long_list = value } };
        return self;
    }

    pub fn copyLongList(gpa: Allocator, value: []const i64) !*Value {
        const list = try gpa.dupe(i64, value);
        errdefer gpa.free(list);
        const self = try gpa.create(Value);
        errdefer comptime unreachable;
        self.* = .{ .as = .{ .long_list = list } };
        return self;
    }

    pub fn real(gpa: Allocator, value: f32) !*Value {
        const self = try gpa.create(Value);
        errdefer comptime unreachable;
        self.* = .{ .as = .{ .real = value } };
        return self;
    }

    pub fn realList(gpa: Allocator, value: []const f32) !*Value {
        const self = try gpa.create(Value);
        errdefer comptime unreachable;
        self.* = .{ .as = .{ .real_list = value } };
        return self;
    }

    pub fn copyRealList(gpa: Allocator, value: []const f32) !*Value {
        const list = try gpa.dupe(f32, value);
        errdefer gpa.free(list);
        const self = try gpa.create(Value);
        errdefer comptime unreachable;
        self.* = .{ .as = .{ .real_list = list } };
        return self;
    }

    pub fn float(gpa: Allocator, value: f64) !*Value {
        const self = try gpa.create(Value);
        errdefer comptime unreachable;
        self.* = .{ .as = .{ .float = value } };
        return self;
    }

    pub fn floatList(gpa: Allocator, value: []const f64) !*Value {
        const self = try gpa.create(Value);
        errdefer comptime unreachable;
        self.* = .{ .as = .{ .float_list = value } };
        return self;
    }

    pub fn copyFloatList(gpa: Allocator, value: []const f64) !*Value {
        const list = try gpa.dupe(f64, value);
        errdefer gpa.free(list);
        const self = try gpa.create(Value);
        errdefer comptime unreachable;
        self.* = .{ .as = .{ .float_list = list } };
        return self;
    }

    pub fn char(gpa: Allocator, value: u8) !*Value {
        const self = try gpa.create(Value);
        errdefer comptime unreachable;
        self.* = .{ .as = .{ .char = value } };
        return self;
    }

    pub fn charList(gpa: Allocator, value: []const u8) !*Value {
        const self = try gpa.create(Value);
        errdefer comptime unreachable;
        self.* = .{ .as = .{ .char_list = value } };
        return self;
    }

    pub fn copyCharList(gpa: Allocator, value: []const u8) !*Value {
        const list = try gpa.dupe(u8, value);
        errdefer gpa.free(list);
        const self = try gpa.create(Value);
        errdefer comptime unreachable;
        self.* = .{ .as = .{ .char_list = list } };
        return self;
    }

    pub fn symbol(gpa: Allocator, value: [*:0]const u8) !*Value {
        const self = try gpa.create(Value);
        errdefer comptime unreachable;
        self.* = .{ .as = .{ .symbol = value } };
        return self;
    }

    pub fn symbolList(gpa: Allocator, value: []const [*:0]const u8) !*Value {
        const self = try gpa.create(Value);
        errdefer comptime unreachable;
        self.* = .{ .as = .{ .symbol_list = value } };
        return self;
    }

    pub fn copySymbolList(gpa: Allocator, value: []const [*:0]const u8) !*Value {
        const list = try gpa.dupe([*:0]const u8, value);
        errdefer gpa.free(list);
        const self = try gpa.create(Value);
        errdefer comptime unreachable;
        self.* = .{ .as = .{ .symbol_list = list } };
        return self;
    }
};

test {
    std.testing.refAllDecls(@This());
}
