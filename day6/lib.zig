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

    fn turn_right(self: Self) Direction {
        return switch (self) {
            .Up => .Right,
            .Right => .Down,
            .Down => .Left,
            .Left => .Up,
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

test calculateNextGuardPosition {
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

    const maybe_new_pos_1 = calculateNextGuardPosition(param, .Up);
    try testing.expectError(MapOpError.FoundObstacleError, maybe_new_pos_1);
    // try testing.expectEqual('^', param[new_pos_1.y][new_pos_1.x]);

    const new_pos_2 = try calculateNextGuardPosition(param, .Right);
    try testing.expectEqual(GuardPosition{ .x = 5, .y = 1 }, new_pos_2);

    const new_pos_4 = try calculateNextGuardPosition(param, .Down);
    try testing.expectEqual(GuardPosition{ .x = 4, .y = 2 }, new_pos_4);

    const new_pos_5 = try calculateNextGuardPosition(param, .Left);
    try testing.expectEqual(GuardPosition{ .x = 3, .y = 1 }, new_pos_5);
}

/// result is new position of guard .{x, y}
fn calculateNextGuardPosition(input: []const []const u8, direction: Direction) MapOpError!GuardPosition {
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

    return new_pos;
}

fn already_visited(char: u8) bool {
    return switch (char) {
        '|', '-', '+' => true,
        else => false,
    };
}

fn printMap(map: [][]u8) void {
    for (map) |line| {
        std.debug.print("{s}\n", .{line});
    }
    std.debug.print("\n", .{});
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

/// result is number of positions visited;
pub fn walkGuard(input: [][]u8) MapOpError!u64 {
    // starting at 1 to include spot guard is standing on
    var positions_visited: u64 = 1;

    var guard_position = try findGuard(input);
    var direction = Direction.from_char(input[guard_position.y][guard_position.x]) orelse @panic("found unexpected character");

    var current_char: *u8 = undefined;
    var next_char: *u8 = undefined;
    var curr_char_already_visited = false;

    loop: while (true) : ({
        curr_char_already_visited = already_visited(next_char.*);
        next_char.* = direction.to_char();
        // printMap(input);
    }) {
        const maybe_move_result = calculateNextGuardPosition(input, direction);

        current_char = &input[guard_position.y][guard_position.x];

        if (maybe_move_result) |move_result| {
            next_char = &input[move_result.y][move_result.x];

            // draw map
            current_char.* = blk: {
                if (curr_char_already_visited) {
                    break :blk '+';
                } else {
                    break :blk switch (direction) {
                        .Up, .Down => '|',
                        .Left, .Right => '-',
                    };
                }
            };
            guard_position = move_result;

            if (!already_visited(next_char.*)) {
                positions_visited += 1;
            }

            continue;
        } else |err| {
            switch (err) {
                // in the end the map is left with the guard char still in place
                // and no X, but count is accurate
                MapOpError.FoundObstacleError => {

                    // this codifies the action of "turning right"
                    direction = switch (direction) {
                        .Up => .Right,
                        .Right => .Down,
                        .Down => .Left,
                        .Left => .Up,
                    };

                    const maybe_another_move_result = calculateNextGuardPosition(input, direction);
                    if (maybe_another_move_result) |good_result| {
                        current_char.* = '+';
                        next_char = &input[good_result.y][good_result.x];
                        guard_position = good_result;
                        positions_visited += 1;
                    } else |other_err| return other_err;
                },
                MapOpError.OutOfBoundsError => break :loop,
                else => return err,
            }
        }
    }

    return positions_visited;
}

test findTurnToTheRight {
    var param = try testing.allocator.alloc([]u8, 10);
    param[0] = try testing.allocator.dupe(u8, "....#.....");
    param[1] = try testing.allocator.dupe(u8, "....+---+#");
    param[2] = try testing.allocator.dupe(u8, "....|...|.");
    param[3] = try testing.allocator.dupe(u8, "..#.|...|.");
    param[4] = try testing.allocator.dupe(u8, "....|..#|.");
    param[5] = try testing.allocator.dupe(u8, "....|...|.");
    param[6] = try testing.allocator.dupe(u8, ".#..<---+.");
    param[7] = try testing.allocator.dupe(u8, "........#.");
    param[8] = try testing.allocator.dupe(u8, "#.........");
    param[9] = try testing.allocator.dupe(u8, "......#...");
    defer {
        for (param) |line| testing.allocator.free(line);
        testing.allocator.free(param);
    }

    try testing.expectEqual(true, try findTurnToTheRight(param));
    // try testing.expectEqual('^', param[new_pos_1.y][new_pos_1.x]);
}

pub fn findTurnToTheRight(input: [][]u8) MapOpError!bool {
    // need to copy the input in;
    // extract a function from the walk one to advance the cursor
    const current_pos = try findGuard(input);
    const current_char = input[current_pos.y][current_pos.x];
    const direction = Direction.from_char(current_char) orelse @panic("no direction");
    const new_direction = direction.turn_right();
    while (calculateNextGuardPosition(input, new_direction)) |_| {} else |err| {
        switch (err) {
            MapOpError.FoundObstacleError => return true,
            MapOpError.OutOfBoundsError => return false,
            else => return err,
        }
    }
}

test findLoops {
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

    try testing.expectEqual(41, try findLoops(param));
    // try testing.expectEqual('^', param[new_pos_1.y][new_pos_1.x]);
}

/// result is number of loops visited;
// algo is as follows: every time we re-rencounter a cell we've stepped on, we
// copy the map and run a  line straigh ahead to the right; if we find a '+'
// it is a position where a loop could be successfully created
pub fn findLoops(input: [][]u8) MapOpError!u64 {
    // starting at 1 to include spot guard is standing on
    var positions_visited: u64 = 1;

    var guard_position = try findGuard(input);
    var direction = Direction.from_char(input[guard_position.y][guard_position.x]) orelse @panic("found unexpected character");

    var current_char: *u8 = undefined;
    var next_char: *u8 = undefined;
    var curr_char_already_visited = false;

    loop: while (true) : ({
        curr_char_already_visited = already_visited(next_char.*);
        next_char.* = direction.to_char();
        // printMap(input);
    }) {
        const maybe_move_result = calculateNextGuardPosition(input, direction);

        current_char = &input[guard_position.y][guard_position.x];

        if (maybe_move_result) |move_result| {
            next_char = &input[move_result.y][move_result.x];

            // draw map
            current_char.* = blk: {
                if (curr_char_already_visited) {
                    break :blk '+';
                } else {
                    break :blk switch (direction) {
                        .Up, .Down => '|',
                        .Left, .Right => '-',
                    };
                }
            };
            guard_position = move_result;

            if (!already_visited(next_char.*)) {
                positions_visited += 1;
            }

            continue;
        } else |err| {
            switch (err) {
                // in the end the map is left with the guard char still in place
                // and no X, but count is accurate
                MapOpError.FoundObstacleError => {

                    // this codifies the action of "turning right"
                    direction = direction.turn_right();

                    const maybe_another_move_result = calculateNextGuardPosition(input, direction);
                    if (maybe_another_move_result) |good_result| {
                        current_char.* = '+';
                        next_char = &input[good_result.y][good_result.x];
                        guard_position = good_result;
                        positions_visited += 1;
                    } else |other_err| return other_err;
                },
                MapOpError.OutOfBoundsError => break :loop,
                else => return err,
            }
        }
    }

    return positions_visited;
}
