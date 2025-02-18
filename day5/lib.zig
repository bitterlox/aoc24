const std = @import("std");
const testing = std.testing;

test "Rules.init - test" {
    const slice: []const [2]u64 = &[_][2]u64{.{ 47, 53 }};
    var rules = try Rules.init(testing.allocator, slice);
    defer rules.deinit();

    try testing.expectEqual({}, rules.map.get(47).?.before.get(53).?);
}
const ordering_rules_for_tests: []const [2]u64 = &[_][2]u64{
    .{ 47, 53 },
    .{ 97, 13 },
    .{ 97, 61 },
    .{ 97, 47 },
    .{ 75, 29 },
    .{ 61, 13 },
    .{ 75, 53 },
    .{ 29, 13 },
    .{ 97, 29 },
    .{ 53, 29 },
    .{ 61, 53 },
    .{ 97, 53 },
    .{ 61, 29 },
    .{ 47, 13 },
    .{ 75, 47 },
    .{ 97, 75 },
    .{ 47, 61 },
    .{ 75, 61 },
    .{ 47, 29 },
    .{ 75, 13 },
    .{ 53, 13 },
};

test "Rules.init - example" {
    var rules = try Rules.init(testing.allocator, ordering_rules_for_tests);
    defer rules.deinit();

    const tests = [_]struct { param: []const u64, expected: bool }{
        .{ .param = &[_]u64{ 75, 47, 61, 53, 29 }, .expected = true },
        .{ .param = &[_]u64{ 97, 61, 53, 29, 13 }, .expected = true },
        .{ .param = &[_]u64{ 75, 29, 13 }, .expected = true },
        .{ .param = &[_]u64{ 75, 97, 47, 61, 53 }, .expected = false },
        .{ .param = &[_]u64{ 61, 13, 29 }, .expected = false },
        .{ .param = &[_]u64{ 97, 13, 75, 29, 47 }, .expected = false },
    };

    try testing.expectEqual(tests[0].expected, rules.is_in_order(tests[0].param));
    try testing.expectEqual(tests[1].expected, rules.is_in_order(tests[1].param));
    try testing.expectEqual(tests[2].expected, rules.is_in_order(tests[2].param));
    try testing.expectEqual(tests[3].expected, rules.is_in_order(tests[3].param));
    try testing.expectEqual(tests[4].expected, rules.is_in_order(tests[4].param));
    try testing.expectEqual(tests[5].expected, rules.is_in_order(tests[5].param));
}

/// caller takes ownership of memory
pub const Rules = struct {
    map: std.AutoHashMap(u64, Ordering),
    allocator: std.mem.Allocator,

    const Self = @This();
    const Ordering = struct { before: *std.AutoHashMap(u64, void), after: *std.AutoHashMap(u64, void) };
    const Set = std.AutoHashMap(u64, void);

    pub fn init(allocator: std.mem.Allocator, rules_slice: []const [2]u64) !Self {
        var map = std.AutoHashMap(u64, Ordering).init(allocator);
        errdefer map.deinit();

        // try map.ensureTotalCapacity(@intCast(rules_slice.len * 2));

        for (rules_slice) |arr| {
            const should_be_before = arr[0];
            const should_be_after = arr[1];

            // here is the reason for the memory leak: when we call putNoClobber
            // at some point we need to grow the map, but doing so renders the pointer
            // for before invalid
            // https://github.com/ziglang/zig/issues/18198
            if (map.get(should_be_before)) |set| {
                try set.before.putNoClobber(should_be_after, {});
            } else {
                const before_set: *Set = try allocator.create(Set);
                before_set.* = Set.init(allocator);
                const after_set: *Set = try allocator.create(Set);
                after_set.* = Set.init(allocator);
                errdefer {
                    before_set.deinit();
                    allocator.destroy(before_set);
                    after_set.deinit();
                    allocator.destroy(after_set);
                }
                try before_set.putNoClobber(should_be_after, {});
                try map.putNoClobber(should_be_before, .{ .before = before_set, .after = after_set });
            }

            if (map.get(should_be_after)) |set| {
                try set.after.putNoClobber(should_be_before, {});
            } else {
                const before_set: *Set = try allocator.create(Set);
                before_set.* = Set.init(allocator);
                const after_set: *Set = try allocator.create(Set);
                after_set.* = Set.init(allocator);
                errdefer {
                    before_set.deinit();
                    allocator.destroy(before_set);
                    after_set.deinit();
                    allocator.destroy(after_set);
                }
                try after_set.putNoClobber(should_be_before, {});
                try map.putNoClobber(should_be_after, .{ .before = before_set, .after = after_set });
            }
        }

        return Self{
            .map = map,
            .allocator = allocator,
        };
    }

    pub fn is_in_order(self: *Self, page_numbers: []const u64) !bool {
        for (page_numbers, 0..) |number, idx| {
            // std.debug.print("{d} ", .{number});

            if (self.map.get(number)) |map| {
                const rest = page_numbers[idx + 1 ..];

                for (rest) |other| {
                    const other_should_be_after = map.before.contains(other);
                    if (!other_should_be_after) return false;
                }
            }
        }

        const reversed = try self.allocator.alloc(u64, page_numbers.len);
        defer self.allocator.free(reversed);
        @memcpy(reversed, page_numbers);

        std.mem.reverse(u64, reversed);

        // std.debug.print("{d}\n", .{reversed});

        for (reversed, 0..) |number, idx| {
            // std.debug.print("{d}\n", .{number});
            if (self.map.get(number)) |map| {
                const rest = reversed[idx + 1 ..];

                for (rest) |other| {
                    const other_should_be_before = map.after.contains(other);
                    // std.debug.print("{d} {any}\n", .{ other, other_should_be_before });
                    if (!other_should_be_before) return false;
                }
            }
        }
        // std.debug.print("\n", .{});

        return true;
    }

    pub fn deinit(self: *Self) void {
        var it = self.map.iterator();
        while (it.next()) |entry| {
            entry.value_ptr.before.deinit();
            self.allocator.destroy(entry.value_ptr.before);
            entry.value_ptr.*.after.deinit();
            self.allocator.destroy(entry.value_ptr.after);
        }
        self.map.deinit();
    }
};
