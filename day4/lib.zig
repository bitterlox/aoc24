const std = @import("std");
const testing = std.testing;

test "parse - example 1" {}

// take input string and produce array of slices for each direction of search
// line_forwards, line_backwards, column_forwards, column_backwards,
// diagonal_forwards, diagonal_backwards; it looks like diagonals can overflow
// eg part of the xmas can be at the end and star back at the beginning
fn make_permutations() !void {}
