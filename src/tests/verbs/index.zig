const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;

test "index/apply" {
    try runTest("(!10)@2", .{ .int = 2 });
    try runTest("a:!10;`a@2", .{ .int = 2 });
    try runTest("a:!10;a@2", .{ .int = 2 });

    try runTest("{[x]x*x}@2", .{ .int = 4 });
    try runTest("a:{[x]x*x};`a@2", .{ .int = 4 });
    try runTest("a:{[x]x*x};a@2", .{ .int = 4 });
}
