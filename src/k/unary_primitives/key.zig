const k = @import("../../root.zig");
const Vm = k.Vm;
const Value = k.Value;

pub fn key(vm: *Vm, x: *Value) !*Value {
    switch (x.as) {
        .long => {
            if (x.as.long < 0) return vm.runtimeError("domain", .{});

            const items = try vm.gpa.alloc(i64, @intCast(x.as.long));
            errdefer vm.gpa.free(items);
            for (items, 0..) |*item, i| {
                item.* = @intCast(i);
            }
            return .longList(vm.gpa, items);
        },
        else => return vm.runtimeError("nyi: {s}[{t}]", .{ @src().fn_name, x.as }),
    }
}
