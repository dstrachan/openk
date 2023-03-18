const std = @import("std");

const utils_mod = @import("../utils.zig");
const print = utils_mod.print;

const value_mod = @import("../value.zig");
const Value = value_mod.Value;
const ValueDictionary = value_mod.ValueDictionary;
const ValueTable = value_mod.ValueTable;
const ValueType = value_mod.ValueType;

const vm_mod = @import("../vm.zig");
const VM = vm_mod.VM;

pub const AscendError = error{
    invalid_type,
};

fn runtimeError(comptime err: AscendError) AscendError!*Value {
    switch (err) {
        AscendError.invalid_type => print("Can only ascend lists values.\n", .{}),
    }
    return err;
}

fn asc(a: *Value, b: *Value) bool {
    return switch (a.as) {
        .boolean => |bool_a| switch (b.as) {
            .boolean => |bool_b| @boolToInt(bool_a) < @boolToInt(bool_b),
            else => true,
        },
        .int => |int_a| switch (b.as) {
            .boolean => false,
            .int => |int_b| int_a < int_b,
            else => true,
        },
        .float => |float_a| switch (b.as) {
            .boolean, .int => false,
            .float => |float_b| float_a < float_b,
            else => true,
        },
        .char => |char_a| switch (b.as) {
            .boolean, .int, .float => false,
            .char => |char_b| char_a < char_b,
            else => true,
        },
        .symbol => |symbol_a| switch (b.as) {
            .boolean, .int, .float, .char => false,
            .symbol => |symbol_b| std.mem.order(u8, symbol_a, symbol_b) == .lt,
            else => true,
        },
        .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list_a| switch (b.as) {
            .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list_b| blk: {
                if (@as(ValueType, a.as) != b.as) break :blk @enumToInt(a.as) < @enumToInt(b.as);

                const len = std.math.min(list_a.len, list_b.len);

                var i: usize = 0;
                while (i < len) : (i += 1) {
                    if (list_a[i].eql(list_b[i])) continue;
                    break :blk asc(list_a[i], list_b[i]);
                }

                break :blk list_a.len < list_b.len;
            },
            else => @enumToInt(a.as) < @enumToInt(b.as),
        },
        else => unreachable,
    };
}

const Pair = struct {
    value: *Value,
    index: *Value = undefined,
};

const PairContext = struct {
    values: []*Value,

    pub fn lessThan(ctx: @This(), a_index: usize, b_index: usize) bool {
        return asc(ctx.values[a_index], ctx.values[b_index]);
    }
};

pub fn ascend(vm: *VM, x: *Value) AscendError!*Value {
    return switch (x.as) {
        .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list_x| blk: {
            if (list_x.len == 0) break :blk vm.initValue(.{ .int_list = &.{} });

            var list = std.MultiArrayList(Pair){};
            defer list.deinit(vm.allocator);

            list.ensureTotalCapacity(vm.allocator, list_x.len) catch std.debug.panic("Failed to create list.", .{});
            for (list_x, 0..) |v, i| {
                list.appendAssumeCapacity(.{
                    .value = v,
                    .index = vm.initValue(.{ .int = @intCast(i64, i) }),
                });
            }
            list.sort(PairContext{ .values = list.items(.value) });
            break :blk vm.initValue(.{ .int_list = list.toOwnedSlice().items(.index) });
        },
        .dictionary => |dict_x| blk: {
            if (dict_x.keys.asList().len == 0) break :blk dict_x.keys.ref();

            var list = std.MultiArrayList(Pair){};
            defer list.deinit(vm.allocator);

            list.ensureTotalCapacity(vm.allocator, dict_x.keys.asList().len) catch std.debug.panic("Failed to create list.", .{});
            for (dict_x.keys.asList(), dict_x.values.asList()) |k, v| {
                list.appendAssumeCapacity(.{
                    .value = v,
                    .index = k.ref(),
                });
            }
            list.sort(PairContext{ .values = list.items(.value) });
            break :blk vm.initList(list.toOwnedSlice().items(.index), dict_x.keys.as);
        },
        .table => |table_x| blk: {
            const len = table_x.values.as.list[0].asList().len;
            if (len == 0) break :blk vm.initValue(.{ .int_list = &.{} });

            var list = std.MultiArrayList(Pair){};
            defer list.deinit(vm.allocator);

            list.ensureTotalCapacity(vm.allocator, len) catch std.debug.panic("Failed to create list.", .{});
            var i: usize = 0;
            while (i < len) : (i += 1) {
                const temp_list = vm.allocator.alloc(*Value, table_x.columns.as.symbol_list.len) catch std.debug.panic("Failed to create list.", .{});
                for (temp_list, 0..) |*v, j| {
                    v.* = table_x.values.as.list[j].asList()[i].ref();
                }
                const value = vm.initValue(.{ .list = temp_list });
                list.appendAssumeCapacity(.{
                    .value = value,
                    .index = vm.initValue(.{ .int = @intCast(i64, i) }),
                });
            }
            list.sort(PairContext{ .values = list.items(.value) });
            const slice = list.toOwnedSlice();
            for (slice.items(.value)) |v| {
                v.deref(vm.allocator);
            }
            break :blk vm.initValue(.{ .int_list = slice.items(.index) });
        },
        else => runtimeError(AscendError.invalid_type),
    };
}
