const std = @import("std");
const lib = @import("lib.zig");

/// Caller takes ownership of the result
fn get_input(allocator: std.mem.Allocator) anyerror!*std.ArrayList(u64) {
    const fileContent = allocator.alloc(u8, 1024 * 16) catch |err| return err;
    defer allocator.free(fileContent);

    const file = std.fs.cwd().openFile("input.txt", .{}) catch |err| return err;
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var linesPtr = try allocator.create(std.ArrayList(u64));
    linesPtr.* = std.ArrayList(u64).init(allocator);

    while (try in_stream.readUntilDelimiterOrEof(fileContent, '\n')) |line| {
        var it = std.mem.splitAny(u8, line, " ");
        while (it.next()) |number| {
            const i = try std.fmt.parseInt(u64, number, 10);
            try linesPtr.append(i);
        }
    }

    return linesPtr;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // var buffer: [1024 * 2500]u8 = undefined;
    // var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = gpa.allocator();

    const input = try get_input(allocator);
    defer {
        input.deinit();
        allocator.destroy(input);
    }

    try lib.blink(input, 25);
    std.debug.print("part 1: {d}\n", .{input.items.len});

    try lib.blink(input, 50);
    std.debug.print("part 2: {d}\n", .{input.items.len});
    // std.debug.print("part 1: {d}\n", .{try lib.calculateAllTrailScores(allocator, converted)});
    // std.debug.print("part 2: {d}\n", .{try lib.calculateAllTrailRatings(allocator, converted)});
}
