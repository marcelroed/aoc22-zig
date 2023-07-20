const std = @import("std");
const input = @import("../input.zig");
const output = @import("../output.zig");

// Note that this initializes to zeros, so is unsuitable for anything but strings
// pub fn Queue(comptime T: type, comptime bufsize: comptime_int) type {
//     return struct {
//         buf: [bufsize]T,

//         const Self = @This();
//         pub fn init() Self {
//             return .{ .buf = std.mem.zeroes([bufsize]T) };
//         }
//         pub fn inQueue(self: *Self, val: T) ?isize {
//             std.log.warn("Checking if {c} is in {s}", .{ val, self.buf });
//             for (self.buf, 0..) |v, i| {
//                 if (v == val) {
//                     std.log.warn("Found {c} at {}", .{ val, i });
//                     return @intCast(i);
//                 }
//             }
//             return null;
//         }
//         pub fn insertAt(self: *Self, val: T, pos: usize) void {
//             self.buf[pos % bufsize] = val;
//         }
//     };
// }

const small_size = 4;
const big_size = 14;

const reversed = std.mem.reverseIterator;

pub fn solve() !void {
    const line = try input.readLine(4096);

    // Store results when found
    var small_first_index: ?usize = null;
    var big_first_index: ?usize = null;

    var small_countdown: isize = 0;
    var big_countdown: isize = 0;

    for (line, 0..) |c, i| {
        small_blk: {
            if (small_first_index != null)
                break :small_blk;
            const start_idx = @max(
                @as(isize, @intCast(i)) - small_size + 1,
                0,
            );
            const small_slice = line[start_idx..i];
            // std.log.warn("The small slice contains {s} and we are looking at {c}", .{ small_slice, c });
            var iter = reversed(small_slice);

            const slice_size: isize = @intCast(small_slice.len);
            var j: isize = slice_size - @as(isize, 1);
            while (iter.next()) |p| : (j -= 1) {
                if (p == c) {
                    small_countdown = @max(
                        j,
                        small_countdown,
                    );
                    // std.log.warn("Found a match at idx {}, small_countdown: {}", .{ j, small_countdown });
                    break;
                }
            }

            // std.log.warn("small_countdown: {}", .{small_countdown});

            if (small_countdown < 0) {
                small_first_index = i + 1;
                // std.log.warn("Found no duplicates for {s}", .{line[start_idx..(i + 1)]});
                break :small_blk;
            }

            if (slice_size >= small_size - 1)
                small_countdown -= 1;
        }

        if (big_first_index != null)
            break;
        const start_idx = @max(
            @as(isize, @intCast(i)) - big_size + 1,
            0,
        );
        const big_slice = line[start_idx..i];
        // std.log.warn("The big slice contains {s} and we are looking at {c}", .{ big_slice, c });
        var iter = reversed(big_slice);

        const slice_size: isize = @intCast(big_slice.len);
        var j: isize = slice_size - @as(isize, 1);
        while (iter.next()) |p| : (j -= 1) {
            if (p == c) {
                big_countdown = @max(
                    j,
                    big_countdown,
                );
                // std.log.warn("Found a match at idx {}, big_countdown: {}", .{ j, big_countdown });
                break;
            }
        }

        // std.log.warn("big_countdown: {}", .{big_countdown});

        if (big_countdown < 0) {
            big_first_index = i + 1;
            // std.log.warn("Found no duplicates for {s}", .{line[start_idx..(i + 1)]});
            break;
        }

        if (slice_size >= big_size - 1)
            big_countdown -= 1;
    }
    output.part1(small_first_index);
    output.part2(big_first_index);
}
