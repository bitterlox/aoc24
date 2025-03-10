const std = @import("std");
const testing = std.testing;

const MapError = error{ OutOfBounds, NotNeighbours };

fn checkCoordsOutOfBounds(input: []const []const Cell, maybe_x: ?usize, maybe_y: ?usize) MapError!void {
    if (maybe_x) |x| {
        const max_x = input[0].len;
        if (x >= max_x) return MapError.OutOfBounds;
    }

    if (maybe_y) |y| {
        const max_y = input.len;
        if (y >= max_y) return MapError.OutOfBounds;
    }
}

const Direction = enum {
    N,
    NE,
    E,
    SE,
    S,
    SW,
    W,
    NW,
    const Self = @This();
    fn opposite(self: Self) Direction {
        return switch (self) {
            .N => .S,
            .NE => .SW,
            .E => .W,
            .SE => .NW,
            .S => .N,
            .SW => .NE,
            .W => .E,
            .NW => .SE,
        };
    }
};

test "getAdjacentPosition - test N" {
    var data = try testing.allocator.alloc([]Cell, 3);
    data[0] = try testing.allocator.dupe(Cell, &[_]Cell{
        try Cell.init(testing.allocator, 0, 0, CellContent.empty),
        try Cell.init(testing.allocator, 4, 0, CellContent{ .antenna = 'a' }),
        try Cell.init(testing.allocator, 1, 0, CellContent.empty),
        try Cell.init(testing.allocator, 2, 0, CellContent.empty),
    });
    data[1] = try testing.allocator.dupe(Cell, &[_]Cell{
        try Cell.init(testing.allocator, 0, 1, CellContent.empty),
        try Cell.init(testing.allocator, 1, 1, CellContent.empty),
        try Cell.init(testing.allocator, 2, 1, CellContent.empty),
    });
    data[2] = try testing.allocator.dupe(Cell, &[_]Cell{
        try Cell.init(testing.allocator, 0, 2, CellContent.empty),
        try Cell.init(testing.allocator, 1, 2, CellContent.empty),
        try Cell.init(testing.allocator, 2, 2, CellContent.empty),
    });
    defer {
        for (data) |line| {
            for (line) |cell| cell.deinit();
            testing.allocator.free(line);
        }
        testing.allocator.free(data);
    }

    const expected = &data[0][1];
    const actual = try getAdjacentPosition(data, 1, 1, .N);

    try testing.expectEqualDeep(expected, actual);
}

test "getAdjacentPosition - test N S E W" {
    var data = try testing.allocator.alloc([]Cell, 3);
    data[0] = try testing.allocator.dupe(Cell, &[_]Cell{
        try Cell.init(testing.allocator, 0, 0, CellContent.empty),
        try Cell.init(testing.allocator, 1, 0, CellContent.empty),
        try Cell.init(testing.allocator, 2, 0, CellContent.empty),
    });
    data[1] = try testing.allocator.dupe(Cell, &[_]Cell{
        try Cell.init(testing.allocator, 0, 1, CellContent.empty),
        try Cell.init(testing.allocator, 1, 1, CellContent.empty),
        try Cell.init(testing.allocator, 4, 0, CellContent{ .antenna = 'a' }),
    });
    data[2] = try testing.allocator.dupe(Cell, &[_]Cell{
        try Cell.init(testing.allocator, 0, 2, CellContent.empty),
        try Cell.init(testing.allocator, 1, 2, CellContent.empty),
        try Cell.init(testing.allocator, 2, 2, CellContent.empty),
    });
    defer {
        for (data) |line| {
            for (line) |cell| cell.deinit();
            testing.allocator.free(line);
        }
        testing.allocator.free(data);
    }

    try testing.expectEqualDeep(&data[0][1], getAdjacentPosition(data, 1, 1, .N));
    try testing.expectEqualDeep(&data[2][1], getAdjacentPosition(data, 1, 1, .S));
    try testing.expectEqualDeep(&data[1][2], getAdjacentPosition(data, 1, 1, .E));
    try testing.expectEqualDeep(&data[1][0], getAdjacentPosition(data, 1, 1, .W));
}

test "getAdjacentPosition - test NE NW SE SW" {
    // a..z
    // ...
    // .a.
    var data = try testing.allocator.alloc([]Cell, 3);
    data[0] = try testing.allocator.dupe(Cell, &[_]Cell{
        try Cell.init(testing.allocator, 0, 0, CellContent{ .antenna = 'a' }),
        try Cell.init(testing.allocator, 1, 0, CellContent.empty),
        try Cell.init(testing.allocator, 2, 0, CellContent.empty),
    });
    data[1] = try testing.allocator.dupe(Cell, &[_]Cell{
        try Cell.init(testing.allocator, 0, 1, CellContent.empty),
        try Cell.init(testing.allocator, 1, 1, CellContent.empty),
        try Cell.init(testing.allocator, 2, 1, CellContent.empty),
    });
    data[2] = try testing.allocator.dupe(Cell, &[_]Cell{
        try Cell.init(testing.allocator, 0, 2, CellContent.empty),
        try Cell.init(testing.allocator, 1, 2, CellContent{ .antenna = 'a' }),
        try Cell.init(testing.allocator, 2, 2, CellContent.empty),
    });
    defer {
        for (data) |line| {
            for (line) |cell| cell.deinit();
            testing.allocator.free(line);
        }
        testing.allocator.free(data);
    }

    try testing.expectEqualDeep(&data[0][1], getAdjacentPosition(data, 0, 2, .NE));
    try testing.expectEqualDeep(&data[2][0], getAdjacentPosition(data, 1, 0, .SW));
    try testing.expectEqualDeep(&data[0][0], getAdjacentPosition(data, 1, 2, .NW));
    try testing.expectEqualDeep(&data[2][1], getAdjacentPosition(data, 0, 0, .SE));
}

fn getAdjacentPosition(input: [][]Cell, current_x: usize, current_y: usize, direction: Direction) MapError!*Cell {
    return switch (direction) {
        .N => blk: {
            if (current_y == 0) break :blk MapError.OutOfBounds;
            const new_y = current_y - 1;
            try checkCoordsOutOfBounds(input, null, new_y);
            break :blk &input[new_y][current_x];
        },
        .NE => blk: {
            if (current_y < 2) break :blk MapError.OutOfBounds;
            const new_y = current_y - 2;
            const new_x = current_x + 1;
            try checkCoordsOutOfBounds(input, new_x, new_y);
            break :blk &input[new_y][new_x];
        },
        .E => blk: {
            const new_x = current_x + 1;
            try checkCoordsOutOfBounds(input, new_x, null);
            break :blk &input[current_y][new_x];
        },
        .SE => blk: {
            const new_y = current_y + 2;
            const new_x = current_x + 1;
            try checkCoordsOutOfBounds(input, new_x, new_y);
            break :blk &input[new_y][new_x];
        },
        .S => blk: {
            const new_y = current_y + 1;
            try checkCoordsOutOfBounds(input, null, new_y);
            break :blk &input[new_y][current_x];
        },
        .SW => blk: {
            if (current_x < 1) break :blk MapError.OutOfBounds;
            const new_y = current_y + 2;
            const new_x = current_x - 1;
            try checkCoordsOutOfBounds(input, new_x, new_y);
            break :blk &input[new_y][new_x];
        },

        .W => blk: {
            if (current_x == 0) break :blk MapError.OutOfBounds;
            const new_x = current_x - 1;
            try checkCoordsOutOfBounds(input, new_x, null);
            break :blk &input[current_y][new_x];
        },
        .NW => blk: {
            if (current_y < 2 or current_x < 1) break :blk MapError.OutOfBounds;
            const new_y = current_y - 2;
            const new_x = current_x - 1;
            try checkCoordsOutOfBounds(input, new_x, new_y);
            break :blk &input[new_y][new_x];
        },
    };
}

// fn getDistance(input: []const []const Cell, cell1: Cell, cell2: Cell, direction:Direction) MapError!void {
//     // todo: need generalized way to loop a direction
// }

const MapDirectionIterator = struct {
    map: [][]Cell,
    starting_x: usize,
    starting_y: usize,
    direction: Direction,

    const Self = @This();

    fn next(self: *Self) ?*Cell {
        const cell_or_err = getAdjacentPosition(self.map, self.starting_x, self.starting_y, self.direction);

        if (cell_or_err) |cell| {
            self.starting_x = cell.x;
            self.starting_y = cell.y;
            return cell;
        } else |_| {
            return null;
        }
    }
};

fn iterateInDirection(map: [][]Cell, start: Cell, direction: Direction) MapDirectionIterator {
    return MapDirectionIterator{
        .direction = direction,
        .starting_x = start.x,
        .starting_y = start.y,
        .map = map,
    };
}

// TODO:
// make function that gets passed a Direction and starting coordinates and input
// and returns a []*Cell
// for that direction
// implement this functionality by returning an iterator
// https://danthedev.com/zig-iterators/

const Cell = struct {
    x: usize,
    y: usize,
    content: CellContent,
    neighbors: *Neighbors,

    allocator: std.mem.Allocator,

    const Neighbors = std.AutoHashMap(Direction, struct { cell: *Cell, distance: usize });
    const Self = @This();

    fn init(allocator: std.mem.Allocator, x: usize, y: usize, content: CellContent) !Self {
        const map: *Neighbors = try allocator.create(Neighbors);
        map.* = Neighbors.init(allocator);
        return Self{
            .y = y,
            .x = x,
            .content = content,
            .neighbors = map,
            .allocator = allocator,
        };
    }

    fn deinit(self: Self) void {
        self.neighbors.deinit();
        self.allocator.destroy(self.neighbors);
    }
};

const CellContent = union(enum) {
    empty,
    antinode,
    antenna: u8,
    antenna_and_antinode: u8,
};

/// caller takes ownership of memory
fn parseInputString(allocator: std.mem.Allocator, input: []const []const u8) ![][]Cell {
    var data = try allocator.alloc([]Cell, input.len);

    for (input, 0..) |row, row_idx| {
        var row_mem = try allocator.alloc(Cell, row.len);
        for (row, 0..) |cell_char, cell_idx| {
            const cell_content = switch (cell_char) {
                'a'...'z', 'A'...'Z', '0'...'9' => CellContent{ .antenna = cell_char },
                else => CellContent.empty,
            };

            row_mem[cell_idx] = try Cell.init(allocator, cell_idx, row_idx, cell_content);
        }
        data[row_idx] = row_mem;
    }

    return data;
}

test "establishNeihborRelationships - 1" {
    var input = try testing.allocator.alloc([]u8, 12);
    input[0] = try testing.allocator.dupe(u8, "............");
    input[1] = try testing.allocator.dupe(u8, "........0...");
    input[2] = try testing.allocator.dupe(u8, ".....0......");
    input[3] = try testing.allocator.dupe(u8, ".......0....");
    input[4] = try testing.allocator.dupe(u8, "....0.......");
    input[5] = try testing.allocator.dupe(u8, "......A.....");
    input[6] = try testing.allocator.dupe(u8, "............");
    input[7] = try testing.allocator.dupe(u8, "............");
    input[8] = try testing.allocator.dupe(u8, "........A...");
    input[9] = try testing.allocator.dupe(u8, ".........A..");
    input[10] = try testing.allocator.dupe(u8, "............");
    input[11] = try testing.allocator.dupe(u8, "............");
    defer {
        for (input) |line| testing.allocator.free(line);
        testing.allocator.free(input);
    }

    const map = try Map.init(testing.allocator, input);
    defer map.deinit();

    map.print();

    try establishNeighbourRelationships(testing.allocator, map.data);
}

// fn establishRelationship(maybe_first: ?*Cell, maybe_last: ?*Cell, direction: Direction, distance: usize) void {
//     if (maybe_first) |first| {
//         if (maybe_last) |last| {
//             first.*.neighbors.put(direction.opposite(), last);
//         }
//     }
// }

// when iterator function is ready use that
fn establishNeighbourRelationships(_: std.mem.Allocator, data: [][]Cell) !void {
    // 4 passes:
    // - N to S
    // - W to e
    // - NW to SE
    // - NE to SW

    for (0..data.len) |x_coord| {
        var it = iterateInDirection(data, data[0][x_coord], .S);
        var antenna1: ?*Cell = null;
        var antenna2: ?*Cell = null;
        while (it.next()) |cell| {
            switch (cell.content) {
                CellContent.antenna => |_| {
                    antenna1 = antenna2;
                    antenna2 = cell;
                },
                else => {},
            }
            if (antenna1) |a1| {
                if (antenna2) |a2| {
                    std.debug.print("{d},{d}: {s} ", .{ a1.x, a1.y, &[_]u8{a1.content.antenna} });
                    std.debug.print("{d},{d}: {s}\n", .{ a2.x, a2.y, &[_]u8{a2.content.antenna} });
                }
            }
        }
    }
}

pub const Map = struct {
    data: [][]Cell,
    allocator: std.mem.Allocator,

    const Self = @This();

    /// caller owns the memory; call deinit() when done
    pub fn init(allocator: std.mem.Allocator, input: []const []const u8) !*Self {
        const data = try parseInputString(allocator, input);

        const ptr: *Self = try allocator.create(Self);
        ptr.* = Self{
            .data = data,
            .allocator = allocator,
        };

        return ptr;
    }

    pub fn deinit(self: *Self) void {
        for (self.data) |sl| {
            for (sl) |cell| cell.deinit();
            self.allocator.free(sl);
        }
        self.allocator.free(self.data);
        self.allocator.destroy(self);
    }

    pub fn print(self: *Self) void {
        for (self.data) |row| {
            for (row) |cell| {
                switch (cell.content) {
                    CellContent.empty => std.debug.print(".", .{}),
                    CellContent.antinode => std.debug.print("#", .{}),
                    // antenna_and_antinode should print a !
                    CellContent.antenna, CellContent.antenna_and_antinode => |char| std.debug.print("{s}", .{&[_]u8{char}}),
                }
                // std.debug.print("{s}", .{" "});
            }

            std.debug.print("\n", .{});
        }

        std.debug.print("\n", .{});
    }
};

// first make a function that passes over the map in all directions and populates
// the neighbor maps in cells
// could work like this
// loop over cells sequencially and store the latest 2 encountered towers in two variables
// prev_cell, curr_cell
// whenever we encounter a new one we put new into curr, curr into prev, and we
// establish in each a neighbor pointer to the other (according to the direction)
// we also keep track of distance between the two with other variable(s) that count the
// empty cells inbetween
//
// we also need a function that given a Direction and a distance returns a pointer to a cell
// at this point pass over all the cells with antennas and using this function
// assign antinodes based on the neighbors stuff
//
// maybe it's worth storing pointers to all antenna cells somewhere in map

// diagonals work like this
// a
// xx
//  a
//  xx
//   a
//   xx
