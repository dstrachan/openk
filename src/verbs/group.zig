const std = @import("std");

const utils_mod = @import("../utils.zig");
const print = utils_mod.print;

const value_mod = @import("../value.zig");
const Value = value_mod.Value;
const ValueDictionary = value_mod.ValueDictionary;
const ValueHashMapContext = value_mod.ValueHashMapContext;
const ValueSliceHashMapContext = value_mod.ValueSliceHashMapContext;
const ValueTable = value_mod.ValueTable;
const ValueType = value_mod.ValueType;

const vm_mod = @import("../vm.zig");
const VM = vm_mod.VM;

pub const GroupError = error{
    invalid_type,
};

fn runtimeError(comptime err: GroupError) GroupError!*Value {
    switch (err) {
        GroupError.invalid_type => print("Can only group lists values.\n", .{}),
    }
    return err;
}

pub fn group(vm: *VM, x: *Value) GroupError!*Value {
    return switch (x.as) {
        .list, .boolean_list, .int_list, .float_list, .char_list, .symbol_list => |list_x| blk: {
            if (list_x.len == 0) {
                const value = vm.initValue(.{ .list = &.{} });
                break :blk vm.initDictionary(.{ .keys = x.ref(), .values = value });
            }

            var hash_map = std.ArrayHashMap(*Value, *std.ArrayList(*Value), ValueHashMapContext, false).init(vm.allocator);
            defer hash_map.deinit();

            for (list_x, 0..) |k, i| {
                if (hash_map.get(k)) |*list| {
                    list.*.append(vm.initValue(.{ .int = @intCast(i64, i) })) catch std.debug.panic("Failed to append item.", .{});
                } else {
                    const list = vm.allocator.create(std.ArrayList(*Value)) catch std.debug.panic("Failed to create list.", .{});
                    list.* = std.ArrayList(*Value).init(vm.allocator);
                    list.*.append(vm.initValue(.{ .int = @intCast(i64, i) })) catch std.debug.panic("Failed to append item.", .{});
                    hash_map.put(k.ref(), list) catch std.debug.panic("Failed to put item.", .{});
                }
            }

            const keys_list = vm.allocator.dupe(*Value, hash_map.keys()) catch std.debug.panic("Failed to create list.", .{});
            const keys = vm.initList(keys_list, x.as);
            const values_list = vm.allocator.alloc(*Value, keys_list.len) catch std.debug.panic("Failed to create list.", .{});
            for (hash_map.values(), 0..) |array_list, i| {
                const slice = array_list.toOwnedSlice() catch std.debug.panic("Failed to create list.", .{});
                values_list[i] = vm.initList(slice, .int);
                vm.allocator.destroy(array_list);
            }
            const values = vm.initValue(.{ .list = values_list });
            break :blk vm.initDictionary(.{ .keys = keys, .values = values });
        },
        .dictionary => |dict_x| blk: {
            if (dict_x.keys.asList().len == 0) {
                const value = vm.initValue(.{ .list = &.{} });
                break :blk vm.initDictionary(.{ .keys = dict_x.values.ref(), .values = value });
            }

            var hash_map = std.ArrayHashMap(*Value, *std.ArrayList(*Value), ValueHashMapContext, false).init(vm.allocator);
            defer hash_map.deinit();

            for (dict_x.values.asList(), dict_x.keys.asList()) |k, v| {
                if (hash_map.get(k)) |*list| {
                    list.*.append(v.ref()) catch std.debug.panic("Failed to append item.", .{});
                } else {
                    const list = vm.allocator.create(std.ArrayList(*Value)) catch std.debug.panic("Failed to create list.", .{});
                    list.* = std.ArrayList(*Value).init(vm.allocator);
                    list.*.append(v.ref()) catch std.debug.panic("Failed to append item.", .{});
                    hash_map.put(k.ref(), list) catch std.debug.panic("Failed to put item.", .{});
                }
            }

            const keys_list = vm.allocator.dupe(*Value, hash_map.keys()) catch std.debug.panic("Failed to create list.", .{});
            const keys = vm.initList(keys_list, dict_x.values.as);
            const values_list = vm.allocator.alloc(*Value, keys_list.len) catch std.debug.panic("Failed to create list.", .{});
            for (hash_map.values(), 0..) |array_list, i| {
                const slice = array_list.toOwnedSlice() catch std.debug.panic("Failed to create list.", .{});
                values_list[i] = vm.initList(slice, dict_x.keys.as);
                vm.allocator.destroy(array_list);
            }
            const values = vm.initValue(.{ .list = values_list });
            break :blk vm.initDictionary(.{ .keys = keys, .values = values });
        },
        .table => |table_x| blk: {
            const table_len = table_x.values.asList()[0].asList().len;
            if (table_len == 0) {
                const key = x.ref();
                const value = vm.initValue(.{ .list = &.{} });
                break :blk vm.initDictionary(.{ .keys = key, .values = value });
            }

            var hash_map = std.ArrayHashMap([]*Value, *std.ArrayList(*Value), ValueSliceHashMapContext, false).init(vm.allocator);
            defer hash_map.deinit();

            var i: usize = 0;
            while (i < table_len) : (i += 1) {
                const k = vm.allocator.alloc(*Value, table_x.columns.as.symbol_list.len) catch std.debug.panic("Failed to create list.", .{});
                for (table_x.values.asList(), 0..) |c, j| {
                    k[j] = c.asList()[i];
                }

                if (hash_map.get(k)) |*list| {
                    vm.allocator.free(k);
                    list.*.append(vm.initValue(.{ .int = @intCast(i64, i) })) catch std.debug.panic("Failed to append item.", .{});
                } else {
                    for (k) |v| _ = v.ref();
                    const list = vm.allocator.create(std.ArrayList(*Value)) catch std.debug.panic("Failed to create list.", .{});
                    list.* = std.ArrayList(*Value).init(vm.allocator);
                    list.*.append(vm.initValue(.{ .int = @intCast(i64, i) })) catch std.debug.panic("Failed to append item.", .{});
                    hash_map.put(k, list) catch std.debug.panic("Failed to put item.", .{});
                }
            }

            const keys_slice = hash_map.keys();
            defer for (keys_slice) |v| vm.allocator.free(v);
            const keys_list = vm.allocator.alloc(*Value, keys_slice[0].len) catch std.debug.panic("Failed to create list.", .{});
            i = 0;
            while (i < keys_slice[0].len) : (i += 1) {
                const list = vm.allocator.alloc(*Value, keys_slice.len) catch std.debug.panic("Failed to create list.", .{});
                for (keys_slice, 0..) |v, j| {
                    list[j] = v[i];
                }
                keys_list[i] = vm.initValue(.{ .int_list = list });
            }
            const keys = vm.initTable(.{ .columns = table_x.columns.ref(), .values = vm.initValue(.{ .list = keys_list }) });

            const values_list = vm.allocator.alloc(*Value, keys_slice.len) catch std.debug.panic("Failed to create list.", .{});
            for (hash_map.values(), 0..) |array_list, j| {
                const slice = array_list.toOwnedSlice() catch std.debug.panic("Failed to create list.", .{});
                values_list[j] = vm.initList(slice, .int);
                vm.allocator.destroy(array_list);
            }
            const values = vm.initValue(.{ .list = values_list });
            break :blk vm.initDictionary(.{ .keys = keys, .values = values });
        },
        else => runtimeError(GroupError.invalid_type),
    };
}
