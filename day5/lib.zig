const std = @import("std");
const testing = std.testing;

test "parse - example 1" {}

/// caller takes ownership of memory
const Rules = struct {
    map: std.AutoHashMap(u64, [2]std.ArrayList(u64)),
    allocator: std.mem.Allocator,

    const Self = @This();

    fn init(allocator: std.mem.Allocator, rules_slice: [][2]64) Self {
        const map = std.AutoHashMap(u64, [2]std.ArrayList(u64)).init(allocator);

        for (rules_slice) |arr| {
            const elem = map.get(arr[0]);

            if (elem) |arr_2| {
                arr_2[0].append(arr[0]);
                arr_2[1].append(arr[1]);
            } else {
                map.put(arr, value: V)
            }
        }

        return Self{
            .map = map,
            .allocator = allocator,
        };
    }

    fn deinit(self: Self) void {
        var it = self.map.iterator();
        while (it.next()) |arr| {
            self.allocator.free(arr[0]);
            self.allocator.free(arr[1]);
        }
        self.map.deinit();
    }
};
