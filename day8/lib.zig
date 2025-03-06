const std = @import("std");
const testing = std.testing;

const MapError = error{OutOfBounds};

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
};

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

            row_mem[cell_idx] = try Cell.init(allocator, row_idx, cell_idx, cell_content);
        }
        data[row_idx] = row_mem;
    }

    return data;
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
