const std = @import("std");

/// Caller takes ownership of the result
const Numbers = struct { left: []u64, right: []u64 };
fn getInput(allocator: std.mem.Allocator) anyerror!Numbers {
    const fileContent = allocator.alloc(u8, 1024 * 16) catch |err| return err;
    defer allocator.free(fileContent);

    var leftNumbers = std.ArrayList(u64).init(allocator);
    defer leftNumbers.deinit();

    var rightNumbers = std.ArrayList(u64).init(allocator);
    defer rightNumbers.deinit();

    const file = std.fs.cwd().openFile("input.txt", .{}) catch |err| return err;
    defer file.close();

    std.debug.print("got path", .{});

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    while (try in_stream.readUntilDelimiterOrEof(fileContent, '\n')) |line| {
        var it = std.mem.tokenizeAny(u8, line, "  ");
        const firstStr = it.next() orelse break;
        const secondStr = it.next() orelse break;

        const first: u64 = try std.fmt.parseInt(u64, firstStr, 10);
        const second: u64 = try std.fmt.parseInt(u64, secondStr, 10);
        try leftNumbers.append(first);
        try rightNumbers.append(second);
    }

    // const count = file.read(&buf) catch |err| return err;

    // std.debug.print("input:\n{s}\n", .{buf});
    // std.debug.print("read {d} bytes\n", .{count});
    return .{
        .left = try leftNumbers.toOwnedSlice(),
        .right = try rightNumbers.toOwnedSlice(),
    };
}

fn sortInput(numbers: Numbers) void {
    std.mem.sort(u64, numbers.left, {}, std.sort.asc(u64));
    std.mem.sort(u64, numbers.right, {}, std.sort.asc(u64));
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    std.debug.print("getting input\n", .{});

    const numbers = getInput(allocator) catch unreachable;
    sortInput(numbers);

    var result = try std.math.big.int.Managed.init(allocator);
    defer result.deinit();

    for (numbers.left, numbers.right) |left, right| {
        var rightB = try std.math.big.int.Managed.init(allocator);
        defer rightB.deinit();
        try rightB.set(right);

        var leftB = try std.math.big.int.Managed.init(allocator);
        defer leftB.deinit();
        try leftB.set(left);

        var tmp = try std.math.big.int.Managed.init(allocator);
        defer tmp.deinit();
        try tmp.sub(&leftB, &rightB);

        // std.debug.print("tmp: {s}", .{try tmp.toString(allocator, 10, std.fmt.Case.lower)});
        try result.add(&result, &tmp);
    }
    std.debug.print("result: {s}", .{try result.toString(allocator, 10, std.fmt.Case.lower)});
}
