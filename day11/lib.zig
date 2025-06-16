const std = @import("std");
const testing = std.testing;

// 1. If the stone is engraved with the number 0, it is replaced by a stone engraved with the number 1.
// 2. If the stone is engraved with a number that has an even number of digits, it is replaced by two stones.
//     The left half of the digits are engraved on the new left stone, and the right half of the digits are engraved on the new right stone.
//     (The new numbers don't keep extra leading zeroes: 1000 would become stones 10 and 0.)
// 3. If none of the other rules apply, the stone is replaced by a new stone; the old stone's number multiplied by 2024 is engraved on the new stone.

fn countDigits(n: u64) usize {
    if (n == 0) return 1;

    var count: usize = 0;
    var num = n;
    while (num > 0) {
        count += 1;
        num /= 10;
    }

    return count;
}

test "halveInt" {
    const i: u64 = 1234;
    const top, const bottom = halveInt(i, 4);

    try testing.expectEqual(12, top);
    try testing.expectEqual(34, bottom);
}

fn halveInt(i: u64, digitCount: usize) struct { u64, u64 } {
    const shiftDigitsBy = std.math.pow(u64, 10, digitCount / 2);

    // split out top half
    const top = i / shiftDigitsBy;

    // split out bottom half
    const bottom = i % shiftDigitsBy;

    return .{ top, bottom };
}

test "applyRulesToStone" {
    try testing.expectEqual(RulesApplicationResult{ .first = 1 }, applyRulesToStone(0));
    try testing.expectEqual(RulesApplicationResult{ .third = 2024 }, applyRulesToStone(1));
    try testing.expectEqual(RulesApplicationResult{ .second = .{ 1, 0 } }, applyRulesToStone(10));
    try testing.expectEqual(RulesApplicationResult{ .second = .{ 9, 9 } }, applyRulesToStone(99));
    try testing.expectEqual(RulesApplicationResult{ .third = 999 * 2024 }, applyRulesToStone(999));
}

fn applyRulesToStone(stone: u64) RulesApplicationResult {
    // first rule
    if (stone == 0) {
        return RulesApplicationResult{ .first = 1 };
    }

    // second rule
    const digitCount = countDigits(stone);
    if (digitCount % 2 == 0) {
        return RulesApplicationResult{ .second = halveInt(stone, digitCount) };
    }

    // third rule
    return RulesApplicationResult{ .third = stone * 2024 };
}

const RulesApplicationResult = union(enum) {
    first: u64,
    second: struct { u64, u64 },
    third: u64,
};

test "blinkCount - 1" {
    const listPtr = try testing.allocator.create(std.ArrayList(u64));
    defer testing.allocator.destroy(listPtr);

    const initData = try testing.allocator.dupe(u64, &[_]u64{ 125, 17 });
    listPtr.* = std.ArrayList(u64).fromOwnedSlice(testing.allocator, initData);
    defer listPtr.deinit();

    const actual = try blinkCount(listPtr, 6);

    try testing.expectEqual(22, actual);
}

test "blinkCount - 2" {
    const listPtr = try testing.allocator.create(std.ArrayList(u64));
    defer testing.allocator.destroy(listPtr);

    const initData = try testing.allocator.dupe(u64, &[_]u64{ 4022724, 951333, 0, 21633, 5857, 97, 702, 6 });
    listPtr.* = std.ArrayList(u64).fromOwnedSlice(testing.allocator, initData);
    defer listPtr.deinit();

    const actual = try blinkCount(listPtr, 25);

    try testing.expectEqual(211306, actual);
}

const CacheKey = struct { u64, usize };
const CacheValue = struct { *usize, *std.ArrayList(*usize) };

// without childmap, recomputing applyRulesToStone when counting
pub fn f(allocator: std.mem.Allocator, cache: *MemoCache, initialStone: u64, n: usize) !usize {
    var worklist = std.ArrayList(CacheKey).init(allocator);
    defer worklist.deinit();

    var visitedNodes = std.AutoHashMap(CacheKey, void).init(allocator);
    defer visitedNodes.deinit();

    try worklist.append(.{ initialStone, n });
    try visitedNodes.put(.{ initialStone, n }, {});

    // std.debug.print("len: {d}\n", .{worklist.items.len});

    //  idk whats going on here the optional cacheKey is not working
    while (worklist.getLastOrNull()) |parentKey| {
        // remove element we just retrieved from the map since .pop doesn't work
        _ = worklist.orderedRemove(worklist.items.len - 1);

        const stone, const blinkNo = parentKey;
        if (blinkNo == 0) continue;

        // std.debug.print("items: ", .{});
        // for (worklist.items) |item| std.debug.print("({d},{d}) ", .{ item.@"0", item.@"1" });
        // std.debug.print("\n", .{});

        const result = applyRulesToStone(stone);
        switch (result) {
            .first, .third => |newStone| {
                const childKey: CacheKey = .{ newStone, blinkNo - 1 };

                const putResult = try visitedNodes.getOrPut(childKey);
                if (!putResult.found_existing) try worklist.append(childKey);
            },
            .second => |newStones| {
                const upper, const lower = newStones;

                const upperChildKey: CacheKey = .{ upper, blinkNo - 1 };

                const putResult1 = try visitedNodes.getOrPut(upperChildKey);
                if (!putResult1.found_existing) try worklist.append(upperChildKey);

                const lowerChildKey: CacheKey = .{ lower, blinkNo - 1 };

                const putResult2 = try visitedNodes.getOrPut(lowerChildKey);
                if (!putResult2.found_existing) try worklist.append(lowerChildKey);
            },
        }
    }

    for (0..n + 1) |currentBlink| {
        var it = visitedNodes.iterator();
        innerWhile: while (it.next()) |entry| {
            const entryBlinkNo = entry.key_ptr.@"1";
            if (entryBlinkNo > 0) {
                if (entryBlinkNo != currentBlink) continue :innerWhile;
                const result = applyRulesToStone(entry.key_ptr.@"0");
                switch (result) {
                    .first, .third => |stone| {
                        const cachedStoneValue = cache.get(.{ stone, currentBlink - 1 });
                        try cache.put(entry.key_ptr.*, cachedStoneValue.?);
                    },
                    .second => |stones| {
                        const upper, const lower = stones;

                        const cachedUpperStoneValue = cache.get(.{ upper, currentBlink - 1 });
                        const cachedLowerStoneValue = cache.get(.{ lower, currentBlink - 1 });
                        try cache.put(entry.key_ptr.*, cachedUpperStoneValue.? + cachedLowerStoneValue.?);
                    },
                }
            } else {
                try cache.put(entry.key_ptr.*, 1);
            }
        }
    }

    return cache.get(.{ initialStone, n }).?;
}

// this should work but i don't have time to debug it
pub fn g(allocator: std.mem.Allocator, cache: *MemoCache, initialStone: u64, n: usize) !usize {
    var worklist = std.ArrayList(CacheKey).init(allocator);
    defer worklist.deinit();

    var visitedNodes = std.AutoHashMap(CacheKey, void).init(allocator);
    defer visitedNodes.deinit();
    var childMap = std.AutoHashMap(CacheKey, std.ArrayList(CacheKey)).init(allocator);
    defer {
        var it = childMap.iterator();
        while (it.next()) |entry| entry.value_ptr.deinit();
        childMap.deinit();
    }

    try worklist.append(.{ initialStone, n });
    try visitedNodes.put(.{ initialStone, n }, {});

    // std.debug.print("len: {d}\n", .{worklist.items.len});

    //  idk whats going on here the optional cacheKey is not working
    while (worklist.getLastOrNull()) |parentKey| {
        // remove element we just retrieved from the map since .pop doesn't work
        _ = worklist.orderedRemove(worklist.items.len - 1);

        const stone, const blinkNo = parentKey;
        if (blinkNo == 0) continue;

        // std.debug.print("items: ", .{});
        // for (worklist.items) |item| std.debug.print("({d},{d}) ", .{ item.@"0", item.@"1" });
        // std.debug.print("\n", .{});

        const result = applyRulesToStone(stone);
        switch (result) {
            .first, .third => |newStone| {
                const childKey: CacheKey = .{ newStone, blinkNo - 1 };
                if (childMap.getEntry(parentKey)) |entry| {
                    try entry.value_ptr.append(childKey);
                } else {
                    var childrenList = std.ArrayList(CacheKey).init(allocator);
                    try childrenList.append(childKey);
                    try childMap.put(parentKey, childrenList);
                }

                const putResult = try visitedNodes.getOrPut(parentKey);
                if (!putResult.found_existing) try worklist.append(parentKey);
            },
            .second => |newStones| {
                const upper, const lower = newStones;

                const upperChildKey: CacheKey = .{ upper, blinkNo - 1 };
                if (childMap.getEntry(upperChildKey)) |entry| {
                    try entry.value_ptr.append(upperChildKey);
                } else {
                    var childrenList = std.ArrayList(CacheKey).init(allocator);
                    try childrenList.append(upperChildKey);
                    try childMap.put(upperChildKey, childrenList);
                }

                const putResult1 = try visitedNodes.getOrPut(upperChildKey);
                if (!putResult1.found_existing) try worklist.append(upperChildKey);

                const lowerChildKey: CacheKey = .{ lower, blinkNo - 1 };
                if (childMap.getEntry(lowerChildKey)) |entry| {
                    try entry.value_ptr.append(lowerChildKey);
                } else {
                    var childrenList = std.ArrayList(CacheKey).init(allocator);
                    try childrenList.append(lowerChildKey);
                    try childMap.put(lowerChildKey, childrenList);
                }

                const putResult2 = try visitedNodes.getOrPut(lowerChildKey);
                if (!putResult2.found_existing) try worklist.append(lowerChildKey);
            },
        }
    }

    for (0..n + 1) |currentBlink| {
        var it = visitedNodes.iterator();
        innerWhile: while (it.next()) |entry| {
            const entryBlinkNo = entry.key_ptr.@"1";
            if (entryBlinkNo > 0) {
                if (entryBlinkNo != currentBlink) continue :innerWhile;
                const maybeChildren = childMap.get(.{ entry.key_ptr.@"0", currentBlink });
                if (maybeChildren) |children| {
                    var count: usize = 0;
                    for (children.items) |child| {
                        std.debug.print("parent: {d},{d}, child: {d},{d}", .{ entry.key_ptr.@"0", entry.key_ptr.@"1", child.@"0", child.@"1" });
                        const cachedStoneValue = cache.get(child);
                        count += cachedStoneValue.?;
                    }
                }
            } else {
                try cache.put(entry.key_ptr.*, 1);
            }
        }
    }

    // var it = parentMap.iterator();
    // while (it.next()) |entry| {
    //     std.debug.print("({d},{d}) <- ", .{ entry.key_ptr.@"0", entry.key_ptr.@"1" });
    //     for (entry.value_ptr.items) |item| {
    //         std.debug.print("({d},{d}) ", .{ item.@"0", item.@"1" });
    //     }
    //     std.debug.print("\n", .{});
    // }

    return cache.get(.{ initialStone, n }).?;
}

const MemoCache = std.AutoHashMap(CacheKey, usize);

// trick is i need to memoize blink(stone, n)
pub fn blinkCount(stones: *std.ArrayList(u64), n: usize) !usize {
    const allocator = stones.allocator;

    var memoCache = MemoCache.init(allocator);
    defer memoCache.deinit();

    var count: usize = 0;

    for (stones.items) |stone| {
        const result = try f(allocator, &memoCache, stone, n);
        // std.debug.print("count {d}\n", .{result});
        count += result;
    }

    return count;
}
