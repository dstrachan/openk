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

pub const Type = enum(i8) {
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
    iterator = 103,
    // projection = 104,
    // composition = 105,
    each = 106,
    over = 107,
    scan = 108,
    each_prior = 109,
    each_right = 110,
    each_left = 111,
};

const Union = union(Type) {
    list: []*Value,
    boolean: bool,
    boolean_list: []bool,
    byte: u8,
    byte_list: []u8,
    short: i16,
    short_list: []i16,
    int: i32,
    int_list: []i32,
    long: i64,
    long_list: []i64,
    real: f32,
    real_list: []f32,
    float: f64,
    float_list: []f64,
    char: u8,
    char_list: []u8,
    symbol: NullTerminatedString,
    symbol_list: []NullTerminatedString,
    lambda: Lambda,
    unary_primitive: UnaryPrimitive,
    operator: Operator,
    iterator: Iterator,
    each: Each,
    over: Over,
    scan: Scan,
    each_prior: EachPrior,
    each_right: EachRight,
    each_left: EachLeft,
};

pub const Lambda = struct {
    source: NullTerminatedString,
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
            .assign => try w.writeByte(':'),
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

pub const Iterator = enum(u8) {
    each,
    over,
    scan,
    each_prior,
    each_right,
    each_left,

    pub fn format(self: Iterator, w: *Io.Writer) !void {
        switch (self) {
            .each => try w.writeByte('\''),
            .over => try w.writeByte('/'),
            .scan => try w.writeByte('\\'),
            .each_prior => try w.writeAll("':"),
            .each_right => try w.writeAll("/:"),
            .each_left => try w.writeAll("\\:"),
        }
    }
};

pub const Each = struct {
    value: *Value,
};

pub const Over = struct {
    value: *Value,
};

pub const Scan = struct {
    value: *Value,
};

pub const EachPrior = struct {
    value: *Value,
};

pub const EachRight = struct {
    value: *Value,
};

pub const EachLeft = struct {
    value: *Value,
};

pub fn create(comptime tag: Type, gpa: Allocator, value: @FieldType(Union, @tagName(tag))) !*Value {
    const self: *Value = try gpa.create(Value);
    errdefer comptime unreachable;
    self.* = .{ .as = @unionInit(Union, @tagName(tag), value) };
    return self;
}

pub fn dupe(comptime tag: Type, gpa: Allocator, value: @FieldType(Union, @tagName(tag))) !*Value {
    const type_info = @typeInfo(@TypeOf(value));
    assert(type_info.pointer.size == .slice);
    const items = try gpa.dupe(type_info.pointer.child, value);
    errdefer gpa.free(items);
    return .create(tag, gpa, items);
}

pub fn alloc(comptime tag: Type, gpa: Allocator, len: usize) !*Value {
    const type_info = @typeInfo(@FieldType(Union, @tagName(tag)));
    assert(type_info.pointer.size == .slice);
    const items = try gpa.alloc(type_info.pointer.child, len);
    errdefer gpa.free(items);
    return .create(tag, gpa, items);
}

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
            .iterator => {},
            .each => |v| v.value.deref(gpa),
            .over => |v| v.value.deref(gpa),
            .scan => |v| v.value.deref(gpa),
            .each_prior => |v| v.value.deref(gpa),
            .each_right => |v| v.value.deref(gpa),
            .each_left => |v| v.value.deref(gpa),
        }
        gpa.destroy(self);
    }
}

pub fn reduce(self: *Value, gpa: Allocator) !*Value {
    if (self.as != .list) return self.ref();
    if (self.as.list.len == 0) return self.ref();

    const first_type: Type = self.as.list[0].as;
    for (self.as.list[1..]) |v| {
        if (v.as != first_type) return self.ref();
    }

    switch (self.as.list[0].as) {
        .boolean => {
            const new_list: *Value = try .alloc(.boolean_list, gpa, self.as.list.len);
            errdefer comptime unreachable;
            for (new_list.as.boolean_list, self.as.list) |*new_value, list_value| {
                new_value.* = list_value.as.boolean;
            }
            return new_list;
        },
        .byte => {
            const new_list: *Value = try .alloc(.byte_list, gpa, self.as.list.len);
            errdefer comptime unreachable;
            for (new_list.as.byte_list, self.as.list) |*new_value, list_value| {
                new_value.* = list_value.as.byte;
            }
            return new_list;
        },
        .short => {
            const new_list: *Value = try .alloc(.short_list, gpa, self.as.list.len);
            errdefer comptime unreachable;
            for (new_list.as.short_list, self.as.list) |*new_value, list_value| {
                new_value.* = list_value.as.short;
            }
            return new_list;
        },
        .int => {
            const new_list: *Value = try .alloc(.int_list, gpa, self.as.list.len);
            errdefer comptime unreachable;
            for (new_list.as.int_list, self.as.list) |*new_value, list_value| {
                new_value.* = list_value.as.int;
            }
            return new_list;
        },
        .long => {
            const new_list: *Value = try .alloc(.long_list, gpa, self.as.list.len);
            errdefer comptime unreachable;
            for (new_list.as.long_list, self.as.list) |*new_value, list_value| {
                new_value.* = list_value.as.long;
            }
            return new_list;
        },
        .real => {
            const new_list: *Value = try .alloc(.real_list, gpa, self.as.list.len);
            errdefer comptime unreachable;
            for (new_list.as.real_list, self.as.list) |*new_value, list_value| {
                new_value.* = list_value.as.real;
            }
            return new_list;
        },
        .float => {
            const new_list: *Value = try .alloc(.float_list, gpa, self.as.list.len);
            errdefer comptime unreachable;
            for (new_list.as.float_list, self.as.list) |*new_value, list_value| {
                new_value.* = list_value.as.float;
            }
            return new_list;
        },
        .char => {
            const new_list: *Value = try .alloc(.char_list, gpa, self.as.list.len);
            errdefer comptime unreachable;
            for (new_list.as.char_list, self.as.list) |*new_value, list_value| {
                new_value.* = list_value.as.char;
            }
            return new_list;
        },
        .symbol => {
            const new_list: *Value = try .alloc(.symbol_list, gpa, self.as.list.len);
            errdefer comptime unreachable;
            for (new_list.as.symbol_list, self.as.list) |*new_value, list_value| {
                new_value.* = list_value.as.symbol;
            }
            return new_list;
        },
        else => return self.ref(),
    }
}

pub fn index(self: *Value, gpa: Allocator, i: usize) !*Value {
    switch (self.as) {
        .boolean_list => |v| return .create(.boolean, gpa, if (i < v.len) v[i] else false),
        .byte_list => |v| return .create(.byte, gpa, if (i < v.len) v[i] else 0),
        .short_list => |v| return .create(.short, gpa, if (i < v.len) v[i] else 0),
        .int_list => |v| return .create(.int, gpa, if (i < v.len) v[i] else 0),
        .long_list => |v| return .create(.long, gpa, if (i < v.len) v[i] else 0),
        .real_list => |v| return .create(.real, gpa, if (i < v.len) v[i] else 0),
        .float_list => |v| return .create(.float, gpa, if (i < v.len) v[i] else 0),
        .char_list => |v| return .create(.char, gpa, if (i < v.len) v[i] else ' '),
        .symbol_list => |v| return .create(.symbol, gpa, if (i < v.len) v[i] else .empty),
        inline else => |_, t| @panic(@tagName(t)),
    }
}

pub fn reverse(self: *Value, gpa: Allocator) !*Value {
    switch (self.as) {
        inline else => |v, t| {
            const type_info = @typeInfo(@FieldType(Union, @tagName(t)));
            if (type_info == .pointer and type_info.pointer.size == .slice) {
                const value: *Value = try .dupe(t, gpa, v);
                errdefer comptime unreachable;
                std.mem.reverse(type_info.pointer.child, @field(value.as, @tagName(t)));
                return value;
            } else return self.ref();
        },
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
                if (value.len == 1) try w.writeByte(',');
                try w.writeByte('(');
                try w.print("{f}", .{value[0].alt(vm)});
                for (value[1..]) |v| try w.print(";{f}", .{v.alt(vm)});
                try w.writeByte(')');
            }
        },
        .boolean => |v| try w.print("{d}b", .{@intFromBool(v)}),
        .boolean_list => |value| {
            if (value.len == 0) {
                try w.writeAll("`boolean$()");
            } else {
                if (value.len == 1) try w.writeByte(',');
                for (value) |v| try w.print("{d}", .{@intFromBool(v)});
                try w.writeByte('b');
            }
        },
        .byte => |v| try w.print("0x{x:02}", .{v}),
        .byte_list => |value| {
            if (value.len == 0) {
                try w.writeAll("`byte$()");
            } else {
                if (value.len == 1) try w.writeByte(',');
                try w.writeAll("0x");
                for (value) |v| try w.print("{x:02}", .{v});
            }
        },
        .short => |v| try w.print("{f}h", .{@as(Short, @enumFromInt(v))}),
        .short_list => |value| {
            if (value.len == 0) {
                try w.writeAll("`short$()");
            } else {
                if (value.len == 1) try w.writeByte(',');
                try w.print("{f}", .{@as(Short, @enumFromInt(value[0]))});
                for (value[1..]) |v| try w.print(" {f}", .{@as(Short, @enumFromInt(v))});
                try w.writeByte('h');
            }
        },
        .int => |v| try w.print("{f}i", .{@as(Int, @enumFromInt(v))}),
        .int_list => |value| {
            if (value.len == 0) {
                try w.writeAll("`int$()");
            } else {
                if (value.len == 1) try w.writeByte(',');
                try w.print("{f}", .{@as(Int, @enumFromInt(value[0]))});
                for (value[1..]) |v| try w.print(" {f}", .{@as(Int, @enumFromInt(v))});
                try w.writeByte('i');
            }
        },
        .long => |v| try w.print("{f}", .{@as(Long, @enumFromInt(v))}),
        .long_list => |value| {
            if (value.len == 0) {
                try w.writeAll("`long$()");
            } else {
                if (value.len == 1) try w.writeByte(',');
                try w.print("{f}", .{@as(Long, @enumFromInt(value[0]))});
                for (value[1..]) |v| try w.print(" {f}", .{@as(Long, @enumFromInt(v))});
            }
        },
        .real => |v| try w.print("{d}e", .{v}),
        .real_list => |value| {
            if (value.len == 0) {
                try w.writeAll("`real$()");
            } else {
                if (value.len == 1) try w.writeByte(',');
                try w.print("{d}", .{value[0]});
                for (value[1..]) |v| try w.print(" {d}", .{v});
                try w.writeByte('e');
            }
        },
        .float => |v| try w.print("{d}f", .{v}),
        .float_list => |value| {
            if (value.len == 0) {
                try w.writeAll("`float$()");
            } else {
                if (value.len == 1) try w.writeByte(',');
                try w.print("{d}", .{value[0]});
                for (value[1..]) |v| try w.print(" {d}", .{v});
                try w.writeByte('f');
            }
        },
        .char => |v| try w.print("\"{c}\"", .{v}),
        .char_list => |value| {
            if (value.len == 1) try w.writeByte(',');
            try w.print("\"{s}\"", .{value});
        },
        .symbol => |v| try w.print("`{s}", .{vm.nullTerminatedString(v)}),
        .symbol_list => |value| {
            if (value.len == 0) {
                try w.writeAll("`symbol$()");
            } else {
                if (value.len == 1) try w.writeByte(',');
                for (value) |v| try w.print("`{s}", .{vm.nullTerminatedString(v)});
            }
        },
        .lambda => |v| try w.print("{s}", .{vm.nullTerminatedString(v.source)}),
        .unary_primitive => |v| try w.print("{f}", .{v}),
        .operator => |v| try w.print("{f}", .{v}),
        .iterator => |v| try w.print("{f}", .{v}),
        .each => |v| try w.print("{f}'", .{v.value.alt(vm)}),
        .over => |v| try w.print("{f}/", .{v.value.alt(vm)}),
        .scan => |v| try w.print("{f}\\", .{v.value.alt(vm)}),
        .each_prior => |v| try w.print("{f}':", .{v.value.alt(vm)}),
        .each_right => |v| try w.print("{f}/:", .{v.value.alt(vm)}),
        .each_left => |v| try w.print("{f}\\:", .{v.value.alt(vm)}),
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
        .iterator => |v| v == b.as.iterator,
        .each => |v| v.value.match(b.as.each.value),
        .over => |v| v.value.match(b.as.over.value),
        .scan => |v| v.value.match(b.as.scan.value),
        .each_prior => |v| v.value.match(b.as.each_prior.value),
        .each_right => |v| v.value.match(b.as.each_right.value),
        .each_left => |v| v.value.match(b.as.each_left.value),
    };
}

pub fn count(x: *Value) usize {
    return switch (x.as) {
        inline .list,
        .boolean_list,
        .byte_list,
        .short_list,
        .int_list,
        .long_list,
        .real_list,
        .float_list,
        .char_list,
        .symbol_list,
        => |slice| slice.len,
        else => 1,
    };
}

pub fn toIndex(x: *Value, gpa: Allocator) !?*Value {
    return switch (x.as) {
        .boolean => |v| .create(.long, gpa, @intFromBool(v)),
        .boolean_list => |values| blk: {
            const value: *Value = try .alloc(.long_list, gpa, values.len);
            errdefer comptime unreachable;
            for (value.as.long_list, values) |*v, b| v.* = @intFromBool(b);
            break :blk value;
        },
        .byte, .short, .int, .char => |v| .create(.long, gpa, v),
        inline .byte_list, .short_list, .int_list, .char_list => |values| blk: {
            const value: *Value = try .alloc(.long_list, gpa, values.len);
            errdefer comptime unreachable;
            for (value.as.long_list, values) |*v, i| v.* = i;
            break :blk value;
        },
        .long, .long_list => x.ref(),
        else => null,
    };
}

pub const Short = enum(i16) {
    null = std.math.minInt(i16),
    neg_inf = -std.math.maxInt(i16),
    inf = std.math.maxInt(i16),
    _,

    pub fn format(self: @This(), w: *Io.Writer) !void {
        try switch (self) {
            .null => w.writeAll("0N"),
            .neg_inf => w.writeAll("-0W"),
            .inf => w.writeAll("0W"),
            else => w.print("{d}", .{self}),
        };
    }
};

pub const Int = enum(i32) {
    null = std.math.minInt(i32),
    neg_inf = -std.math.maxInt(i32),
    inf = std.math.maxInt(i32),
    _,

    pub fn format(self: @This(), w: *Io.Writer) !void {
        try switch (self) {
            .null => w.writeAll("0N"),
            .neg_inf => w.writeAll("-0W"),
            .inf => w.writeAll("0W"),
            else => w.print("{d}", .{self}),
        };
    }
};

pub const Long = enum(i64) {
    null = std.math.minInt(i64),
    neg_inf = -std.math.maxInt(i64),
    inf = std.math.maxInt(i64),
    _,

    pub fn format(self: @This(), w: *Io.Writer) !void {
        try switch (self) {
            .null => w.writeAll("0N"),
            .neg_inf => w.writeAll("-0W"),
            .inf => w.writeAll("0W"),
            else => w.print("{d}", .{self}),
        };
    }
};

test {
    std.testing.refAllDecls(@This());
}
