const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;

const k = @import("k");
const Ast = k.Ast;

pub fn printAstErrorsToStderr(io: Io, gpa: Allocator, tree: Ast, path: []const u8, color: std.zig.Color) !void {
    var wip_errors: std.zig.ErrorBundle.Wip = undefined;
    try wip_errors.init(gpa);
    defer wip_errors.deinit();

    try k.putAstErrorsIntoBundle(tree, path, &wip_errors);

    var error_bundle = try wip_errors.toOwnedBundle("");
    defer error_bundle.deinit(gpa);
    try error_bundle.renderToStderr(io, .{}, color);
}

test {
    std.testing.refAllDecls(@This());
}
