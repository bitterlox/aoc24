const std = @import("std");
const lib = @import("lib.zig");

/// Caller takes ownership of the result
fn get_input(allocator: std.mem.Allocator) anyerror![]lib.Calibration {
    const fileContent = allocator.alloc(u8, 1024 * 16) catch |err| return err;
    defer allocator.free(fileContent);

    const file = std.fs.cwd().openFile("input.txt", .{}) catch |err| return err;
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var lines = std.ArrayList(lib.Calibration).init(allocator);
    defer lines.deinit();

    while (try in_stream.readUntilDelimiterOrEof(fileContent, '\n')) |line| {
        var num_list = std.ArrayList(u64).init(allocator);
        defer num_list.deinit();

        var it = std.mem.tokenizeAny(u8, line, ": ");

        while (it.next()) |val| {
            const num = try std.fmt.parseInt(u64, val, 10);
            try num_list.append(num);
        }

        const product = num_list.orderedRemove(0);

        try lines.append(.{ product, try num_list.toOwnedSlice() });
    }

    return try lines.toOwnedSlice();
}

fn firstPartResult(allocator: std.mem.Allocator, calibrations: []lib.Calibration) !u64 {
    var result: u64 = 0;

    for (calibrations) |calibration| {
        if (try lib.calibrationIsValid(allocator, calibration)) result += calibration.@"0";
    }

    return result;
}

fn secondPartResult(allocator: std.mem.Allocator, calibrations: []lib.Calibration) !u64 {
    var result: u64 = 0;

    for (calibrations) |calibration| {
        const value, _ = calibration;
        const valid = try lib.calibrationIsValidWithConcat(allocator, calibration);
        if (valid) result += value;
    }

    return result;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input = try get_input(allocator);
    defer {
        for (input) |line| allocator.free(line.@"1");
        allocator.free(input);
    }
    const first = try firstPartResult(allocator, input);
    const second = try secondPartResult(allocator, input);

    // std.debug.print("input: {any}\n", .{input});
    std.debug.print("result: {d}\n", .{first});
    std.debug.print("result: {d}\n", .{second});
    // for (input) |line| { }
}
