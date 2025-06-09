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

test "applyRules" {
    const listPtr = try testing.allocator.create(std.ArrayList(u64));
    defer testing.allocator.destroy(listPtr);

    const initData = try testing.allocator.dupe(u64, &[_]u64{ 0, 1, 10, 99, 999 });
    listPtr.* = std.ArrayList(u64).fromOwnedSlice(testing.allocator, initData);
    defer listPtr.deinit();

    try applyRules(listPtr);

    const actual = try listPtr.toOwnedSlice();
    defer testing.allocator.free(actual);

    try testing.expectEqualSlices(u64, &[_]u64{ 1, 2024, 1, 0, 9, 9, 2021976 }, actual);
}

fn applyRules(stones: *std.ArrayList(u64)) !void {
    var idx: usize = 0;

    while (idx < stones.items.len) : (idx += 1) {
        const stone = stones.items[idx];

        // first rule
        if (stone == 0) {
            stones.items[idx] = 1;
            continue;
        }

        // second rule
        const digitCount = countDigits(stone);
        if (digitCount % 2 == 0) {
            const upper, const lower = halveInt(stone, digitCount);

            stones.items[idx] = upper;

            try stones.insert(idx + 1, lower);

            // add one more to the index since we split the stone
            idx += 1;
            continue;
        }

        // third rule
        stones.items[idx] *= 2024;
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

    try testing.expectEqualSlices(u64, &[_]u64{ 2097446912, 14168, 4048, 2, 0, 2, 4, 40, 48, 2024, 40, 48, 80, 96, 2, 8, 6, 7, 6, 0, 3, 2 }, actual);
}

// use std.SinglyLinkedList in the implementation
pub fn blink(stones: *std.ArrayList(u64), n: usize) !void {
    var i: usize = 0;
    while (i < n) : (i += 1) {
        try applyRules(stones);
    }
}
