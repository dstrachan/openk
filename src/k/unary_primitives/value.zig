const k = @import("../../root.zig");
const Vm = k.Vm;
const Value = k.Value;

pub fn value(vm: *Vm, x: *Value) !*Value {
    switch (x.as) {
        .lambda => |lambda| {
            const bytes: *Value = try .copyByteList(vm.gpa, lambda.chunk.data.items(.code));
            errdefer bytes.deref(vm.gpa);
            const params: *Value = try .copySymbolList(vm.gpa, lambda.chunk.params.items);
            errdefer params.deref(vm.gpa);
            const locals: *Value = try .copySymbolList(vm.gpa, lambda.chunk.locals.items);
            errdefer locals.deref(vm.gpa);
            const globals: *Value = try .copySymbolList(vm.gpa, lambda.chunk.globals.items);
            errdefer globals.deref(vm.gpa);
            const list: *Value = try .list(vm.gpa, 4);
            errdefer comptime unreachable;
            list.as.list[0] = bytes;
            list.as.list[1] = params;
            list.as.list[2] = locals;
            list.as.list[3] = globals;
            return list;
        },
        else => return vm.runtimeError("nyi: {s}[{t}]", .{ @src().fn_name, x.as }),
    }
}
