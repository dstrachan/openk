const k = @import("../../root.zig");
const Vm = k.Vm;
const Value = k.Value;

pub fn drop(vm: *Vm, x: *Value, y: *Value) !*Value {
    switch (x.as) {
        .long => |l| {
            if (l == 0) return y.ref();
            switch (y.as) {
                .long_list => |items| {
                    if (l < 0) {
                        if (-l < items.len) {
                            return .dupe(.long_list, vm.gpa, items[0 .. items.len - @as(usize, @intCast(-l))]);
                        } else {
                            return .create(.long_list, vm.gpa, &.{});
                        }
                    } else if (l < items.len) {
                        return .dupe(.long_list, vm.gpa, items[@intCast(l)..]);
                    } else {
                        return .create(.long_list, vm.gpa, &.{});
                    }
                },
                else => return vm.runtimeError("nyi: {s}[{t};{t}]", .{ @src().fn_name, x.as, y.as }),
            }
        },
        else => return vm.runtimeError("nyi: {s}[{t};{t}]", .{ @src().fn_name, x.as, y.as }),
    }
}
