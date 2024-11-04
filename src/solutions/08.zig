const std = @import("std");
const input = @import("../input.zig");
const output = @import("../output.zig");

const width = 99;
const height = 99;

pub fn solve() !void {
    var trees: [height][width]u8 = undefined;
    var visible = std.mem.zeroes([height][width]bool);
    {
        var i: usize = 0;
        while (input.readLine(101)) |line| : (i += 1) {
            for (line, 0..) |c, j| {
                trees[i][j] = c - '0';
            }
        } else |_| {}
    }

    for (1..(height - 1)) |i| {
        var tallest: isize = -1;
        for (0..width) |j| {
            const current_height = trees[i][j];
            if (current_height > tallest) {
                visible[i][j] = true;
                tallest = current_height;
            }
        }
        tallest = -1;
        var j: usize = width;
        while (j > 0) {
            j -= 1;
            const current_height = trees[i][j];
            if (current_height > tallest) {
                visible[i][j] = true;
                tallest = current_height;
            }
        }
    }

    for (1..(width - 1)) |j| {
        var tallest: isize = -1;
        for (0..height) |i| {
            const current_height = trees[i][j];
            if (current_height > tallest) {
                visible[i][j] = true;
                tallest = current_height;
            }
        }
        tallest = -1;
        var i: usize = height;
        while (i > 0) {
            i -= 1;
            const current_height = trees[i][j];
            if (current_height > tallest) {
                visible[i][j] = true;
                tallest = current_height;
            }
        }
    }

    var accum: usize = 4;
    for (&visible) |*line| {
        for (line) |vis| {
            if (vis) accum += 1;
            // std.debug.print("{}", .{@as(u8, if (vis) 1 else 0)});
        }
        // std.debug.print("\n", .{});
    }
    output.part1(accum);

    var highest_scenic: usize = 0;
    for (0..height) |i| {
        for (0..width) |j| {
            const base_height = trees[i][j];

            var si = i;
            const up = while (si > 0) {
                si -= 1;
                if (trees[si][j] >= base_height) break i - si;
            } else i;

            const down = for ((i + 1)..height) |s| {
                if (trees[s][j] >= base_height) break s - i;
            } else height - i - 1;

            var sj = j;
            const left = while (sj > 0) {
                sj -= 1;
                if (trees[i][sj] >= base_height) break j - sj;
            } else j;

            const right = for ((j + 1)..width) |s| {
                if (trees[i][s] >= base_height) break s - j;
            } else width - j - 1;

            highest_scenic = @max(
                highest_scenic,
                left * right * up * down,
            );
        }
    }
    output.part2(highest_scenic);
}
