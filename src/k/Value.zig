const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

const k = @import("../root.zig");
const Chunk = k.Chunk;
const NullTerminatedString = k.NullTerminatedString;
const Vm = k.Vm;

const Value = @This();

ref_count: u32 = 0,
as: Union,

const Type = enum(i8) {
    list = 0,
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
    lambda = 100,
    unary_primitive = 101,
    operator = 102,
};

const Union = union(Type) {
    list: []*Value,
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
    symbol: NullTerminatedString,
    symbol_list: []const NullTerminatedString,
    lambda: Lambda,
    unary_primitive: UnaryPrimitive,
    operator: Operator,
};

pub const Lambda = struct {
    source: NullTerminatedString,
    arity: usize = 0,
    locals: usize = 0,
    chunk: Chunk = .empty,

    pub fn deinit(self: Lambda, gpa: Allocator) void {
        var chunk = self.chunk;
        chunk.deinit(gpa);
    }
};

// :: +: -: *: %: &: |: ^: =: <: >: $: ,: #: _: ~: !: ?: @: .: 0:: 1:: 2::
// avg last sum prd min max exit getenv abs sqrt log exp sin asin cos acos tan atan enlist var dev hopen
pub const UnaryPrimitive = enum(u8) {
    identity,
    flip,
    neg,
    first,
    reciprocal,
    where,
    reverse,
    null,
    group,
    asc,
    desc,
    string,
    list,
    count,
    lower,
    not,
    key,
    distinct,
    type,
    value,
    read_text,
    read_binary,
    _unused,
    avg,
    last,
    sum,
    prd,
    min,
    max,
    exit,
    getenv,
    abs,
    sqrt,
    log,
    exp,
    sin,
    asin,
    cos,
    acos,
    tan,
    atan,
    enlist,
    @"var",
    dev,
    hopen,

    pub fn format(self: UnaryPrimitive, w: *Io.Writer) !void {
        switch (self) {
            .identity => try w.writeAll("::"),
            .flip => try w.writeAll("+:"),
            .neg => try w.writeAll("-:"),
            .first => try w.writeAll("*:"),
            .reciprocal => try w.writeAll("%:"),
            .where => try w.writeAll("&:"),
            .reverse => try w.writeAll("|:"),
            .null => try w.writeAll("^:"),
            .group => try w.writeAll("=:"),
            .asc => try w.writeAll("<:"),
            .desc => try w.writeAll(">:"),
            .string => try w.writeAll("$:"),
            .list => try w.writeAll(",:"),
            .count => try w.writeAll("#:"),
            .lower => try w.writeAll("_:"),
            .not => try w.writeAll("~:"),
            .key => try w.writeAll("!:"),
            .distinct => try w.writeAll("?:"),
            .type => try w.writeAll("@:"),
            .value => try w.writeAll(".:"),
            .read_text => try w.writeAll("0::"),
            .read_binary => try w.writeAll("1::"),
            inline else => |t| try w.writeAll(@tagName(t)),
        }
    }
};

// : + - * % & | ^ = < > $ , # _ ~ ! ? @ . 0: 1: 2:
// in within like bin ss insert wsum wavg div xexp setenv binr cov cor
pub const Operator = enum(u8) {
    assign,
    add,
    subtract,
    multiply,
    divide,
    @"and",
    @"or",
    fill,
    equals,
    less_than,
    greater_than,
    cast,
    join,
    take,
    drop,
    match,
    dict,
    find,
    apply_at,
    apply,
    file_text,
    file_binary,
    dynamic_load,
    in,
    within,
    like,
    bin,
    ss,
    insert,
    wsum,
    wavg,
    div,
    xexp,
    setenv,
    binr,
    cov,
    cor,

    pub fn format(self: Operator, w: *Io.Writer) !void {
        switch (self) {
            .assign => try w.writeAll("TODO"),
            .add => try w.writeByte('+'),
            .subtract => try w.writeByte('-'),
            .multiply => try w.writeByte('*'),
            .divide => try w.writeByte('%'),
            .@"and" => try w.writeByte('&'),
            .@"or" => try w.writeByte('|'),
            .fill => try w.writeByte('^'),
            .equals => try w.writeByte('='),
            .less_than => try w.writeByte('<'),
            .greater_than => try w.writeByte('>'),
            .cast => try w.writeByte('$'),
            .join => try w.writeByte(','),
            .take => try w.writeByte('#'),
            .drop => try w.writeByte('_'),
            .match => try w.writeByte('~'),
            .dict => try w.writeByte('!'),
            .find => try w.writeByte('?'),
            .apply_at => try w.writeByte('@'),
            .apply => try w.writeByte('.'),
            .file_text => try w.writeAll("0:"),
            .file_binary => try w.writeAll("1:"),
            .dynamic_load => try w.writeAll("2:"),
            inline else => |t| try w.writeAll(@tagName(t)),
        }
    }
};

pub fn ref(self: *Value) *Value {
    self.ref_count += 1;
    return self;
}

pub fn deref(self: *Value, gpa: Allocator) void {
    if (self.ref_count > 0) {
        self.ref_count -= 1;
    } else {
        switch (self.as) {
            .list => |value| {
                for (value) |v| v.deref(gpa);
                gpa.free(value);
            },
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
            .lambda => |v| v.deinit(gpa),
            .unary_primitive => {},
            .operator => {},
        }
        gpa.destroy(self);
    }
}

pub const Alt = struct {
    vm: *Vm,
    value: *Value,

    pub fn format(data: @This(), w: *Io.Writer) Io.Writer.Error!void {
        try data.value.format(w, data.vm);
    }
};

pub fn alt(value: *Value, vm: *Vm) std.fmt.Alt(Alt, Alt.format) {
    return .{ .data = .{ .vm = vm, .value = value } };
}

pub fn format(self: Value, w: *Io.Writer, vm: *Vm) !void {
    switch (self.as) {
        .list => |value| {
            if (value.len == 0) {
                try w.writeAll("()");
            } else {
                try w.writeByte('(');
                try w.print("{f}", .{value[0].alt(vm)});
                for (value[1..]) |v| try w.print(";{f}", .{v.alt(vm)});
                try w.writeByte(')');
            }
        },
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
        .symbol => |v| try w.print("`{s}", .{vm.nullTerminatedString(v)}),
        .symbol_list => |value| {
            for (value) |v| try w.print("`{s}", .{vm.nullTerminatedString(v)});
        },
        .lambda => |v| try w.print("{s}", .{vm.nullTerminatedString(v.source)}),
        .unary_primitive => |v| try w.print("{f}", .{v}),
        .operator => |v| try w.print("{f}", .{v}),
    }
}

pub fn match(a: *Value, b: *Value) bool {
    if (@as(Type, a.as) != b.as) return false;

    return switch (a.as) {
        .list => |value| blk: {
            if (value.len != b.as.list.len) return false;
            for (value, b.as.list) |va, vb| if (!va.match(vb)) return false;
            break :blk true;
        },
        .boolean => |v| v == b.as.boolean,
        .boolean_list => |v| std.mem.eql(bool, v, b.as.boolean_list),
        .byte => |v| v == b.as.byte,
        .byte_list => |v| std.mem.eql(u8, v, b.as.byte_list),
        .short => |v| v == b.as.short,
        .short_list => |v| std.mem.eql(i16, v, b.as.short_list),
        .int => |v| v == b.as.int,
        .int_list => |v| std.mem.eql(i32, v, b.as.int_list),
        .long => |v| v == b.as.long,
        .long_list => |v| std.mem.eql(i64, v, b.as.long_list),
        .real => |v| v == b.as.real,
        .real_list => |v| std.mem.eql(f32, v, b.as.real_list),
        .float => |v| v == b.as.float,
        .float_list => |v| std.mem.eql(f64, v, b.as.float_list),
        .char => |v| v == b.as.char,
        .char_list => |v| std.mem.eql(u8, v, b.as.char_list),
        .symbol => |v| v == b.as.symbol,
        .symbol_list => |v| std.mem.eql(NullTerminatedString, v, b.as.symbol_list),
        .lambda => |v| v.source == b.as.lambda.source,
        .unary_primitive => |v| v == b.as.unary_primitive,
        .operator => |v| v == b.as.operator,
    };
}

pub fn list(gpa: Allocator, len: usize) !*Value {
    const items = try gpa.alloc(*Value, len);
    errdefer gpa.free(items);
    const self = try gpa.create(Value);
    errdefer comptime unreachable;
    self.* = .{ .as = .{ .list = items } };
    return self;
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
    const items = try gpa.dupe(bool, value);
    errdefer gpa.free(items);
    const self = try gpa.create(Value);
    errdefer comptime unreachable;
    self.* = .{ .as = .{ .boolean_list = items } };
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
    const items = try gpa.dupe(u8, value);
    errdefer gpa.free(items);
    const self = try gpa.create(Value);
    errdefer comptime unreachable;
    self.* = .{ .as = .{ .byte_list = items } };
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
    const items = try gpa.dupe(i16, value);
    errdefer gpa.free(items);
    const self = try gpa.create(Value);
    errdefer comptime unreachable;
    self.* = .{ .as = .{ .short_list = items } };
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
    const items = try gpa.dupe(i32, value);
    errdefer gpa.free(items);
    const self = try gpa.create(Value);
    errdefer comptime unreachable;
    self.* = .{ .as = .{ .int_list = items } };
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
    const items = try gpa.dupe(i64, value);
    errdefer gpa.free(items);
    const self = try gpa.create(Value);
    errdefer comptime unreachable;
    self.* = .{ .as = .{ .long_list = items } };
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
    const items = try gpa.dupe(f32, value);
    errdefer gpa.free(items);
    const self = try gpa.create(Value);
    errdefer comptime unreachable;
    self.* = .{ .as = .{ .real_list = items } };
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
    const items = try gpa.dupe(f64, value);
    errdefer gpa.free(items);
    const self = try gpa.create(Value);
    errdefer comptime unreachable;
    self.* = .{ .as = .{ .float_list = items } };
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
    const items = try gpa.dupe(u8, value);
    errdefer gpa.free(items);
    const self = try gpa.create(Value);
    errdefer comptime unreachable;
    self.* = .{ .as = .{ .char_list = items } };
    return self;
}

pub fn symbol(gpa: Allocator, value: NullTerminatedString) !*Value {
    const self = try gpa.create(Value);
    errdefer comptime unreachable;
    self.* = .{ .as = .{ .symbol = value } };
    return self;
}

pub fn symbolList(gpa: Allocator, value: []const NullTerminatedString) !*Value {
    const self = try gpa.create(Value);
    errdefer comptime unreachable;
    self.* = .{ .as = .{ .symbol_list = value } };
    return self;
}

pub fn copySymbolList(gpa: Allocator, value: []const NullTerminatedString) !*Value {
    const items = try gpa.dupe(NullTerminatedString, value);
    errdefer gpa.free(items);
    const self = try gpa.create(Value);
    errdefer comptime unreachable;
    self.* = .{ .as = .{ .symbol_list = items } };
    return self;
}

pub fn lambda(gpa: Allocator, value: Lambda) !*Value {
    const self = try gpa.create(Value);
    errdefer comptime unreachable;
    self.* = .{ .as = .{ .lambda = value } };
    return self;
}

pub fn unaryPrimitive(gpa: Allocator, value: UnaryPrimitive) !*Value {
    const self = try gpa.create(Value);
    errdefer comptime unreachable;
    self.* = .{ .as = .{ .unary_primitive = value } };
    return self;
}

pub fn operator(gpa: Allocator, value: Operator) !*Value {
    const self = try gpa.create(Value);
    errdefer comptime unreachable;
    self.* = .{ .as = .{ .operator = value } };
    return self;
}

test {
    std.testing.refAllDecls(@This());
}
