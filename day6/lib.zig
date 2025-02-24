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

fn checkCoordsOutOfBounds(input: []const []const u8, maybe_y: ?usize, maybe_x: ?usize) MapOpError!void {
    if (maybe_y) |y| {
        const max_y = input.len;
        if (y >= max_y) return MapOpError.OutOfBoundsError;
    }

    if (maybe_x) |x| {
        const max_x = input[0].len;
        if (x >= max_x) return MapOpError.OutOfBoundsError;
    }
}

fn getNeighboringCoords(input: []const []const u8, y: usize, x: usize, direction: Direction) MapOpError!GuardPosition {
    return switch (direction) {
        .Up => blk: {
            const new_y = y - 1;
            try checkCoordsOutOfBounds(input, new_y, null);
            break :blk .{ .y = new_y, .x = x };
        },
        .Down => blk: {
            const new_y = y + 1;
            try checkCoordsOutOfBounds(input, new_y, null);
            break :blk .{ .y = new_y, .x = x };
        },
        .Left => blk: {
            const new_x = x - 1;
            try checkCoordsOutOfBounds(input, null, new_x);
            break :blk .{ .y = y, .x = new_x };
        },
        .Right => blk: {
            const new_x = x + 1;
            try checkCoordsOutOfBounds(input, null, new_x);
            break :blk .{ .y = y, .x = new_x };
        },
    };
}

fn already_visited(char: u8) bool {
    return switch (char) {
        '|', '-', '+' => true,
        else => false,
    };
}

fn is_obstructed(char: u8) bool {
    return switch (char) {
        '#' => true,
        else => false,
    };
}

fn printMap(map: []const []const u8) void {
    for (map) |line| {
        std.debug.print("{s}\n", .{line});
    }
    std.debug.print("\n", .{});
}

test "test - advanceCursor 1" {
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

    const actual = try advanceCursor(param, GuardPosition{ .y = 6, .x = 4 }, GuardPosition{ .y = 5, .x = 4 }, false);

    try testing.expectEqual(MoveResult.regular_cell, actual);
    try testing.expectEqual('^', param[5][4]);
    try testing.expectEqual('|', param[6][4]);
    // try testing.expectEqual('^', param[new_pos_1.y][new_pos_1.x]);
}

test "test - advanceCursor 2" {
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

    const actual = try advanceCursor(param, GuardPosition{ .y = 1, .x = 4 }, GuardPosition{ .y = 0, .x = 4 }, false);

    errdefer printMap(param);

    try testing.expectEqual(MoveResult.obstruction, actual);
    try testing.expectEqual('+', param[1][4]);
    try testing.expectEqual('>', param[1][5]);
    // try testing.expectEqual('^', param[new_pos_1.y][new_pos_1.x]);
}

test "test - advanceCursor 3" {
    var param = try testing.allocator.alloc([]u8, 10);
    param[0] = try testing.allocator.dupe(u8, "....#.....");
    param[1] = try testing.allocator.dupe(u8, "....+---+#");
    param[2] = try testing.allocator.dupe(u8, "....|...|.");
    param[3] = try testing.allocator.dupe(u8, "..#.|...|.");
    param[4] = try testing.allocator.dupe(u8, "....|..#|.");
    param[5] = try testing.allocator.dupe(u8, "....|...|.");
    param[6] = try testing.allocator.dupe(u8, ".#..|<--+.");
    param[7] = try testing.allocator.dupe(u8, "........#.");
    param[8] = try testing.allocator.dupe(u8, "#.........");
    param[9] = try testing.allocator.dupe(u8, "......#...");
    defer {
        for (param) |line| testing.allocator.free(line);
        testing.allocator.free(param);
    }

    const actual = try advanceCursor(param, GuardPosition{ .y = 6, .x = 5 }, GuardPosition{ .y = 6, .x = 4 }, false);

    errdefer printMap(param);

    try testing.expectEqual(MoveResult.already_visited, actual);
    try testing.expectEqual('<', param[6][4]);
    try testing.expectEqual('-', param[6][5]);
    // try testing.expectEqual('^', param[new_pos_1.y][new_pos_1.x]);
}

test "test - advanceCursor 4" {
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

    const actual = try advanceCursor(param, GuardPosition{ .y = 6, .x = 4 }, GuardPosition{ .y = 6, .x = 3 }, true);

    errdefer printMap(param);

    try testing.expectEqual(MoveResult.regular_cell, actual);
    try testing.expectEqual('+', param[6][4]);
    try testing.expectEqual('<', param[6][3]);
    // try testing.expectEqual('^', param[new_pos_1.y][new_pos_1.x]);
}

const MoveResult = enum { already_visited, obstruction, regular_cell };

/// result is number of positions visited;
// cases:
// - 1 we want to move to an unvisited, unobstructed cell
// - 2 we want to move to a cell with an obstruction
// - 3 we want to move to an already visited cell
pub fn advanceCursor(input: [][]u8, current_position: GuardPosition, next_position: GuardPosition, current_pos_overlapped: bool) MapOpError!MoveResult {
    const current_char = &input[current_position.y][current_position.x];
    const next_char = &input[next_position.y][next_position.x];

    var result = MoveResult.regular_cell;

    // printMap(input);

    var current_direction = Direction.from_char(current_char.*).?;

    if (is_obstructed(next_char.*)) {
        current_char.* = '+';

        const new_direction = current_direction.turn_right();
        const coords_to_the_right = try getNeighboringCoords(input, current_position.y, current_position.x, new_direction);
        const char_to_the_right = &input[coords_to_the_right.y][coords_to_the_right.x];
        char_to_the_right.* = new_direction.to_char();
        return MoveResult.obstruction;
    } else {
        if (next_char.* == '|' or next_char.* == '-') result = MoveResult.already_visited;

        current_char.* = if (current_pos_overlapped) '+' else if (current_direction == .Up or current_direction == .Down) '|' else '-';
        next_char.* = current_direction.to_char();
    }
    return result;
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
    // adding 1 for the first position
    var positions_visited: u64 = 1;
    var prev_iteration_already_visited = false;

    loop: while (true) {
        const prev_pos = try findGuard(input);
        const direction = Direction.from_char(input[prev_pos.y][prev_pos.x]).?;
        const prev_y = prev_pos.y;
        const prev_x = prev_pos.x;

        const new_pos = getNeighboringCoords(input, prev_y, prev_x, direction) catch |err| switch (err) {
            MapOpError.OutOfBoundsError => break :loop,
            else => return err,
        };

        const move_result = try advanceCursor(input, prev_pos, new_pos, prev_iteration_already_visited);

        if (prev_iteration_already_visited) prev_iteration_already_visited = false;

        switch (move_result) {
            MoveResult.already_visited => prev_iteration_already_visited = true,
            MoveResult.obstruction => positions_visited += 1,
            MoveResult.regular_cell => positions_visited += 1,
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

    try testing.expectEqual(true, try findTurnToTheRight(testing.allocator, param));
    // try testing.expectEqual('^', param[new_pos_1.y][new_pos_1.x]);
}

pub fn findTurnToTheRight(allocator: std.mem.Allocator, input: []const []const u8) !bool {
    var input_copy = try allocator.alloc([]u8, input.len);
    defer {
        for (input_copy) |sl| allocator.free(sl);
        allocator.free(input_copy);
    }

    for (input, 0..) |sl, idx| {
        input_copy[idx] = try allocator.dupe(u8, sl);
    }

    // need to copy the input in;
    // extract a function from the walk one to advance the cursor
    var current_pos = try findGuard(input);

    const current_char: *u8 = &input_copy[current_pos.y][current_pos.x];
    const direction = Direction.from_char(current_char.*).?;

    const new_direction = direction.turn_right();
    current_char.* = new_direction.to_char();

    var next_pos = try getNeighboringCoords(input, current_pos.y, current_pos.x, new_direction);

    while (advanceCursor(input_copy, current_pos, next_pos, false)) |move_result| : ({
        current_pos = next_pos;
        next_pos = try getNeighboringCoords(input, current_pos.y, current_pos.x, new_direction);
        // printMap(input_copy);
    }) {
        if (move_result == MoveResult.obstruction) return true;
    } else |err| {
        switch (err) {
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

    try testing.expectEqual(6, try findLoops(testing.allocator, param));
    // try testing.expectEqual('^', param[new_pos_1.y][new_pos_1.x]);
}

// /// result is number of loops visited;
// // algo is as follows: every time we re-rencounter a cell we've stepped on, we
// // copy the map and run a  line straigh ahead to the right; if we find a '+'
// // it is a position where a loop could be successfully created
pub fn findLoops(allocator: std.mem.Allocator, input: [][]u8) !u64 {
    // adding 1 for the first position
    var cycles: u64 = 1;
    var prev_iteration_already_visited = false;

    const prev_pos = try findGuard(input);
    loop: while (true) : (printMap(input)) {
        const direction = Direction.from_char(input[prev_pos.y][prev_pos.x]).?;
        const prev_y = prev_pos.y;
        const prev_x = prev_pos.x;

        const new_pos = getNeighboringCoords(input, prev_y, prev_x, direction) catch |err| switch (err) {
            MapOpError.OutOfBoundsError => break :loop,
            else => return err,
        };

        if (prev_iteration_already_visited) {
            if (try findTurnToTheRight(allocator, input)) cycles += 1;
        }

        const move_result = try advanceCursor(input, prev_pos, new_pos, prev_iteration_already_visited);

        if (prev_iteration_already_visited) prev_iteration_already_visited = false;

        switch (move_result) {
            MoveResult.already_visited => {},
            MoveResult.obstruction => {},
            MoveResult.regular_cell => {},
        }
    }

    return cycles;
}
