const std = @import("std");
const lib = @import("lib.zig");

const Input = struct {
    allocator: std.mem.Allocator,

    page_ordering_rules: [][2]u64,
    update_page_numbers: [][]u64,

    const Self = @This();

    fn init(allocator: std.mem.Allocator, rules: [][2]u64, numbers: [][]u64) Self {
        return Self{
            .allocator = allocator,
            .page_ordering_rules = rules,
            .update_page_numbers = numbers,
        };
    }

    fn deinit(self: *Self) void {
        self.allocator.free(self.page_ordering_rules);

        for (self.update_page_numbers) |slice| {
            self.allocator.free(slice);
        }
        self.allocator.free(self.update_page_numbers);
    }
};

// i should probably target \n\n and then start another read
/// Caller takes ownership of the result
fn get_input(allocator: std.mem.Allocator) anyerror!Input {
    const fileContent = allocator.alloc(u8, 1024 * 16) catch |err| return err;
    defer allocator.free(fileContent);

    const file = std.fs.cwd().openFile("input.txt", .{}) catch |err| return err;
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var ordering_rules = std.ArrayList([2]u64).init(allocator);
    defer ordering_rules.deinit();

    var update_numbers = std.ArrayList([]u64).init(allocator);
    defer update_numbers.deinit();

    while (try in_stream.readUntilDelimiterOrEof(fileContent, '\n')) |line| {
        if (line.len == 0) break;

        var pair: [2]u64 = undefined;
        pair[0] = try std.fmt.parseInt(u64, line[0..2], 10);
        pair[1] = try std.fmt.parseInt(u64, line[3..5], 10);

        try ordering_rules.append(pair);
    }

    while (try in_stream.readUntilDelimiterOrEof(fileContent, '\n')) |line| {
        var sublist = std.ArrayList(u64).init(allocator);
        defer sublist.deinit();

        var it = std.mem.tokenizeScalar(u8, line, ',');

        while (it.next()) |numstr| {
            try sublist.append(try std.fmt.parseInt(u64, numstr, 10));
        }

        try update_numbers.append(try sublist.toOwnedSlice());
    }

    return Input.init(allocator, try ordering_rules.toOwnedSlice(), try update_numbers.toOwnedSlice());
}

fn result1(rules: *lib.Rules, page_numbers: [][]u64) !u64 {
    var count: u64 = 0;
    for (page_numbers) |line| {
        if (try rules.is_in_order(line)) {
            const idx = @divTrunc(line.len - 1, 2);
            // std.debug.print("{d}: {d}\n", .{ line, line[idx] });
            count += line[idx];
        }
    }
    return count;
}

fn result2(rules: *lib.Rules, page_numbers: [][]u64) !u64 {
    var count: u64 = 0;

    var sorted_page_numbers_list = std.ArrayList([]u64).init(rules.allocator);
    defer sorted_page_numbers_list.deinit();

    for (page_numbers) |line| {
        if (!try rules.is_in_order(line)) {
            const sorted = try rules.sort(line);
            try sorted_page_numbers_list.append(sorted);
        }
    }

    const sorted_page_numbers = try sorted_page_numbers_list.toOwnedSlice();
    defer {
        for (sorted_page_numbers) |slice| rules.allocator.free(slice);
        rules.allocator.free(sorted_page_numbers);
    }

    for (sorted_page_numbers) |line| {
        const idx = @divTrunc(line.len - 1, 2);
        // std.debug.print("{d}: {d}\n", .{ line, line[idx] });
        count += line[idx];
    }
    return count;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var input = try get_input(allocator);
    defer input.deinit();

    // std.debug.print("rules: {d}\n", .{input.page_ordering_rules});
    // std.debug.print("numbers: {d}\n", .{input.update_page_numbers});

    var rules = try lib.Rules.init(allocator, input.page_ordering_rules);
    defer rules.deinit();

    std.debug.print("already in order: {d}\n", .{try result1(&rules, input.update_page_numbers)});
    std.debug.print("ordered: {d}\n", .{try result2(&rules, input.update_page_numbers)});
}
