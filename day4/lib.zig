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

// TODO: guard against slices less than 4 elements long
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
        "XMASXX",
        "SXAMXMM",
        "SMASAMSA",
        "MASMASAMS",
        "MAXMMMMASM",
        "XMASXXSMA",
        "MMMAXAMM",
        "XMASAMX",
        "AXSXMM",
        "XMASA",
        "MMAS",
        "AMA",
        "SM",
        "X",
    };
    const actual = try make_diagonals(allocator, input);
    defer {
        for (actual) |sl| {
            allocator.free(sl);
        }
        allocator.free(actual);
    }

    try testing.expectEqualDeep(expected, actual);
}

pub fn make_diagonals(allocator: std.mem.Allocator, str: []const []const u8) ![]const []const u8 {
    var first_half_list = std.ArrayList([]u8).init(allocator);
    defer first_half_list.deinit();

    // for (str, 0..) |row, i| {
    //     for (row, 0..) |_, j| {
    //         std.debug.print("({d}, {d})", .{ i, j });
    //     }
    //     std.debug.print("\n", .{});
    // }

    // std.debug.print("\n", .{});

    for (str, 0..) |_, i| {
        var tmp = std.ArrayList(u8).init(allocator);
        defer tmp.deinit();

        for (0..i + 1) |j| {
            // std.debug.print("({d}, {d})", .{ i - j, j });
            try tmp.append(str[i - j][j]);
        }

        // std.debug.print("\n", .{});
        const slice = try tmp.toOwnedSlice();
        try first_half_list.append(slice);
    }

    var second_half_list = std.ArrayList([]u8).init(allocator);
    defer second_half_list.deinit();

    for (str, 0..) |_, i| {
        var tmp = std.ArrayList(u8).init(allocator);
        defer tmp.deinit();

        const lastIdx = str.len - 1;

        for (0..str.len - i) |j| {
            // std.debug.print("({d}, {d})", .{ lastIdx - j, j + i });
            try tmp.append(str[lastIdx - j][j + i]);
        }
        // std.debug.print("\n", .{});
        const slice = try tmp.toOwnedSlice();
        try second_half_list.append(slice);
    }

    try first_half_list.appendSlice(second_half_list.items[1..]);
    allocator.free(second_half_list.items[0]);

    return first_half_list.toOwnedSlice();
}

test "make_columns - example 2" {
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
        "MMAMXXSSMM",
        "MSMSMXMAAX",
        "MAXAAASXMM",
        "SMSMSMMAMX",
        "XXXAAMSMMA",
        "XMMSMXAAXX",
        "MSAMXXSSMM",
        "AMASAAXAMA",
        "SSMMMMSAMS",
        "MAMXMASAMX",
    };
    const actual = try make_columns(allocator, input);
    defer {
        for (actual) |sl| {
            allocator.free(sl);
        }
        allocator.free(actual);
    }

    try testing.expectEqualDeep(expected, actual);
}

pub fn make_columns(allocator: std.mem.Allocator, str: []const []const u8) ![]const []const u8 {
    var map = std.AutoArrayHashMap(usize, std.ArrayList(u8)).init(allocator);
    defer map.deinit();

    for (str, 0..) |_, row_idx| {
        const sublist = std.ArrayList(u8).init(allocator);
        try map.put(row_idx, sublist);
    }

    for (str) |substr| {
        for (substr, 0..) |char, col_idx| {
            // if you use map.get it leaks memory, switched to getEntry
            // which returns pointers and it's all good
            var entry = map.getEntry(col_idx).?;
            try entry.value_ptr.append(char);
        }
    }

    var result = std.ArrayList([]u8).init(allocator);
    defer result.deinit();

    var it = map.iterator();

    while (it.next()) |row| {
        const value_ptr = row.value_ptr;
        try result.append(try value_ptr.toOwnedSlice());
        value_ptr.deinit();
    }

    return try result.toOwnedSlice();
}

test "find_xmases_in_matrix - example 2" {
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
    const expected: u64 = 18;
    const actual = try find_xmases_in_matrix(allocator, input);

    try testing.expectEqualDeep(expected, actual);
}

test "reverse_rows - example 2" {
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
        "MSAMXXSMMM",
        "ASMSMXMASM",
        "MMAAMXSXMA",
        "XMSMSAMASM",
        "MMAXMASAMX",
        "AMAXXMMAXX",
        "SSXSASMSMS",
        "AAASAMAXAS",
        "MMMMXMMMAM",
        "XSAMXAXMXM",
    };
    const actual = try reverse_rows(allocator, input);
    defer {
        for (actual) |sl| {
            allocator.free(sl);
        }
        allocator.free(actual);
    }

    try testing.expectEqualDeep(expected, actual);
}

pub fn reverse_rows(allocator: std.mem.Allocator, str: []const []const u8) ![]const []const u8 {
    var result = std.ArrayList([]u8).init(allocator);
    defer result.deinit();

    for (str) |row| {
        var reversed = std.ArrayList(u8).init(allocator);
        defer reversed.deinit();

        try reversed.appendSlice(row);
        std.mem.reverse(u8, reversed.items);

        try result.append(try reversed.toOwnedSlice());
    }

    return try result.toOwnedSlice();
}

// wrap it up tomorrow, have all the pieces now
// diagonals, columns, reverse
pub fn find_xmases_in_matrix(allocator: std.mem.Allocator, matrix: []const []const u8) !u64 {
    var count: u64 = 0;

    for (matrix) |str| {
        count += find_xmases_in_string(str);
    }

    _ = allocator;

    return count;
}
