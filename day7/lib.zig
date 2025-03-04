const std = @import("std");
const testing = std.testing;

// 81 * 40 + 27
// 81 * 40 * 27
// 81 + 40 * 27
// 81 + 40 + 27
//
//
// loop over [ 81 40 27 ] |val|
// it 1: val 81
// - two nested loops:
// loop over [ 40 27 ] |val|
// it 1: val 40
// - two nested loops:
// loop over [ 27 ] |val|
// loop over [ 27 ] |val|
//    81 * 40 + 27
//    81 * 40 * 27
//
// loop over [ 40 27 ] |val|
// it 1: val 40
// - two nested loops:
// loop over [ 27 ] |val|
// loop over [ 27 ] |val|
//    81 + 40 * 27
//    81 + 40 + 27
//
//
//  [ 81 40 27 ]
//  const list = [[ 81 * ] [ 81 + ]]
//  for ([40 27], 0..) |val,idx| {
//     const copy = list.clone()
//     while (copy.popOrNull()) |*aval| {
//     if (idx == len(operands)-1 {
//
//     }
//     for (a) |*aval| {
//        for ([op_plus,ops_minus]) |op| {
//          list.instert(0) [ apply(op(aval[1]), val), op ]
//        }
//     }
//  }
//
//  after 1 iter a =
//  a = [[(81*40) *] [(81*40) +] [(81+40) *] [(81+40) +]]
//
//

test "computePermutations - 1" {
    const operands: []const u64 = &[_]u64{ 10, 19 };
    const operations = &[_]Operation{ .addition, .multiplication };

    const expected: []const u64 = &[_]u64{ 29, 190 };

    const actual = try computePermutations(testing.allocator, operands, operations);
    defer testing.allocator.free(actual);

    try testing.expectEqualSlices(u64, expected, actual);
}

test "computePermutations - 2" {
    const operands: []const u64 = &[_]u64{ 81, 40, 27 };
    const operations = &[_]Operation{ .addition, .multiplication };

    const expected: []const u64 = &[_]u64{ 148, 3267, 3267, 87480 };

    const actual = try computePermutations(testing.allocator, operands, operations);
    defer testing.allocator.free(actual);

    try testing.expectEqualSlices(u64, expected, actual);
}

test "computePermutations - 3" {
    const operands: []const u64 = &[_]u64{ 11, 6, 16, 20 };
    const operations = &[_]Operation{ .addition, .multiplication };

    const expected: []const u64 = &[_]u64{
        53,
        660,
        292,
        5440,
        102,
        1640,
        1076,
        21120,
    };

    const actual = try computePermutations(testing.allocator, operands, operations);
    defer testing.allocator.free(actual);

    try testing.expectEqualSlices(u64, expected, actual);
}

// SICP: solve a recursive process in a iterative way
// store itermediate results in variables
fn computePermutations(allocator: std.mem.Allocator, operands: []const u64, operations: []const Operation) ![]const u64 {
    var permutations = std.ArrayList(struct { u64, Operation }).init(allocator);
    defer permutations.deinit();

    var result = std.ArrayList(u64).init(allocator);
    defer result.deinit();

    const first_item = operands[0];

    try permutations.append(.{ first_item, .addition });
    try permutations.append(.{ first_item, .multiplication });

    for (operands[1..], 1..) |val, idx| {
        const clone = try permutations.clone();
        defer clone.deinit();
        permutations.clearRetainingCapacity();

        if (idx == operands.len - 1) {
            for (clone.items) |p| {
                const param1, const op1 = p;
                try result.append(op1.apply(param1, val));
            }
        }

        for (clone.items) |permutation| {
            const param1, const op1 = permutation;
            for (operations) |op| {
                try permutations.append(.{ op1.apply(param1, val), op });
            }
        }
    }

    return result.toOwnedSlice();
}

pub const Calibration = struct {
    u64,
    []const u64,
};

test "Operations.apply - concatenation" {
    const op = Operation.concatenation;

    const actual = op.apply(12, 345);

    try testing.expectEqual(12345, actual);
}

const Operation = enum {
    addition,
    multiplication,
    concatenation,
    fn apply(self: Operation, a: u64, b: u64) u64 {
        return switch (self) {
            .addition => a + b,
            .multiplication => a * b,
            .concatenation => blk: {

                // TODO: implement concatenation

                break :blk a + b;
            },
        };
    }
};

// test "calibrationIsValid - 190" {
//     const calibration = Calibration{ 190, &[_]u64{ 19, 10 } };
//     const actual = try calibrationIsValid(testing.allocator, calibration);
//     try testing.expectEqual(true, actual);
// }

// test "calibrationIsValid - 3267" {
//     const calibration = Calibration{ 3267, &[_]u64{ 81, 40, 27 } };
//     const actual = try calibrationIsValid(testing.allocator, calibration);
//     try testing.expectEqual(true, actual);
// }

// test "calibrationIsValid - 83" {
//     const calibration = Calibration{ 83, &[_]u64{ 17, 5 } };
//     const actual = try calibrationIsValid(testing.allocator, calibration);
//     try testing.expectEqual(false, actual);
// }

// test "calibrationIsValid - 156" {
//     const calibration = Calibration{ 156, &[_]u64{ 15, 6 } };
//     const actual = try calibrationIsValid(testing.allocator, calibration);
//     try testing.expectEqual(false, actual);
// }

// test "calibrationIsValid - 7290" {
//     const calibration = Calibration{ 7290, &[_]u64{ 6, 8, 6, 15 } };
//     const actual = try calibrationIsValid(testing.allocator, calibration);
//     try testing.expectEqual(false, actual);
// }

// test "calibrationIsValid - 161011" {
//     const calibration = Calibration{ 161011, &[_]u64{ 16, 10, 13 } };
//     const actual = try calibrationIsValid(testing.allocator, calibration);
//     try testing.expectEqual(false, actual);
// }

// test "calibrationIsValid - 192" {
//     const calibration = Calibration{ 192, &[_]u64{ 17, 8, 14 } };
//     const actual = try calibrationIsValid(testing.allocator, calibration);
//     try testing.expectEqual(false, actual);
// }

// test "calibrationIsValid - 21037" {
//     const calibration = Calibration{ 21037, &[_]u64{ 9, 7, 18, 13 } };
//     const actual = try calibrationIsValid(testing.allocator, calibration);
//     try testing.expectEqual(false, actual);
// }

// test "calibrationIsValid - 292" {
//     const calibration = Calibration{ 292, &[_]u64{ 11, 6, 16, 20 } };
//     const actual = try calibrationIsValid(testing.allocator, calibration);
//     try testing.expectEqual(true, actual);
// }

// pub fn calibrationIsValid(allocator: std.mem.Allocator, calibration: Calibration) !bool {
//     const result, const operands = calibration;
//     const operations = &[_]Operation{ .addition, .multiplication };

//     const permutations = try computePermutations(allocator, operands, operations);
//     defer allocator.free(permutations);

//     for (permutations) |p| {
//         if (p == result) return true;
//     }
//     return false;
// }

// test "calibrationIsValidWithConcat - 190" {
//     const calibration = Calibration{ 190, &[_]u64{ 19, 10 } };
//     const actual = try calibrationIsValidWithConcat(testing.allocator, calibration);
//     try testing.expectEqual(true, actual);
// }

// test "calibrationIsValidWithConcat - 3267" {
//     const calibration = Calibration{ 3267, &[_]u64{ 81, 40, 27 } };
//     const actual = try calibrationIsValidWithConcat(testing.allocator, calibration);
//     try testing.expectEqual(true, actual);
// }

// test "calibrationIsValidWithConcat - 83" {
//     const calibration = Calibration{ 83, &[_]u64{ 17, 5 } };
//     const actual = try calibrationIsValidWithConcat(testing.allocator, calibration);
//     try testing.expectEqual(false, actual);
// }

// test "calibrationIsValidWithConcat - 156" {
//     const calibration = Calibration{ 156, &[_]u64{ 15, 6 } };
//     const actual = try calibrationIsValidWithConcat(testing.allocator, calibration);
//     try testing.expectEqual(true, actual);
// }

// test "calibrationIsValidWithConcat - 7290" {
//     const calibration = Calibration{ 7290, &[_]u64{ 6, 8, 6, 15 } };
//     const actual = try calibrationIsValidWithConcat(testing.allocator, calibration);
//     try testing.expectEqual(true, actual);
// }

// test "calibrationIsValidWithConcat - 161011" {
//     const calibration = Calibration{ 161011, &[_]u64{ 16, 10, 13 } };
//     const actual = try calibrationIsValidWithConcat(testing.allocator, calibration);
//     try testing.expectEqual(false, actual);
// }

// test "calibrationIsValidWithConcat - 192" {
//     const calibration = Calibration{ 192, &[_]u64{ 17, 8, 14 } };
//     const actual = try calibrationIsValidWithConcat(testing.allocator, calibration);
//     try testing.expectEqual(true, actual);
// }

// test "calibrationIsValidWithConcat - 21037" {
//     const calibration = Calibration{ 21037, &[_]u64{ 9, 7, 18, 13 } };
//     const actual = try calibrationIsValidWithConcat(testing.allocator, calibration);
//     try testing.expectEqual(false, actual);
// }

// test "calibrationIsValidWithConcat - 292" {
//     const calibration = Calibration{ 292, &[_]u64{ 11, 6, 16, 20 } };
//     const actual = try calibrationIsValidWithConcat(testing.allocator, calibration);
//     try testing.expectEqual(true, actual);
// }

// pub fn calibrationIsValidWithConcat(allocator: std.mem.Allocator, calibration: Calibration) !bool {
//     const result, const operands = calibration;
//     const operations = &[_]Operation{ .addition, .multiplication, .concatenation };

//     const permutations = try computePermutations(allocator, operands, operations);
//     defer allocator.free(permutations);

//     for (permutations) |p| {
//         if (p == result) return true;
//     }
//     return false;
// }
