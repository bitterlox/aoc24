const std = @import("std");
const testing = std.testing;

test "test - parseInput 1" {
    var expected = try testing.allocator.alloc([]Position, 2);
    expected[0] = try testing.allocator.dupe(Position, &[_]Position{
        .{ .x = 0, .y = 0, .content = .not_walked },
        .{ .x = 1, .y = 0, .content = .guard },
    });
    expected[1] = try testing.allocator.dupe(Position, &[_]Position{
        .{ .x = 0, .y = 1, .content = .not_walked },
        .{ .x = 1, .y = 1, .content = .obstruction },
    });
    defer {
        for (expected) |line| testing.allocator.free(line);
        testing.allocator.free(expected);
    }

    const input = &[_][]const u8{ ".v", ".#" };

    const actual, const guard_position = try parseInputString(testing.allocator, input);
    defer {
        for (actual) |sl| testing.allocator.free(sl);
        testing.allocator.free(actual);
    }

    try testing.expectEqualDeep(expected, actual);
    try testing.expectEqual(expected[0][1], guard_position.cell.*);
    try testing.expectEqual(.Down, guard_position.direction);
}

const MapOpError = error{ NoGuardError, OutOfBoundsError };

// try to make this into an enum union with guard storing a direction
const CellContent = enum { not_walked, walked_vertically, walked_horizontally, walked_both, obstruction, guard };

const Position = struct {
    x: usize,
    y: usize,
    content: CellContent,

    const Self = @This();

    fn eql(self: Self, other: Self) bool {
        return self.x == other.x and self.y == other.y;
    }
};

const GuardPosition = struct {
    cell: *Position,
    direction: Direction,
};

/// caller takes ownership of memory
fn parseInputString(allocator: std.mem.Allocator, input: []const []const u8) !struct { [][]Position, GuardPosition } {
    var data = try allocator.alloc([]Position, input.len);

    var guard_position_ptr: ?*Position = null;
    var guard_position_direction: ?Direction = null;

    for (input, 0..) |row, row_idx| {
        var row_mem = try allocator.alloc(Position, row.len);
        for (row, 0..) |cell, cell_idx| {
            const cell_content = switch (cell) {
                '#' => CellContent.obstruction,
                '|' => CellContent.walked_vertically,
                '-' => CellContent.walked_horizontally,
                '+' => CellContent.walked_both,
                '^' => blk: {
                    guard_position_direction = .Up;
                    break :blk CellContent.guard;
                },
                'v' => blk: {
                    guard_position_direction = .Down;
                    break :blk CellContent.guard;
                },
                '>' => blk: {
                    guard_position_direction = .Right;
                    break :blk CellContent.guard;
                },
                '<' => blk: {
                    guard_position_direction = .Left;
                    break :blk CellContent.guard;
                },
                else => CellContent.not_walked,
            };

            row_mem[cell_idx] = Position{ .x = cell_idx, .y = row_idx, .content = cell_content };

            if (cell_content == .guard) guard_position_ptr = &row_mem[cell_idx];
        }
        data[row_idx] = row_mem;
    }

    if (guard_position_ptr) |ptr| {
        if (guard_position_direction) |direction| {
            return .{ data, GuardPosition{ .cell = ptr, .direction = direction } };
        }
    }
    return MapOpError.NoGuardError;
}

fn checkCoordsOutOfBounds(input: []const []const Position, maybe_x: ?usize, maybe_y: ?usize) MapOpError!void {
    if (maybe_x) |x| {
        const max_x = input[0].len;
        if (x >= max_x) return MapOpError.OutOfBoundsError;
    }

    if (maybe_y) |y| {
        const max_y = input.len;
        if (y >= max_y) return MapOpError.OutOfBoundsError;
    }
}

test "getAdjacentPosition - test 1" {
    var data = try testing.allocator.alloc([]Position, 2);
    data[0] = try testing.allocator.dupe(Position, &[_]Position{
        .{ .x = 0, .y = 0, .content = .not_walked },
        .{ .x = 1, .y = 0, .content = .guard },
    });
    data[1] = try testing.allocator.dupe(Position, &[_]Position{
        .{ .x = 0, .y = 1, .content = .not_walked },
        .{ .x = 1, .y = 1, .content = .obstruction },
    });
    defer {
        for (data) |line| testing.allocator.free(line);
        testing.allocator.free(data);
    }

    const expected = &data[1][1];
    const actual = try getAdjacentPosition(data, 0, 1, .Right);

    try testing.expectEqual(expected, actual);
}

test "getAdjacentPosition - test 2" {
    var data = try testing.allocator.alloc([]Position, 2);
    data[0] = try testing.allocator.dupe(Position, &[_]Position{
        .{ .x = 0, .y = 0, .content = .not_walked },
        .{ .x = 1, .y = 0, .content = .guard },
    });
    data[1] = try testing.allocator.dupe(Position, &[_]Position{
        .{ .x = 0, .y = 1, .content = .not_walked },
        .{ .x = 1, .y = 1, .content = .obstruction },
    });
    defer {
        for (data) |line| testing.allocator.free(line);
        testing.allocator.free(data);
    }

    const actual = getAdjacentPosition(data, 0, 1, .Left);

    try testing.expectError(MapOpError.OutOfBoundsError, actual);
}

// it's wierd because by passing in input we have a map where in a normal state
// we already have a current position, eg where the guard is, so it's wierd that
// this function accepts arbitrary x and y
fn getAdjacentPosition(input: [][]Position, current_x: usize, current_y: usize, direction: Direction) MapOpError!*Position {
    return switch (direction) {
        .Up => {
            if (current_y == 0) return MapOpError.OutOfBoundsError;
            const new_y = current_y - 1;
            try checkCoordsOutOfBounds(input, null, new_y);
            return &input[new_y][current_x];
        },
        .Down => {
            const new_y = current_y + 1;
            try checkCoordsOutOfBounds(input, null, new_y);
            return &input[new_y][current_x];
        },
        .Left => {
            if (current_x == 0) return MapOpError.OutOfBoundsError;
            const new_x = current_x - 1;
            try checkCoordsOutOfBounds(input, new_x, null);
            return &input[current_y][new_x];
        },
        .Right => {
            const new_x = current_x + 1;
            try checkCoordsOutOfBounds(input, new_x, null);
            return &input[current_y][new_x];
        },
    };
}

test "test - Map.moveGuard 1" {
    const param: []const []const u8 = &[_][]const u8{
        "....#.....",
        ".........#",
        "..........",
        "..#.......",
        ".......#..",
        "..........",
        ".#..^.....",
        "........#.",
        "#.........",
        "......#...",
    };

    const map = try Map.init(testing.allocator, param);
    const to = &map.data[5][4];
    defer map.deinit();

    errdefer map.print();

    const moved, const moved_to_cell_content = try map.moveGuard(.not_walked, to);

    try testing.expectEqual(true, moved);
    try testing.expectEqual(CellContent.not_walked, moved_to_cell_content);
    try testing.expectEqual(CellContent.guard, map.data[5][4].content);
    try testing.expectEqual(CellContent.walked_vertically, map.data[6][4].content);
}

test "test - Map.moveGuard 2" {
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

    const map = try Map.init(testing.allocator, param);
    const to = &map.data[0][4];
    defer map.deinit();

    errdefer map.print();

    const moved, const moved_to_cell_content = try map.moveGuard(.not_walked, to);

    try testing.expectEqual(false, moved);
    try testing.expectEqual(null, moved_to_cell_content);
    try testing.expectEqual(CellContent.obstruction, map.data[0][4].content);
    try testing.expectEqual(CellContent.guard, map.data[1][4].content);
}

test "test - Map.moveGuard 3" {
    const param: []const []const u8 = &[_][]const u8{
        "....#.....",
        "....+---+#",
        "....|...|.",
        "..#.|...|.",
        "....|..#|.",
        "....|...|.",
        ".#..|<--+.",
        "........#.",
        "#.........",
        "......#...",
    };

    const map = try Map.init(testing.allocator, param);
    const to = &map.data[6][4];
    defer map.deinit();

    errdefer map.print();

    const moved, const moved_to_cell_content = try map.moveGuard(.not_walked, to);

    try testing.expectEqual(true, moved);
    try testing.expectEqual(CellContent.walked_vertically, moved_to_cell_content);
    try testing.expectEqual(CellContent.guard, map.data[6][4].content);
    try testing.expectEqual(CellContent.walked_horizontally, map.data[6][5].content);
}

test "test - Map.moveGuard 4" {
    const param: []const []const u8 = &[_][]const u8{
        "....#.....",
        "....+---+#",
        "....|...|.",
        "..#.|...|.",
        "....|..#|.",
        "....|...|.",
        ".#..<---+.",
        "........#.",
        "#.........",
        "......#...",
    };

    const map = try Map.init(testing.allocator, param);
    const to = &map.data[6][3];
    defer map.deinit();

    errdefer map.print();

    const moved, const moved_to_cell_content = try map.moveGuard(.walked_vertically, to);

    try testing.expectEqual(true, moved);
    try testing.expectEqual(CellContent.not_walked, moved_to_cell_content);
    try testing.expectEqual(CellContent.guard, map.data[6][3].content);
    try testing.expectEqual(CellContent.walked_both, map.data[6][4].content);
}

test "test - Map.walkGuard - 1" {
    const param: []const []const u8 = &[_][]const u8{
        "....#.....",
        ".........#",
        "..........",
        "..#.......",
        ".......#..",
        "..........",
        ".#..^.....",
        "........#.",
        "#.........",
        "......#...",
    };

    const map = try Map.init(testing.allocator, param);
    defer map.deinit();

    errdefer map.print();

    try testing.expectEqual(41, try map.walkGuard());
}

test "test - Map.walkGuard - 2" {
    const param: []const []const u8 = &[_][]const u8{
        "..#.",
        "...#",
        "..^.",
    };

    const map = try Map.init(testing.allocator, param);
    defer map.deinit();

    errdefer map.print();

    try testing.expectEqual(2, try map.walkGuard());
}

test "test - Map.walkGuard - 3" {
    const param: []const []const u8 = &[_][]const u8{
        ".#.",
        "#.#",
        "#^.",
        "...",
    };

    const map = try Map.init(testing.allocator, param);
    defer map.deinit();

    errdefer map.print();

    try testing.expectEqual(3, try map.walkGuard());
}

test "test - Map.walkGuard - 4" {
    const param: []const []const u8 = &[_][]const u8{
        ".#.",
        "..#",
        "#^.",
        "...",
    };

    const map = try Map.init(testing.allocator, param);
    defer map.deinit();

    errdefer map.print();

    try testing.expectEqual(3, try map.walkGuard());
}

test "test - Map.findLoop - 1" {
    const param: []const []const u8 = &[_][]const u8{
        "....#.....",
        "....+---+#",
        "....|...|.",
        "..#.|...|.",
        "....|..#|.",
        "....|...|.",
        ".#..<---+.",
        "........#.",
        "#.........",
        "......#...",
    };

    const map = try Map.init(testing.allocator, param);
    defer map.deinit();

    errdefer map.print();

    try testing.expectEqual(false, try map.hasLoop());
}

test "test - Map.findLoop - 2" {
    const param: []const []const u8 = &[_][]const u8{
        "....#.....",
        "....+---+#",
        "....|...|.",
        "..#.|...|.",
        "....|..#|.",
        "....|...|.",
        ".#.#<---+.",
        "........#.",
        "#.........",
        "......#...",
    };

    const map = try Map.init(testing.allocator, param);
    defer map.deinit();

    errdefer map.print();

    try testing.expectEqual(true, try map.hasLoop());
}

test "test - Map.addObstruction - 1" {
    const param: []const []const u8 = &[_][]const u8{
        "....#.....",
        ".........#",
        "..........",
        "..#.......",
        ".......#..",
        "..........",
        ".#..^.....",
        "........#.",
        "#.........",
        "......#...",
    };

    const map = try Map.init(testing.allocator, param);
    defer map.deinit();

    errdefer map.print();

    try map.addObstacleInFront();

    try testing.expectEqual(CellContent.obstruction, map.data[5][4].content);
}

test "test - Map.findLoops - 1" {
    const param: []const []const u8 = &[_][]const u8{
        "....#.....",
        ".........#",
        "..........",
        "..#.......",
        ".......#..",
        "..........",
        ".#..^.....",
        "........#.",
        "#.........",
        "......#...",
    };

    const map = try Map.init(testing.allocator, param);
    defer map.deinit();

    errdefer map.print();

    try testing.expectEqual(6, try map.findLoops());
}

test "test - Map.findLoops - 2" {
    const param: []const []const u8 = &[_][]const u8{
        "..#.",
        "...#",
        "..^.",
    };

    const map = try Map.init(testing.allocator, param);
    defer map.deinit();

    errdefer map.print();

    try testing.expectEqual(0, try map.findLoops());
}

test "test - Map.findLoops - 3" {
    const param: []const []const u8 = &[_][]const u8{
        ".#.",
        "#.#",
        "#^.",
        "...",
    };

    const map = try Map.init(testing.allocator, param);
    defer map.deinit();

    errdefer map.print();

    try testing.expectEqual(1, try map.findLoops());
}

test "test - Map.findLoops - 4" {
    const param: []const []const u8 = &[_][]const u8{
        ".#.",
        "..#",
        "#^.",
        "...",
    };

    const map = try Map.init(testing.allocator, param);
    defer map.deinit();

    errdefer map.print();

    try testing.expectEqual(1, try map.findLoops());
}

test "test - Map.findLoops - 5" {
    const param: []const []const u8 = &[_][]const u8{
        "....",
        "#...",
        ".^#.",
        ".#..",
    };

    const map = try Map.init(testing.allocator, param);
    defer map.deinit();

    errdefer map.print();

    try testing.expectEqual(0, try map.findLoops());
}

test "test - Map.findLoops - 6" {
    const param: []const []const u8 = &[_][]const u8{
        "....",
        "#..#",
        ".^#.",
    };

    const map = try Map.init(testing.allocator, param);
    defer map.deinit();

    errdefer map.print();

    try testing.expectEqual(1, try map.findLoops());
}

test "test - Map.findLoops - 7" {
    const param: []const []const u8 = &[_][]const u8{
        ".##..",
        "....#",
        ".....",
        ".^.#.",
        ".....",
    };

    const map = try Map.init(testing.allocator, param);
    defer map.deinit();

    errdefer map.print();

    try testing.expectEqual(1, try map.findLoops());
}

pub const Map = struct {
    data: [][]Position,
    current_position: GuardPosition,
    allocator: std.mem.Allocator,

    const Self = @This();

    /// caller owns the memory; call deinit() when done
    pub fn init(allocator: std.mem.Allocator, input: []const []const u8) !*Self {
        const data, const guard_position = try parseInputString(allocator, input);

        const ptr: *Self = try allocator.create(Self);
        ptr.* = Self{
            .data = data,
            .allocator = allocator,
            .current_position = guard_position,
        };

        return ptr;
    }

    pub fn deinit(self: *Self) void {
        for (self.data) |sl| self.allocator.free(sl);
        self.allocator.free(self.data);
        self.allocator.destroy(self);
    }

    /// caller takes ownership of memory
    pub fn clone(self: *Self) !*Self {
        const new_data = try self.allocator.alloc([]Position, self.data.len);

        for (self.data, 0..) |sl, idx| {
            new_data[idx] = try self.allocator.dupe(Position, sl);
        }

        const curr_pos_x = self.current_position.cell.x;
        const curr_pos_y = self.current_position.cell.y;

        const ptr: *Self = try self.allocator.create(Self);
        ptr.* = Self{
            .data = new_data,
            .allocator = self.allocator,
            .current_position = GuardPosition{ .cell = &new_data[curr_pos_y][curr_pos_x], .direction = self.current_position.direction },
        };

        return ptr;
    }

    fn print(self: *Self) void {
        for (self.data) |row| {
            for (row) |cell| {
                switch (cell.content) {
                    CellContent.guard => std.debug.print("{s}", .{[_]u8{self.current_position.direction.to_char()}}),
                    CellContent.not_walked => std.debug.print("{s}", .{"."}),
                    CellContent.obstruction => std.debug.print("{s}", .{"#"}),
                    CellContent.walked_horizontally => std.debug.print("{s}", .{"-"}),
                    CellContent.walked_vertically => std.debug.print("{s}", .{"|"}),
                    CellContent.walked_both => std.debug.print("{s}", .{"+"}),
                }
                // std.debug.print("{s}", .{" "});
            }

            std.debug.print("\n", .{});
        }

        std.debug.print("\n", .{});
    }

    fn moveGuard(self: *Self, current_position_prev_content: CellContent, to: *Position) !struct { bool, ?CellContent } {
        if (to.content == .obstruction) {
            return .{ false, null };
        }

        const to_return = to.content;

        self.current_position.cell.content = switch (current_position_prev_content) {
            CellContent.not_walked => blk: {
                if (self.current_position.direction.is_horizontal()) {
                    break :blk CellContent.walked_horizontally;
                } else {
                    break :blk CellContent.walked_vertically;
                }
            },
            CellContent.walked_horizontally => blk: {
                if (self.current_position.direction.is_vertical()) {
                    break :blk CellContent.walked_both;
                } else {
                    break :blk CellContent.walked_horizontally;
                }
            },
            CellContent.walked_vertically => blk: {
                if (self.current_position.direction.is_horizontal()) {
                    break :blk CellContent.walked_both;
                } else {
                    break :blk CellContent.walked_vertically;
                }
            },
            CellContent.walked_both => CellContent.walked_both,
            CellContent.obstruction, CellContent.guard => unreachable,
        };

        to.content = .guard;
        self.current_position.cell = to;

        return .{ true, to_return };
    }

    pub fn walkGuard(self: *Self) !u64 {
        // adding 1 for the first position
        var positions_visited: u64 = 1;
        var moved_to_cell_content: CellContent = CellContent.not_walked;

        loop: while (true) {
            const current_position = self.current_position.cell;
            const current_direction = self.current_position.direction;

            const current_x = current_position.x;
            const current_y = current_position.y;

            const new_pos = getAdjacentPosition(self.data, current_x, current_y, current_direction) catch |err| switch (err) {
                MapOpError.OutOfBoundsError => {
                    break :loop;
                },
                else => return err,
            };

            const did_move, const maybe_moved_to_cell_content = try self.moveGuard(moved_to_cell_content, new_pos);

            // if we encounter an obstruction turn direction to the right and
            // re-run loop from the top
            if (!did_move) {
                self.current_position.direction = current_direction.turn_right();
                moved_to_cell_content = if (self.current_position.direction.is_vertical()) blk: {
                    break :blk CellContent.walked_horizontally;
                } else blk: {
                    break :blk CellContent.walked_vertically;
                };
                continue;
            } else {
                if (maybe_moved_to_cell_content) |cell_content| {
                    moved_to_cell_content = cell_content;
                    switch (cell_content) {
                        CellContent.walked_both, CellContent.walked_horizontally, CellContent.walked_vertically => {},
                        CellContent.not_walked => positions_visited += 1,
                        else => @panic("unexpected cell content"),
                    }
                }
            }
        }

        return positions_visited;
    }

    pub const Cache = std.AutoHashMap(struct { Position, Direction }, void);

    fn hasLoop(self: *Self) !bool {
        var moved_to_cell_content: CellContent = CellContent.not_walked;

        var inner_cache = Cache.init(self.allocator);
        defer inner_cache.deinit();

        loop: while (true) {
            const current_position = self.current_position.cell;
            const current_direction = self.current_position.direction;

            const current_x = current_position.x;
            const current_y = current_position.y;

            const new_pos = getAdjacentPosition(self.data, current_x, current_y, current_direction) catch |err| switch (err) {
                MapOpError.OutOfBoundsError => {
                    break :loop;
                },
                else => return err,
            };

            const did_move, const maybe_moved_to_cell_content = try self.moveGuard(moved_to_cell_content, new_pos);

            // if we encounter an obstruction turn direction to the right and
            // re-run loop from the top
            if (!did_move) {
                self.current_position.direction = current_direction.turn_right();
                moved_to_cell_content = if (self.current_position.direction.is_vertical()) blk: {
                    break :blk CellContent.walked_horizontally;
                } else blk: {
                    break :blk CellContent.walked_vertically;
                };
                continue;
            } else {
                if (maybe_moved_to_cell_content) |cell_content| {
                    moved_to_cell_content = cell_content;
                    switch (cell_content) {
                        CellContent.walked_both, CellContent.walked_horizontally, CellContent.walked_vertically => {},
                        CellContent.not_walked => {},
                        else => @panic("unexpected cell content"),
                    }
                }
                const gop_result = try inner_cache.getOrPut(.{ current_position.*, current_direction });
                if (gop_result.found_existing) return true;
            }
        }

        return false;
    }

    pub fn findLoops(self: *Self) !u64 {
        var cycles: u64 = 0;
        var moved_to_cell_content: CellContent = CellContent.not_walked;

        // var cache = Cache.init(self.allocator);
        // defer cache.deinit();

        loop: while (true) {
            const current_position = self.current_position.cell;
            const current_direction = self.current_position.direction;

            const current_x = current_position.x;
            const current_y = current_position.y;

            const new_pos = getAdjacentPosition(self.data, current_x, current_y, current_direction) catch |err| switch (err) {
                MapOpError.OutOfBoundsError => {
                    break :loop;
                },
                else => return err,
            };

            if (new_pos.content == .not_walked) {
                const cloned_map = try self.clone();
                defer cloned_map.deinit();

                try cloned_map.addObstacleInFront();
                if (try cloned_map.hasLoop()) {
                    // cloned_map.print();
                    cycles += 1;
                }
            }

            const did_move, const maybe_moved_to_cell_content = try self.moveGuard(moved_to_cell_content, new_pos);

            // if we encounter an obstruction turn direction to the right and
            // re-run loop from the top
            if (!did_move) {
                self.current_position.direction = current_direction.turn_right();
                moved_to_cell_content = if (self.current_position.direction.is_vertical()) blk: {
                    break :blk CellContent.walked_horizontally;
                } else blk: {
                    break :blk CellContent.walked_vertically;
                };
                continue;
            } else {
                if (maybe_moved_to_cell_content) |cell_content| {
                    moved_to_cell_content = cell_content;
                    switch (cell_content) {
                        CellContent.walked_both, CellContent.walked_horizontally, CellContent.walked_vertically => {},
                        CellContent.not_walked => {},
                        else => @panic("unexpected cell content"),
                    }
                }
            }
        }

        return cycles;
    }

    fn addObstacleInFront(self: *Self) !void {
        const current_position = self.current_position.cell;
        const current_direction = self.current_position.direction;

        const current_x = current_position.x;
        const current_y = current_position.y;

        const new_pos = try getAdjacentPosition(self.data, current_x, current_y, current_direction);

        new_pos.*.content = CellContent.obstruction;
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

    fn is_vertical(self: Self) bool {
        return switch (self) {
            .Up, .Down => true,
            else => false,
        };
    }

    fn is_horizontal(self: Self) bool {
        return switch (self) {
            .Left, .Right => true,
            else => false,
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
