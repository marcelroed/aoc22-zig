const std = @import("std");
const input = @import("../input.zig");
const output = @import("../output.zig");
const abs = std.math.absInt;
const sign = std.math.sign;

const Dir = enum {
    L,
    R,
    U,
    D,
};

const HashSet = std.AutoHashMap(Position, void);

const Position = struct {
    x: i32 = 0,
    y: i32 = 0,

    const Self = @This();
    pub fn sub(self: Self, other: Self) Self {
        return .{
            .x = self.x - other.x,
            .y = self.y - other.y,
        };
    }
    pub fn add(self: Self, other: Self) Self {
        return .{
            .x = self.x + other.x,
            .y = self.y + other.y,
        };
    }
    pub fn dragOther(self: Self, other: Self) Self {
        // Assumes that movement has only progressed a single step, so can't be 2 away in more than one axis
        const distance = self.sub(other);
        const far_x = abs(distance.x) catch unreachable >= 2;
        const far_y = abs(distance.y) catch unreachable >= 2;
        const touching = !(far_x or far_y);
        if (touching) return other;

        return .{
            .x = other.x + sign(distance.x),
            .y = other.y + sign(distance.y),
        };
    }
    pub fn move(self: Self, dir: Dir) Self {
        return self.add(switch (dir) {
            .U => .{ .y = 1 },
            .D => .{ .y = -1 },
            .L => .{ .x = -1 },
            .R => .{ .x = 1 },
        });
    }
    pub fn min(self: Self, other: Self) Self {
        return .{
            .x = @min(self.x, other.x),
            .y = @min(self.y, other.y),
        };
    }
    pub fn max(self: Self, other: Self) Self {
        return .{
            .x = @max(self.x, other.x),
            .y = @max(self.y, other.y),
        };
    }
};

fn plotRope(rope: []Position) void {
    const grid_n = 100;
    const grid_m = 100;
    var grid: [grid_n][grid_m]u8 = undefined;
    for (&grid) |*line| {
        for (line) |*c| {
            c.* = '.';
        }
    }

    var min_pos = rope[0];
    var max_pos = rope[0];

    for (rope, 0..) |pos, i| {
        min_pos = min_pos.min(pos);
        max_pos = max_pos.max(pos);
        const x: usize = @intCast(pos.x + grid_n / 2);
        const y: usize = @intCast(pos.y + grid_m / 2);
        grid[y][x] = std.fmt.digitToChar(@intCast(i), .lower);
    }

    for (@intCast(min_pos.y + grid_n / 2)..@intCast(max_pos.y + grid_n / 2 + 1)) |i| {
        for (@intCast(min_pos.x + grid_m / 2)..@intCast(max_pos.x + grid_m / 2 + 1)) |j| {
            output.print("{c}", .{grid[i][j]});
        }
        output.print("\n", .{});
    }
}

const N_KNOTS = 10;

pub fn solve() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    var allocator = arena.allocator();
    defer _ = arena.reset(.free_all);

    const ParseType = struct {
        dir: Dir,
        n_steps: u8,
    };
    var second_been = HashSet.init(allocator);
    var last_been = HashSet.init(allocator);
    var knots: [N_KNOTS]Position = std.mem.zeroes([N_KNOTS]Position);

    second_been.put(knots[1], {}) catch unreachable;
    last_been.put(knots[N_KNOTS - 1], {}) catch unreachable;
    while (input.readAndParseLine(ParseType, 10)) |p| {
        for (0..p.n_steps) |_| {
            knots[0] = knots[0].move(p.dir);
            for (1..N_KNOTS) |i| {
                knots[i] = knots[i - 1].dragOther(knots[i]);
            }
            second_been.put(knots[1], {}) catch unreachable;
            last_been.put(knots[N_KNOTS - 1], {}) catch unreachable;
        }
        // output.print("{s} {}\n", .{ @tagName(p.dir), p.n_steps });
        // plotRope(&knots);
        // output.print("\n", .{});
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }
    output.part1(second_been.count());

    output.part2(last_been.count());
}
