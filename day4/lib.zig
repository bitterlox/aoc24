const std = @import("std");
const testing = std.testing;

test "parse - example 1" {}

// take input string and produce array of slices for each direction of search
// line_forwards, line_backwards, column_forwards, column_backwards,
// diagonal_forwards, diagonal_backwards; it looks like diagonals can overflow
// eg part of the xmas can be at the end and star back at the beginning
pub fn make_permutations() !void {}

test "find_xmases - example 1" {
    const input = "MMMSXXMASM";
    const expected = 1;
    try testing.expectEqual(expected, find_xmases_in_string(input));
}

pub fn find_xmases_in_string(str: []const u8) u64 {
    var result: u64 = 0;

    const view_start_min_idx = 0;
    const view_start_max_idx = str.len - 3;
    const view_end_min_idx = 4;
    const view_end_max_idx = str.len + 1;
    for (view_start_min_idx..view_start_max_idx, view_end_min_idx..view_end_max_idx) |i, j| {
        const view = str[i..j];
        if (std.mem.eql(u8, view, "XMAS")) result += 1;
    }
    return result;
}

test "make_diagonals - example 2" {
    const allocator = std.testing.allocator;
    const input: []const []const u8 = &[_][]const u8{
        "MMMSXXMASM",
        "MSAMXMSMSA",
        "AMXSXMAAMM",
        "MSAMASMSMX",
        "XMASAMXAMM",
        "XXAMMXXAMA",
        "SMSMSASXSS",
        "SAXAMASAAA",
        "MAMMMXMMMM",
        "MXMXAXMASX",
    };
    const expected: []const []const u8 = &[_][]const u8{
        "M",
        "MM",
        "ASM",
        "MMAS",
        "XSXMX",
    };
    const actual = try make_diagonals(allocator, input);
    defer {
        for (actual) |sl| {
            allocator.free(sl);
        }
        allocator.free(actual);
    }
    try testing.expectEqualSlices([]const u8, expected, actual);
}

// this works just need to fix the test
pub fn make_diagonals(allocator: std.mem.Allocator, str: []const []const u8) ![]const []const u8 {
    var first_half_list = std.ArrayList([]u8).init(allocator);
    defer first_half_list.deinit();

    for (str, 0..) |row, i| {
        for (row, 0..) |_, j| {
            std.debug.print("({d}, {d})", .{ i, j });
        }
        std.debug.print("\n", .{});
    }

    std.debug.print("\n", .{});

    for (str, 0..) |_, i| {
        // const reversed: []u8 = try copy_and_reverse(allocator, row);
        // defer allocator.free(reversed);

        var tmp = std.ArrayList(u8).init(allocator);
        defer tmp.deinit();

        for (0..i + 1) |j| {
            std.debug.print("({d}, {d})", .{ i - j, j });
            try tmp.append(str[i - j][j]);
        }

        std.debug.print("\n", .{});
        try first_half_list.append(try tmp.toOwnedSlice());
    }

    var second_half_list = std.ArrayList([]u8).init(allocator);
    defer second_half_list.deinit();

    for (str, 0..) |_, i| {
        // const reversed: []u8 = try copy_and_reverse(allocator, row);
        // defer allocator.free(reversed);

        var tmp = std.ArrayList(u8).init(allocator);
        defer tmp.deinit();

        const lastIdx = str.len - i - 1;

        for (0..lastIdx + 1) |j| {
            std.debug.print("({d}, {d})", .{ lastIdx - j, j });
            try tmp.append(str[lastIdx - j][j]);
        }
        std.debug.print("\n", .{});
        try second_half_list.append(try tmp.toOwnedSlice());
    }

    const second_list_slice = try second_half_list.toOwnedSlice();
    defer allocator.free(second_list_slice[0]);

    try first_half_list.appendSlice(second_list_slice[1..]);

    return first_half_list.toOwnedSlice();
}
