const std = @import("std");

const k = @import("../../root.zig");
const Vm = k.Vm;
const Value = k.Value;

pub fn exit(vm: *Vm, x: *Value) !*Value {
    const status: u8 = switch (x.as) {
        .boolean => |v| @intFromBool(v),
        .byte, .short, .int, .long, .char => |v| @intCast(v),
        else => return vm.runtimeError("type", .{}),
    };
    std.process.exit(status);
}
