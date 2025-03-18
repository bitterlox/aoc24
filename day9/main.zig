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

    // using this method to read somehow sneaks in a line feed (ascii 10)
    // so we remove it in the next loop
    var buffer: [100]u8 = undefined;
    while (in_stream.read(&buffer)) |count| {
        if (count == 0) break;
        // std.debug.print("{c}\n", .{buffer[0..count]});
        // std.debug.print("{s}\n", .{buffer[0..count]});
        // std.debug.print("{d}\n", .{buffer[count - 1]});
        // std.debug.print("read: {d}\n", .{count});
        try string.appendSlice(buffer[0..count]);
    } else |_| {}

    for (string.items, 0..) |char, idx| {
        if (char == 10) {
            _ = string.orderedRemove(idx);
        }
    }

    return try string.toOwnedSlice();
}

fn partOne(allocator: std.mem.Allocator, input: []const u8) !u64 {
    const disk_map = try lib.generateDiskmap(allocator, input);
    defer allocator.free(disk_map);

    const compressed = try lib.compressDiskmap(allocator, disk_map);
    defer allocator.free(compressed);

    return lib.calculateChecksum(compressed);
}

fn partTwo(allocator: std.mem.Allocator, input: []const u8) !u64 {
    const disk_map = try lib.generateDiskmap(allocator, input);
    defer allocator.free(disk_map);

    const compressed = try lib.compressOnlyWholeFiles(allocator, disk_map);
    defer allocator.free(compressed);

    return lib.calculateChecksum(compressed);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input = try get_input(allocator);
    defer allocator.free(input);

    // std.debug.print("input: {s}\n", .{input});
    std.debug.print("pt1: {d}\n", .{try partOne(allocator, input)});
    std.debug.print("pt1: {d}\n", .{try partTwo(allocator, input)});
}
