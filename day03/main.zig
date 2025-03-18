const std = @import("std");
const lib = @import("lib.zig");

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

fn first_result(allocator: std.mem.Allocator, input: []u8) !u64 {
    const muls = try lib.find_muls(allocator, input);
    defer allocator.free(muls);

    var sum: u64 = 0;
    for (muls) |arr| {
        const a, const b = arr;
        sum += a * b;
    }
    return sum;
}

fn second_result(allocator: std.mem.Allocator, input: []u8) !u64 {
    const ops = try lib.parse_string(allocator, input);
    defer allocator.free(ops);

    var sum: u64 = 0;
    var add = true;
    for (ops) |op| {
        switch (op) {
            .mul => |arr| {
                if (add) sum += arr[0] * arr[1];
            },
            .do => add = true,
            .dont => add = false,
        }
    }
    return sum;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input = try get_input(allocator);

    std.debug.print("result: {d}\n", .{try first_result(allocator, input)});
    std.debug.print("result: {d}", .{try second_result(allocator, input)});
}
