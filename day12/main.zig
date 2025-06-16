const std = @import("std");
const lib = @import("lib.zig");

/// Caller takes ownership of the result
fn get_input(allocator: std.mem.Allocator) anyerror!*std.ArrayList([]u8) {
    const fileContent = allocator.alloc(u8, 1024 * 16) catch |err| return err;
    defer allocator.free(fileContent);

    const file = std.fs.cwd().openFile("input.txt", .{}) catch |err| return err;
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var lines = try allocator.create(std.ArrayList([]u8));
    lines.* = std.ArrayList([]u8).init(allocator);

    while (try in_stream.readUntilDelimiterOrEof(fileContent, '\n')) |line| {
        var list = std.ArrayList(u8).init(allocator);
        for (line) |char| try list.append(char);
        try lines.append(try list.toOwnedSlice());
    }

    return lines;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // var buffer: [1024 * 2500]u8 = undefined;
    // var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = gpa.allocator();

    const input = try get_input(allocator);
    defer {
        for (input.items) |l| allocator.free(l);
        input.deinit();
        allocator.destroy(input);
    }

    std.debug.print("input: {s}", .{input.items});
}
