const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

const k = @import("../root.zig");
const Value = k.Value;

pub fn parseNumber(gpa: Allocator, bytes: []const u8) !*Value {
    assert(bytes.len > 0);
    if (std.mem.startsWith(u8, bytes, "0x")) {
        unreachable;
    }

    std.log.debug("parseNumber: {s} {d}", .{ bytes, bytes.len });

    switch (bytes[bytes.len - 1]) {
        'b' => return parseBoolean(gpa, bytes[0 .. bytes.len - 1]),
        'h' => unreachable,
        'i' => unreachable,
        'j' => unreachable,
        'e' => unreachable,
        'f' => unreachable,
        '.' => unreachable,
        '0'...'9' => unreachable,
        else => unreachable,
    }

    unreachable;
}

fn parseBoolean(gpa: Allocator, bytes: []const u8) !*Value {
    if (bytes.len == 1) {
        return .boolean(gpa, switch (bytes[0]) {
            '0' => false,
            '1' => true,
            else => return error.InvalidCharacter,
        });
    }

    const items = try gpa.alloc(bool, bytes.len);
    errdefer gpa.free(items);
    for (items, bytes) |*i, b| {
        i.* = switch (b) {
            '0' => false,
            '1' => true,
            else => return error.InvalidCharacter,
        };
    }
    return .booleanList(gpa, items);
}
