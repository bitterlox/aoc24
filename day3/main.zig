const std = @import("std");
const find_muls = @import("find_muls.zig").find_muls;

/// Caller takes ownership of the result
fn get_input(allocator: std.mem.Allocator) anyerror![]u8 {
    const fileContent = allocator.alloc(u8, 1024 * 16) catch |err| return err;
    defer allocator.free(fileContent);

    const file = std.fs.cwd().openFile("input.txt", .{}) catch |err| return err;
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var list = std.ArrayList(u8).init(allocator);
    defer list.deinit();

    while (try in_stream.readUntilDelimiterOrEof(fileContent, '\n')) |line| {
        try list.appendSlice(line);
    }

    return try list.toOwnedSlice();
}

fn add_muls(muls: []const [2]u64) u64 {
    var sum: u64 = 0;
    for (muls) |arr| {
        const a, const b = arr;
        sum += a * b;
    }
    return sum;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input = try get_input(allocator);

    const muls = try find_muls(allocator, input);
    defer allocator.free(muls);

    std.debug.print("result: {d}", .{add_muls(muls)});
}
