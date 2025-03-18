const std = @import("std");
const testing = std.testing;

test "generateDiskmap - 1" {
    const input: []const u8 = "12345";

    const expected = &[_]?u64{ 0, null, null, 1, 1, 1, null, null, null, null, 2, 2, 2, 2, 2 };
    //
    const actual = try generateDiskmap(testing.allocator, input);
    defer testing.allocator.free(actual);

    try testing.expectEqualSlices(?u64, expected, actual);
}

test "generateDiskmap - 2" {
    const input: []const u8 = "2333133121414131402";

    const expected = &[_]?u64{ 0, 0, null, null, null, 1, 1, 1, null, null, null, 2, null, null, null, 3, 3, 3, null, 4, 4, null, 5, 5, 5, 5, null, 6, 6, 6, 6, null, 7, 7, 7, null, 8, 8, 8, 8, 9, 9 };
    //
    const actual = try generateDiskmap(testing.allocator, input);
    defer testing.allocator.free(actual);

    try testing.expectEqualSlices(?u64, expected, actual);
}

/// caller owns result slice
pub fn generateDiskmap(allocator: std.mem.Allocator, input: []const u8) ![]?u64 {
    var result = std.ArrayList(?u64).init(allocator);
    defer result.deinit();

    var id: u64 = 0;

    for (input, 0..) |size_char, idx| {
        const is_file = idx % 2 == 0;

        const payload: ?u64 = if (is_file) blk: {
            const tmp = id;
            id += 1;
            break :blk tmp;
        } else blk: {
            break :blk null;
        };

        // std.debug.print("{c} {d}\n", .{ size_char, size_char });
        const size = try std.fmt.parseInt(u8, &[_]u8{size_char}, 10);
        for (size) |_| {
            try result.append(payload);
        }
    }

    return try result.toOwnedSlice();
}

test "compressDiskmap - 1" {
    const input = &[_]?u64{ 0, null, null, 1, 1, 1, null, null, null, null, 2, 2, 2, 2, 2 };

    const expected = &[_]?u64{ 0, 2, 2, 1, 1, 1, 2, 2, 2, null, null, null, null, null, null };

    const actual = try compressDiskmap(testing.allocator, input);
    defer testing.allocator.free(actual);

    try testing.expectEqualSlices(?u64, expected, actual);
}

test "compressDiskmap - 2" {
    const input = &[_]?u64{ 0, 0, null, null, null, 1, 1, 1, null, null, null, 2, null, null, null, 3, 3, 3, null, 4, 4, null, 5, 5, 5, 5, null, 6, 6, 6, 6, null, 7, 7, 7, null, 8, 8, 8, 8, 9, 9 };

    const expected = &[_]?u64{ 0, 0, 9, 9, 8, 1, 1, 1, 8, 8, 8, 2, 7, 7, 7, 3, 3, 3, 6, 4, 4, 6, 5, 5, 5, 5, 6, 6, null, null, null, null, null, null, null, null, null, null, null, null, null, null };

    const actual = try compressDiskmap(testing.allocator, input);
    defer testing.allocator.free(actual);

    try testing.expectEqualSlices(?u64, expected, actual);
}

/// caller owns result slice
pub fn compressDiskmap(allocator: std.mem.Allocator, input: []const ?u64) ![]?u64 {
    var result = try allocator.dupe(?u64, input);

    var last_null_idx_from_bottom: usize = 0;

    outer: for (result, 0..) |elem, idx| {
        if (elem) |_| {
            continue :outer;
        } else {
            // std.debug.print("{any}\n", .{result});
            inner: for (1..result.len + 1) |loop_counter| {
                const index_from_end = result.len - loop_counter;

                if (index_from_end <= idx) break :outer;

                const maybe_elem_to_pack = result[index_from_end];
                if (maybe_elem_to_pack) |elem_to_pack| {
                    // std.debug.print("{d}", .{elem_to_pack});
                    result[idx] = elem_to_pack;
                    result[index_from_end] = null;
                    break :inner;
                } else {
                    last_null_idx_from_bottom = loop_counter;
                    continue :inner;
                }
            }
        }
    }

    return result;
}

test "compressOnlyWholeFiles - 1" {
    const input = &[_]?u64{ 0, null, null, null, 1, null, null, null, 2, null, null, null, null, null, null, 3, 3, 3, 3, 3 };

    const expected = &[_]?u64{ 0, 2, 1, null, null, null, null, null, null, 3, 3, 3, 3, 3, null, null, null, null, null, null };

    const actual = try compressOnlyWholeFiles(testing.allocator, input);
    defer testing.allocator.free(actual);

    try testing.expectEqualSlices(?u64, expected, actual);
}

test "compressOnlyWholeFiles - 2" {
    const input = &[_]?u64{ 0, 0, null, null, null, 1, 1, 1, null, null, null, 2, null, null, null, 3, 3, 3, null, 4, 4, null, 5, 5, 5, 5, null, 6, 6, 6, 6, null, 7, 7, 7, null, 8, 8, 8, 8, 9, 9 };

    const expected = &[_]?u64{ 0, 0, 9, 9, 2, 1, 1, 1, 7, 7, 7, null, 4, 4, null, 3, 3, 3, null, null, null, null, 5, 5, 5, 5, null, 6, 6, 6, 6, null, null, null, null, null, 8, 8, 8, 8, null, null };

    const actual = try compressOnlyWholeFiles(testing.allocator, input);
    defer testing.allocator.free(actual);

    try testing.expectEqualSlices(?u64, expected, actual);
}

fn idxOfFirstNonNullElementForwards(slice: []const ?u64, current_pos: usize) usize {
    var tmp: usize = current_pos;
    for (current_pos..slice.len) |val| {
        if (slice[val]) |_| break else tmp += 1;
    }
    return tmp;
}

fn idxOfFirstDifferentElementBackwards(slice: []const ?u64, current_pos: usize) usize {
    const current_val = slice[current_pos];
    var tmp: usize = current_pos;

    for (0..current_pos) |val| {
        if (slice[current_pos - val]) |prev_val| {
            if (prev_val == current_val) tmp -= 1;
        } else break;
    }
    // add one because tmp now points to an empty spot
    return tmp;
}

const SliceBounds = struct { start: usize, end: usize };
fn findBlockToMove(input: []const ?u64) SliceBounds {
    var result: SliceBounds = undefined;

    var loop_counter: usize = input.len - 1;
    while (loop_counter >= 0) : (loop_counter -= 1) {
        const maybe_elem_to_pack = input[loop_counter];
        if (maybe_elem_to_pack) |_| {
            const idx_of_different_block_or_null = idxOfFirstDifferentElementBackwards(input, loop_counter);
            result.end = loop_counter + 1;
            result.start = idx_of_different_block_or_null + 1;
            break;
        } else {
            continue;
        }
    }

    return result;
}

fn findEmptySpace(input: []const ?u64, maybe_start: ?usize) SliceBounds {
    var start_empty_space_idx: usize = 0;
    var end_empty_space_idx: usize = 0;

    if (maybe_start) |start| {
        start_empty_space_idx = start;
    }

    while (start_empty_space_idx < input.len) : (start_empty_space_idx += 1) {
        if (input[start_empty_space_idx]) |_| {
            continue;
        } else {
            end_empty_space_idx = idxOfFirstNonNullElementForwards(input, start_empty_space_idx);
            break;

            // std.debug.print("{d}:{d}\n", .{ start_empty_space, end_empty_space });
            // std.debug.print("space: {d}:{d}\n", .{ start_empty_space_idx, end_empty_space_idx });
        }
    }
    return .{
        .start = start_empty_space_idx,
        .end = end_empty_space_idx,
    };
}

/// caller owns result slice
pub fn compressOnlyWholeFiles(allocator: std.mem.Allocator, input: []const ?u64) ![]?u64 {
    const result = try allocator.dupe(?u64, input);

    var block_to_move_bounds = findBlockToMove(result);
    outer: while (block_to_move_bounds.start > 1) : (block_to_move_bounds = findBlockToMove(result[0..block_to_move_bounds.start])) {
        const block_to_move = result[block_to_move_bounds.start..block_to_move_bounds.end];
        // std.debug.print("block_to_move: {d}:{d}\n", .{ block_to_move_bounds.start, block_to_move_bounds.end });

        const maybe_elem_to_pack = result[block_to_move_bounds.start];
        if (maybe_elem_to_pack) |block_val| {
            var empty_space_bounds = findEmptySpace(result, null);

            while (empty_space_bounds.end <= block_to_move_bounds.start) {
                // std.debug.print("space: {d}:{d}\n", .{ empty_space_bounds.start, empty_space_bounds.end });

                if (block_to_move.len <= empty_space_bounds.end - empty_space_bounds.start) {
                    // std.debug.print("block fits, moving to {d}:{d}\n", .{ empty_space_bounds.start, empty_space_bounds.end });
                    for (0..block_to_move.len) |i| result[empty_space_bounds.start + i] = block_val;
                    // empty_space_bounds.start += block_to_move.len;
                    // set what we've moved to null
                    for (block_to_move_bounds.start..block_to_move_bounds.end) |i| result[i] = null;
                    // empty_space_bounds = findEmptySpace(result, null);
                    continue :outer;
                } else {
                    // std.debug.print("block doesn't fit, continuing\n", .{});
                    empty_space_bounds = findEmptySpace(result, empty_space_bounds.end);
                }
            }
        } else {
            // std.debug.print("block_to_move_len: {d}\n", .{block_to_move.len});
        }
    }

    return result;
}

test "calculateChecksum - 1" {
    const input = &[_]?u64{ 0, null, null, null, 1, null, null, null, 2, null, null, null, null, null, null, 3, 3, 3, 3, 3 };

    const compressed = try compressOnlyWholeFiles(testing.allocator, input);
    defer testing.allocator.free(compressed);

    std.debug.print("{any}\n", .{compressed});

    const expected: u64 = 169;

    const actual = calculateChecksum(compressed);

    try testing.expectEqual(expected, actual);
}

test "calculateChecksum - 2" {
    const input = &[_]?u64{ 0, 0, 9, 9, 8, 1, 1, 1, 8, 8, 8, 2, 7, 7, 7, 3, 3, 3, 6, 4, 4, 6, 5, 5, 5, 5, 6, 6, null, null, null, null, null, null, null, null, null, null, null, null, null, null };

    const expected: u64 = 1928;

    const actual = calculateChecksum(input);

    try testing.expectEqual(expected, actual);
}

/// caller owns result slice
pub fn calculateChecksum(input: []const ?u64) u64 {
    var count: u64 = 0;

    for (input, 0..) |maybe_elem, idx| {
        if (maybe_elem) |elem| {
            count += elem * @as(u64, @intCast(idx));
        }
    }

    return count;
}
