const std = @import("std");
const testing = std.testing;

test "convertInput - 1" {
    const input = &[_][]const u8{
        "89010123",
        "78121874",
        "87430965",
        "96549874",
        "45678903",
        "32019012",
        "01329801",
        "10456732",
    };

    const expected = &[_][]const u8{
        &[_]u8{ 8, 9, 0, 1, 0, 1, 2, 3 },
        &[_]u8{ 7, 8, 1, 2, 1, 8, 7, 4 },
        &[_]u8{ 8, 7, 4, 3, 0, 9, 6, 5 },
        &[_]u8{ 9, 6, 5, 4, 9, 8, 7, 4 },
        &[_]u8{ 4, 5, 6, 7, 8, 9, 0, 3 },
        &[_]u8{ 3, 2, 0, 1, 9, 0, 1, 2 },
        &[_]u8{ 0, 1, 3, 2, 9, 8, 0, 1 },
        &[_]u8{ 1, 0, 4, 5, 6, 7, 3, 2 },
    };

    const actual = try convertInput(testing.allocator, input);
    defer {
        for (actual) |line| testing.allocator.free(line);
        testing.allocator.free(actual);
    }

    try testing.expectEqualDeep(expected, actual);
}

pub fn convertInput(allocator: std.mem.Allocator, input: []const []const u8) ![][]u8 {
    var result = try allocator.alloc([]u8, input.len);

    for (input, 0..) |line, i| {
        var list = try allocator.alloc(u8, line.len);

        for (line, 0..) |char, j| {
            const num = try std.fmt.parseUnsigned(u8, &[_]u8{char}, 10);
            list[j] = num;
        }

        result[i] = list;
    }

    return result;
}

const TrailError = error{OutOfBounds};

fn checkCoordsOutOfBounds(input: []const []const u8, maybe_x: ?usize, maybe_y: ?usize) TrailError!void {
    if (maybe_x) |x| {
        const max_x = input[0].len;
        if (x >= max_x) return TrailError.OutOfBounds;
    }

    if (maybe_y) |y| {
        const max_y = input.len;
        if (y >= max_y) return TrailError.OutOfBounds;
    }
}

test "getAdjacentPosition - test 1" {
    const input = &[_][]const u8{
        &[_]u8{ 8, 9, 0, 1, 0, 1, 2, 3 },
        &[_]u8{ 7, 8, 1, 2, 1, 8, 7, 4 },
        &[_]u8{ 8, 7, 4, 3, 0, 9, 6, 5 },
        &[_]u8{ 9, 6, 5, 4, 9, 8, 7, 4 },
        &[_]u8{ 4, 5, 6, 7, 8, 9, 0, 3 },
        &[_]u8{ 3, 2, 0, 1, 9, 0, 1, 2 },
        &[_]u8{ 0, 1, 3, 2, 9, 8, 0, 1 },
        &[_]u8{ 1, 0, 4, 5, 6, 7, 3, 2 },
    };

    try testing.expectEqual(Coords{ .x = 2, .y = 1 }, try getAdjacentPosition(input, Coords{ .x = 1, .y = 1 }, .Right));
    try testing.expectEqual(Coords{ .x = 1, .y = 2 }, try getAdjacentPosition(input, Coords{ .x = 1, .y = 1 }, .Down));
    try testing.expectEqual(Coords{ .x = 0, .y = 1 }, try getAdjacentPosition(input, Coords{ .x = 1, .y = 1 }, .Left));
    try testing.expectEqual(Coords{ .x = 1, .y = 0 }, try getAdjacentPosition(input, Coords{ .x = 1, .y = 1 }, .Up));
}

test "getAdjacentPosition - test 2" {
    const input = &[_][]const u8{
        &[_]u8{ 8, 9, 0, 1, 0, 1, 2, 3 },
        &[_]u8{ 7, 8, 1, 2, 1, 8, 7, 4 },
        &[_]u8{ 8, 7, 4, 3, 0, 9, 6, 5 },
        &[_]u8{ 9, 6, 5, 4, 9, 8, 7, 4 },
        &[_]u8{ 4, 5, 6, 7, 8, 9, 0, 3 },
        &[_]u8{ 3, 2, 0, 1, 9, 0, 1, 2 },
        &[_]u8{ 0, 1, 3, 2, 9, 8, 0, 1 },
        &[_]u8{ 1, 0, 4, 5, 6, 7, 3, 2 },
    };

    const actual = getAdjacentPosition(input, Coords{ .x = 7, .y = 0 }, .Right);

    try testing.expectError(TrailError.OutOfBounds, actual);
}

const Direction = enum {
    Up,
    Down,
    Left,
    Right,
};

// it's wierd because by passing in input we have a map where in a normal state
// we already have a current position, eg where the guard is, so it's wierd that
// this function accepts arbitrary x and y
fn getAdjacentPosition(input: []const []const u8, current_pos: Coords, direction: Direction) TrailError!Coords {
    const current_x, const current_y = .{ current_pos.x, current_pos.y };

    return switch (direction) {
        .Up => {
            if (current_y == 0) return TrailError.OutOfBounds;
            const new_y = current_y - 1;
            try checkCoordsOutOfBounds(input, null, new_y);
            return Coords{ .x = current_x, .y = new_y };
        },
        .Down => {
            const new_y = current_y + 1;
            try checkCoordsOutOfBounds(input, null, new_y);
            return Coords{ .x = current_x, .y = new_y };
        },
        .Left => {
            if (current_x == 0) return TrailError.OutOfBounds;
            const new_x = current_x - 1;
            try checkCoordsOutOfBounds(input, new_x, null);
            return Coords{ .x = new_x, .y = current_y };
        },
        .Right => {
            const new_x = current_x + 1;
            try checkCoordsOutOfBounds(input, new_x, null);
            return Coords{ .x = new_x, .y = current_y };
        },
    };
}

test "calculateTrailHeadScore - 1" {
    const input = &[_][]const u8{
        &[_]u8{ 8, 8, 8, 0, 8, 8, 8 },
        &[_]u8{ 8, 8, 8, 1, 8, 8, 8 },
        &[_]u8{ 8, 8, 8, 2, 8, 8, 8 },
        &[_]u8{ 6, 5, 4, 3, 4, 5, 6 },
        &[_]u8{ 7, 2, 8, 8, 8, 2, 7 },
        &[_]u8{ 8, 8, 8, 8, 8, 8, 8 },
        &[_]u8{ 9, 8, 8, 8, 8, 8, 9 },
    };

    try testing.expectEqual(2, try calculateTrailHeadScore(testing.allocator, input, .{ .x = 3, .y = 0 }));
}

test "calculateTrailHeadScore - 2" {
    const input = &[_][]const u8{
        &[_]u8{ 1, 1, 9, 0, 2, 1, 9 },
        &[_]u8{ 1, 1, 1, 1, 1, 9, 8 },
        &[_]u8{ 1, 1, 1, 2, 1, 1, 7 },
        &[_]u8{ 6, 5, 4, 3, 4, 5, 6 },
        &[_]u8{ 7, 6, 5, 1, 9, 8, 7 },
        &[_]u8{ 8, 7, 6, 1, 1, 1, 1 },
        &[_]u8{ 9, 8, 7, 1, 1, 1, 1 },
    };

    try testing.expectEqual(4, try calculateTrailHeadScore(testing.allocator, input, .{ .x = 3, .y = 0 }));
}

test "calculateTrailHeadScore - 3" {
    const input = &[_][]const u8{
        &[_]u8{ 8, 9, 0, 1, 0, 1, 2, 3 },
        &[_]u8{ 7, 8, 1, 2, 1, 8, 7, 4 },
        &[_]u8{ 8, 7, 4, 3, 0, 9, 6, 5 },
        &[_]u8{ 9, 6, 5, 4, 9, 8, 7, 4 },
        &[_]u8{ 4, 5, 6, 7, 8, 9, 0, 3 },
        &[_]u8{ 3, 2, 0, 1, 9, 0, 1, 2 },
        &[_]u8{ 0, 1, 3, 2, 9, 8, 0, 1 },
        &[_]u8{ 1, 0, 4, 5, 6, 7, 3, 2 },
    };

    try testing.expectEqual(5, try calculateTrailHeadScore(testing.allocator, input, .{ .x = 2, .y = 0 }));
}

const Coords = struct {
    x: usize,
    y: usize,
};

pub fn calculateTrailHeadScore(allocator: std.mem.Allocator, input: []const []const u8, start: Coords) !u64 {
    var score: u64 = 0;

    var list: *std.ArrayList(Coords) = try allocator.create(std.ArrayList(Coords));
    list.* = std.ArrayList(Coords).init(allocator);

    // std.debug.print("start: {*}\n", .{list});
    defer {
        // std.debug.print("end: {*}\n", .{list});
        list.deinit();
        allocator.destroy(list);
    }

    try list.append(start);

    var nines_found = std.AutoHashMap(Coords, void).init(allocator);
    defer nines_found.deinit();

    while (list.items.len > 0) {
        // std.debug.print("{any}\n", .{list.items});
        // sometimes the loop below appends stuff to the list and it is resized
        // automatically, invalidating the list.items pointer, so we ensure that
        // before the loop we at least have space to fit all the potential items
        // we might add

        const new_list_ptr = try allocator.create(std.ArrayList(Coords));
        new_list_ptr.* = std.ArrayList(Coords).init(allocator);

        var just_added = std.AutoHashMap(Coords, void).init(allocator);
        defer just_added.deinit();

        // std.debug.print("list: {any}\n", .{list.items});

        try new_list_ptr.ensureUnusedCapacity(list.items.len * 4);
        for (list.items) |coords| {
            const current_val = input[coords.y][coords.x];

            inner: for ([_]Direction{ .Up, .Down, .Left, .Right }) |new_direction| {
                if (getAdjacentPosition(input, coords, new_direction)) |new_pos| {
                    const next_val = input[new_pos.y][new_pos.x];
                    const diff: i16 = @as(i8, @intCast(next_val)) - @as(i8, @intCast(current_val));
                    const slope_is_gradual = diff == 1;

                    if (slope_is_gradual) {
                        if (next_val == 9 and !nines_found.contains(new_pos)) {
                            // std.debug.print("found 9: current:{any} new:{any}\n", .{ coords, new_pos });
                            score += 1;
                            try nines_found.put(new_pos, {});
                            continue :inner;
                        }
                        if (!just_added.contains(new_pos)) {
                            // std.debug.print("appending: current:{any} new:{any}\n", .{ coords, new_pos });
                            try new_list_ptr.append(new_pos);
                        }

                        try just_added.put(new_pos, {});
                    }
                } else |_| {}
            }
        }
        // std.debug.print("new_list: {any}\n", .{new_list_ptr.*.items});

        list.deinit();
        allocator.destroy(list);
        list = new_list_ptr;
    }
    return score;
}

test "calculateAllTrailScores - 1" {
    const input = &[_][]const u8{
        &[_]u8{ 8, 9, 0, 1, 0, 1, 2, 3 },
        &[_]u8{ 7, 8, 1, 2, 1, 8, 7, 4 },
        &[_]u8{ 8, 7, 4, 3, 0, 9, 6, 5 },
        &[_]u8{ 9, 6, 5, 4, 9, 8, 7, 4 },
        &[_]u8{ 4, 5, 6, 7, 8, 9, 0, 3 },
        &[_]u8{ 3, 2, 0, 1, 9, 0, 1, 2 },
        &[_]u8{ 0, 1, 3, 2, 9, 8, 0, 1 },
        &[_]u8{ 1, 0, 4, 5, 6, 7, 3, 2 },
    };

    try testing.expectEqual(36, try calculateAllTrailScores(testing.allocator, input));
}

pub fn calculateAllTrailScores(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var score: u64 = 0;

    var trailheads = std.ArrayList(Coords).init(allocator);
    defer trailheads.deinit();

    for (input, 0..) |row, row_i| {
        for (row, 0..) |cell, col_i| {
            if (cell == 0) try trailheads.append(Coords{ .x = col_i, .y = row_i });
        }
    }

    for (trailheads.items) |trailhead_coords| {
        const trailhead_score = try calculateTrailHeadScore(allocator, input, trailhead_coords);
        score += trailhead_score;
    }
    return score;
}

test "calculateTrailHeadRating - 1" {
    const input = &[_][]const u8{
        &[_]u8{ 1, 1, 1, 1, 8, 0, 8 },
        &[_]u8{ 1, 1, 4, 3, 2, 1, 1 },
        &[_]u8{ 1, 1, 5, 1, 1, 2, 1 },
        &[_]u8{ 1, 1, 6, 5, 4, 3, 1 },
        &[_]u8{ 1, 1, 7, 1, 1, 4, 1 },
        &[_]u8{ 1, 1, 8, 7, 6, 5, 1 },
        &[_]u8{ 1, 1, 9, 1, 1, 1, 1 },
    };

    try testing.expectEqual(3, try calculateTrailHeadRating(testing.allocator, input, .{ .x = 5, .y = 0 }));
}

test "calculateTrailHeadRating - 2" {
    const input = &[_][]const u8{
        &[_]u8{ 1, 1, 9, 0, 8, 1, 9 },
        &[_]u8{ 1, 1, 1, 1, 1, 9, 8 },
        &[_]u8{ 1, 1, 1, 2, 1, 1, 7 },
        &[_]u8{ 6, 5, 4, 3, 4, 5, 6 },
        &[_]u8{ 7, 6, 5, 1, 9, 8, 7 },
        &[_]u8{ 8, 7, 6, 1, 1, 1, 1 },
        &[_]u8{ 9, 8, 7, 1, 1, 1, 1 },
    };

    try testing.expectEqual(13, try calculateTrailHeadRating(testing.allocator, input, .{ .x = 3, .y = 0 }));
}

test "calculateTrailHeadRating - 3" {
    const input = &[_][]const u8{
        &[_]u8{ 0, 1, 2, 3, 4, 5 },
        &[_]u8{ 1, 2, 3, 4, 5, 6 },
        &[_]u8{ 2, 3, 4, 5, 6, 7 },
        &[_]u8{ 3, 4, 5, 6, 7, 8 },
        &[_]u8{ 4, 1, 6, 7, 8, 9 },
        &[_]u8{ 5, 6, 7, 8, 9, 1 },
    };

    try testing.expectEqual(227, try calculateTrailHeadRating(testing.allocator, input, .{ .x = 2, .y = 0 }));
}

// should probably implement a pathfinding algorithm
pub fn calculateTrailHeadRating(allocator: std.mem.Allocator, input: []const []const u8, start: Coords) !u64 {
    var score: u64 = 0;
    var tmp: u64 = 0;

    var list: *std.ArrayList(Coords) = try allocator.create(std.ArrayList(Coords));
    list.* = std.ArrayList(Coords).init(allocator);

    // std.debug.print("start: {*}\n", .{list});
    defer {
        // std.debug.print("end: {*}\n", .{list});
        list.deinit();
        allocator.destroy(list);
    }

    try list.append(start);

    while (list.items.len > 0) {
        // std.debug.print("{any}\n", .{list.items});
        // sometimes the loop below appends stuff to the list and it is resized
        // automatically, invalidating the list.items pointer, so we ensure that
        // before the loop we at least have space to fit all the potential items
        // we might add

        const new_list_ptr = try allocator.create(std.ArrayList(Coords));
        new_list_ptr.* = std.ArrayList(Coords).init(allocator);

        std.debug.print("list: {any}\n", .{list.items});
        std.debug.print("score: {d}\n", .{list.items.len});
        std.debug.print("tmp: {d}\n", .{tmp});

        try new_list_ptr.ensureUnusedCapacity(list.items.len * 4);
        for (list.items) |coords| {
            const current_val = input[coords.y][coords.x];

            inner: for ([_]Direction{ .Up, .Down, .Left, .Right }) |new_direction| {
                if (getAdjacentPosition(input, coords, new_direction)) |new_pos| {
                    const next_val = input[new_pos.y][new_pos.x];
                    const diff: i16 = @as(i8, @intCast(next_val)) - @as(i8, @intCast(current_val));
                    const slope_is_gradual = diff == 1;

                    if (slope_is_gradual) {
                        tmp += 1;
                        if (next_val == 9) {
                            // std.debug.print("found 9: current:{any} new:{any}\n", .{ coords, new_pos });
                            score += 1;
                            continue :inner;
                        }
                        std.debug.print("appending: current:{any} new:{any}\n", .{ coords, new_pos });
                        try new_list_ptr.append(new_pos);
                    }
                } else |_| {}
            }
        }
        std.debug.print("new_list: {any}\n", .{new_list_ptr.*.items});

        list.deinit();
        allocator.destroy(list);
        list = new_list_ptr;
    }
    return score;
}

test "calculateAllTrailRatings - 1" {
    const input = &[_][]const u8{
        &[_]u8{ 8, 9, 0, 1, 0, 1, 2, 3 },
        &[_]u8{ 7, 8, 1, 2, 1, 8, 7, 4 },
        &[_]u8{ 8, 7, 4, 3, 0, 9, 6, 5 },
        &[_]u8{ 9, 6, 5, 4, 9, 8, 7, 4 },
        &[_]u8{ 4, 5, 6, 7, 8, 9, 0, 3 },
        &[_]u8{ 3, 2, 0, 1, 9, 0, 1, 2 },
        &[_]u8{ 0, 1, 3, 2, 9, 8, 0, 1 },
        &[_]u8{ 1, 0, 4, 5, 6, 7, 3, 2 },
    };

    try testing.expectEqual(36, try calculateAllTrailRatings(testing.allocator, input));
}

pub fn calculateAllTrailRatings(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var score: u64 = 0;

    var trailheads = std.ArrayList(Coords).init(allocator);
    defer trailheads.deinit();

    for (input, 0..) |row, row_i| {
        for (row, 0..) |cell, col_i| {
            if (cell == 0) try trailheads.append(Coords{ .x = col_i, .y = row_i });
        }
    }

    for (trailheads.items) |trailhead_coords| {
        const trailhead_score = try calculateTrailHeadRating(allocator, input, trailhead_coords);
        score += trailhead_score;
    }
    return score;
}
