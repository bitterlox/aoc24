const std = @import("std");
const testing = std.testing;

// 1. If the stone is engraved with the number 0, it is replaced by a stone engraved with the number 1.
// 2. If the stone is engraved with a number that has an even number of digits, it is replaced by two stones.
//     The left half of the digits are engraved on the new left stone, and the right half of the digits are engraved on the new right stone.
//     (The new numbers don't keep extra leading zeroes: 1000 would become stones 10 and 0.)
// 3. If none of the other rules apply, the stone is replaced by a new stone; the old stone's number multiplied by 2024 is engraved on the new stone.

test "applyFirstRule" {
    const values = try testing.allocator.alloc(u64, 2);
    defer testing.allocator.free(values);
    values[0] = 0;
    values[1] = 1;

    const res_0 = applyFirstRule(&values[0]);
    const res_1 = applyFirstRule(&values[1]);

    try testing.expectEqual(1, values[0]);
    try testing.expectEqual(true, res_0);
    try testing.expectEqual(1, values[1]);
    try testing.expectEqual(false, res_1);
}

fn applyFirstRule(stone: *u64) !bool {
    if (stone.* == 0) {
        stone.* = 1;
        return true;
    }
    return false;
}

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

fn fillUpLinkedListFromArrayList(allocator: std.mem.Allocator, ll: *std.DoublyLinkedList(u64), al: *std.ArrayList(u64)) !void {
    const Node = std.DoublyLinkedList(u64).Node;
    for (al.items) |item| {
        const node = try allocator.create(Node);
        node.* = Node{ .data = item };
        ll.append(node);
    }
}

fn fillUpArrayListFromLinkedList(al: *std.ArrayList(u64), ll: *std.DoublyLinkedList(u64)) !void {
    var firstNode: ?*std.DoublyLinkedList(u64).Node = ll.first;
    while (firstNode) |node| {
        firstNode = node.next;
        try al.append(node.data);
    }
}

fn freeNodes(allocator: std.mem.Allocator, ll: *std.DoublyLinkedList(u64)) void {
    var firstNode: ?*std.DoublyLinkedList(u64).Node = ll.first;
    while (firstNode) |node| {
        firstNode = node.next;
        allocator.destroy(node);
    }
}

test "applyRules" {
    const allocator = testing.allocator;
    const llPtr = try allocator.create(std.DoublyLinkedList(u64));
    llPtr.* = std.DoublyLinkedList(u64){};
    defer allocator.destroy(llPtr);

    const inputData = try allocator.dupe(u64, &[_]u64{ 0, 1, 10, 99, 999 });
    const arrayListPtr = try allocator.create(std.ArrayList(u64));
    defer allocator.destroy(arrayListPtr);
    arrayListPtr.* = std.ArrayList(u64).fromOwnedSlice(allocator, inputData);

    try fillUpLinkedListFromArrayList(allocator, llPtr, arrayListPtr);
    defer freeNodes(allocator, llPtr);

    try applyRulesToStones(allocator, llPtr);

    arrayListPtr.clearAndFree();
    try fillUpArrayListFromLinkedList(arrayListPtr, llPtr);

    const actual = try arrayListPtr.toOwnedSlice();
    defer testing.allocator.free(actual);

    try testing.expectEqualSlices(u64, &[_]u64{ 1, 2024, 1, 0, 9, 9, 2021976 }, actual);
}

const RulesApplicationResult = union(enum) {
    first: u64,
    second: struct { u64, u64 },
    third: u64,
};

const Cache = std.AutoHashMap(u64, RulesApplicationResult);

fn memoizedApplyRulesToStone(cache: *Cache, stone: u64) !RulesApplicationResult {
    if (cache.get(stone)) |cached| {
        std.debug.print("cache hit: {d} {?}\n", .{ stone, cached });
        return cached;
    } else {
        const result = applyRulesToStone(stone);
        try cache.put(stone, result);
        return result;
    }
}

//???
// cache seems to not be working
// also on reddit they're saying lanterfish
fn applyRulesToStones(allocator: std.mem.Allocator, llPtr: *std.DoublyLinkedList(u64)) !void {
    const Node = std.DoublyLinkedList(u64).Node;

    var cache: Cache = Cache.init(allocator);
    defer cache.deinit();

    var currNode: ?*Node = llPtr.first;

    while (currNode) |node| {
        const result = if (cache.get(node.data)) |cached| blk: {
            // std.debug.print("cache hit: {d} {?}\n", .{ node., cached });
            break :blk cached;
        } else blk: {
            const result = applyRulesToStone(node.data);
            try cache.put(node.data, result);
            break :blk result;
        };

        switch (result) {
            .first, .third => |newStoneValue| {
                node.data = newStoneValue;
                currNode = node.next;
            },
            .second => |newStoneValues| {
                const upper, const lower = newStoneValues;

                node.data = upper;

                const newNode = try allocator.create(Node);
                newNode.* = Node{ .data = lower };

                llPtr.insertAfter(node, newNode);

                // set next node
                currNode = newNode.next;
            },
        }
    }
}

test "blink" {
    const listPtr = try testing.allocator.create(std.ArrayList(u64));
    defer testing.allocator.destroy(listPtr);

    const initData = try testing.allocator.dupe(u64, &[_]u64{ 125, 17 });
    listPtr.* = std.ArrayList(u64).fromOwnedSlice(testing.allocator, initData);
    defer listPtr.deinit();

    try blink(listPtr, 6);

    const actual = try listPtr.toOwnedSlice();
    defer testing.allocator.free(actual);

    try testing.expectEqualSlices(u64, &[_]u64{
        2097446912, //
        14168, //
        4048, //
        2, //
        0, //
        2, //
        4, //
        40,
        48,
        2024, //
        40, //
        48, //
        80, //
        96, //
        2,
        8, //
        6,
        7, //
        6, //
        0, //
        3, //
        2,
    }, actual);
}

// use std.SinglyLinkedList in the implementation
pub fn blink(stones: *std.ArrayList(u64), n: usize) !void {
    const allocator = stones.allocator;
    const llPtr = try allocator.create(std.DoublyLinkedList(u64));
    llPtr.* = std.DoublyLinkedList(u64){};
    defer allocator.destroy(llPtr);

    try fillUpLinkedListFromArrayList(allocator, llPtr, stones);
    defer freeNodes(allocator, llPtr);

    var i: usize = 0;
    while (i < n) : (i += 1) {
        // std.debug.print("running {d} blink\n", .{i});
        try applyRulesToStones(allocator, llPtr);
    }

    stones.clearAndFree();
    try fillUpArrayListFromLinkedList(stones, llPtr);
}

test "blinkCount" {
    const listPtr = try testing.allocator.create(std.ArrayList(u64));
    defer testing.allocator.destroy(listPtr);

    const initData = try testing.allocator.dupe(u64, &[_]u64{ 125, 17 });
    listPtr.* = std.ArrayList(u64).fromOwnedSlice(testing.allocator, initData);
    defer listPtr.deinit();

    const actual = try blinkCount(listPtr, 6);

    try testing.expectEqual(22, actual);
}

// represent the recursion in a map
// store intermediate computation results like this
// [stone, blink_count, counter]
// as you compute stones build an arraylist of values where
// each subsequent value is
// [stone, blink_count-1, 0] and then go back and add 1 to counter for old values
// at then end arraylist[0].counter should countain the actual count
// cache all the values [stone, blink_count] -> counter
pub fn f(allocator: std.mem.Allocator, _: *Cache2, stone: u64, n: usize) !usize {
    const CacheKey = struct { u64, usize };
    const CacheValue = struct { *usize, *std.ArrayList(*usize) };

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

            // std.debug.print("stone ({d}): {d} {d}\n", .{ i, stonee, blinkNo });

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
                    const key = .{ newStoneValue, n - i };
                    if (!cache.contains(key)) {
                        const listPtr = try allocator.create(std.ArrayList(*usize));
                        listPtr.* = std.ArrayList(*usize).init(allocator);
                        const count = try allocator.create(usize);
                        count.* = 1;
                        if (parentEntry) |entry1| try listPtr.append(entry1.@"0");
                        if (parentEntry) |pe| for (pe.@"1".items) |p| try listPtr.append(p);
                        try cache.put(key, .{ count, listPtr });
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
                        count1.* = 1;
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
                        count2.* = 1;
                        try cache.put(key2, .{ count2, list2Ptr });
                    }
                    try stones.append(.{ lower, n - i });

                    // std.debug.print("adding to parent: {?}\n", .{entry.value_ptr});
                    // do i care if the items are in the cache or not when adding 1?
                    if (entryNew) |_entryNew| {
                        // std.debug.print("parent({d}, {d})\n", .{ stonee, blinkNo });
                        // std.debug.print("upper: {d}, lower:{d}\n", .{ upper, lower });
                        // add 1 to the parent pointer
                        _entryNew.@"0".* += 1;
                        for (_entryNew.@"1".items) |ptr| {
                            // add 1 to all the pointers in list which are not
                            // the parent pointer
                            // this exception is done because if the first stone
                            // is a split, we don't have any means to add 1 to it since
                            // we only increment pointers contained in the parent's list
                            // and in that case the list would be empty
                            // we still need to add the parent pointer to the list
                            // so it is propagated down the 'tree'
                            if (ptr != _entryNew.@"0") ptr.* += 1;
                            // std.debug.print("adding to ptr({?}): {d}\n", .{ ptr, ptr.* });
                        }
                    } else {
                        // std.debug.print("missing item from cache\n", .{});
                    }
                },
            }
        }
    }

    const result = cache.get(.{ stone, n }).?.@"0".*;
    var it = cache.iterator();
    while (it.next()) |entry| {
        // std.debug.print("cached stone ({d},{d}): {?}\n", .{ entry.key_ptr.@"0", entry.key_ptr.@"1", entry.value_ptr.@"0".* });
        // std.debug.print("pointers: {?}\n", .{entry.value_ptr.@"1"});
        allocator.destroy(entry.value_ptr.@"0");
        entry.value_ptr.@"1".deinit();
        allocator.destroy(entry.value_ptr.@"1");
    }

    cache.deinit();
    return result;
}

const Cache2 = std.AutoHashMap(struct { u64, usize }, struct { usize, RulesApplicationResult });

// use std.SinglyLinkedList in the implementation
// trick is i need to memoize blink(stone, n)
pub fn blinkCount(stones: *std.ArrayList(u64), n: usize) !usize {
    const allocator = stones.allocator;

    var cache = Cache2.init(allocator);
    defer cache.deinit();

    var count: usize = 0;

    for (stones.items) |stone| {
        const result = try f(allocator, &cache, stone, n);
        // std.debug.print("count {d}\n", .{result});
        count += result;
    }

    return count;
}
