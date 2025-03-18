const std = @import("std");
const lib = @import("lib.zig");
const lib2 = @import("lib2.zig");

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
        var line_list = std.ArrayList(u8).init(allocator);
        defer line_list.deinit();

        try line_list.appendSlice(line);
        try lines.append(try line_list.toOwnedSlice());
    }

    return try lines.toOwnedSlice();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input = try get_input(allocator);
    defer {
        for (input) |line| allocator.free(line);
        allocator.free(input);
    }

    const map = try lib2.Map.init(allocator, input);
    defer map.deinit();

    const map2 = try map.clone();
    defer map2.deinit();

    std.debug.print("count: {d}\n", .{try map.walkGuard()});
    std.debug.print("loops: {d}\n", .{try map2.findLoops()});
    // for (input) |line| { }
}
