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

fn count_already_in_order(rules: *lib.Rules, page_numbers: [][]u64) u64 {
    var count: u64 = 0;
    for (page_numbers) |line| {
        if (rules.is_in_order(line)) count += 1;
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

    std.debug.print("already in order: {d}", .{count_already_in_order(&rules, input.update_page_numbers)});
}
