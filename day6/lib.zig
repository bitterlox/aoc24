const std = @import("std");
const testing = std.testing;

test "test" {}

fn parseInput() void {}

test findGuard {
    const param: []const []const u8 = &[_][]const u8{
        "....#.....",
        "....^....#",
        "..........",
        "..#.......",
        ".......#..",
        "..........",
        ".#........",
        "........#.",
        "#.........",
        "......#...",
    };

    try testing.expectEqual(GuardPosition{ .x = 4, .y = 1 }, try findGuard(param));
}

const MapOpError = error{ FoundObstacleError, OutOfBoundsError, NoGuardError };

const GuardPosition = struct { x: usize, y: usize };

const Direction = union(enum) {
    Up,
    Down,
    Left,
    Right,

    const Self = @This();

    fn from_char(char: u8) ?Self {
        return switch (char) {
            '^' => .Up,
            'v' => .Down,
            '<' => .Left,
            '>' => .Right,
            else => null,
        };
    }

    fn to_char(self: Self) u8 {
        return switch (self) {
            .Up => '^',
            .Down => 'v',
            .Left => '<',
            .Right => '>',
        };
    }
};

/// result is .{x, y}
fn findGuard(input: []const []const u8) MapOpError!GuardPosition {
    for (input, 0..) |line, y| {
        for (line, 0..) |char, x| {
            const maybe_direction = Direction.from_char(char);
            if (maybe_direction) |_| return .{ .x = x, .y = y };
        }
    }

    return MapOpError.NoGuardError;
}

test moveGuard {
    var param = try testing.allocator.alloc([]u8, 10);
    param[0] = try testing.allocator.dupe(u8, "....#.....");
    param[1] = try testing.allocator.dupe(u8, "....^....#");
    param[2] = try testing.allocator.dupe(u8, "..........");
    param[3] = try testing.allocator.dupe(u8, "..#.......");
    param[4] = try testing.allocator.dupe(u8, ".......#..");
    param[5] = try testing.allocator.dupe(u8, "..........");
    param[6] = try testing.allocator.dupe(u8, ".#........");
    param[7] = try testing.allocator.dupe(u8, "........#.");
    param[8] = try testing.allocator.dupe(u8, "#.........");
    param[9] = try testing.allocator.dupe(u8, "......#...");
    defer {
        for (param) |line| testing.allocator.free(line);
        testing.allocator.free(param);
    }

    const maybe_new_pos_1 = moveGuard(param, .Up);
    try testing.expectError(MapOpError.FoundObstacleError, maybe_new_pos_1);
    // try testing.expectEqual('^', param[new_pos_1.y][new_pos_1.x]);

    const new_pos_2, _ = try moveGuard(param, .Right);
    try testing.expectEqual(GuardPosition{ .x = 5, .y = 1 }, new_pos_2);
    try testing.expectEqual('>', param[new_pos_2.y][new_pos_2.x]);

    const new_pos_3, _ = try moveGuard(param, .Up);
    try testing.expectEqual(GuardPosition{ .x = 5, .y = 0 }, new_pos_3);
    try testing.expectEqual('^', param[new_pos_3.y][new_pos_3.x]);

    const new_pos_4, _ = try moveGuard(param, .Down);
    try testing.expectEqual(GuardPosition{ .x = 5, .y = 1 }, new_pos_4);
    try testing.expectEqual('v', param[new_pos_4.y][new_pos_4.x]);

    const new_pos_5, _ = try moveGuard(param, .Left);
    try testing.expectEqual(GuardPosition{ .x = 4, .y = 1 }, new_pos_5);
    try testing.expectEqual('<', param[new_pos_5.y][new_pos_5.x]);
}

/// result is new position of guard .{x, y}
fn moveGuard(input: [][]u8, direction: Direction) MapOpError!struct { GuardPosition, bool } {
    const prev_pos = try findGuard(input);
    const prev_y = prev_pos.y;
    const prev_x = prev_pos.x;

    const max_x = input[0].len;
    const max_y = input.len;

    const new_pos: GuardPosition = switch (direction) {
        .Up => blk: {
            const new_y = prev_y - 1;
            if (new_y >= max_y) return MapOpError.OutOfBoundsError;
            break :blk .{ .y = new_y, .x = prev_x };
        },
        .Down => blk: {
            const new_y = prev_y + 1;
            if (new_y >= max_y) return MapOpError.OutOfBoundsError;
            break :blk .{ .y = new_y, .x = prev_x };
        },
        .Left => blk: {
            const new_x = prev_x - 1;
            if (new_x >= max_x) return MapOpError.OutOfBoundsError;
            break :blk .{ .y = prev_y, .x = new_x };
        },
        .Right => blk: {
            const new_x = prev_x + 1;
            if (new_x >= max_x) return MapOpError.OutOfBoundsError;
            break :blk .{ .y = prev_y, .x = new_x };
        },
    };
    if (input[new_pos.y][new_pos.x] == '#') return MapOpError.FoundObstacleError;

    var already_visited = false;

    input[prev_y][prev_x] = 'X';

    if (input[new_pos.y][new_pos.x] == 'X') already_visited = true;

    input[new_pos.y][new_pos.x] = direction.to_char();

    return .{ new_pos, already_visited };
}

test walkGuard {
    var param = try testing.allocator.alloc([]u8, 10);
    param[0] = try testing.allocator.dupe(u8, "....#.....");
    param[1] = try testing.allocator.dupe(u8, ".........#");
    param[2] = try testing.allocator.dupe(u8, "..........");
    param[3] = try testing.allocator.dupe(u8, "..#.......");
    param[4] = try testing.allocator.dupe(u8, ".......#..");
    param[5] = try testing.allocator.dupe(u8, "..........");
    param[6] = try testing.allocator.dupe(u8, ".#..^.....");
    param[7] = try testing.allocator.dupe(u8, "........#.");
    param[8] = try testing.allocator.dupe(u8, "#.........");
    param[9] = try testing.allocator.dupe(u8, "......#...");
    defer {
        for (param) |line| testing.allocator.free(line);
        testing.allocator.free(param);
    }

    try testing.expectEqual(41, try walkGuard(param));
    // try testing.expectEqual('^', param[new_pos_1.y][new_pos_1.x]);
}

fn printMap(map: [][]u8) void {
    for (map) |line| {
        std.debug.print("{s}\n", .{line});
    }
    std.debug.print("\n", .{});
}

/// result is number of positions visited;
pub fn walkGuard(input: [][]u8) MapOpError!u64 {
    // starting at 1 to include spot guard is standing on
    var positions_visited: u64 = 1;

    const guard_position = try findGuard(input);
    const current_char = input[guard_position.y][guard_position.x];
    var direction = Direction.from_char(current_char) orelse @panic("found unexpected character");

    loop: while (true) {
        const maybe_move_result = moveGuard(input, direction);
        if (maybe_move_result) |move_result| {
            _, const already_visited = move_result;
            if (!already_visited) positions_visited += 1;
            continue;
        } else |err| {
            switch (err) {
                MapOpError.FoundObstacleError => {
                    // this codifies the action of "turning right"
                    direction = switch (direction) {
                        .Up => .Right,
                        .Right => .Down,
                        .Down => .Left,
                        .Left => .Up,
                    };
                    continue;
                },
                // in the end the map is left with the guard char still in place
                // and no X, but count is accurate
                MapOpError.OutOfBoundsError => break :loop,
                else => @panic("unexpected MapOpError"),
            }
        }
    }

    return positions_visited;
}
