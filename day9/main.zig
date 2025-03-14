const std = @import("std");
const lib = @import("lib.zig");

/// Caller takes ownership of the result
fn get_input(allocator: std.mem.Allocator) anyerror![]const u8 {
    const file = std.fs.cwd().openFile("input.txt", .{}) catch |err| return err;
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var string = std.ArrayList(u8).init(allocator);
    defer string.deinit();

    var buffer: [100]u8 = undefined;
    while (in_stream.read(&buffer)) |count| {
        if (count == 0) break;
        try string.appendSlice(&buffer);
    } else |_| {}

    return try string.toOwnedSlice();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input = try get_input(allocator);
    defer {
        allocator.free(input);
    }

    std.debug.print("input: {s}\n", .{input});
}
