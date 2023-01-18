const vm_mod = @import("../vm.zig");
const verbTest = vm_mod.verbTest;
const DataType = vm_mod.DataType;

fn getDataType(comptime x: DataType, comptime y: DataType) DataType {
    return switch (x) {
        .boolean => switch (y) {
            .boolean => .int,
            .int => .int,
            .float => .float,
        },
        .int => switch (y) {
            .boolean => .int,
            .int => .int,
            .float => .float,
        },
        .float => .float,
    };
}

fn add(comptime x: comptime_int, comptime y: comptime_int) comptime_int {
    return x + y;
}

test "add" {
    try verbTest(
        &[_]DataType{ .boolean, .int, .float },
        &[_]comptime_int{ 0, 1, -1 },
        getDataType,
        add,
        "+",
    );
}
