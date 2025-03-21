const std = @import("std");
const lib = @import("lib.zig");

/// Caller takes ownership of the result
fn get_input(allocator: std.mem.Allocator) anyerror![][]u8 {
    const fileContent = allocator.alloc(u8, 1024 * 16) catch |err| return err;
    defer allocator.free(fileContent);

    const file = std.fs.cwd().openFile("input.txt", .{}) catch |err| return err;
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var lines = std.ArrayList([]u8).init(allocator);
    defer lines.deinit();

    while (try in_stream.readUntilDelimiterOrEof(fileContent, '\n')) |line| {
        var list = std.ArrayList(u8).init(allocator);
        defer list.deinit();

        try list.appendSlice(line);

        try lines.append(try list.toOwnedSlice());
    }

    return try lines.toOwnedSlice();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input = try get_input(allocator);
    defer {
        for (input) |sl| allocator.free(sl);
        allocator.free(input);
    }

    const converted = try lib.convertInput(allocator, input);
    defer {
        for (converted) |sl| allocator.free(sl);
        allocator.free(converted);
    }

    // std.debug.print("input: {s}\n", .{input});
    std.debug.print("part 1: {d}\n", .{try lib.calculateAllTrailScores(allocator, converted)});
}
