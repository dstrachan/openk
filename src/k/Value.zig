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

pub const ByteCode = enum(u8) {
    @"return" = 0,
    // TODO: 1
    pop = 2,
    assign = 3, // 1 byte operand - 3 9 (assign, 1-based local index byte (1 = param_1, 9 = local_1))
    amend = 4, // 2 byte operand - 4 129 0 (amend, global_0, assign), 4 129 1 (amend, global_0, add)
    jump = 5, // 2 byte operand
    jump_if_zero = 6, // 2 byte operand
    do = 7, // immediately followed by jump_if_zero_dec
    jump_if_zero_dec = 8, // 2 byte operand
    loop = 9, // 2 byte operand
    call = 10, // 1 byte operand

    // builtins
    empty_list = 11,
    zero = 12,
    one = 13,
    comma = 14,
    null_symbol = 15,
    nil = 16,
    empty = 17,

    // iterators
    each = 18,
    over = 19,
    scan = 20,
    each_prior = 21,
    each_right = 22,
    each_left = 23,

    // TODO: 24-31

    // unary primitives
    identity = 32,
    flip = 33,
    neg = 34,
    first = 35,
    reciprocal = 36,
    where = 37,
    reverse = 38,
    null = 39,
    group = 40,
    asc = 41,
    desc = 42,
    string = 43,
    list = 44,
    count = 45,
    lower = 46,
    not = 47,
    key = 48,
    distinct = 49,
    type = 50,
    value = 51,
    read_text = 52,
    read_binary = 53,
    // TODO: 54
    avg = 55,
    last = 56,
    sum = 57,
    prd = 58,
    min = 59,
    max = 60,
    exit = 61,
    getenv = 62,
    abs = 63,

    // TODO: 64

    // operators
    add = 65,
    subtract = 66,
    multiply = 67,
    divide = 68,
    @"and" = 69,
    @"or" = 70,
    fill = 71,
    equals = 72,
    less_than = 73,
    greater_than = 74,
    cast = 75,
    join = 76,
    take = 77,
    drop = 78,
    match = 79,
    dict = 80,
    find = 81,
    apply_at = 82,
    apply = 83,
    file_text = 84,
    file_binary = 85,
    dynamic_load = 86,
    in = 87,
    within = 88,
    like = 89,
    bin = 90,
    ss = 91,
    insert = 92,
    wsum = 93,
    wavg = 94,
    div = 95,

    self = 96,

    // params (8)
    param_1 = 97,
    param_2 = 98,
    param_3 = 99,
    param_4 = 100,
    param_5 = 101,
    param_6 = 102,
    param_7 = 103,
    param_8 = 104,

    // locals (110)
    local_1 = 105,
    local_2 = 106,
    local_3 = 107,
    local_4 = 108,
    local_5 = 109,
    local_6 = 110,
    local_7 = 111,
    local_8 = 112,
    local_9 = 113,
    local_10 = 114,
    local_11 = 115,
    local_12 = 116,
    local_13 = 117,
    local_14 = 118,
    local_15 = 119,
    local_16 = 120,
    local_17 = 121,
    local_18 = 122,
    local_19 = 123,
    local_20 = 124,
    local_21 = 125,
    local_22 = 126,
    local_23_110 = 127, // 1 byte operand (31-118)

    // TODO: 128

    // globals (110)
    global_1 = 129,
    global_2 = 130,
    global_3 = 131,
    global_4 = 132,
    global_5 = 133,
    global_6 = 134,
    global_7 = 135,
    global_8 = 136,
    global_9 = 137,
    global_10 = 138,
    global_11 = 139,
    global_12 = 140,
    global_13 = 141,
    global_14 = 142,
    global_15 = 143,
    global_16 = 144,
    global_17 = 145,
    global_18 = 146,
    global_19 = 147,
    global_20 = 148,
    global_21 = 149,
    global_22 = 150,
    global_23 = 151,
    global_24 = 152,
    global_25 = 153,
    global_26 = 154,
    global_27 = 155,
    global_28 = 156,
    global_29 = 157,
    global_30 = 158,
    global_31_110 = 159, // 1 byte operand (31-110)

    // constants (239-(locals+globals))
    constant_1 = 160,
    constant_2 = 161,
    constant_3 = 162,
    constant_4 = 163,
    constant_5 = 164,
    constant_6 = 165,
    constant_7 = 166,
    constant_8 = 167,
    constant_9 = 168,
    constant_10 = 169,
    constant_11 = 170,
    constant_12 = 171,
    constant_13 = 172,
    constant_14 = 173,
    constant_15 = 174,
    constant_16 = 175,
    constant_17 = 176,
    constant_18 = 177,
    constant_19 = 178,
    constant_20 = 179,
    constant_21 = 180,
    constant_22 = 181,
    constant_23 = 182,
    constant_24 = 183,
    constant_25 = 184,
    constant_26 = 185,
    constant_27 = 186,
    constant_28 = 187,
    constant_29 = 188,
    constant_30 = 189,
    constant_31 = 190,
    constant_32 = 191,
    constant_33 = 192,
    constant_34 = 193,
    constant_35 = 194,
    constant_36 = 195,
    constant_37 = 196,
    constant_38 = 197,
    constant_39 = 198,
    constant_40 = 199,
    constant_41 = 200,
    constant_42 = 201,
    constant_43 = 202,
    constant_44 = 203,
    constant_45 = 204,
    constant_46 = 205,
    constant_47 = 206,
    constant_48 = 207,
    constant_49 = 208,
    constant_50 = 209,
    constant_51 = 210,
    constant_52 = 211,
    constant_53 = 212,
    constant_54 = 213,
    constant_55 = 214,
    constant_56 = 215,
    constant_57 = 216,
    constant_58 = 217,
    constant_59 = 218,
    constant_60 = 219,
    constant_61 = 220,
    constant_62 = 221,
    constant_63 = 222,
    constant_64 = 223,
    constant_65 = 224,
    constant_66 = 225,
    constant_67 = 226,
    constant_68 = 227,
    constant_69 = 228,
    constant_70 = 229,
    constant_71 = 230,
    constant_72 = 231,
    constant_73 = 232,
    constant_74 = 233,
    constant_75 = 234,
    constant_76 = 235,
    constant_77 = 236,
    constant_78 = 237,
    constant_79 = 238,
    constant_80 = 239,
    constant_81 = 240,
    constant_82 = 241,
    constant_83 = 242,
    constant_84 = 243,
    constant_85 = 244,
    constant_86 = 245,
    constant_87 = 246,
    constant_88 = 247,
    constant_89 = 248,
    constant_90 = 249,
    constant_91 = 250,
    constant_92 = 251,
    constant_93 = 252,
    constant_94 = 253,
    constant_95_239 = 254, // 1 byte operand (94-238)

    // TODO: 255
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
