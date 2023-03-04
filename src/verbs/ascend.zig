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

fn asc(context: void, a: Pair, b: Pair) bool {
    _ = context;
    return switch (a.value.as) {
        .boolean => |bool_a| switch (b.value.as) {
            .boolean => |bool_b| @boolToInt(bool_a) < @boolToInt(bool_b),
            else => true,
        },
        .int => |int_a| switch (b.value.as) {
            .boolean => false,
            .int => |int_b| int_a < int_b,
            else => true,
        },
        .float => |float_a| switch (b.value.as) {
            .boolean, .int => false,
            .float => |float_b| float_a < float_b,
            else => true,
        },
        .char => |char_a| switch (b.value.as) {
            .boolean, .int, .float => false,
            .char => |char_b| char_a < char_b,
            else => true,
        },
        .symbol => |symbol_a| switch (b.value.as) {
            .boolean, .int, .float, .char => false,
            .symbol => |symbol_b| std.mem.lessThan(u8, symbol_a, symbol_b),
            else => true,
        },
        .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list_a| switch (b.value.as) {
            .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list_b| blk: {
                if (@as(ValueType, a.value.as) != b.value.as) break :blk @enumToInt(a.value.as) < @enumToInt(b.value.as);

                const len = std.math.min(list_a.len, list_b.len);

                var i: usize = 0;
                while (i < len) : (i += 1) {
                    if (list_a[i].eql(list_b[i])) continue;
                    break :blk asc({}, .{ .value = list_a[i] }, .{ .value = list_b[i] });
                }

                break :blk list_a.len < list_b.len;
            },
            else => @enumToInt(a.value.as) < @enumToInt(b.value.as),
        },
        else => unreachable,
    };
}

const Pair = struct {
    value: *Value,
    index: *Value = undefined,
};

pub fn ascend(vm: *VM, x: *Value) AscendError!*Value {
    return switch (x.as) {
        .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list_x| blk: {
            if (list_x.len == 0) break :blk vm.initValue(.{ .int_list = &[_]*Value{} });

            const pairs = vm.allocator.alloc(Pair, list_x.len) catch std.debug.panic("Failed to create list.", .{});
            defer vm.allocator.free(pairs);
            for (list_x, 0..) |v, i| {
                pairs[i] = .{
                    .value = v,
                    .index = vm.initValue(.{ .int = @intCast(i64, i) }),
                };
            }
            std.sort.sort(Pair, pairs, {}, asc);
            const list = vm.allocator.alloc(*Value, pairs.len) catch std.debug.panic("Failed to create list.", .{});
            for (pairs, 0..) |p, i| {
                list[i] = p.index;
            }
            break :blk vm.initValue(.{ .int_list = list });
        },
        .dictionary => |dict_x| blk: {
            if (dict_x.key.asList().len == 0) break :blk dict_x.key.ref();

            const pairs = vm.allocator.alloc(Pair, dict_x.key.asList().len) catch std.debug.panic("Failed to create list.", .{});
            defer vm.allocator.free(pairs);
            for (dict_x.value.asList(), 0..) |v, i| {
                pairs[i] = .{
                    .value = v,
                    .index = dict_x.key.asList()[i].ref(),
                };
            }
            std.sort.sort(Pair, pairs, {}, asc);
            const list = vm.allocator.alloc(*Value, pairs.len) catch std.debug.panic("Failed to create list.", .{});
            for (pairs, 0..) |p, i| {
                list[i] = p.index;
            }
            break :blk vm.initList(list, dict_x.key.as);
        },
        .table => |table_x| blk: {
            const len = table_x.values.as.list[0].asList().len;
            if (len == 0) break :blk vm.initValue(.{ .int_list = &[_]*Value{} });

            const pairs = vm.allocator.alloc(Pair, len) catch std.debug.panic("Failed to create list.", .{});
            defer vm.allocator.free(pairs);
            var i: usize = 0;
            while (i < len) : (i += 1) {
                const list = vm.allocator.alloc(*Value, table_x.columns.as.symbol_list.len) catch std.debug.panic("Failed to create list.", .{});
                for (list, 0..) |*v, j| {
                    v.* = table_x.values.as.list[j].asList()[i].ref();
                }
                const value = vm.initValue(.{ .list = list });
                pairs[i] = .{
                    .value = value,
                    .index = vm.initValue(.{ .int = @intCast(i64, i) }),
                };
            }
            std.sort.sort(Pair, pairs, {}, asc);
            const list = vm.allocator.alloc(*Value, len) catch std.debug.panic("Failed to create list.", .{});
            for (pairs, 0..) |p, j| {
                p.value.deref(vm.allocator);
                list[j] = p.index;
            }
            break :blk vm.initValue(.{ .int_list = list });
        },
        else => runtimeError(AscendError.invalid_type),
    };
}
