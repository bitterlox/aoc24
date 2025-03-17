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
            inner: for (1..result.len + 1) |inner_idx| {
                const index_from_end = result.len - inner_idx;

                if (index_from_end <= idx) break :outer;

                const maybe_elem_to_pack = result[index_from_end];
                if (maybe_elem_to_pack) |elem_to_pack| {
                    // std.debug.print("{d}", .{elem_to_pack});
                    result[idx] = elem_to_pack;
                    result[index_from_end] = null;
                    break :inner;
                } else {
                    last_null_idx_from_bottom = inner_idx;
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

/// caller owns result slice
pub fn compressOnlyWholeFiles(allocator: std.mem.Allocator, input: []const ?u64) ![]?u64 {
    const result = try allocator.dupe(?u64, input);

    var last_null_idx_from_bottom: usize = 0;

    var result_idx: usize = 0;

    outer: while (result_idx < result.len) : (result_idx += 1) {
        if (result[result_idx]) |_| {
            continue :outer;
        } else {
            const start_empty_space = result_idx;
            const end_empty_space = blk: {
                var tmp: usize = start_empty_space;
                innerFor: for (start_empty_space..result.len) |val| {
                    if (result[val]) |_| break :innerFor else tmp += 1;
                }
                break :blk tmp;
            };
            const empty_space_length = end_empty_space - start_empty_space;
            // std.debug.print("{d}:{d}\n", .{ start_empty_space, end_empty_space });
            std.debug.print("space: {d}:{d}\n", .{ start_empty_space, end_empty_space });
            var idx_of_last_block = result.len;
            inner: for (1..result.len + 1) |inner_idx| {
                // FIXME this is overflowing idx_of_last_block is small and inner is big
                std.debug.print("dixse: {d}:{d}\n", .{ idx_of_last_block, inner_idx });
                const index_from_end = idx_of_last_block - inner_idx;

                if (index_from_end <= result_idx) break :outer;

                const maybe_elem_to_pack = result[index_from_end];
                if (maybe_elem_to_pack) |block_val| {
                    const first_empty_spot_before_block = blk: {
                        var tmp: usize = index_from_end;
                        innerFor: for (0..index_from_end) |val| {
                            if (result[index_from_end - val]) |backlooping_val| {
                                if (backlooping_val == block_val) tmp -= 1 else break :innerFor;
                            } else break :innerFor;
                        }
                        // add one because tmp now points to an empty spot
                        break :blk tmp;
                    };
                    // TODO: we good with indexes. need some logic to check if
                    // the piece of data we find within end indexes fits int the empty spots at the start
                    // if yes, move, else, restart end loop and check lower data
                    const block_to_move = result[first_empty_spot_before_block + 1 .. index_from_end + 1];

                    std.debug.print("{d} elem: {d}:{d}\n", .{ block_to_move.len, first_empty_spot_before_block + 1, index_from_end + 1 });
                    if (block_to_move.len <= empty_space_length) {
                        std.debug.print("block fits, moving\n", .{});
                        for (0..block_to_move.len) |i| result[start_empty_space + i] = block_val;
                        continue :inner;
                    } else {
                        std.debug.print("block doesn't fit, continuing\n", .{});
                        idx_of_last_block = first_empty_spot_before_block;
                        continue :inner;
                    }

                    // result[result_idx] = elem_to_pack;
                    // result[index_from_end] = null;
                    break :inner;
                } else {
                    last_null_idx_from_bottom = inner_idx;
                    continue :inner;
                }
            }
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
