const std = @import("std");

const chunk_mod = @import("chunk.zig");
const OpCode = chunk_mod.OpCode;

const compiler_mod = @import("compiler.zig");

const scanner_mod = @import("scanner.zig");
const Token = scanner_mod.Token;

pub const Node = struct {
    const Self = @This();

    const Config = struct {
        op_code: OpCode,
        byte: ?u8 = null,
    };

    op_code: OpCode,
    byte: ?u8,
    lhs: ?*Node,
    rhs: ?*Node,

    pub fn init(config: Config, allocator: std.mem.Allocator) *Self {
        var self = allocator.create(Self) catch @panic("ALLOC");
        self.op_code = config.op_code;
        self.byte = config.byte;
        self.lhs = null;
        self.rhs = null;
        return self;
    }

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("Node{{ .op_code = {}", .{self.op_code});
        if (self.byte) |byte| try writer.print(", .byte = {d}", .{byte});
        if (self.lhs) |lhs| try writer.print(", .lhs = {}", .{lhs});
        if (self.rhs) |rhs| try writer.print(", .rhs = {}", .{rhs});
        try writer.writeAll(" }");
    }

    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        if (self.lhs) |lhs| lhs.deinit(allocator);
        if (self.rhs) |rhs| rhs.deinit(allocator);
        allocator.destroy(self);
    }

    pub fn traverse(self: *Self) void {
        if (self.rhs) |rhs| traverse(rhs);
        if (self.lhs) |lhs| traverse(lhs);
        compiler_mod.emitInstruction(self.op_code);
        if (self.byte) |byte| compiler_mod.emitByte(byte);
    }
};
