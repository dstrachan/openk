const std = @import("std");

const value_mod = @import("value.zig");
const Value = value_mod.Value;

const log_messages = !@import("builtin").is_test;

pub fn print(comptime format: []const u8, args: anytype) void {
    if (comptime log_messages) {
        std.debug.print(format, args);
    }
}

pub fn intToFloat(int: i64) f64 {
    if (int == Value.null_int) return Value.null_float;
    return @intToFloat(f64, int);
}
