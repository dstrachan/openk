const std = @import("std");

const log_messages = !@import("builtin").is_test;

pub fn print(comptime format: []const u8, args: anytype) void {
    if (comptime log_messages) {
        std.debug.print(format, args);
    }
}
