const std = @import("std");

const value_mod = @import("../value.zig");
const ValueType = value_mod.ValueType;

const vm_mod = @import("../vm.zig");
const VM = vm_mod.VM;

test "top-level script returns result" {
    var vm = VM.init(std.testing.allocator);
    defer vm.deinit();

    const result = try vm.interpret("1");
    defer result.deref(std.testing.allocator);

    try std.testing.expectEqual(ValueType.float, result.as);
    try std.testing.expectEqual(@floatCast(f64, 1), result.as.float);
}

test "chained add operations do not leak intermediate results" {
    var vm = VM.init(std.testing.allocator);
    defer vm.deinit();

    const result = try vm.interpret("1+2+3+4+5");
    defer result.deref(std.testing.allocator);

    try std.testing.expectEqual(ValueType.float, result.as);
    try std.testing.expectEqual(@floatCast(f64, 15), result.as.float);
}

test "chained global set operations" {
    var vm = VM.init(std.testing.allocator);
    defer vm.deinit();

    const result = try vm.interpret("a:b:c:1+2+3+4+5");
    defer result.deref(std.testing.allocator);

    try std.testing.expectEqual(ValueType.float, result.as);
    try std.testing.expectEqual(@floatCast(f64, 15), result.as.float);
}

test "simple function call" {
    var vm = VM.init(std.testing.allocator);
    defer vm.deinit();

    const result = try vm.interpret("{[x]a:x}[1]");
    defer result.deref(std.testing.allocator);

    try std.testing.expectEqual(ValueType.float, result.as);
    try std.testing.expectEqual(@floatCast(f64, 1), result.as.float);
}

test "nested function calls" {
    var vm = VM.init(std.testing.allocator);
    defer vm.deinit();

    const result = try vm.interpret("{[x;y;z]{[x;y]{[x]a:x}[x]}[x;y]}[1;2;3]");
    defer result.deref(std.testing.allocator);

    try std.testing.expectEqual(ValueType.float, result.as);
    try std.testing.expectEqual(@floatCast(f64, 1), result.as.float);
}

test "projection call" {
    var vm = VM.init(std.testing.allocator);
    defer vm.deinit();

    const result = try vm.interpret("{[x;y]x+y}[;1][2]");
    defer result.deref(std.testing.allocator);

    try std.testing.expectEqual(ValueType.float, result.as);
    try std.testing.expectEqual(@floatCast(f64, 3), result.as.float);
}
