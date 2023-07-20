const std = @import("std");
const input = @import("../input.zig");
const output = @import("../output.zig");

const height = 8;
const width = 9;
const height_limit = 100;
const bufsize = 36;

fn parseStackLine(line: []const u8) [width]u8 {
    var result = std.mem.zeroes([width]u8);

    for (0..width) |i| {
        result[i] = line[1 + 4 * i];
    }
    return result;
}

fn moveBetweenStacks(stacks: *[width][]u8, from: u32, to: u32) void {
    const element = stacks.*[from][stacks.*[from].len - 1];
    stacks.*[from].len -= 1;
    stacks.*[to].len += 1;
    stacks.*[to][stacks.*[to].len - 1] = element;
}

fn groupedMoveBetweenStacks(stacks: *[width][]u8, move_count: u32, from: u32, to: u32) void {
    const first_from_idx = stacks.*[from].len - move_count;
    const first_to_idx = stacks.*[to].len;
    stacks.*[to].len += move_count;
    for (0..move_count) |i| {
        const c = stacks.*[from][first_from_idx + i];
        stacks.*[to][first_to_idx + i] = c;
    }
    stacks.*[from].len -= move_count;
}

pub fn solve() !void {
    defer output.flush() catch unreachable;
    var memory = std.mem.zeroes([width][height_limit]u8);
    var stacks: [width][]u8 = undefined;
    for (0..width) |i|
        stacks[i] = @constCast(&memory[i]);

    for (0..height) |i| {
        const line = try input.readLine(bufsize);
        const stack_line = parseStackLine(line);
        for (0..width) |j| {
            const cj = stack_line[j];
            if (cj == ' ') continue;
            if (stacks[j].len == height_limit) stacks[j].len = height - i;
            stacks[j][height - i - 1] = cj;
        }
    }
    const space = 2;
    for (0..space) |_| {
        _ = try input.readLine(bufsize);
    }

    var grouped_memory = memory;
    var grouped_stacks: [width][]u8 = undefined;
    for (0..width) |i| {
        grouped_stacks[i] = @constCast(&grouped_memory[i]);
        grouped_stacks[i].len = stacks[i].len;
    }

    while (input.readLine(bufsize)) |line| {
        const l = try input.parseLineTo(struct {
            pub const indices: [3]usize = .{ 1, 3, 5 };
            move_count: u32,
            from_idx: u32,
            to_idx: u32,
        }, line);
        groupedMoveBetweenStacks(&grouped_stacks, l.move_count, l.from_idx - 1, l.to_idx - 1);
        for (0..l.move_count) |_| {
            moveBetweenStacks(&stacks, l.from_idx - 1, l.to_idx - 1);
        }
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }

    var result: [width]u8 = undefined;
    var grouped_result: [width]u8 = undefined;
    for (stacks, grouped_stacks, 0..) |stack, grouped_stack, i| {
        result[i] = stack[stack.len - 1];
        grouped_result[i] = grouped_stack[stack.len - 1];
    }
    output.part1(result);
    output.part2(grouped_result);
}
