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
                const value = vm.initValue(.{ .list = &[_]*Value{} });
                const dictionary = ValueDictionary.init(.{ .key = x.ref(), .value = value }, vm.allocator);
                break :blk vm.initValue(.{ .dictionary = dictionary });
            }

            var key_hash_map = std.ArrayHashMap(*Value, *std.ArrayList(*Value), ValueHashMapContext, false).init(vm.allocator);

            for (list_x, 0..) |k, i| {
                if (key_hash_map.get(k)) |*list| {
                    list.*.append(vm.initValue(.{ .int = @intCast(i64, i) })) catch std.debug.panic("Failed to append item.", .{});
                } else {
                    const list = vm.allocator.create(std.ArrayList(*Value)) catch std.debug.panic("Failed to create list.", .{});
                    list.* = std.ArrayList(*Value).init(vm.allocator);
                    list.*.append(vm.initValue(.{ .int = @intCast(i64, i) })) catch std.debug.panic("Failed to append item.", .{});
                    key_hash_map.put(k.ref(), list) catch std.debug.panic("Failed to put item.", .{});
                }
            }

            const key_slice = key_hash_map.keys();
            const key = vm.initList(key_slice, x.as);
            const list = vm.allocator.alloc(*Value, key_slice.len) catch std.debug.panic("Failed to create list.", .{});
            for (key_hash_map.values(), 0..) |array_list, i| {
                const slice = array_list.toOwnedSlice() catch std.debug.panic("Failed to create list.", .{});
                list[i] = vm.initList(slice, .int);
                vm.allocator.destroy(array_list);
            }
            const value = vm.initValue(.{ .list = list });
            const dictionary = ValueDictionary.init(.{ .key = key, .value = value }, vm.allocator);
            break :blk vm.initValue(.{ .dictionary = dictionary });
        },
        .dictionary => |dict_x| blk: {
            if (dict_x.key.asList().len == 0) {
                const value = vm.initValue(.{ .list = &[_]*Value{} });
                const dictionary = ValueDictionary.init(.{ .key = dict_x.value.ref(), .value = value }, vm.allocator);
                break :blk vm.initValue(.{ .dictionary = dictionary });
            }

            var key_hash_map = std.ArrayHashMap(*Value, *std.ArrayList(*Value), ValueHashMapContext, false).init(vm.allocator);

            for (dict_x.value.asList(), dict_x.key.asList()) |k, v| {
                if (key_hash_map.get(k)) |*list| {
                    list.*.append(v.ref()) catch std.debug.panic("Failed to append item.", .{});
                } else {
                    const list = vm.allocator.create(std.ArrayList(*Value)) catch std.debug.panic("Failed to create list.", .{});
                    list.* = std.ArrayList(*Value).init(vm.allocator);
                    list.*.append(v.ref()) catch std.debug.panic("Failed to append item.", .{});
                    key_hash_map.put(k.ref(), list) catch std.debug.panic("Failed to put item.", .{});
                }
            }

            const key_slice = key_hash_map.keys();
            const key = vm.initList(key_slice, dict_x.value.as);
            const list = vm.allocator.alloc(*Value, key_slice.len) catch std.debug.panic("Failed to create list.", .{});
            for (key_hash_map.values(), 0..) |array_list, i| {
                const slice = array_list.toOwnedSlice() catch std.debug.panic("Failed to create list.", .{});
                list[i] = vm.initList(slice, dict_x.key.as);
                vm.allocator.destroy(array_list);
            }
            const value = vm.initValue(.{ .list = list });
            const dictionary = ValueDictionary.init(.{ .key = key, .value = value }, vm.allocator);
            break :blk vm.initValue(.{ .dictionary = dictionary });
        },
        .table => |table_x| blk: {
            const table_len = table_x.values.asList()[0].asList().len;
            if (table_len == 0) {
                const key = x.ref();
                const value = vm.initValue(.{ .list = &[_]*Value{} });
                const dictionary = ValueDictionary.init(.{ .key = key, .value = value }, vm.allocator);
                break :blk vm.initValue(.{ .dictionary = dictionary });
            }

            var key_hash_map = std.ArrayHashMap([]*Value, *std.ArrayList(*Value), ValueSliceHashMapContext, false).init(vm.allocator);

            var i: usize = 0;
            while (i < table_len) : (i += 1) {
                const k = vm.allocator.alloc(*Value, table_x.columns.as.symbol_list.len) catch std.debug.panic("Failed to create list.", .{});
                for (table_x.values.asList(), 0..) |c, j| {
                    k[j] = c.asList()[i];
                }

                if (key_hash_map.get(k)) |*list| {
                    vm.allocator.free(k);
                    list.*.append(vm.initValue(.{ .int = @intCast(i64, i) })) catch std.debug.panic("Failed to append item.", .{});
                } else {
                    for (k) |v| _ = v.ref();
                    const list = vm.allocator.create(std.ArrayList(*Value)) catch std.debug.panic("Failed to create list.", .{});
                    list.* = std.ArrayList(*Value).init(vm.allocator);
                    list.*.append(vm.initValue(.{ .int = @intCast(i64, i) })) catch std.debug.panic("Failed to append item.", .{});
                    key_hash_map.put(k, list) catch std.debug.panic("Failed to put item.", .{});
                }
            }

            const key_slice = key_hash_map.keys();
            defer vm.allocator.free(key_slice);
            defer for (key_slice) |v| vm.allocator.free(v);
            const key_list = vm.allocator.alloc(*Value, key_slice[0].len) catch std.debug.panic("Failed to create list.", .{});
            i = 0;
            while (i < key_slice[0].len) : (i += 1) {
                const list = vm.allocator.alloc(*Value, key_slice.len) catch std.debug.panic("Failed to create list.", .{});
                for (key_slice, 0..) |v, j| {
                    list[j] = v[i];
                }
                key_list[i] = vm.initValue(.{ .int_list = list });
            }

            const values = vm.initValue(.{ .list = key_list });
            const table = ValueTable.init(.{ .columns = table_x.columns.ref(), .values = values }, vm.allocator);
            const key = vm.initValue(.{ .table = table });

            const value_list = vm.allocator.alloc(*Value, key_slice.len) catch std.debug.panic("Failed to create list.", .{});
            for (key_hash_map.values(), 0..) |array_list, j| {
                const slice = array_list.toOwnedSlice() catch std.debug.panic("Failed to create list.", .{});
                value_list[j] = vm.initList(slice, .int);
                vm.allocator.destroy(array_list);
            }
            const value = vm.initValue(.{ .list = value_list });
            const dictionary = ValueDictionary.init(.{ .key = key, .value = value }, vm.allocator);
            break :blk vm.initValue(.{ .dictionary = dictionary });
        },
        else => runtimeError(GroupError.invalid_type),
    };
}
