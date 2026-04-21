const k = @import("../../root.zig");
const Vm = k.Vm;
const Value = k.Value;

pub fn key(vm: *Vm, x: *Value) !*Value {
    switch (x.as) {
        .long => {
            if (x.as.long < 0) return vm.runtimeError("domain", .{});

            const value: *Value = try .alloc(.long_list, vm.gpa, @intCast(x.as.long));
            errdefer comptime unreachable;
            for (value.as.long_list, 0..) |*v, i| v.* = @intCast(i);
            return value;
        },
        else => return vm.runtimeError("nyi: {s}[{t}]", .{ @src().fn_name, x.as }),
    }
}
