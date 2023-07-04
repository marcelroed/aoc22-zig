const std = @import("std");
const output = @import("../output.zig");
const input = @import("../input.zig");

const print = output.print;
const flush = output.flush;

const scan = input.readAndParseLine;

pub fn insertIfGreater(comptime T: type, comptime arrSize: comptime_int, arr: *[arrSize]T, value: T) void {
    // Takes a sorted array and inserts the element in the appropriate position, pushing the lowest element down
    var found: bool = false;
    var holding: T = undefined;
    for (0..arrSize) |i| {
        if (!found and arr[i] < value) {
            found = true;
            holding = arr[i];
            arr[i] = value;
        } else if (found) {
            const tmp = arr[i];
            arr[i] = holding;
            holding = tmp;
        }
    }
}

pub fn solve() !void {
    print("Running d01\n", .{});
    try output.flush();
    defer _ = output.flush() catch unreachable;

    var three_highest: [3]u64 = .{0} ** 3;
    var running_count: u64 = 0;

    while (scan(?u64, 100)) |maybe_val| {
        if (maybe_val) |val| {
            running_count += val;
        } else {
            insertIfGreater(u64, 3, &three_highest, running_count);
            running_count = 0;
        }
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }

    insertIfGreater(u64, 3, &three_highest, running_count);
    const max_seen = three_highest[0];
    var sum: u64 = 0;
    for (three_highest) |val| {
        sum += val;
    }

    print("Part One: {}\n", .{max_seen});
    print("Part Two: {any}\n", .{sum});
}
