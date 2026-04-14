const k = @import("../../root.zig");
const Vm = k.Vm;
const Value = k.Value;

pub fn add(vm: *Vm, x: *Value, y: *Value) !*Value {
    return switch (x.as) {
        .long => switch (y.as) {
            .long => .long(vm.gpa, x.as.long + y.as.long),
            .float => .float(vm.gpa, @as(f64, @floatFromInt(x.as.long)) + y.as.float),
            else => vm.runtimeError("nyi: {s}[{t};{t}]", .{ @src().fn_name, x.as, y.as }),
        },
        .float => switch (y.as) {
            .long => .float(vm.gpa, x.as.float + @as(f64, @floatFromInt(y.as.long))),
            .float => .float(vm.gpa, x.as.float + y.as.float),
            else => vm.runtimeError("nyi: {s}[{t};{t}]", .{ @src().fn_name, x.as, y.as }),
        },
        else => vm.runtimeError("nyi: {s}[{t};{t}]", .{ @src().fn_name, x.as, y.as }),
    };
}
