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

const Cell = struct {
    x: usize,
    y: usize,
    content: CellContent,

    const Self = @This();
    const Coords = struct { x: usize, y: usize };

    fn init(_: std.mem.Allocator, x: usize, y: usize, content: CellContent) Self {
        return Self{
            .y = y,
            .x = x,
            .content = content,
        };
    }
};

const CellContent = union(enum) {
    empty,
    antinode,
    antenna: u8,
    antenna_and_antinode: u8,
};

test "calculateAntinodePositions - 1" {
    const param = &[_]Cell{
        Cell{ .x = 4, .y = 3, .content = CellContent{ .antenna = 'a' } },
        Cell{ .x = 5, .y = 5, .content = CellContent{ .antenna = 'a' } },
    };

    const expected = &[_]Cell.Coords{
        Cell.Coords{ .x = 6, .y = 7 },
        Cell.Coords{ .x = 3, .y = 1 },
    };

    const actual = try calculateAntinodePositions(testing.allocator, param);
    defer testing.allocator.free(actual);

    try testing.expectEqualDeep(expected, actual);
}

test "calculateAntinodePositions - 2" {
    const param = &[_]Cell{
        Cell{ .x = 4, .y = 3, .content = CellContent{ .antenna = 'a' } },
        Cell{ .x = 5, .y = 5, .content = CellContent{ .antenna = 'a' } },
        Cell{ .x = 8, .y = 4, .content = CellContent{ .antenna = 'a' } },
    };

    const expected = &[_]Cell.Coords{
        Cell.Coords{ .x = 6, .y = 7 },
        Cell.Coords{ .x = 12, .y = 5 },
        Cell.Coords{ .x = 3, .y = 1 },
        Cell.Coords{ .x = 11, .y = 3 },
        Cell.Coords{ .x = 0, .y = 2 },
        Cell.Coords{ .x = 2, .y = 6 },
    };

    const actual = try calculateAntinodePositions(testing.allocator, param);
    defer testing.allocator.free(actual);

    errdefer std.debug.print("{any}\n", .{actual});

    try testing.expectEqualSlices(Cell.Coords, expected, actual);
}

fn hypot(x: usize, y: usize) f32 {
    const pow = std.math.pow;
    return @floatFromInt(std.math.sqrt(pow(usize, x, 2) + pow(usize, y, 2)));
}

fn calculateAntinodesOfPair(list: *std.AutoArrayHashMap(Cell.Coords, void), cell_a: Cell, cell_b: Cell) !void {
    const x_a = cell_a.x;
    const y_a = cell_a.y;
    const x_b = cell_b.x;
    const y_b = cell_b.y;

    var xa_gt_xb = false;
    var ya_gt_yb = false;

    const x_diff = if (x_a > x_b) blk: {
        xa_gt_xb = true;
        break :blk x_a - x_b;
    } else blk: {
        break :blk x_b - x_a;
    };

    const y_diff = if (y_a > y_b) blk: {
        ya_gt_yb = true;
        break :blk y_a - y_b;
    } else blk: {
        break :blk y_b - y_a;
    };

    // helpful math refresher
    // https://stackoverflow.com/a/27223108
    const cells_distance = hypot(x_diff, y_diff);

    const dx: f32 = @as(f32, @floatFromInt(x_diff)) / cells_distance;
    const dy: f32 = @as(f32, @floatFromInt(y_diff)) / cells_distance;

    // for each we have a vector in the same direction, and one in the opposite one
    const x_antinode_b = if (xa_gt_xb) blk: {
        break :blk @as(f32, @floatFromInt(x_a)) - cells_distance * 2 * dx;
    } else blk: {
        break :blk @as(f32, @floatFromInt(x_a)) + cells_distance * 2 * dx;
    };

    const y_antinode_b = if (ya_gt_yb) blk: {
        break :blk @as(f32, @floatFromInt(y_a)) - cells_distance * 2 * dy;
    } else blk: {
        break :blk @as(f32, @floatFromInt(y_a)) + cells_distance * 2 * dy;
    };

    // std.debug.print("x3 {d} y3 {d} \n", .{ x_antinode_b, y_antinode_b });

    if (x_antinode_b >= 0 and y_antinode_b >= 0) {
        try list.put(.{ .x = @intFromFloat(x_antinode_b), .y = @intFromFloat(y_antinode_b) }, {});
    }

    // const x_antinode_a = @as(f32, @floatFromInt(x_b)) + cells_distance * dx;
    // const y_antinode_a = @as(f32, @floatFromInt(y_b)) + cells_distance * dy;
    // std.debug.print("x3 {d} y3 {d} \n", .{ x_antinode_a, y_antinode_a });

    // if (x_antinode_a >= 0 and y_antinode_a >= 0) {
    //     try list.put(.{ .x = @intFromFloat(x_antinode_a), .y = @intFromFloat(y_antinode_a) }, {});
    // }

    // std.debug.print("dx {d} dy {d} \n", .{ dx, dy });
    // std.debug.print("distance {d} \n", .{ab_distance});
}

/// caller owns the returned memory
fn calculateAntinodePositions(allocator: std.mem.Allocator, antennas: []const Cell) ![]Cell.Coords {
    var result = std.AutoArrayHashMap(Cell.Coords, void).init(allocator);
    defer result.deinit();

    for (antennas) |cell| {
        for (antennas) |other_cell| {
            // std.debug.print("cell:({d} {d}) other:({d} {d})\n", .{ cell.x, cell.y, other_cell.x, other_cell.y });
            if (cell.x == other_cell.x and cell.y == other_cell.y) continue;
            try calculateAntinodesOfPair(&result, cell, other_cell);
        }
    }

    return allocator.dupe(Cell.Coords, result.keys());
}

test "calculateAntinodePositionsWithResonantFreqs - 1" {
    const param = &[_]Cell{
        Cell{ .x = 0, .y = 0, .content = CellContent{ .antenna = 'T' } },
        Cell{ .x = 1, .y = 2, .content = CellContent{ .antenna = 'T' } },
        Cell{ .x = 3, .y = 1, .content = CellContent{ .antenna = 'T' } },
    };

    const expected = &[_]Cell.Coords{
        Cell.Coords{ .x = 1, .y = 2 },
        Cell.Coords{ .x = 2, .y = 4 },
        Cell.Coords{ .x = 3, .y = 6 },
        Cell.Coords{ .x = 4, .y = 8 },
        Cell.Coords{ .x = 3, .y = 1 },
        Cell.Coords{ .x = 6, .y = 2 },
        Cell.Coords{ .x = 9, .y = 3 },
        Cell.Coords{ .x = 0, .y = 0 },
        Cell.Coords{ .x = 5, .y = 0 },
    };

    const actual = try calculateAntinodePositionsWithResonantFreqs(testing.allocator, param, 10, 10);
    defer testing.allocator.free(actual);

    errdefer std.debug.print("{any}\n", .{actual});

    try testing.expectEqualSlices(Cell.Coords, expected, actual);
}

fn calculateAntinodesOfPairWithResonantFreqs(list: *std.AutoArrayHashMap(Cell.Coords, void), cell_a: Cell, cell_b: Cell, max_x: usize, max_y: usize) !void {
    const x_a = cell_a.x;
    const y_a = cell_a.y;
    const x_b = cell_b.x;
    const y_b = cell_b.y;

    var xa_gt_xb = false;
    var ya_gt_yb = false;

    const x_diff = if (x_a > x_b) blk: {
        xa_gt_xb = true;
        break :blk x_a - x_b;
    } else blk: {
        break :blk x_b - x_a;
    };

    const y_diff = if (y_a > y_b) blk: {
        ya_gt_yb = true;
        break :blk y_a - y_b;
    } else blk: {
        break :blk y_b - y_a;
    };

    // helpful math refresher
    // https://stackoverflow.com/a/27223108
    const cells_distance = hypot(x_diff, y_diff);

    const dx: f32 = @as(f32, @floatFromInt(x_diff)) / cells_distance;
    const dy: f32 = @as(f32, @floatFromInt(y_diff)) / cells_distance;

    var x_antinode: f32 = 0;
    var y_antinode: f32 = 0;
    var distance_multiplier: f32 = 1;

    var x_in_bounds = x_antinode >= 0 and x_antinode < @as(f32, @floatFromInt(max_x));
    var y_in_bounds = y_antinode >= 0 and y_antinode < @as(f32, @floatFromInt(max_y));

    while (x_in_bounds and y_in_bounds) : ({
        x_in_bounds = x_antinode >= 0 and x_antinode < @as(f32, @floatFromInt(max_x));
        y_in_bounds = y_antinode >= 0 and y_antinode < @as(f32, @floatFromInt(max_y));
        if (x_in_bounds and y_in_bounds) {
            try list.put(.{ .x = @intFromFloat(x_antinode), .y = @intFromFloat(y_antinode) }, {});
        }
    }) {
        // for each we have a vector in the same direction, and one in the opposite one
        x_antinode = if (xa_gt_xb) blk: {
            break :blk @as(f32, @floatFromInt(x_a)) - cells_distance * distance_multiplier * dx;
        } else blk: {
            break :blk @as(f32, @floatFromInt(x_a)) + cells_distance * distance_multiplier * dx;
        };

        y_antinode = if (ya_gt_yb) blk: {
            break :blk @as(f32, @floatFromInt(y_a)) - cells_distance * distance_multiplier * dy;
        } else blk: {
            break :blk @as(f32, @floatFromInt(y_a)) + cells_distance * distance_multiplier * dy;
        };
        distance_multiplier += 1;
        std.debug.print("x3 {d} y3 {d} \n", .{ x_antinode, y_antinode });
    }
}

/// caller owns the returned memory
fn calculateAntinodePositionsWithResonantFreqs(allocator: std.mem.Allocator, antennas: []const Cell, max_x: usize, max_y: usize) ![]Cell.Coords {
    var result = std.AutoArrayHashMap(Cell.Coords, void).init(allocator);
    defer result.deinit();

    for (antennas) |cell| {
        for (antennas) |other_cell| {
            // std.debug.print("cell:({d} {d}) other:({d} {d})\n", .{ cell.x, cell.y, other_cell.x, other_cell.y });
            if (cell.x == other_cell.x and cell.y == other_cell.y) continue;
            try calculateAntinodesOfPairWithResonantFreqs(&result, cell, other_cell, max_x, max_y);
        }
    }

    return allocator.dupe(Cell.Coords, result.keys());
}

/// caller owns the returned memory
fn parseInputString(allocator: std.mem.Allocator, input: []const []const u8) ![][]Cell {
    var data = try allocator.alloc([]Cell, input.len);

    for (input, 0..) |row, row_idx| {
        var row_mem = try allocator.alloc(Cell, row.len);
        for (row, 0..) |cell_char, cell_idx| {
            const cell_content = switch (cell_char) {
                'a'...'z', 'A'...'Z', '0'...'9' => CellContent{ .antenna = cell_char },
                else => CellContent.empty,
            };

            row_mem[cell_idx] = Cell.init(allocator, cell_idx, row_idx, cell_content);
        }
        data[row_idx] = row_mem;
    }

    return data;
}

test "Map.countAntinodes() - 1" {
    const str = &[_][]const u8{
        "............",
        "........0...",
        ".....0......",
        ".......0....",
        "....0.......",
        "......A.....",
        "............",
        "............",
        "........A...",
        ".........A..",
        "............",
        "............",
    };

    const map = try Map.init(testing.allocator, str);
    defer map.deinit();

    try map.setAntinodes();
    // map.print();

    try testing.expectEqual(14, map.countAntinodes());
}

test "Map.countAntinodesWithResonantFreqs() - 1" {
    const str = &[_][]const u8{
        "............",
        "........0...",
        ".....0......",
        ".......0....",
        "....0.......",
        "......A.....",
        "............",
        "............",
        "........A...",
        ".........A..",
        "............",
        "............",
    };

    const map = try Map.init(testing.allocator, str);
    defer map.deinit();

    try map.setAntinodesWithResonantFreqs();
    // map.print();

    try testing.expectEqual(34, map.countAntinodes());
}

pub const Map = struct {
    data: [][]Cell,
    antennas: std.AutoHashMap(u8, []Cell),
    allocator: std.mem.Allocator,

    const Self = @This();

    /// caller owns the memory; call deinit() when done
    pub fn init(allocator: std.mem.Allocator, input: []const []const u8) !*Self {
        const data = try parseInputString(allocator, input);

        var map = std.AutoHashMap(u8, []Cell).init(allocator);

        for (data) |row| {
            for (row) |cell| {
                switch (cell.content) {
                    CellContent.antenna => |c| {
                        if (map.getEntry(c)) |entry| {
                            var list = std.ArrayList(Cell).fromOwnedSlice(allocator, entry.value_ptr.*);
                            defer list.deinit();

                            try list.append(cell);
                            try map.put(c, try list.toOwnedSlice());
                        } else {
                            var list = std.ArrayList(Cell).init(allocator);
                            defer list.deinit();

                            try list.append(cell);
                            try map.put(c, try list.toOwnedSlice());
                        }
                    },
                    else => {},
                }
            }
        }

        const ptr: *Self = try allocator.create(Self);
        ptr.* = Self{
            .data = data,
            .antennas = map,
            .allocator = allocator,
        };

        return ptr;
    }

    pub fn deinit(self: *Self) void {
        for (self.data) |sl| {
            // for (sl) |cell| cell.deinit();
            self.allocator.free(sl);
        }

        var it = self.antennas.iterator();
        while (it.next()) |entry| {
            self.allocator.free(entry.value_ptr.*);
        }
        self.antennas.deinit();

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
                    CellContent.antenna => |char| std.debug.print("{s}", .{&[_]u8{char}}),
                    CellContent.antenna_and_antinode => |_| std.debug.print("!", .{}),
                }
                // std.debug.print("{s}", .{" "});
            }

            std.debug.print("\n", .{});
        }

        std.debug.print("\n", .{});

        // var it = self.antennas.iterator();
        // while (it.next()) |entry| {
        //     for (entry.value_ptr.*) |cell| {
        //         std.debug.print("{c}({d} {d})", .{ cell.content.antenna, cell.x, cell.y });
        //     }
        //     std.debug.print("\n", .{});
        // }
    }

    pub fn setAntinodes(self: *Self) !void {
        var it = self.antennas.iterator();
        while (it.next()) |entry| {
            const potential_antinode_positions = try calculateAntinodePositions(self.allocator, entry.value_ptr.*);
            defer self.allocator.free(potential_antinode_positions);

            for (potential_antinode_positions) |coords| {
                if (checkCoordsOutOfBounds(self.data, coords.x, coords.y)) |_| {
                    const new_content = switch (self.data[coords.y][coords.x].content) {
                        CellContent.antenna => |c| CellContent{ .antenna_and_antinode = c },
                        else => CellContent.antinode,
                    };
                    self.data[coords.y][coords.x].content = new_content;
                } else |_| {}
            }
        }
    }

    pub fn setAntinodesWithResonantFreqs(self: *Self) !void {
        var it = self.antennas.iterator();
        while (it.next()) |entry| {
            const potential_antinode_positions = try calculateAntinodePositionsWithResonantFreqs(self.allocator, entry.value_ptr.*, self.data[0].len, self.data.len);
            defer self.allocator.free(potential_antinode_positions);

            for (potential_antinode_positions) |coords| {
                if (checkCoordsOutOfBounds(self.data, coords.x, coords.y)) |_| {
                    const new_content = switch (self.data[coords.y][coords.x].content) {
                        CellContent.antenna => |c| CellContent{ .antenna_and_antinode = c },
                        else => CellContent.antinode,
                    };
                    self.data[coords.y][coords.x].content = new_content;
                } else |_| {}
            }
        }
    }

    pub fn countAntinodes(self: *Self) u64 {
        var count: u64 = 0;

        for (self.data) |row| {
            for (row) |cell| {
                switch (cell.content) {
                    CellContent.antinode, CellContent.antenna_and_antinode => count += 1,
                    else => {},
                }
            }
        }

        return count;
    }
};
