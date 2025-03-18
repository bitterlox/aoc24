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

/// caller owns result slice
pub fn compressOnlyWholeFiles(allocator: std.mem.Allocator, input: []const ?u64) ![]?u64 {
    const result = try allocator.dupe(?u64, input);

    // var last_null_idx_from_bottom: usize = 0;

    var start_empty_space: usize = 0;
    // this assumes there's a block at the last index
    // var last_space_with_block: usize = result.len - 1;

    outer: while (start_empty_space < result.len) : (start_empty_space += 1) {
        if (result[start_empty_space]) |_| {
            continue :outer;
        } else {
            const end_empty_space = idxOfFirstNonNullElementForwards(result, start_empty_space);

            // std.debug.print("{d}:{d}\n", .{ start_empty_space, end_empty_space });
            std.debug.print("space: {d}:{d}\n", .{ start_empty_space, end_empty_space });

            var block_to_move_bounds = findBlockToMove(result);
            while (block_to_move_bounds.start >= start_empty_space) {
                const block_to_move = result[block_to_move_bounds.start..block_to_move_bounds.end];
                std.debug.print("block_to_move: {d}:{d}\n", .{ block_to_move_bounds.start, block_to_move_bounds.end });

                const maybe_elem_to_pack = result[block_to_move_bounds.start];
                if (maybe_elem_to_pack) |block_val| {
                    if (block_to_move.len <= end_empty_space - start_empty_space) {
                        std.debug.print("block fits, moving to {d}:{d}\n", .{ start_empty_space, end_empty_space });
                        for (0..block_to_move.len) |i| result[start_empty_space + i] = block_val;
                        start_empty_space += block_to_move.len;
                        // set what we've moved to null
                        for (block_to_move_bounds.start..block_to_move_bounds.end) |i| result[i] = null;
                    } else {
                        std.debug.print("block doesn't fit, continuing\n", .{});
                    }
                } else {
                    std.debug.print("block_to_move_len: {d}:{d}\n", .{ block_to_move.len, end_empty_space - start_empty_space });
                }
                block_to_move_bounds = findBlockToMove(result[0..block_to_move_bounds.start]);
            }

            // var loop_counter: usize = result.len - 1;
            // inner: while (loop_counter >= 0) : (loop_counter -= 1) {
            //     std.debug.print("loop_cntr: {d} {d}\n", .{ loop_counter, start_empty_space });
            //     if (loop_counter < start_empty_space) break :inner;

            //     const maybe_elem_to_pack = result[loop_counter];
            //     if (maybe_elem_to_pack) |block_val| {
            //         const idx_of_different_block_or_null = idxOfFirstDifferentElementBackwards(result, loop_counter);
            //         std.debug.print("elem: {d}:{d}\n", .{ idx_of_different_block_or_null + 1, loop_counter + 1 });

            //         const block_to_move = result[idx_of_different_block_or_null + 1 .. loop_counter + 1];

            //         if (block_to_move.len <= end_empty_space - start_empty_space) {
            //             std.debug.print("block fits, moving\n", .{});
            //             for (0..block_to_move.len) |i| result[start_empty_space + i] = block_val;
            //             // set what we've moved to null
            //             for (idx_of_different_block_or_null + 1..loop_counter + 1) |i| result[i] = null;
            //             start_empty_space += block_to_move.len;
            //             loop_counter = idx_of_different_block_or_null;
            //             continue :inner;
            //         } else {
            //             std.debug.print("block doesn't fit, continuing\n", .{});
            //             loop_counter = idx_of_different_block_or_null;
            //             continue :inner;
            //         }

            //         // result[result_idx] = elem_to_pack;
            //         // result[index_from_end] = null;
            //         break :inner;
            //     } else {
            //         last_null_idx_from_bottom = loop_counter;
            //         continue :inner;
            //     }
            // }
        }
    }

    return result;
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
        } else {
            break;
        }
    }

    return count;
}
