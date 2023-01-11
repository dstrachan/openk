const std = @import("std");

const value_mod = @import("../value.zig");
const ValueType = value_mod.ValueType;

const vm_mod = @import("../vm.zig");
const VM = vm_mod.VM;

test "top-level script returns result" {
    var vm = VM.init(std.testing.allocator);
    defer vm.deinit();

    const result = try vm.interpret("1");
    defer result.deinit(std.testing.allocator);

    try std.testing.expectEqual(ValueType.float, result.data);
    try std.testing.expectEqual(@floatCast(f64, 1), result.data.float);
}
