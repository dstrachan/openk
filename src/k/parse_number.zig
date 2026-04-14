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
        unreachable;
    }

    std.log.debug("parseNumber: {s} {d}", .{ bytes, bytes.len });

    switch (bytes[bytes.len - 1]) {
        'b' => return if (sign == .pos) parseBoolean(gpa, bytes[0 .. bytes.len - 1]) else error.InvalidCharacter,
        'h' => return parseShort(gpa, bytes[0 .. bytes.len - 1], sign),
        'i' => return parseInt(gpa, bytes[0 .. bytes.len - 1], sign),
        'j' => return parseLong(gpa, bytes[0 .. bytes.len - 1], sign),
        'e' => return parseReal(gpa, bytes[0 .. bytes.len - 1], sign),
        'f' => return parseFloat(gpa, bytes[0 .. bytes.len - 1], sign),
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

fn parseShort(gpa: Allocator, bytes: []const u8, comptime sign: Sign) !*Value {
    return .short(gpa, try parseIntWithSign(i16, bytes, sign));
}

fn parseInt(gpa: Allocator, bytes: []const u8, comptime sign: Sign) !*Value {
    return .int(gpa, try parseIntWithSign(i32, bytes, sign));
}

fn parseLong(gpa: Allocator, bytes: []const u8, comptime sign: Sign) !*Value {
    return .long(gpa, try parseIntWithSign(i64, bytes, sign));
}

fn parseIntWithSign(comptime T: type, bytes: []const u8, comptime sign: Sign) !T {
    const add = switch (sign) {
        .pos => std.math.add,
        .neg => std.math.sub,
    };

    var accumulate: T = 0;
    for (bytes) |c| {
        const digit = try std.fmt.charToDigit(c, 10);
        if (accumulate != 0) {
            accumulate = try std.math.mul(T, accumulate, 10);
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
    return .real(gpa, switch (sign) {
        .neg => -value,
        .pos => value,
    });
}

fn parseFloat(gpa: Allocator, bytes: []const u8, comptime sign: Sign) !*Value {
    const value = try std.fmt.parseFloat(f64, bytes);
    return .float(gpa, switch (sign) {
        .neg => -value,
        .pos => value,
    });
}
