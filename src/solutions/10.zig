const std = @import("std");
const input = @import("../input.zig");
const output = @import("../output.zig");

const ParseType = union(enum) {
    addx: i32,
    noop,
};

const interesting_cycles = &[_]u8{ 20, 60, 100, 140, 180, 220 };

const Machine = struct {
    X: i32,
    cycle: isize,
    interesting_slice: []const u8,
    current_op: ?ParseType,
    cycles_remaining: isize,
    interesting_score: isize,
    screen: [6][40]u8,

    const Self = @This();
    fn init() Self {
        return .{
            .X = 1,
            .cycle = 0,
            .interesting_slice = interesting_cycles,
            .current_op = null,
            .cycles_remaining = 0,
            .interesting_score = 0,
            .screen = std.mem.zeroes([6][40]u8),
        };
    }

    fn read_op() !ParseType {
        return input.readAndParseLine(ParseType, 30);
    }

    fn maybe_read_op(self: *Self) !void {
        if (self.cycles_remaining == 0) {
            self.current_op = try Self.read_op();
            self.cycles_remaining = switch (self.*.current_op orelse unreachable) {
                .addx => 2,
                .noop => 1,
            };
        }
    }

    fn maybe_finish_op(self: *Self) void {
        self.cycles_remaining -= 1;
        if (self.cycles_remaining == 0) {
            switch (self.current_op orelse unreachable) {
                .addx => |payload| {
                    self.X += payload;
                },
                else => {},
            }
        }
    }

    fn tally_interesting(self: *Self) void {
        const interesting = self.interesting_slice.len > 0 and self.interesting_slice[0] == self.cycle;
        if (interesting) {
            // Advance slice
            self.interesting_slice = self.interesting_slice[1..];
            const to_add = @as(i32, @intCast(self.cycle)) * self.X;
            self.*.interesting_score += to_add;
        }
    }

    fn draw_pixel(self: *Self) void {
        const cycle = self.cycle - 1;
        if (self.cycle >= 240) return;
        const pixel_i: usize = @intCast(@divFloor(cycle, @as(isize, 40)));
        const pixel_j: usize = @intCast(@mod(cycle, 40));

        const colored = std.math.absCast(@as(u8, @intCast(pixel_j)) - self.*.X) <= 1;
        const char: u8 = if (colored) '#' else '.';

        self.*.screen[pixel_i][pixel_j] = char;
    }

    fn advance(self: *Self) !void {
        defer self.maybe_finish_op();
        defer self.tally_interesting();
        defer self.draw_pixel();
        defer self.cycle += 1;
        try self.maybe_read_op();

        // self.cycle += 1; // Current cycle is now one higher
        // self.maybe_finish_op();
        // if(std.mem.)
    }
    // fn addx(self: *Self, visize) {
    //     self.advance();
    //     self.advance();
    //     self.*.X += v;
    // }
};

pub fn solve() !void {
    var machine = Machine.init();
    var score: i32 = 0;
    _ = score;
    while (true) {
        machine.advance() catch |err| switch (err) {
            error.EndOfStream => break,
            else => |e| return e,
        };
    }

    output.part1(machine.interesting_score);
    output.print("Part 2:\n", .{});
    for (&machine.screen) |*line| {
        output.print("{s}\n", .{line});
    }
    try output.flush();
}
