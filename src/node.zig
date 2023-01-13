const std = @import("std");

const chunk_mod = @import("chunk.zig");
const OpCode = chunk_mod.OpCode;

const compiler_mod = @import("compiler.zig");

const scanner_mod = @import("scanner.zig");
const Token = scanner_mod.Token;

const utils_mod = @import("utils.zig");
const print = utils_mod.print;

pub const Node = struct {
    const Self = @This();

    const Config = struct {
        op_code: OpCode,
        byte: ?u8 = null,
        name: ?Token = null,
    };

    op_code: OpCode,
    byte: ?u8,
    name: ?Token, // Used for variable resolution
    lhs: ?*Node = null,
    rhs: ?*Node = null,

    pub fn init(config: Config, allocator: std.mem.Allocator) *Self {
        var self = allocator.create(Self) catch std.debug.panic("Failed to create Node", .{});
        self.* = Self{
            .op_code = config.op_code,
            .byte = config.byte,
            .name = config.name,
        };
        return self;
    }

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("Node{{ .op_code = {}", .{self.op_code});
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
        if (self.name) |name| self.resolveVariable(name);
        compiler_mod.emitInstruction(self.op_code);
        if (self.byte) |byte| compiler_mod.emitByte(byte);
    }

    fn resolveVariable(self: *Self, name: Token) void {
        switch (self.op_code) {
            .op_get_global => {
                var arg = compiler_mod.resolveLocal(name);
                if (arg) |byte| {
                    self.op_code = .op_get_local;
                    self.byte = byte;
                } else {
                    self.byte = compiler_mod.identifierConstant(name);
                }
            },
            else => unreachable,
        }
    }
};
