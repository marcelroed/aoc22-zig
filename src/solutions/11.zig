const std = @import("std");
const input = @import("../input.zig");
const output = @import("../output.zig");

const Operation = union(enum) {
    square: void,
    multiply: i32,
    add: i32,
};

const Monkey = struct {
    item_storage: [100]u8,
    num_items: usize,
    operation: Operation,
    divisible_by: i32,
    true_throw: usize,
    false_throw: usize,

    const Self = @This();

    fn items(self: *const Self) []const u8 {
        return self.item_storage[0..self.num_items];
    }
};

fn parse_operation(s: []const u8) Operation {
    var split = std.mem.splitScalar(u8, s[19..], ' ');
    _ = split.next();
    const op = split.next().?;
    const rhs = split.next().?;

    if (op[0] == '+') {
        return .{ .add = input.parseLineTo(i32, rhs) catch unreachable };
    }
    // Op must be '*'
    const parsed = input.parseLineTo(i32, rhs) catch |err| switch (err) {
        error.InvalidCharacter => return .{ .square = {} },
        else => unreachable,
    };
    return .{
        .multiply = parsed,
    };
}

fn try_read_monkey() !Monkey {
    _ = try input.readLine(50);
    const item_text = try input.readLine(50);
    var split_items = std.mem.splitSequence(u8, item_text[18..], ", ");
    var item_storage = std.mem.zeroes(std.meta.fields(Monkey)[0].type);
    var num_items: usize = 0;
    while (split_items.next()) |item| {
        std.log.warn("\"{s}\"", .{item});
        item_storage[num_items] = try input.parseLineTo(u8, item);
        num_items += 1;
    }

    const operation = parse_operation(try input.readLine(50));

    const divisible_by = try input.parseLineTo(i32, (try input.readLine(50))[21..]);
    const true_throw = try input.parseLineTo(usize, (try input.readLine(50))[29..]);
    const false_throw = try input.parseLineTo(usize, (try input.readLine(50))[30..]);

    return Monkey{
        .item_storage = item_storage,
        .num_items = num_items,
        .operation = operation,
        .divisible_by = divisible_by,
        .true_throw = true_throw,
        .false_throw = false_throw,
    };
}

pub fn solve() !void {
    var buffer = std.mem.zeroes([std.math.powi(usize, 2, 13) catch 0]u8);
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    var monkeys = std.ArrayList(Monkey).init(allocator);
    while (try_read_monkey()) |monkey| {
        try monkeys.append(monkey);
        _ = input.readLine(50) catch null;
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => |e| return e,
    }

    std.log.warn("Number of monkeys: {}", .{monkeys.items.len});
    std.log.warn("Monkeys: {any}", .{monkeys.items});
}
