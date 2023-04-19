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

pub const DescendError = error{
    invalid_type,
};

fn runtimeError(comptime err: DescendError) DescendError!*Value {
    switch (err) {
        DescendError.invalid_type => print("Can only descend lists values.\n", .{}),
    }
    return err;
}

fn desc(a: *Value, b: *Value) bool {
    return switch (a.as) {
        .boolean => |bool_a| switch (b.as) {
            .boolean => |bool_b| @boolToInt(bool_a) > @boolToInt(bool_b),
            else => false,
        },
        .int => |int_a| switch (b.as) {
            .boolean => true,
            .int => |int_b| int_a > int_b,
            else => false,
        },
        .float => |float_a| switch (b.as) {
            .boolean, .int => true,
            .float => |float_b| float_a > float_b,
            else => false,
        },
        .char => |char_a| switch (b.as) {
            .boolean, .int, .float => true,
            .char => |char_b| char_a > char_b,
            else => false,
        },
        .symbol => |symbol_a| switch (b.as) {
            .boolean, .int, .float, .char => true,
            .symbol => |symbol_b| std.mem.order(u8, symbol_a, symbol_b) == .gt,
            else => false,
        },
        .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list_a| switch (b.as) {
            .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list_b| blk: {
                if (@as(ValueType, a.as) != b.as) break :blk @enumToInt(a.as) > @enumToInt(b.as);

                const len = std.math.min(list_a.len, list_b.len);

                var i: usize = 0;
                while (i < len) : (i += 1) {
                    if (list_a[i].eql(list_b[i])) continue;
                    break :blk desc(list_a[i], list_b[i]);
                }

                break :blk list_a.len > list_b.len;
            },
            else => @enumToInt(a.as) > @enumToInt(b.as),
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
        return desc(ctx.values[a_index], ctx.values[b_index]);
    }
};

pub fn descend(vm: *VM, x: *Value) DescendError!*Value {
    return switch (x.as) {
        .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list_x| blk: {
            if (list_x.len == 0) break :blk vm.initValue(.{ .int_list = &.{} });

            var multi_list = std.MultiArrayList(Pair){};
            defer multi_list.deinit(vm.allocator);

            multi_list.ensureTotalCapacity(vm.allocator, list_x.len) catch std.debug.panic("Failed to create list.", .{});
            for (list_x, 0..) |v, i| {
                multi_list.appendAssumeCapacity(.{
                    .value = v,
                    .index = vm.initValue(.{ .int = @intCast(i64, i) }),
                });
            }
            const slice = multi_list.slice();
            multi_list.sort(PairContext{ .values = slice.items(.value) });
            const list = vm.allocator.dupe(*Value, slice.items(.index)) catch std.debug.panic("Failed to create list.", .{});
            break :blk vm.initValue(.{ .int_list = list });
        },
        .dictionary => |dict_x| blk: {
            if (dict_x.keys.asList().len == 0) break :blk dict_x.keys.ref();

            var multi_list = std.MultiArrayList(Pair){};
            defer multi_list.deinit(vm.allocator);

            multi_list.ensureTotalCapacity(vm.allocator, dict_x.keys.asList().len) catch std.debug.panic("Failed to create list.", .{});
            for (dict_x.keys.asList(), dict_x.values.asList()) |k, v| {
                multi_list.appendAssumeCapacity(.{
                    .value = v,
                    .index = k.ref(),
                });
            }
            const slice = multi_list.slice();
            multi_list.sort(PairContext{ .values = slice.items(.value) });
            const list = vm.allocator.dupe(*Value, slice.items(.index)) catch std.debug.panic("Failed to create list.", .{});
            break :blk vm.initList(list, dict_x.keys.as);
        },
        .table => |table_x| blk: {
            const len = table_x.values.as.list[0].asList().len;
            if (len == 0) break :blk vm.initValue(.{ .int_list = &.{} });

            var multi_list = std.MultiArrayList(Pair){};
            defer multi_list.deinit(vm.allocator);

            multi_list.ensureTotalCapacity(vm.allocator, len) catch std.debug.panic("Failed to create list.", .{});
            var i: usize = 0;
            while (i < len) : (i += 1) {
                const temp_list = vm.allocator.alloc(*Value, table_x.columns.as.symbol_list.len) catch std.debug.panic("Failed to create list.", .{});
                for (temp_list, 0..) |*v, j| {
                    v.* = table_x.values.as.list[j].asList()[i].ref();
                }
                const value = vm.initValue(.{ .list = temp_list });
                multi_list.appendAssumeCapacity(.{
                    .value = value,
                    .index = vm.initValue(.{ .int = @intCast(i64, i) }),
                });
            }
            const slice = multi_list.slice();
            multi_list.sort(PairContext{ .values = slice.items(.value) });
            for (slice.items(.value)) |v| {
                v.deref(vm.allocator);
            }
            const list = vm.allocator.dupe(*Value, slice.items(.index)) catch std.debug.panic("Failed to create list.", .{});
            break :blk vm.initValue(.{ .int_list = list });
        },
        else => runtimeError(DescendError.invalid_type),
    };
}
