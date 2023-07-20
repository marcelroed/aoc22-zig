const std = @import("std");
const output = @import("../output.zig");
const input = @import("../input.zig");

fn getScore(i_chose: u32, opponent_chose: u32) u32 {
    const result = (3 + i_chose - opponent_chose) % 3;
    const result_score: u32 = switch (result) {
        0 => 3, // Tie
        1 => 6, // I win
        2 => 0, // I lose
        else => unreachable,
    };
    const choice_score = i_chose + 1;
    return result_score + choice_score;
}

pub fn solve() !void {
    defer output.flush() catch unreachable;
    var total_1: u32 = 0;
    var total_2: u32 = 0;
    while (input.readLine(4)) |line| {
        const i = try input.parseLineTo(struct { opponent: [1]u8, mine: [1]u8 }, line);
        const opponent_chose = i.opponent[0] - 'A';
        const i_chose = i.mine[0] - 'X';
        const inferred_choice: u32 = (3 + opponent_chose + i_chose - 1) % 3;

        total_1 += getScore(i_chose, opponent_chose);
        total_2 += getScore(inferred_choice, opponent_chose);
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }

    output.part1(total_1);
    output.part2(total_2);
}
