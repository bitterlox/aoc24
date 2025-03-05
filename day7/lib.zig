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

test "computeOperators - 1" {
    const operand_count: usize = 2;
    const operations = &[_]Operation{ .addition, .multiplication };

    const expected: []const []const Operation = &[_][]const Operation{
        &[_]Operation{.addition},
        &[_]Operation{.multiplication},
    };

    const actual = try computeOperators(testing.allocator, operand_count, operations);
    defer {
        for (actual) |sl| testing.allocator.free(sl);
        testing.allocator.free(actual);
    }

    errdefer std.debug.print("{any}", .{actual});

    try testing.expectEqualDeep(expected, actual);
}

test "computeOperators - 2" {
    const operand_count: usize = 3;
    const operations = &[_]Operation{ .addition, .multiplication };

    const expected: []const []const Operation = &[_][]const Operation{
        &[_]Operation{ .addition, .addition },
        &[_]Operation{ .addition, .multiplication },
        &[_]Operation{ .multiplication, .addition },
        &[_]Operation{ .multiplication, .multiplication },
    };

    const actual = try computeOperators(testing.allocator, operand_count, operations);
    defer {
        for (actual) |sl| testing.allocator.free(sl);
        testing.allocator.free(actual);
    }

    errdefer std.debug.print("{any}", .{actual});

    try testing.expectEqualDeep(expected, actual);
}

test "computeOperators - 3" {
    const operand_count: usize = 4;
    const operations = &[_]Operation{ .addition, .multiplication };

    const expected: []const []const Operation = &[_][]const Operation{
        &[_]Operation{ .addition, .addition, .addition },
        &[_]Operation{ .addition, .addition, .multiplication },
        &[_]Operation{ .addition, .multiplication, .addition },
        &[_]Operation{ .addition, .multiplication, .multiplication },
        &[_]Operation{ .multiplication, .addition, .addition },
        &[_]Operation{ .multiplication, .addition, .multiplication },
        &[_]Operation{ .multiplication, .multiplication, .addition },
        &[_]Operation{ .multiplication, .multiplication, .multiplication },
    };

    const actual = try computeOperators(testing.allocator, operand_count, operations);
    defer {
        for (actual) |sl| testing.allocator.free(sl);
        testing.allocator.free(actual);
    }

    errdefer std.debug.print("{any}", .{actual});

    try testing.expectEqualDeep(expected, actual);
}

/// caller takes ownership of result
fn computeOperators(allocator: std.mem.Allocator, operand_count: u64, operations: []const Operation) ![]const []const Operation {
    var permutations = std.ArrayList([]Operation).init(allocator);

    for (operations) |op| {
        var list = std.ArrayList(Operation).init(allocator);
        defer list.deinit();

        try list.append(op);

        try permutations.append(try list.toOwnedSlice());
    }

    for (1..operand_count - 1) |_| {
        const clone = try permutations.clone();
        defer clone.deinit();
        permutations.clearRetainingCapacity();

        for (clone.items) |prev_list| {
            var old_list = std.ArrayList(Operation).fromOwnedSlice(allocator, prev_list);
            defer old_list.deinit();

            for (operations) |op| {
                var new_list = try old_list.clone();
                try new_list.append(op);

                try permutations.append(try new_list.toOwnedSlice());
            }
        }
    }

    return permutations.toOwnedSlice();
}

test "applyOperators - 190" {
    const actual = applyOperators(&[_]u64{ 19, 10 }, &[_]Operation{.multiplication});
    try testing.expectEqual(190, actual);
}

test "applyOperators - 1308486" {
    const operations: []const Operation = &[_]Operation{ .addition, .addition, .addition, .multiplication, .multiplication, .concatenation, .multiplication, .multiplication };

    const actual = applyOperators(&[_]u64{ 997, 7, 783, 939, 4, 2, 1, 1, 6 }, operations);
    try testing.expectEqual(1308486, actual);
}

fn applyOperators(operands: []const u64, operators: []const Operation) u64 {
    if (operands.len != operators.len + 1) @panic("wrong length operators/operands");

    var running_total: u64 = operands[0];

    for (operators, 1..) |op, operands_idx| {
        running_total = op.apply(running_total, operands[operands_idx]);
    }

    return running_total;
}

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

// []
// [ 10 ]
// [ 10 ]
// // for 10 ->
// // 10 + val, 10 * val

// first ugly but working impl
// SICP: solve a recursive process in a iterative way
// store itermediate results in variables
// fn computePermutations(allocator: std.mem.Allocator, operands: []const u64, operations: []const Operation) ![]const u64 {
//     var permutations = std.ArrayList(struct { u64, Operation }).init(allocator);
//     defer permutations.deinit();

//     var result = std.ArrayList(u64).init(allocator);
//     defer result.deinit();

//     const first_item = operands[0];

//     for (operations) |operation| {
//         try permutations.append(.{ first_item, operation });
//     }

//     for (operands[1..], 1..) |val, idx| {
//         const clone = try permutations.clone();
//         defer clone.deinit();
//         permutations.clearRetainingCapacity();

//         if (idx == operands.len - 1) {
//             for (clone.items) |p| {
//                 const param1, const op1 = p;
//                 try result.append(op1.apply(param1, val));
//             }
//         }

//         for (clone.items) |permutation| {
//             const param1, const op1 = permutation;
//             for (operations) |op| {
//                 try permutations.append(.{ op1.apply(param1, val), op });
//             }
//         }
//     }

//     return result.toOwnedSlice();
// }

// second cleaned up impl
fn computePermutations(allocator: std.mem.Allocator, operands: []const u64, operations: []const Operation) ![]const u64 {
    var permutations = std.ArrayList(u64).init(allocator);
    defer permutations.deinit();

    for (operands) |val| {
        const clone = try permutations.clone();
        defer clone.deinit();
        permutations.clearRetainingCapacity();

        if (clone.items.len == 0) {
            try permutations.append(val);
        } else {
            for (clone.items) |v2| {
                for (operations) |op| {
                    try permutations.append(op.apply(v2, val));
                }
            }
        }
    }

    return permutations.toOwnedSlice();
}

// third impl using different approach
// using second because it's way faster
// (wrote this to ease debugging)
//
// fn computePermutations(allocator: std.mem.Allocator, operands: []const u64, operations: []const Operation) ![]const u64 {
//     var permutations = std.ArrayList(u64).init(allocator);
//     defer permutations.deinit();

//     const operator_combinations = try computeOperators(allocator, operands.len, operations);
//     defer {
//         for (operator_combinations) |sl| allocator.free(sl);
//         allocator.free(operator_combinations);
//     }

//     for (operator_combinations) |operators| {
//         const result = applyOperators(operands, operators);
//         try permutations.append(result);
//     }

//     return permutations.toOwnedSlice();
// }

pub const Calibration = struct {
    u64,
    []const u64,
};

test "Operations.apply - concatenation" {
    const op = Operation.concatenation;

    const actual = op.apply(12, 345);

    try testing.expectEqual(12345, actual);
}

test "Operations.apply - concatenation 2" {
    const op = Operation.concatenation;

    const actual = op.apply(120000, 447356);

    try testing.expectEqual(120000447356, actual);
}

test "Operations.apply - concatenation 3" {
    const op = Operation.concatenation;

    const actual = op.apply(21808, 1);

    try testing.expectEqual(218081, actual);
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
                var zeroes_count: u64 = 0;
                var running_division: f64 = @floatFromInt(b);

                // sneaky bug was lurking here for concats of exactly 1
                // changed to >=
                while (running_division >= 1) {
                    running_division /= 10;
                    zeroes_count += 1;
                }

                var tmp = a * std.math.pow(u64, 10, zeroes_count);
                tmp += b;

                break :blk tmp;
            },
        };
    }
};

test "calibrationIsValid - 190" {
    const calibration = Calibration{ 190, &[_]u64{ 19, 10 } };
    const actual = try calibrationIsValid(testing.allocator, calibration);
    try testing.expectEqual(true, actual);
}

test "calibrationIsValid - 3267" {
    const calibration = Calibration{ 3267, &[_]u64{ 81, 40, 27 } };
    const actual = try calibrationIsValid(testing.allocator, calibration);
    try testing.expectEqual(true, actual);
}

test "calibrationIsValid - 83" {
    const calibration = Calibration{ 83, &[_]u64{ 17, 5 } };
    const actual = try calibrationIsValid(testing.allocator, calibration);
    try testing.expectEqual(false, actual);
}

test "calibrationIsValid - 156" {
    const calibration = Calibration{ 156, &[_]u64{ 15, 6 } };
    const actual = try calibrationIsValid(testing.allocator, calibration);
    try testing.expectEqual(false, actual);
}

test "calibrationIsValid - 7290" {
    const calibration = Calibration{ 7290, &[_]u64{ 6, 8, 6, 15 } };
    const actual = try calibrationIsValid(testing.allocator, calibration);
    try testing.expectEqual(false, actual);
}

test "calibrationIsValid - 161011" {
    const calibration = Calibration{ 161011, &[_]u64{ 16, 10, 13 } };
    const actual = try calibrationIsValid(testing.allocator, calibration);
    try testing.expectEqual(false, actual);
}

test "calibrationIsValid - 192" {
    const calibration = Calibration{ 192, &[_]u64{ 17, 8, 14 } };
    const actual = try calibrationIsValid(testing.allocator, calibration);
    try testing.expectEqual(false, actual);
}

test "calibrationIsValid - 21037" {
    const calibration = Calibration{ 21037, &[_]u64{ 9, 7, 18, 13 } };
    const actual = try calibrationIsValid(testing.allocator, calibration);
    try testing.expectEqual(false, actual);
}

test "calibrationIsValid - 292" {
    const calibration = Calibration{ 292, &[_]u64{ 11, 6, 16, 20 } };
    const actual = try calibrationIsValid(testing.allocator, calibration);
    try testing.expectEqual(true, actual);
}

pub fn calibrationIsValid(allocator: std.mem.Allocator, calibration: Calibration) !bool {
    const result, const operands = calibration;
    const operations = &[_]Operation{ .addition, .multiplication };

    const permutations = try computePermutations(allocator, operands, operations);
    defer allocator.free(permutations);

    for (permutations) |p| {
        if (p == result) return true;
    }
    return false;
}

test "calibrationIsValidWithConcat - 190" {
    const calibration = Calibration{ 190, &[_]u64{ 19, 10 } };
    const actual = try calibrationIsValidWithConcat(testing.allocator, calibration);
    try testing.expectEqual(true, actual);
}

test "calibrationIsValidWithConcat - 3267" {
    const calibration = Calibration{ 3267, &[_]u64{ 81, 40, 27 } };
    const actual = try calibrationIsValidWithConcat(testing.allocator, calibration);
    try testing.expectEqual(true, actual);
}

test "calibrationIsValidWithConcat - 83" {
    const calibration = Calibration{ 83, &[_]u64{ 17, 5 } };
    const actual = try calibrationIsValidWithConcat(testing.allocator, calibration);
    try testing.expectEqual(false, actual);
}

test "calibrationIsValidWithConcat - 156" {
    const calibration = Calibration{ 156, &[_]u64{ 15, 6 } };
    const actual = try calibrationIsValidWithConcat(testing.allocator, calibration);
    try testing.expectEqual(true, actual);
}

test "calibrationIsValidWithConcat - 7290" {
    const calibration = Calibration{ 7290, &[_]u64{ 6, 8, 6, 15 } };
    const actual = try calibrationIsValidWithConcat(testing.allocator, calibration);
    try testing.expectEqual(true, actual);
}

test "calibrationIsValidWithConcat - 161011" {
    const calibration = Calibration{ 161011, &[_]u64{ 16, 10, 13 } };
    const actual = try calibrationIsValidWithConcat(testing.allocator, calibration);
    try testing.expectEqual(false, actual);
}

test "calibrationIsValidWithConcat - 192" {
    const calibration = Calibration{ 192, &[_]u64{ 17, 8, 14 } };
    const actual = try calibrationIsValidWithConcat(testing.allocator, calibration);
    try testing.expectEqual(true, actual);
}

test "calibrationIsValidWithConcat - 21037" {
    const calibration = Calibration{ 21037, &[_]u64{ 9, 7, 18, 13 } };
    const actual = try calibrationIsValidWithConcat(testing.allocator, calibration);
    try testing.expectEqual(false, actual);
}

test "calibrationIsValidWithConcat - 292" {
    const calibration = Calibration{ 292, &[_]u64{ 11, 6, 16, 20 } };
    const actual = try calibrationIsValidWithConcat(testing.allocator, calibration);
    try testing.expectEqual(true, actual);
}

test "calibrationIsValidWithConcat - 123" {
    const calibration = Calibration{ 123, &[_]u64{ 1, 2, 3 } };
    const actual = try calibrationIsValidWithConcat(testing.allocator, calibration);
    try testing.expectEqual(true, actual);
}

test "calibrationIsValidWithConcat - 1308486" {
    const calibration = Calibration{ 1308486, &[_]u64{ 997, 7, 783, 939, 4, 2, 1, 1, 6 } };
    const actual = try calibrationIsValidWithConcat(testing.allocator, calibration);
    try testing.expectEqual(true, actual);
}

// 1308486: ['997', '7', '783', '939', '4', '2', '1', '1', '6']
// eq is True
// ops ['+', '+', '+', '*', '*', '||', '*', '*']

pub fn calibrationIsValidWithConcat(allocator: std.mem.Allocator, calibration: Calibration) !bool {
    const result, const operands = calibration;
    const operations = &[_]Operation{ .addition, .multiplication, .concatenation };

    const permutations = try computePermutations(allocator, operands, operations);
    defer allocator.free(permutations);

    for (permutations) |p| {
        if (p == result) return true;
    }
    return false;
}
