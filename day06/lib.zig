const std = @import("std");
const testing = std.testing;
// This code returns a result off by ~80/90
// i spent too much time trying to debug this and then decided for a
// OOP oriented refactoring which by virtue of its cleanliness(and lessons learned?)
// removed the bug without me having to track it down

test "test" {}

fn parseInput() void {}

/// caller takes ownership of memory
pub fn dupeInput(allocator: std.mem.Allocator, input_to_copy: []const []const u8) ![][]u8 {
    const result = try allocator.alloc([]u8, input_to_copy.len);
    for (input_to_copy, 0..) |sl, idx| {
        result[idx] = try allocator.dupe(u8, sl);
    }

    return result;
}

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

const GuardPosition = struct {
    x: usize,
    y: usize,

    const Self = @This();

    fn get_char_from_input(self: Self, input: []const []const u8) !*const u8 {
        try checkCoordsOutOfBounds(input, self.y, self.x);
        return &input[self.y][self.x];
    }

    fn get_mut_char_from_input(self: Self, input: [][]u8) !*u8 {
        try checkCoordsOutOfBounds(input, self.y, self.x);
        return &input[self.y][self.x];
    }

    fn eql(self: Self, other: Self) bool {
        return self.x == other.x and self.y == other.y;
    }
};

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
            if (y == 0) return MapOpError.OutOfBoundsError;
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
            if (x == 0) return MapOpError.OutOfBoundsError;
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

    try testing.expectEqual(MoveResultEnum.regular_cell, actual);
    try testing.expectEqual('^', param[5][4]);
    try testing.expectEqual('|', param[6][4]);
    // try testing.expectEqual('^', param[new_pos_1.y][new_pos_1.x]);
}

test "test - advanceCursor 1.1" {
    var param = try testing.allocator.alloc([]u8, 10);
    param[0] = try testing.allocator.dupe(u8, "....#.....");
    param[1] = try testing.allocator.dupe(u8, ".........#");
    param[2] = try testing.allocator.dupe(u8, "..........");
    param[3] = try testing.allocator.dupe(u8, "..#.......");
    param[4] = try testing.allocator.dupe(u8, ".......#..");
    param[5] = try testing.allocator.dupe(u8, "....^.....");
    param[6] = try testing.allocator.dupe(u8, ".#..|.....");
    param[7] = try testing.allocator.dupe(u8, "........#.");
    param[8] = try testing.allocator.dupe(u8, "#.........");
    param[9] = try testing.allocator.dupe(u8, "......#...");
    defer {
        for (param) |line| testing.allocator.free(line);
        testing.allocator.free(param);
    }

    const actual = try advanceCursor(param, GuardPosition{ .y = 6, .x = 4 }, GuardPosition{ .y = 5, .x = 4 }, false);

    try testing.expectEqual(MoveResultEnum.regular_cell, actual);
    try testing.expectEqual('^', param[4][4]);
    try testing.expectEqual('|', param[5][4]);
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

    try testing.expectEqual(MoveResultEnum.obstruction, actual);
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

    try testing.expectEqual(MoveResultEnum.already_visited, actual);
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

    try testing.expectEqual(MoveResultEnum.regular_cell, actual);
    try testing.expectEqual('+', param[6][4]);
    try testing.expectEqual('<', param[6][3]);
    // try testing.expectEqual('^', param[new_pos_1.y][new_pos_1.x]);
}

const MoveResultEnum = enum { already_visited, obstruction, obstruction_already_visited, regular_cell };

/// result is number of positions visited;
// cases:
// - 1 we want to move to an unvisited, unobstructed cell
// - 2 we want to move to a cell with an obstruction
// - 3 we want to move to an already visited cell
pub fn advanceCursor(input: [][]u8, current_position: GuardPosition, next_position: GuardPosition, current_pos_overlapped: bool) MapOpError!MoveResultEnum {
    const current_char = &input[current_position.y][current_position.x];
    const next_char = &input[next_position.y][next_position.x];

    var result = MoveResultEnum.regular_cell;

    // printMap(input);
    // std.debug.print("currentchar: {s}\n", .{[_]u8{ current_char.*, ' ', next_char.* }});

    var current_direction = Direction.from_char(current_char.*).?;

    if (is_obstructed(next_char.*)) {
        current_char.* = '+';

        result = MoveResultEnum.obstruction;

        // fixed bug thx
        // https://www.reddit.com/r/adventofcode/comments/1h7x808/comment/m0ol010/

        var new_direction = current_direction.turn_right();
        var coords_to_the_right = try getNeighboringCoords(input, current_position.y, current_position.x, new_direction);
        var char_to_the_right = try coords_to_the_right.get_mut_char_from_input(input);

        // this can't fail, worst case we come back from where we came from
        while (is_obstructed(char_to_the_right.*)) {
            new_direction = new_direction.turn_right();
            coords_to_the_right = try getNeighboringCoords(input, current_position.y, current_position.x, new_direction);
            char_to_the_right = try coords_to_the_right.get_mut_char_from_input(input);
        }

        if (char_to_the_right.* == '|' or char_to_the_right.* == '-') result = MoveResultEnum.obstruction_already_visited;

        char_to_the_right.* = new_direction.to_char();

        return result;
    } else {
        if (next_char.* == '|' or next_char.* == '-') result = MoveResultEnum.already_visited;

        current_char.* = if (current_pos_overlapped) '+' else if (current_direction == .Up or current_direction == .Down) '|' else '-';
        next_char.* = current_direction.to_char();
    }
    return result;
}

test "walkGuard - 1" {
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

    try testing.expectEqual(41, try walkGuard(param, null));
    // try testing.expectEqual('^', param[new_pos_1.y][new_pos_1.x]);
}

test "walkGuard - 2" {
    var param = try testing.allocator.alloc([]u8, 3);
    param[0] = try testing.allocator.dupe(u8, "..#.");
    param[1] = try testing.allocator.dupe(u8, "...#");
    param[2] = try testing.allocator.dupe(u8, "..^.");
    defer {
        for (param) |line| testing.allocator.free(line);
        testing.allocator.free(param);
    }

    try testing.expectEqual(2, try walkGuard(param, null));
    // try testing.expectEqual('^', param[new_pos_1.y][new_pos_1.x]);
}

test "walkGuard - 3" {
    var param = try testing.allocator.alloc([]u8, 4);
    param[0] = try testing.allocator.dupe(u8, ".#.");
    param[1] = try testing.allocator.dupe(u8, "#.#");
    param[2] = try testing.allocator.dupe(u8, "#^.");
    param[3] = try testing.allocator.dupe(u8, "...");
    defer {
        for (param) |line| testing.allocator.free(line);
        testing.allocator.free(param);
    }

    try testing.expectEqual(3, try walkGuard(param, null));
    // try testing.expectEqual('^', param[new_pos_1.y][new_pos_1.x]);
}

test "walkGuard - 4" {
    var param = try testing.allocator.alloc([]u8, 4);
    param[0] = try testing.allocator.dupe(u8, ".#.");
    param[1] = try testing.allocator.dupe(u8, "..#");
    param[2] = try testing.allocator.dupe(u8, "#^.");
    param[3] = try testing.allocator.dupe(u8, "...");
    defer {
        for (param) |line| testing.allocator.free(line);
        testing.allocator.free(param);
    }

    try testing.expectEqual(3, try walkGuard(param, null));
    // try testing.expectEqual('^', param[new_pos_1.y][new_pos_1.x]);
}

/// result is number of positions visited;
pub fn walkGuard(input: [][]u8, maybe_cache: ?*Cache) !u64 {
    // adding 1 for the first position
    var positions_visited: u64 = 1;
    var prev_iteration_already_visited = false;

    loop: while (true) {
        const prev_pos = try findGuard(input);
        const direction = Direction.from_char(input[prev_pos.y][prev_pos.x]).?;
        const prev_y = prev_pos.y;
        const prev_x = prev_pos.x;

        if (maybe_cache) |cache| {
            try cache.put(.{ prev_pos, direction }, {});
        }

        const new_pos = getNeighboringCoords(input, prev_y, prev_x, direction) catch |err| switch (err) {
            MapOpError.OutOfBoundsError => break :loop,
            else => return err,
        };

        const move_result = try advanceCursor(input, prev_pos, new_pos, prev_iteration_already_visited);

        if (prev_iteration_already_visited) prev_iteration_already_visited = false;

        switch (move_result) {
            MoveResultEnum.already_visited => prev_iteration_already_visited = true,
            MoveResultEnum.obstruction_already_visited => {},
            MoveResultEnum.obstruction => positions_visited += 1,
            MoveResultEnum.regular_cell => positions_visited += 1,
        }
    }

    // printMap(input);

    return positions_visited;
}

test "findLoop - no loop" {
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

    try testing.expectEqual(false, try findLoop(testing.allocator, null, param));
    // try testing.expectEqual('^', param[new_pos_1.y][new_pos_1.x]);
}

test "findLoop - cache" {
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

    var cache = Cache.init(testing.allocator);
    defer cache.deinit();

    try cache.put(.{ GuardPosition{ .x = 4, .y = 5 }, Direction.Up }, {});

    try testing.expectEqual(false, try findLoop(testing.allocator, &cache, param));
    // try testing.expectEqual('^', param[new_pos_1.y][new_pos_1.x]);
}

pub const Cache = std.AutoHashMap(struct { GuardPosition, Direction }, void);

/// findLoop modifies passed in input slice
pub fn findLoop(allocator: std.mem.Allocator, maybe_outer_cache: ?*Cache, input: [][]u8) !bool {
    const inital_pos = try findGuard(input);
    var current_pos = inital_pos;

    const current_char: *u8 = &input[current_pos.y][current_pos.x];
    const curr_direction = Direction.from_char(current_char.*).?;

    var next_pos = try getNeighboringCoords(input, current_pos.y, current_pos.x, curr_direction);

    var inner_cache = Cache.init(allocator);
    defer inner_cache.deinit();

    // std.debug.print("currentpos {any}\n", .{current_pos});
    // std.debug.print("nextpos {any}\n", .{next_pos});
    //
    var prev_cell_already_visited = false;

    while (advanceCursor(input, current_pos, next_pos, prev_cell_already_visited)) |move_result| {
        printMap(input);
        // std.debug.print("currentpos {any}\n", .{current_pos});
        // std.debug.print("nextpos {any}\n", .{next_pos});
        // std.debug.print("dir {s}\n", .{@tagName(new_direction)});

        current_pos = try findGuard(input);
        const direction = Direction.from_char(input[current_pos.y][current_pos.x]).?;

        // cache positions and direction to speed up in the case of big inputs

        if (maybe_outer_cache) |cache| {
            if (cache.contains(.{ current_pos, direction })) return true;
        }

        const gop_result = try inner_cache.getOrPut(.{ current_pos, direction });
        if (gop_result.found_existing) return true;

        const prev_y = current_pos.y;
        const prev_x = current_pos.x;

        next_pos = getNeighboringCoords(input, prev_y, prev_x, direction) catch |err| switch (err) {
            MapOpError.OutOfBoundsError => return false,
            else => return err,
        };

        switch (move_result) {
            MoveResultEnum.obstruction_already_visited, MoveResultEnum.already_visited => prev_cell_already_visited = true,
            else => {},
        }

        // printMap(input);
        if (current_pos.eql(inital_pos)) {
            return true;
        }
    } else |err| {
        switch (err) {
            MapOpError.OutOfBoundsError => return false,
            else => return err,
        }
    }
}

test "findLoops - 1" {
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

    try testing.expectEqual(6, try findLoops(testing.allocator, param, null));
    // try testing.expectEqual('^', param[new_pos_1.y][new_pos_1.x]);
}

test "findLoops - 2" {
    var param = try testing.allocator.alloc([]u8, 3);
    param[0] = try testing.allocator.dupe(u8, "..#.");
    param[1] = try testing.allocator.dupe(u8, "...#");
    param[2] = try testing.allocator.dupe(u8, "..^.");
    defer {
        for (param) |line| testing.allocator.free(line);
        testing.allocator.free(param);
    }

    try testing.expectEqual(0, try findLoops(testing.allocator, param, null));
    // try testing.expectEqual('^', param[new_pos_1.y][new_pos_1.x]);
}

test "findLoops - 3" {
    var param = try testing.allocator.alloc([]u8, 4);
    param[0] = try testing.allocator.dupe(u8, ".#.");
    param[1] = try testing.allocator.dupe(u8, "#.#");
    param[2] = try testing.allocator.dupe(u8, "#^.");
    param[3] = try testing.allocator.dupe(u8, "...");
    defer {
        for (param) |line| testing.allocator.free(line);
        testing.allocator.free(param);
    }

    try testing.expectEqual(1, try findLoops(testing.allocator, param, null));
    // try testing.expectEqual('^', param[new_pos_1.y][new_pos_1.x]);
}

test "findLoops - 4" {
    var param = try testing.allocator.alloc([]u8, 4);
    param[0] = try testing.allocator.dupe(u8, ".#.");
    param[1] = try testing.allocator.dupe(u8, "..#");
    param[2] = try testing.allocator.dupe(u8, "#^.");
    param[3] = try testing.allocator.dupe(u8, "...");
    defer {
        for (param) |line| testing.allocator.free(line);
        testing.allocator.free(param);
    }

    try testing.expectEqual(1, try findLoops(testing.allocator, param, null));
    // try testing.expectEqual('^', param[new_pos_1.y][new_pos_1.x]);
}

test "findLoops - 5" {
    var param = try testing.allocator.alloc([]u8, 4);
    param[0] = try testing.allocator.dupe(u8, "....");
    param[1] = try testing.allocator.dupe(u8, "#...");
    param[2] = try testing.allocator.dupe(u8, ".^#.");
    param[3] = try testing.allocator.dupe(u8, ".#..");
    defer {
        for (param) |line| testing.allocator.free(line);
        testing.allocator.free(param);
    }

    try testing.expectEqual(0, try findLoops(testing.allocator, param, null));
    // try testing.expectEqual('^', param[new_pos_1.y][new_pos_1.x]);
}

test "findLoops - 6" {
    var param = try testing.allocator.alloc([]u8, 3);
    param[0] = try testing.allocator.dupe(u8, "....");
    param[1] = try testing.allocator.dupe(u8, "#..#");
    param[2] = try testing.allocator.dupe(u8, ".^#.");
    defer {
        for (param) |line| testing.allocator.free(line);
        testing.allocator.free(param);
    }

    try testing.expectEqual(1, try findLoops(testing.allocator, param, null));
    // try testing.expectEqual('^', param[new_pos_1.y][new_pos_1.x]);
}

test "findLoops - 7" {
    var param = try testing.allocator.alloc([]u8, 5);
    param[0] = try testing.allocator.dupe(u8, ".##..");
    param[1] = try testing.allocator.dupe(u8, "....#");
    param[2] = try testing.allocator.dupe(u8, ".....");
    param[3] = try testing.allocator.dupe(u8, ".^.#.");
    param[4] = try testing.allocator.dupe(u8, ".....");
    defer {
        for (param) |line| testing.allocator.free(line);
        testing.allocator.free(param);
    }

    try testing.expectEqual(1, try findLoops(testing.allocator, param, null));
    // try testing.expectEqual('^', param[new_pos_1.y][new_pos_1.x]);
}

/// result is number of loops visited;
pub fn findLoops(allocator: std.mem.Allocator, input: [][]u8, _: ?*Cache) !u64 {
    var cycles: u64 = 0;
    var prev_iteration_already_visited = false;

    var cache = Cache.init(allocator);
    defer cache.deinit();

    const inital_pos = try findGuard(input);
    var current_pos = inital_pos;
    loop: while (true) {
        // std.debug.print("visited: {any}\n", .{prev_iteration_already_visited});

        current_pos = try findGuard(input);
        const direction = Direction.from_char(input[current_pos.y][current_pos.x]).?;
        try cache.put(.{ current_pos, direction }, {});

        const prev_y = current_pos.y;
        const prev_x = current_pos.x;

        const next_pos = getNeighboringCoords(input, prev_y, prev_x, direction) catch |err| switch (err) {
            MapOpError.OutOfBoundsError => break :loop,
            else => return err,
        };

        const next_char = try next_pos.get_char_from_input(input);
        if (next_char.* == '.') {
            const duped_input = try dupeInput(allocator, input);
            defer {
                for (duped_input) |sl| allocator.free(sl);
                allocator.free(duped_input);
            }
            try addObstructionInFront(duped_input);
            if (try findLoop(allocator, &cache, duped_input)) {
                // printMap(input);
                cycles += 1;
            }

            // TODO: for each direction that isn't the direction we're coming from
            // dupe input, add obstacle in that direction, check for loops

            // std.debug.print("next char: {s}\n", .{@tagName(direction)});
            // std.debug.print("next char: {s}\n", .{[_]u8{next_char.*}});
        }

        // if (prev_iteration_already_visited) {
        //     printMap(input);
        // }

        const move_result = try advanceCursor(input, current_pos, next_pos, prev_iteration_already_visited);
        prev_iteration_already_visited = false;

        switch (move_result) {
            MoveResultEnum.already_visited => prev_iteration_already_visited = true,
            else => {},
        }
    }

    return cycles;
}

test "addObstruction - 1" {
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

    try addObstructionInFront(param);

    printMap(param);

    try testing.expectEqual('#', param[5][4]);
    // try testing.expectEqual('^', param[new_pos_1.y][new_pos_1.x]);
}

pub fn addObstructionInFront(input: [][]u8) !void {
    const current_pos = try findGuard(input);
    const direction = Direction.from_char(input[current_pos.y][current_pos.x]).?;
    const new_obstacle_pos = try getNeighboringCoords(input, current_pos.y, current_pos.x, direction);

    const mut_char = try new_obstacle_pos.get_mut_char_from_input(input);

    mut_char.* = '#';
}

test "test - moveGuard 1" {
    var param = try testing.allocator.alloc([]u8, 3);
    param[0] = try testing.allocator.dupe(u8, "..#..");
    param[1] = try testing.allocator.dupe(u8, "..^..");
    param[2] = try testing.allocator.dupe(u8, ".....");
    defer {
        for (param) |line| testing.allocator.free(line);
        testing.allocator.free(param);
    }

    const actual = try moveGuard(param, .regular_cell, GuardPosition{ .y = 0, .x = 2 });

    try testing.expectEqual(.{ false, null }, actual);
    try testing.expectEqual('#', param[0][2]);
    try testing.expectEqual('^', param[1][2]);
    // try testing.expectEqual('^', param[new_pos_1.y][new_pos_1.x]);
}

test "test - moveGuard 2" {
    var param = try testing.allocator.alloc([]u8, 3);
    param[0] = try testing.allocator.dupe(u8, ".....");
    param[1] = try testing.allocator.dupe(u8, "..^..");
    param[2] = try testing.allocator.dupe(u8, ".....");
    defer {
        for (param) |line| testing.allocator.free(line);
        testing.allocator.free(param);
    }

    const actual = try moveGuard(param, .regular_cell, GuardPosition{ .y = 0, .x = 2 });

    errdefer printMap(param);

    try testing.expectEqual(.{ true, MovedTo.regular_cell }, actual);
    try testing.expectEqual('^', param[0][2]);
    try testing.expectEqual('|', param[1][2]);
    // try testing.expectEqual('^', param[new_pos_1.y][new_pos_1.x]);
}

test "test - moveGuard 3" {
    var param = try testing.allocator.alloc([]u8, 3);
    param[0] = try testing.allocator.dupe(u8, ".....");
    param[1] = try testing.allocator.dupe(u8, "..^..");
    param[2] = try testing.allocator.dupe(u8, ".....");
    defer {
        for (param) |line| testing.allocator.free(line);
        testing.allocator.free(param);
    }

    const actual = try moveGuard(param, .already_visited_cell, GuardPosition{ .y = 0, .x = 2 });

    errdefer printMap(param);

    try testing.expectEqual(.{ true, MovedTo.regular_cell }, actual);
    try testing.expectEqual('^', param[0][2]);
    try testing.expectEqual('|', param[1][2]);
    // try testing.expectEqual('^', param[new_pos_1.y][new_pos_1.x]);
}

// test "test - moveGuard 4" {
//     var param = try testing.allocator.alloc([]u8, 10);
//     param[0] = try testing.allocator.dupe(u8, "....#.....");
//     param[1] = try testing.allocator.dupe(u8, "....+---+#");
//     param[2] = try testing.allocator.dupe(u8, "....|...|.");
//     param[3] = try testing.allocator.dupe(u8, "..#.|...|.");
//     param[4] = try testing.allocator.dupe(u8, "....|..#|.");
//     param[5] = try testing.allocator.dupe(u8, "....|...|.");
//     param[6] = try testing.allocator.dupe(u8, ".#..<---+.");
//     param[7] = try testing.allocator.dupe(u8, "........#.");
//     param[8] = try testing.allocator.dupe(u8, "#.........");
//     param[9] = try testing.allocator.dupe(u8, "......#...");
//     defer {
//         for (param) |line| testing.allocator.free(line);
//         testing.allocator.free(param);
//     }

//     const actual = try moveGuard(param, GuardPosition{ .y = 6, .x = 4 }, GuardPosition{ .y = 6, .x = 3 }, true);

//     errdefer printMap(param);

//     try testing.expectEqual(MoveResultEnum.regular_cell, actual);
//     try testing.expectEqual('+', param[6][4]);
//     try testing.expectEqual('<', param[6][3]);
//     // try testing.expectEqual('^', param[new_pos_1.y][new_pos_1.x]);
// }

const MovedTo = union(enum) { already_visited_cell: Direction, regular_cell };

/// result is number of positions visited;
// cases:
// - 1 we want to move to an unvisited, unobstructed cell
// - 2 we want to move to a cell with an obstruction
// - 3 we want to move to an already visited cell
pub fn moveGuard(input: [][]u8, current_pos_status: MovedTo, next_position: GuardPosition) MapOpError!struct { bool, ?MovedTo } {
    const current_position = try findGuard(input);
    const current_char = try current_position.get_mut_char_from_input(input);
    const next_char = try next_position.get_mut_char_from_input(input);

    var result = MovedTo.regular_cell;

    // printMap(input);
    // std.debug.print("currentchar: {s}\n", .{[_]u8{ current_char.*, ' ', next_char.* }});

    var current_direction = Direction.from_char(current_char.*).?;

    if (is_obstructed(next_char.*)) {
        return .{ false, null };
    } else {
        if (next_char.* == '|' or next_char.* == '-' or next_char.* == '+') result = MovedTo.already_visited_cell;

        current_char.* = if (current_pos_status == .already_visited_cell) '+' else if (current_direction == .Up or current_direction == .Down) '|' else '-';
        next_char.* = current_direction.to_char();
    }

    // if (is_obstructed(next_char.*)) {
    //     current_char.* = '+';

    //     result = MoveResultEnum.obstruction;

    //     // fixed bug thx
    //     // https://www.reddit.com/r/adventofcode/comments/1h7x808/comment/m0ol010/

    //     var new_direction = current_direction.turn_right();
    //     var coords_to_the_right = try getNeighboringCoords(input, current_position.y, current_position.x, new_direction);
    //     var char_to_the_right = try coords_to_the_right.get_mut_char_from_input(input);

    //     // this can't fail, worst case we come back from where we came from
    //     while (is_obstructed(char_to_the_right.*)) {
    //         new_direction = new_direction.turn_right();
    //         coords_to_the_right = try getNeighboringCoords(input, current_position.y, current_position.x, new_direction);
    //         char_to_the_right = try coords_to_the_right.get_mut_char_from_input(input);
    //     }

    //     if (char_to_the_right.* == '|' or char_to_the_right.* == '-') result = MoveResultEnum.obstruction_already_visited;

    //     char_to_the_right.* = new_direction.to_char();

    //     return result;
    // } else {
    //     if (next_char.* == '|' or next_char.* == '-') result = MoveResultEnum.already_visited;

    //     current_char.* = if (current_pos_overlapped) '+' else if (current_direction == .Up or current_direction == .Down) '|' else '-';
    //     next_char.* = current_direction.to_char();
    // }
    return .{ true, result };
}
