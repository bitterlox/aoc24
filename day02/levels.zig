const std = @import("std");
const testing = std.testing;
const expect = testing.expect;
const expectEqual = testing.expectEqual;
const expectEqualSlices = testing.expectEqualSlices;

test "pass - max difference" {
    try expect(levels_in_accepted_range(4, 1));
}

test "pass - min difference" {
    try expect(levels_in_accepted_range(2, 1));
}

test "fail - difference too great" {
    try expect(!levels_in_accepted_range(1, 5));
}

test "fail - values equal" {
    try expect(!levels_in_accepted_range(1, 1));
}

fn levels_in_accepted_range(level_1: u8, level_2: u8) bool {
    const l1: i8 = @intCast(level_1);
    const l2: i8 = @intCast(level_2);
    const level_difference = @abs(l1 - l2);
    return level_difference >= 1 and level_difference <= 3;
}

const LevelState = union(enum) {
    no_problems,
    broke_order,
    // broke_asc_order,
    // broke_desc_order,
    too_much_diff_from_next,
};

test "evaluate_levels - example 1 - safe" {
    const input: []const u8 = &[_]u8{ 7, 6, 4, 2, 1 };
    const expected: []const LevelState = &[_]LevelState{
        .no_problems,
        .no_problems,
        .no_problems,
        .no_problems,
        .no_problems,
    };
    const actual = try evaluate_levels(testing.allocator, input);
    defer testing.allocator.free(actual);

    try expectEqualSlices(LevelState, expected, actual);
}

test "evaluate_levels - example 2 - unsafe" {
    const input: []const u8 = &[_]u8{ 1, 2, 7, 8, 9 };
    const expected: []const LevelState = &[_]LevelState{
        .no_problems,
        .too_much_diff_from_next,
        .no_problems,
        .no_problems,
        .no_problems,
    };
    const actual = try evaluate_levels(testing.allocator, input);
    defer testing.allocator.free(actual);

    try expectEqualSlices(LevelState, expected, actual);
}

test "evaluate_levels - example 3 - unsafe" {
    const input: []const u8 = &[_]u8{ 9, 7, 6, 2, 1 };
    const expected: []const LevelState = &[_]LevelState{
        .no_problems,
        .no_problems,
        .too_much_diff_from_next,
        .no_problems,
        .no_problems,
    };
    const actual = try evaluate_levels(testing.allocator, input);
    defer testing.allocator.free(actual);

    try expectEqualSlices(LevelState, expected, actual);
}

test "evaluate_levels - example 4 - unsafe" {
    const input: []const u8 = &[_]u8{ 1, 3, 2, 4, 5 };
    const expected: []const LevelState = &[_]LevelState{
        .no_problems,
        .broke_order,
        .no_problems,
        .no_problems,
        .no_problems,
    };
    const actual = try evaluate_levels(testing.allocator, input);
    defer testing.allocator.free(actual);

    try expectEqualSlices(LevelState, expected, actual);
}

test "evaluate_levels - example 5 - unsafe" {
    const input: []const u8 = &[_]u8{ 8, 6, 4, 4, 1 };
    const expected: []const LevelState = &[_]LevelState{
        .no_problems,
        .no_problems,
        .broke_order,
        .no_problems,
        .no_problems,
    };
    const actual = try evaluate_levels(testing.allocator, input);
    defer testing.allocator.free(actual);

    try expectEqualSlices(LevelState, expected, actual);
}

test "evaluate_levels - example 6 - safe" {
    const input: []const u8 = &[_]u8{ 1, 3, 6, 7, 9 };
    const expected: []const LevelState = &[_]LevelState{
        .no_problems,
        .no_problems,
        .no_problems,
        .no_problems,
        .no_problems,
    };
    const actual = try evaluate_levels(testing.allocator, input);
    defer testing.allocator.free(actual);

    try expectEqualSlices(LevelState, expected, actual);
}

/// caller takes ownership of returned slice
pub fn evaluate_levels(allocator: std.mem.Allocator, lvls: []const u8) ![]LevelState {
    var order: enum {
        asc,
        desc,
    } = undefined;

    if (lvls[0] < lvls[1]) {
        order = .asc;
    } else {
        order = .desc;
    }

    var list = std.ArrayList(LevelState).init(allocator);
    defer list.deinit();

    loop: for (lvls, 0..) |level, idx| {
        if (idx != lvls.len - 1) {
            const next_level = lvls[idx + 1];

            const gt_next = level > next_level;
            const lt_next = level < next_level;

            if (level == next_level) {
                try list.append(.broke_order);
                continue :loop;
            }
            if (lt_next and order == .desc) {
                try list.append(.broke_order);
                continue :loop;
            }
            if (gt_next and order == .asc) {
                try list.append(.broke_order);
                continue :loop;
            }

            if (!levels_in_accepted_range(level, next_level)) {
                try list.append(.too_much_diff_from_next);
                continue :loop;
            }
        }

        try list.append(.no_problems);
    }
    return list.toOwnedSlice();
}

// test "succeeds - descending order" {
//     const valid_levels: []const u8 = &[_]u8{ 7, 6, 4, 2, 1 };
//     try expectEqual(.{ true, null }, levels_are_safe(valid_levels));
// }

// test "succeeds - ascending order" {
//     const valid_levels: []const u8 = &[_]u8{ 1, 3, 6, 7, 9 };
//     try expectEqual(.{ true, null }, levels_are_safe(valid_levels));
// }

// test "fails - descending order broken" {
//     const valid_levels: []const u8 = &[_]u8{ 7, 8, 4, 2, 1 };
//     try expectEqual(.{ false, 1 }, levels_are_safe(valid_levels));
// }

// test "fails - descending order broken 2" {
//     const valid_levels: []const u8 = &[_]u8{ 7, 4, 2, 1, 7 };
//     try expectEqual(.{ false, 4 }, levels_are_safe(valid_levels));
// }

// test "fails - ascending order broken" {
//     const valid_levels: []const u8 = &[_]u8{ 1, 3, 2, 7, 9 };
//     try expectEqual(.{ false, 1 }, levels_are_safe(valid_levels));
// }

// test "fails - ascending order broken 2" {
//     const valid_levels: []const u8 = &[_]u8{ 4, 3, 4, 5, 6 };
//     try expectEqual(.{ false, 0 }, levels_are_safe(valid_levels));
// }

test "safe - example 1 - safe" {
    const input: []const u8 = &[_]u8{ 7, 6, 4, 2, 1 };
    const expected: bool = true;
    const actual = try are_safe(testing.allocator, input);

    try expectEqual(expected, actual);
}

test "safe - example 2 - unsafe" {
    const input: []const u8 = &[_]u8{ 1, 2, 7, 8, 9 };
    const expected: bool = false;
    const actual = try are_safe(testing.allocator, input);

    try expectEqual(expected, actual);
}

test "safe - example 3 - unsafe" {
    const input: []const u8 = &[_]u8{ 9, 7, 6, 2, 1 };
    const expected: bool = false;
    const actual = try are_safe(testing.allocator, input);

    try expectEqual(expected, actual);
}

test "safe - example 4 - unsafe" {
    const input: []const u8 = &[_]u8{ 1, 3, 2, 4, 5 };
    const expected: bool = false;
    const actual = try are_safe(testing.allocator, input);

    try expectEqual(expected, actual);
}

test "safe - example 5 - unsafe" {
    const input: []const u8 = &[_]u8{ 8, 6, 4, 4, 1 };
    const expected: bool = false;
    const actual = try are_safe(testing.allocator, input);

    try expectEqual(expected, actual);
}

test "safe - example 6 - safe" {
    const input: []const u8 = &[_]u8{ 1, 3, 6, 7, 9 };
    const expected: bool = true;
    const actual = try are_safe(testing.allocator, input);

    try expectEqual(expected, actual);
}

pub fn are_safe(allocator: std.mem.Allocator, levels: []const u8) !bool {
    const level_states = try evaluate_levels(allocator, levels);
    defer allocator.free(level_states);

    for (level_states) |state| {
        if (state != .no_problems) return false;
    }

    return true;
}

test "are_safe_dampened - example 1 - safe" {
    const input: []const u8 = &[_]u8{ 7, 6, 4, 2, 1 };
    const expected: bool = true;
    const actual = try are_safe_dampened(testing.allocator, input);

    try expectEqual(expected, actual);
}

test "are_safe_dampened - example 2 - unsafe" {
    const input: []const u8 = &[_]u8{ 1, 2, 7, 8, 9 };
    const expected: bool = false;
    const actual = try are_safe_dampened(testing.allocator, input);

    try expectEqual(expected, actual);
}

test "are_safe_dampened - example 3 - unsafe" {
    const input: []const u8 = &[_]u8{ 9, 7, 6, 2, 1 };
    const expected: bool = false;
    const actual = try are_safe_dampened(testing.allocator, input);

    try expectEqual(expected, actual);
}

test "are_safe_dampened - example 4 - safe" {
    const input: []const u8 = &[_]u8{ 1, 3, 2, 4, 5 };
    const expected: bool = true;
    const actual = try are_safe_dampened(testing.allocator, input);

    try expectEqual(expected, actual);
}

test "are_safe_dampened - example 5 - safe" {
    const input: []const u8 = &[_]u8{ 8, 6, 4, 4, 1 };
    const expected: bool = true;
    const actual = try are_safe_dampened(testing.allocator, input);

    try expectEqual(expected, actual);
}

test "are_safe_dampened - example 6 - safe" {
    const input: []const u8 = &[_]u8{ 1, 3, 6, 7, 9 };
    const expected: bool = true;
    const actual = try are_safe_dampened(testing.allocator, input);

    try expectEqual(expected, actual);
}

fn pop_element_at(allocator: std.mem.Allocator, slice: []const u8, idx: usize) ![]u8 {
    var list1 = std.ArrayList(u8).init(allocator);
    defer list1.deinit();

    try list1.appendSlice(slice[0..idx]);
    try list1.appendSlice(slice[idx + 1 ..]);

    return list1.toOwnedSlice();
}

pub fn are_safe_dampened(allocator: std.mem.Allocator, levels: []const u8) !bool {
    const level_states = try evaluate_levels(allocator, levels);
    defer allocator.free(level_states);

    for (level_states) |state| {
        if (state != .no_problems) {
            for (level_states, 0..) |_, inner_idx| {
                const dampened_levels: []u8 = try pop_element_at(allocator, levels, inner_idx);
                defer allocator.free(dampened_levels);
                if (try are_safe(allocator, dampened_levels)) return true;
            }
            return false;
        }
    }
    return true;
}
