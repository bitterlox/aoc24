const std = @import("std");

const Report = struct {
    levels: []u8,
    allocator: std.mem.Allocator,

    const Self = @This();

    /// caller owns the associated memory
    fn init(arrayList: *std.ArrayList(u8)) !Self {
        const slice = try arrayList.toOwnedSlice();
        return Self{
            .allocator = arrayList.allocator,
            .levels = slice,
        };
    }

    fn deinit(self: *Self) !void {
        self.allocator.free(self.levels);
    }

    fn is_safe() bool {
        return false;
    }
};

const Data = struct {
    reports: []Report,
    allocator: std.mem.Allocator,

    const Self = @This();

    /// caller owns the associated memory
    fn init(arrayList: *std.ArrayList(Report)) !Self {
        const slice = try arrayList.toOwnedSlice();
        return Self{
            .allocator = arrayList.allocator,
            .reports = slice,
        };
    }

    fn deinit(self: *Self) !void {
        for (self.reports) |rep| rep.deinit();
        self.allocator.free(self.reports);
    }

    fn is_safe() bool {
        return false;
    }
};

/// Caller takes ownership of the result
fn get_input(allocator: std.mem.Allocator) anyerror!Data {
    const fileContent = allocator.alloc(u8, 1024 * 16) catch |err| return err;
    defer allocator.free(fileContent);

    const file = std.fs.cwd().openFile("input.txt", .{}) catch |err| return err;
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var reports = std.ArrayList(Report).init(allocator);
    defer reports.deinit();

    while (try in_stream.readUntilDelimiterOrEof(fileContent, '\n')) |line| {
        var it = std.mem.tokenizeAny(u8, line, " ");
        var list = std.ArrayList(u8).init(allocator);
        defer list.deinit();

        while (it.next()) |levelStr| {
            const level: u8 = try std.fmt.parseInt(u8, levelStr, 10);
            try list.append(level);
        }

        const report = try Report.init(&list);
        try reports.append(report);
    }

    return Data.init(&reports);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const data = try get_input(allocator);
    defer data.deinit();

    for (data.reports) |rep| {
        std.debug.print("{d}\n", .{rep.levels});
    }
}
