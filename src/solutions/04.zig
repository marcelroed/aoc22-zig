const std = @import("std");
const input = @import("../input.zig");
const output = @import("../output.zig");

const InclusiveRange = struct {
    pub const delimiter = '-';
    from: u32,
    to: u32,

    const Self = @This();
    pub fn fullyContains(self: Self, other: Self) bool {
        return self.from <= other.from and self.to >= other.to;
    }
    pub fn overlapsWith(self: Self, other: Self) bool {
        return (self.from <= other.to and other.from <= self.to) or (other.from <= self.to and self.from <= other.to);
    }
};

pub fn solve() !void {
    defer output.flush() catch unreachable;

    var contains_count: u32 = 0;
    var overlaps_count: u32 = 0;

    while (input.readLine(12)) |line| {
        const ParseStruct = struct {
            pub const delimiter = ',';
            e1: InclusiveRange,
            e2: InclusiveRange,
        };
        const inp = try input.parseLineTo(ParseStruct, line);
        if (inp.e1.fullyContains(inp.e2) or inp.e2.fullyContains(inp.e1)) {
            contains_count += 1;
        }
        if (inp.e1.overlapsWith(inp.e2)) {
            overlaps_count += 1;
        }
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }

    output.part1(contains_count);
    output.part2(overlaps_count);
}
