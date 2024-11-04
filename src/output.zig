const std = @import("std");

const stdout_file = std.io.getStdOut().writer();
var stdout_bw = std.io.bufferedWriter(stdout_file);
var stdout = stdout_bw.writer();

pub fn print(comptime format: []const u8, args: anytype) void {
    _ = stdout.print(format, args) catch unreachable;
}

pub fn flush() !void {
    try stdout_bw.flush();
}

fn printPart(solution: anytype, part: i32) void {
    const specifier = comptime switch (@typeInfo(@TypeOf(solution))) {
        .array => "s",
        .optional => "any",
        else => "",
    };
    print("Part {}: {" ++ specifier ++ "}\n", .{ part, solution });
    flush() catch unreachable;
}

pub fn part1(solution: anytype) void {
    printPart(solution, 1);
}

pub fn part2(solution: anytype) void {
    printPart(solution, 2);
}
