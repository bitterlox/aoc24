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

    var cache = lib.Cache.init(allocator);
    defer cache.deinit();

    const input = try get_input(allocator);
    defer {
        for (input) |line| allocator.free(line);
        allocator.free(input);
    }

    const input_copy = try lib.dupeInput(allocator, input);
    defer {
        for (input_copy) |sl| allocator.free(sl);
        allocator.free(input_copy);
    }

    std.debug.print("count: {d}\n", .{try lib.walkGuard(input, &cache)});
    std.debug.print("cache count: {d}\n", .{cache.count()});
    std.debug.print("loops: {d}\n", .{try lib.findLoops(allocator, input_copy, &cache)});
    // for (input) |line| { }
}
