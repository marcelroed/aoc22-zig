const std = @import("std");
const input = @import("../input.zig");
const output = @import("../output.zig");

const BitSet = std.bit_set.IntegerBitSet(26 * 2);

fn charIndex(c: u8) u8 {
    const index = if (std.ascii.isLower(c)) c - 'a' else 26 + c - 'A';
    return index;
}

fn fillBitSet(bit_set: *BitSet, xs: []const u8) void {
    for (xs) |c| {
        const index = charIndex(c);
        bit_set.set(index);
    }
}

fn filledBitSet(xs: []const u8) BitSet {
    var bit_set = BitSet.initEmpty();
    fillBitSet(&bit_set, xs);
    return bit_set;
}

fn findFirstSetIndex(bit_set: *BitSet, xs: []const u8) u8 {
    for (xs) |c| {
        const index = charIndex(c);
        if (bit_set.isSet(index)) {
            return index;
        }
    }
    unreachable;
}

fn findCommon(a: []const u8, b: []const u8) u8 {
    const Static = struct {
        var bit_set = BitSet.initEmpty();
    };
    defer Static.bit_set.mask = 0;

    fillBitSet(&Static.bit_set, a);

    return findFirstSetIndex(&Static.bit_set, b);
}

pub fn solve() !void {
    defer output.flush() catch unreachable;
    var priority_sum: u32 = 0;

    var running_bit_set = BitSet.initEmpty();
    var group_index: u32 = 0;
    var group_priority_sum: u32 = 0;
    while (input.readLine(1000)) |line| : (group_index += 1) {
        const half_length = line.len / 2;
        const first = line[0..half_length];
        const second = line[half_length..];
        const common_value = findCommon(first, second) + 1;
        priority_sum += common_value;

        switch (group_index % 3) {
            0 => {
                running_bit_set.mask = 0;
                fillBitSet(&running_bit_set, line);
            },
            1 => running_bit_set.setIntersection(filledBitSet(line)),
            2 => {
                const group_priority = findFirstSetIndex(&running_bit_set, line) + 1;
                group_priority_sum += group_priority;
            },
            else => unreachable,
        }
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }

    output.part1(priority_sum);
    output.part2(group_priority_sum);
}
