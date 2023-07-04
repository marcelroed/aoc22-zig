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
