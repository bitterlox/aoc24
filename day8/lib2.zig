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

    const expected = &[_]Cell.Coords{ Cell.Coords{ .x = 3, .y = 1 }, Cell.Coords{ .x = 6, .y = 7 } };

    const actual = try calculateAntinodePositions(testing.allocator, param);
    defer testing.allocator.free(actual);

    try testing.expectEqualSlices(Cell.Coords, expected, actual);
}

fn hypot(x: usize, y: usize) f32 {
    const pow = std.math.pow;
    return @floatFromInt(std.math.sqrt(pow(usize, x, 2) + pow(usize, y, 2)));
}

fn calculateAntinodePositions(allocator: std.mem.Allocator, antennas: []const Cell) ![]Cell.Coords {
    var result = std.ArrayList(Cell.Coords).init(allocator);
    defer result.deinit();

    for (0..antennas.len - 1, 1..antennas.len) |i, j| {
        const x_a = antennas[i].x;
        const y_a = antennas[i].y;
        const x_b = antennas[j].x;
        const y_b = antennas[j].y;

        const x_diff = if (x_a > x_b) blk: {
            break :blk x_a - x_b;
        } else blk: {
            break :blk x_b - x_a;
        };

        const y_diff = if (y_a > y_b) blk: {
            break :blk y_a - y_b;
        } else blk: {
            break :blk y_b - y_a;
        };

        // helpful math refresher
        // https://stackoverflow.com/a/27223108
        const ab_distance = hypot(x_diff, y_diff);

        const x_diff_float: f32 = @floatFromInt(x_diff);
        const dx: f32 = x_diff_float / ab_distance;
        const y_diff_float: f32 = @floatFromInt(y_diff);
        const dy: f32 = y_diff_float / ab_distance;

        inline for ([2]Cell{ antennas[i], antennas[j] }) |cell| {
            const x = cell.x;
            const y = cell.y;

            // for each we have a vector in the same direction, and one in the opposite one
            const x_same = @as(f32, @floatFromInt(x)) + ab_distance * 2 * dx;
            const y_same = @as(f32, @floatFromInt(y)) + ab_distance * 2 * dy;

            const x_opposite = @as(f32, @floatFromInt(x)) - ab_distance * 2 * dx;
            const y_opposite = @as(f32, @floatFromInt(y)) - ab_distance * 2 * dy;

            std.debug.print("x3 {d} y3 {d} \n", .{ x_same, y_same });
            std.debug.print("x3 {d} y3 {d} \n", .{ x_opposite, y_opposite });
        }

        // const x3 = @as(f32, @floatFromInt(x_a)) + ab_distance * 2 * dx;
        // const y3 = @as(f32, @floatFromInt(y_a)) + ab_distance * 2 * dy;

        std.debug.print("dx {d} dy {d} \n", .{ dx, dy });
        std.debug.print("distance {d} \n", .{ab_distance});

        try result.append(.{ .x = x_a, .y = y_b });
    }

    return result.toOwnedSlice();
}

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

            row_mem[cell_idx] = Cell.init(allocator, cell_idx, row_idx, cell_content);
        }
        data[row_idx] = row_mem;
    }

    return data;
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
                    CellContent.antenna, CellContent.antenna_and_antinode => |char| std.debug.print("{s}", .{&[_]u8{char}}),
                }
                // std.debug.print("{s}", .{" "});
            }

            std.debug.print("\n", .{});
        }

        std.debug.print("\n", .{});

        var it = self.antennas.iterator();
        while (it.next()) |entry| {
            for (entry.value_ptr.*) |cell| {
                std.debug.print("{c}({d} {d})", .{ cell.content.antenna, cell.x, cell.y });
            }
            std.debug.print("\n", .{});
        }
    }
};
