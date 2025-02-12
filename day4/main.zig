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

    var list = std.ArrayList([]u8).init(allocator);
    defer list.deinit();

    while (try in_stream.readUntilDelimiterOrEof(fileContent, '\n')) |line| {
        var sublist = std.ArrayList(u8).init(allocator);
        defer sublist.deinit();

        try sublist.appendSlice(line);
        try list.append(try sublist.toOwnedSlice());
    }

    return try list.toOwnedSlice();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input = try get_input(allocator);
    defer {
        for (input) |line| {
            allocator.free(line);
        }
        allocator.free(input);
    }

    // result is too low, do more stuff
    const result = try lib.find_xmases_in_matrix(allocator, input);

    std.debug.print("line: {d}\n", .{result});
}
