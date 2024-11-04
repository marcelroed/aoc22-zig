const std = @import("std");
const output = @import("output.zig");
const input = @import("input.zig");
const solutions = @import("solutions.zig");

const String = std.ArrayList(u8);
const assert = std.debug.assert;

pub var problem_number: usize = 0;

fn getAllSolutions() []*const fn () anyerror!void {
    const decls = @typeInfo(solutions).@"struct".decls;
    const n_decls = decls.len;

    var funcArr: [n_decls]*const fn () anyerror!void = undefined;
    for (decls, 0..) |dec, i| {
        const name = comptime dec.name;
        funcArr[i] = @field(@field(solutions, name), "solve");
    }
    return &funcArr;
}

fn getSolution(solution_number: ?u32) *const fn () anyerror!void {
    const all_functions = comptime getAllSolutions();
    const solnum: usize = @intCast(solution_number orelse all_functions.len);
    output.print("Running solution number {}\n", .{solnum});
    output.flush() catch unreachable;
    problem_number = solnum;
    // output.print("We have {} {} solutions\n", .{ all_functions.len, all_functions.ptr });
    output.flush() catch unreachable;
    inline for (0..all_functions.len) |i| {
        if (i == solnum - 1) {
            return all_functions[i];
        }
    }
    return all_functions[all_functions.len - 1];
    // return all_functions[solnum - 1];
}

fn runSolution(solution_number: ?u32) !void {
    const solution_function = getSolution(solution_number);
    try solution_function();
}

pub fn main() !void {
    assert(std.os.argv.len == 2 or std.os.argv.len == 1);
    defer _ = output.flush() catch unreachable;

    const solution_number = if (std.os.argv.len == 2)
        std.fmt.parseInt(u32, std.mem.span(std.os.argv[1]), 10) catch null
    else
        null;

    try runSolution(solution_number);
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
