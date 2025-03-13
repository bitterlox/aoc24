const std = @import("std");
const lib = @import("lib2.zig");

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

        var it = std.mem.tokenizeAny(u8, line, " ");

        while (it.next()) |val| {
            try list.appendSlice(val);
        }

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

    const map = try lib.Map.init(allocator, input);
    defer map.deinit();

    for (input) |line| std.debug.print("{s}\n", .{line});

    std.debug.print("\n", .{});

    map.print();

    // std.debug.print("result: {d}\n", .{first});
    // std.debug.print("result: {d}\n", .{second});
    // for (input) |line| { }
}
