const k = @import("../../root.zig");
const Vm = k.Vm;
const Value = k.Value;

pub fn value(vm: *Vm, x: *Value) !*Value {
    switch (x.as) {
        .lambda => |lambda| {
            const items = try vm.gpa.alloc(*Value, 4);
            errdefer vm.gpa.free(items);
            items[0] = try .dupe(.byte_list, vm.gpa, lambda.chunk.data.items(.code));
            errdefer items[0].deref(vm.gpa);
            items[1] = try .dupe(.symbol_list, vm.gpa, lambda.chunk.params.items);
            errdefer items[1].deref(vm.gpa);
            items[2] = try .dupe(.symbol_list, vm.gpa, lambda.chunk.locals.items);
            errdefer items[2].deref(vm.gpa);
            items[3] = try .dupe(.symbol_list, vm.gpa, lambda.chunk.globals.items);
            errdefer items[3].deref(vm.gpa);
            return .create(.list, vm.gpa, items);
        },
        else => return vm.runtimeError("nyi: {s}[{t}]", .{ @src().fn_name, x.as }),
    }
}
