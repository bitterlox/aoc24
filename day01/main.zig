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

fn calculateDistance(left: u64, right: u64) u64 {
    // var rightB = try std.math.big.int.Managed.init(allocator);
    // defer rightB.deinit();
    // try rightB.set(right);

    // var leftB = try std.math.big.int.Managed.init(allocator);
    // defer leftB.deinit();
    // try leftB.set(left);

    // var tmp = try std.math.big.int.Managed.init(allocator);
    // defer tmp.deinit();
    // try tmp.sub(&rightB, &leftB);

    const result = @as(i64, @intCast(left)) - @as(i64, @intCast(right));

    return @abs(result);
}

fn getFirstResult(numbers: Numbers) u64 {
    var result: u64 = 0;

    for (numbers.left, numbers.right) |left, right| {
        result += calculateDistance(left, right);
    }

    return result;
}

const FrequencyMap = std.AutoHashMap(u64, u8);

/// caller takes ownership of result
fn makeFrequencyMap(allocator: std.mem.Allocator, numbers: Numbers) !FrequencyMap {
    var rightMap = std.AutoHashMap(u64, u8).init(allocator);
    defer rightMap.deinit();
    var frequencyMap = std.AutoHashMap(u64, u8).init(allocator);

    for (numbers.right) |right| {
        const maybeCountInList = rightMap.get(right);
        if (maybeCountInList) |count| {
            try rightMap.put(right, count + 1);
        } else {
            try rightMap.put(right, 1);
        }
    }

    // var it = rightMap.iterator();

    // while (it.next()) |entry| {
    //     std.debug.print("{}: {}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    // }

    for (numbers.left) |left| {
        const found = rightMap.get(left);
        if (found) |count| {
            try frequencyMap.put(left, count);
        } else {
            try frequencyMap.put(left, 0);
        }
    }
    return frequencyMap;
}

fn getSecondResult(map: FrequencyMap) u64 {
    var result: u64 = 0;

    var it = map.iterator();

    while (it.next()) |entry| {
        result += entry.key_ptr.* * entry.value_ptr.*;
        // std.debug.print("{}: {}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    }

    return result;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    std.debug.print("getting input\n", .{});

    const numbers = getInput(allocator) catch unreachable;
    sortInput(numbers);

    std.debug.print("result: {d}\n", .{getFirstResult(numbers)});

    const map = try makeFrequencyMap(allocator, numbers);

    var it = map.iterator();

    while (it.next()) |entry| {
        std.debug.print("{}: {}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    }

    std.debug.print("result2: {}\n", .{getSecondResult(map)});
}
