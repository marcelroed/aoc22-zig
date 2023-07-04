const std = @import("std");
const output = @import("output.zig");
const input = @import("input.zig");
const String = std.ArrayList(u8);
const assert = std.debug.assert;

const solutions = @import("solutions.zig");
const sol01 = solutions.sol01;

fn getAllSolutions() []*const fn () anyerror!void {
    const decls = @typeInfo(solutions).Struct.decls;
    // @compileLog(.{decls});
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
    const solnum = solution_number orelse all_functions.len;
    return all_functions[solnum - 1];
}

fn runSolution(solution_number: ?u32) !void {
    output.print("Running solution number {?}\n", .{solution_number});
    try output.flush();

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

    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // var inp = try input.readAll(gpa.allocator());
    // defer inp.deinit();

    try runSolution(solution_number);

    // output.print("Testing {s}\n", .{inp.items});
    // output.print("Args were: {s}\n", .{std.os.argv[1]});

    // try output.flush();
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
