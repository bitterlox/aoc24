const std = @import("std");
const testing = std.testing;

test "halveInt" {
    const i: u64 = 1234;
    const top, const bottom = halveInt(i, 4);

    try testing.expectEqual(12, top);
    try testing.expectEqual(34, bottom);
}

fn halveInt(i: u64, digitCount: usize) struct { u64, u64 } {
    const shiftDigitsBy = std.math.pow(u64, 10, digitCount / 2);

    // split out top half
    const top = i / shiftDigitsBy;

    // split out bottom half
    const bottom = i % shiftDigitsBy;

    return .{ top, bottom };
}
