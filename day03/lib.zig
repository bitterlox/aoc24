const std = @import("std");
const testing = std.testing;

test "find_muls - example 1" {
    const allocator = std.testing.allocator;

    const expected: []const [2]u64 = &.{ .{ 2, 4 }, .{ 5, 5 }, .{ 11, 8 }, .{ 8, 5 } };
    const actual: []const [2]u64 = try find_muls(allocator, "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))");
    defer allocator.free(actual);

    try testing.expectEqualSlices([2]u64, expected, actual);
}

/// caller takes ownership of result slice
pub fn find_muls(allocator: std.mem.Allocator, str: []const u8) ![]const [2]u64 {
    if (str.len < 10) unreachable;

    const ops = try parse_string(allocator, str);
    defer allocator.free(ops);

    var list = std.ArrayList([2]u64).init(allocator);
    defer list.deinit();

    for (ops) |op| {
        switch (op) {
            .mul => |arr| try list.append(arr),
            else => {},
        }
    }

    return list.toOwnedSlice();
}

test "parse_string - example 1" {
    const allocator = std.testing.allocator;

    const expected: []const Op = &.{ .{ .mul = .{ 2, 4 } }, Op.dont, .{ .mul = .{ 5, 5 } }, .{ .mul = .{ 11, 8 } }, Op.do, .{ .mul = .{ 8, 5 } } };
    const actual: []const Op = try parse_string(allocator, "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))");
    defer allocator.free(actual);

    try testing.expectEqualSlices(Op, expected, actual);
}

const Op = union(enum) {
    do,
    dont,
    mul: [2]u64,
};

/// caller takes ownership of result slice
pub fn parse_string(allocator: std.mem.Allocator, str: []const u8) ![]const Op {
    if (str.len < 10) unreachable;

    var list = std.ArrayList(Op).init(allocator);
    defer list.deinit();

    // algo is a 4-item sliding slice over the input string

    // note a ranged for(a..b) is exclusive of the b, so this loops until
    // b-1

    // the -3 +1 is necessary because slice syntax upper bound is exclusive
    // so arr = arr[0..arr.length]
    const view_start_min_idx = 0;
    const view_start_max_idx = str.len - 3;
    const view_end_min_idx = 4;
    const view_end_max_idx = str.len + 1;
    for (view_start_min_idx..view_start_max_idx, view_end_min_idx..view_end_max_idx) |i, j| {
        const view = str[i..j];
        // std.debug.print("{s}\n", .{view});
        // std.debug.print("view: {s} {d} {d} {d}\n", .{ view, i, j, str.len });

        if (std.mem.eql(u8, view, "do()")) {
            try list.append(Op.do);
            continue;
        }
        if (std.mem.eql(u8, view, "don'")) {
            const larger_view = str[i .. j + 3];
            if (std.mem.eql(u8, larger_view, "don't()")) {
                try list.append(Op.dont);
                continue;
            }
        }
        if (std.mem.eql(u8, view, "mul(")) {
            var first_param = std.ArrayList(u8).init(allocator);
            defer first_param.deinit();
            var second_param = std.ArrayList(u8).init(allocator);
            defer second_param.deinit();

            var comma: bool = false;

            var close_parens: ?usize = null;
            {
                var k: usize = j;
                loop: while (k < j + 10 and k < view_end_max_idx) : (k += 1) {
                    switch (str[k]) {
                        '0'...'9' => {
                            if (!comma) {
                                try first_param.append(str[k]);
                            } else {
                                try second_param.append(str[k]);
                            }
                        },
                        ',' => {
                            comma = true;
                        },
                        ')' => {
                            close_parens = k;
                            break;
                        },
                        else => break :loop,
                    }
                }
            }
            if (close_parens != null) {
                // std.debug.print("mul params from {d} to {d}: {s} ", .{ j, close_parens.?, str[i .. close_parens.? + 1] });
            }
            const proceed = first_param.items.len > 0 and second_param.items.len > 0 and comma and close_parens != null;
            if (proceed) {
                const first = try std.fmt.parseInt(u64, first_param.items, 10);
                const second = try std.fmt.parseInt(u64, second_param.items, 10);

                const arr = [2]u64{ first, second };
                // std.debug.print("arr: {d}\n", .{arr});
                // std.debug.print("{d}\n", .{arr});

                try list.append(.{ .mul = arr });
            }
        }
    }
    return try list.toOwnedSlice();
}
