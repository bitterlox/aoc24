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

// this is based on a tree structure, but the problem creates a DAG
pub fn f(allocator: std.mem.Allocator, memoCache: *MemoCache, stone: u64, n: usize) !usize {
    const cache = try allocator.create(std.AutoHashMap(CacheKey, CacheValue));
    defer allocator.destroy(cache);
    cache.* = std.AutoHashMap(CacheKey, CacheValue).init(allocator);

    var stones = try allocator.create(std.ArrayList(CacheKey));
    defer allocator.destroy(stones);
    stones.* = std.ArrayList(CacheKey).init(allocator);
    defer stones.deinit();
    try stones.append(.{ stone, n });

    // var c: usize = 1;
    const c = try allocator.create(usize);
    c.* = 1;
    // instead of optional pointer to an array just put in an empty arraylist

    const extListPtr = try allocator.create(std.ArrayList(*usize));
    extListPtr.* = std.ArrayList(*usize).init(allocator);
    try cache.put(.{ stone, n }, .{ c, extListPtr });

    // start count at 1 due to appending the first stone above
    var i: usize = 1;
    // counting like this because use use 1 in the cache and it should correspond
    // to the number of blinks
    while (i < n + 1) : (i += 1) {
        var currentStones = try stones.clone();
        defer currentStones.deinit();

        stones.clearRetainingCapacity();

        for (currentStones.items) |elem| {
            const stonee, const blinkNo = elem;

            const result = applyRulesToStone(stonee);
            switch (result) {
                .first, .third => |newStoneValue| {
                    // try stones.append(newStoneValue);
                    // var listPtr = std.ArrayList(*usize).init(allocator);
                    // try listPtr.append(entry.value_ptr.@"0");
                    // var s: usize = 1;
                    // try listPtr.append(&s);

                    // if (entry.value_ptr.@"1") |parentList| for (parentList.items) |p| try listPtr.append(p);
                    // var count: usize = 1;
                    const parentEntry = cache.get(.{ stonee, blinkNo });
                    const newKey = .{ newStoneValue, n - i };

                    if (parentEntry) |pe| {
                        pe.@"0".* += 1;
                        for (pe.@"1".items) |p| {
                            if (p != pe.@"0") p.* += 1;
                        }
                    }

                    if (!cache.contains(newKey)) {
                        const listPtr = try allocator.create(std.ArrayList(*usize));
                        listPtr.* = std.ArrayList(*usize).init(allocator);
                        const count = try allocator.create(usize);
                        count.* = 0;

                        if (parentEntry) |entry1| {
                            try listPtr.append(entry1.@"0");
                            for (entry1.@"1".items) |p| try listPtr.append(p);
                        }

                        try cache.put(newKey, .{ count, listPtr });
                    }
                    try stones.append(.{ newStoneValue, n - i });
                },
                .second => |newStoneValues| {
                    const upper, const lower = newStoneValues;
                    const key1 = .{ upper, n - i };
                    const key2 = .{ lower, n - i };

                    const entry = cache.get(.{ stonee, blinkNo });
                    if (!cache.contains(key1)) {
                        var list1Ptr = try allocator.create(std.ArrayList(*usize));
                        list1Ptr.* = std.ArrayList(*usize).init(allocator);
                        // var list1Ptr = std.ArrayList(*usize).init(allocator);

                        if (entry) |entry1| {
                            try list1Ptr.append(entry1.@"0");
                            for (entry1.@"1".items) |p| try list1Ptr.append(p);
                        }

                        // var count1: usize = 1;
                        const count1 = try allocator.create(usize);
                        count1.* = 0;
                        try cache.put(key1, .{ count1, list1Ptr });
                    }
                    try stones.append(.{ upper, n - i });

                    const entryNew = cache.get(.{ stonee, blinkNo });

                    if (!cache.contains(key2)) {
                        var list2Ptr = try allocator.create(std.ArrayList(*usize));
                        list2Ptr.* = std.ArrayList(*usize).init(allocator);
                        // var list2Ptr = std.ArrayList(*usize).init(allocator);
                        if (entryNew) |entry1| {
                            try list2Ptr.append(entry1.@"0");
                            for (entry1.@"1".items) |p| try list2Ptr.append(p);
                        }
                        // var count2: usize = 1;
                        const count2 = try allocator.create(usize);
                        count2.* = 0;
                        try cache.put(key2, .{ count2, list2Ptr });
                    }
                    try stones.append(.{ lower, n - i });

                    // std.debug.print("adding to parent: {?}\n", .{entry.value_ptr});
                    // do i care if the items are in the cache or not when adding 1?
                    // if (entryNew) |_entryNew| {
                    //     // std.debug.print("parent({d}, {d})\n", .{ stonee, blinkNo });
                    //     // std.debug.print("upper: {d}, lower:{d}\n", .{ upper, lower });
                    //     // add 1 to the parent pointer
                    //     _entryNew.@"0".* += 1;
                    //     for (_entryNew.@"1".items) |ptr| {
                    //         // add 1 to all the pointers in list which are not
                    //         // the parent pointer
                    //         // this exception is done because if the first stone
                    //         // is a split, we don't have any means to add 1 to it since
                    //         // we only increment pointers contained in the parent's list
                    //         // and in that case the list would be empty
                    //         // we still need to add the parent pointer to the list
                    //         // so it is propagated down the 'tree'
                    //         if (ptr != _entryNew.@"0") ptr.* += 1;
                    //         // std.debug.print("adding to ptr({?}): {d}\n", .{ ptr, ptr.* });
                    //     }
                    // } else {
                    //     // std.debug.print("missing item from cache\n", .{});
                    // }
                },
            }
            // std.debug.print("running stone ({d},{d})\n", .{ stonee, blinkNo });
            // std.debug.print("stone ({d}): {d} {d}\n", .{ i, stonee, blinkNo });
            // if (memoCache.get(.{ stonee, blinkNo })) |cachedCount| {
            //     const parentEntry = cache.get(.{ stonee, blinkNo });
            //     std.debug.print("cache hit ({d},{d}): {d}\n", .{ stonee, blinkNo, cachedCount });
            //     if (parentEntry) |pe| {
            //         pe.@"0".* += cachedCount;
            //         for (pe.@"1".items) |p| {
            //             if (p != pe.@"0") p.* += cachedCount;
            //             std.debug.print("adding cached count\n", .{});
            //         }
            //     }
            // } else {
            // }
        }
    }

    const result = cache.get(.{ stone, n }).?.@"0".*;
    var it = cache.iterator();
    while (it.next()) |entry| {
        std.debug.print("cached stone ({d},{d}): {?}\n", .{ entry.key_ptr.@"0", entry.key_ptr.@"1", entry.value_ptr.@"0".* });
        // std.debug.print("pointers: {?}\n", .{entry.value_ptr.@"1"});
        if (!memoCache.contains(entry.key_ptr.*)) {
            try memoCache.put(entry.key_ptr.*, entry.value_ptr.@"0".*);
        }
        allocator.destroy(entry.value_ptr.@"0");
        entry.value_ptr.@"1".deinit();
        allocator.destroy(entry.value_ptr.@"1");
    }

    cache.deinit();
    return result;
}

pub fn g(allocator: std.mem.Allocator, cache: *MemoCache, initialStone: u64, n: usize) !usize {
    var worklist = std.ArrayList(CacheKey).init(allocator);
    defer worklist.deinit();

    var visitedNodes = std.AutoHashMap(CacheKey, void).init(allocator);
    defer visitedNodes.deinit();
    var parentMap = std.AutoHashMap(CacheKey, std.ArrayList(CacheKey)).init(allocator);
    defer {
        var it = parentMap.iterator();
        while (it.next()) |entry| {
            entry.value_ptr.deinit();
        }
        parentMap.deinit();
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
                if (parentMap.getEntry(childKey)) |entry| {
                    try entry.value_ptr.append(parentKey);
                } else {
                    var parentList = std.ArrayList(CacheKey).init(allocator);
                    try parentList.append(parentKey);
                    try parentMap.put(childKey, parentList);
                }

                const putResult = try visitedNodes.getOrPut(childKey);
                if (!putResult.found_existing) try worklist.append(childKey);
            },
            .second => |newStones| {
                const upper, const lower = newStones;

                const upperChildKey: CacheKey = .{ upper, blinkNo - 1 };
                if (parentMap.getEntry(upperChildKey)) |entry| {
                    try entry.value_ptr.append(parentKey);
                } else {
                    var parentList = std.ArrayList(CacheKey).init(allocator);
                    try parentList.append(parentKey);
                    try parentMap.put(upperChildKey, parentList);
                }

                const putResult1 = try visitedNodes.getOrPut(upperChildKey);
                if (!putResult1.found_existing) try worklist.append(upperChildKey);

                const lowerChildKey: CacheKey = .{ lower, blinkNo - 1 };
                if (parentMap.getEntry(lowerChildKey)) |entry| {
                    try entry.value_ptr.append(parentKey);
                } else {
                    var parentList = std.ArrayList(CacheKey).init(allocator);
                    try parentList.append(parentKey);
                    try parentMap.put(lowerChildKey, parentList);
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
        const result = try g(allocator, &memoCache, stone, n);
        // std.debug.print("count {d}\n", .{result});
        count += result;
    }

    return count;
}
