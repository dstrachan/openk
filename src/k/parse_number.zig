const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

const k = @import("../root.zig");
const Value = k.Value;

const Sign = enum { pos, neg };

pub fn parseNumber(gpa: Allocator, bytes: []const u8, comptime sign: Sign) !*Value {
    assert(bytes.len > 0);
    if (std.mem.startsWith(u8, bytes, "0x")) {
        if (sign == .neg) return error.InvalidCharacter;
        return parseByte(gpa, bytes[2..]);
    }
    switch (bytes[bytes.len - 1]) {
        'b' => {
            if (sign == .neg) return error.InvalidCharacter;
            return parseBoolean(gpa, bytes[0 .. bytes.len - 1]);
        },
        'h' => return parseShort(gpa, bytes[0 .. bytes.len - 1], sign),
        'i' => return parseInt(gpa, bytes[0 .. bytes.len - 1], sign),
        'j' => return parseLong(gpa, bytes[0 .. bytes.len - 1], sign),
        'e' => return parseReal(gpa, bytes[0 .. bytes.len - 1], sign),
        'f' => return parseFloat(gpa, bytes[0 .. bytes.len - 1], sign),
        '.' => return parseFloat(gpa, bytes, sign),
        '0'...'9' => return parseLong(gpa, bytes, sign),
        else => return error.InvalidCharacter,
    }
}

fn parseBoolean(gpa: Allocator, bytes: []const u8) !*Value {
    if (bytes.len == 1) {
        return .create(.boolean, gpa, switch (bytes[0]) {
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
    return .create(.boolean_list, gpa, items);
}

fn parseByte(gpa: Allocator, bytes: []const u8) !*Value {
    return switch (bytes.len) {
        0 => .create(.byte_list, gpa, &.{}),
        1, 2 => .create(.byte, gpa, try parseIntWithSign(u8, bytes, 16, .pos)),
        else => switch (bytes.len % 2) {
            0 => {
                const len = bytes.len / 2;
                const items = try gpa.alloc(u8, len);
                errdefer gpa.free(items);
                for (items, 0..) |*v, i| {
                    v.* = try parseIntWithSign(u8, bytes[(i * 2)..][0..2], 16, .pos);
                }
                return .create(.byte_list, gpa, items);
            },
            1 => {
                const len = bytes.len / 2 + 1;
                const items = try gpa.alloc(u8, len);
                errdefer gpa.free(items);
                items[0] = try parseIntWithSign(u8, bytes[0..1], 16, .pos);
                for (items[1..], 1..) |*v, i| {
                    v.* = try parseIntWithSign(u8, bytes[1 + ((i - 1) * 2) ..][0..2], 16, .pos);
                }
                return .create(.byte_list, gpa, items);
            },
            else => unreachable,
        },
    };
}

fn parseShort(gpa: Allocator, bytes: []const u8, comptime sign: Sign) !*Value {
    return .create(.short, gpa, try parseIntWithSign(i16, bytes, 10, sign));
}

fn parseInt(gpa: Allocator, bytes: []const u8, comptime sign: Sign) !*Value {
    return .create(.int, gpa, try parseIntWithSign(i32, bytes, 10, sign));
}

fn parseLong(gpa: Allocator, bytes: []const u8, comptime sign: Sign) !*Value {
    return .create(.long, gpa, try parseIntWithSign(i64, bytes, 10, sign));
}

fn parseIntWithSign(comptime T: type, bytes: []const u8, base: u8, comptime sign: Sign) !T {
    const add = switch (sign) {
        .pos => std.math.add,
        .neg => std.math.sub,
    };

    var accumulate: T = 0;
    for (bytes) |c| {
        const digit = try std.fmt.charToDigit(c, base);
        if (accumulate != 0) {
            accumulate = try std.math.mul(T, accumulate, base);
        } else if (sign == .neg) {
            accumulate = -@as(i8, @intCast(digit));
            continue;
        }
        accumulate = try add(T, accumulate, digit);
    }

    return accumulate;
}

fn parseReal(gpa: Allocator, bytes: []const u8, comptime sign: Sign) !*Value {
    const value = try std.fmt.parseFloat(f32, bytes);
    return .create(.real, gpa, switch (sign) {
        .neg => -value,
        .pos => value,
    });
}

fn parseFloat(gpa: Allocator, bytes: []const u8, comptime sign: Sign) !*Value {
    const value = try std.fmt.parseFloat(f64, bytes);
    return .create(.float, gpa, switch (sign) {
        .neg => -value,
        .pos => value,
    });
}
