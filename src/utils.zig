const std = @import("std");

const debug_mod = @import("debug.zig");

const value_mod = @import("value.zig");
const Value = value_mod.Value;
const ValueType = value_mod.ValueType;

pub fn print(comptime format: []const u8, args: anytype) void {
    if (comptime debug_mod.debug_log_messages) {
        std.debug.print(format, args);
    }
}

pub fn intToFloat(int: i64) f64 {
    if (int == Value.null_int) return Value.null_float;
    return @intToFloat(f64, int);
}

pub fn hasSameKeys(a: anytype, b: anytype) bool {
    if (a.hash_map.keys().len != b.hash_map.keys().len) return false;
    for (a.hash_map.keys()) |k| {
        if (!b.hash_map.contains(k)) return false;
    }
    return true;
}

pub fn minType(types: []const ValueType) ValueType {
    var min = @enumToInt(types[0]);
    for (types[1..]) |t| {
        if (@enumToInt(t) < min) min = @enumToInt(t);
    }
    return @intToEnum(ValueType, min);
}

pub fn maxType(types: []const ValueType) ValueType {
    var max = @enumToInt(types[0]);
    for (types[1..]) |t| {
        if (@enumToInt(t) > max) max = @enumToInt(t);
    }
    return @intToEnum(ValueType, max);
}
