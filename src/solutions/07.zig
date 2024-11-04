const std = @import("std");
const input = @import("../input.zig");
const output = @import("../output.zig");

const NodeList = std.ArrayList(Node);
const Allocator = std.mem.Allocator;

const Node = union(enum) {
    directory: Directory,
    file: File,
    const Directory = struct {
        name: [20:0]u8,
        children: NodeList,
        parent: ?*Node.Directory = null,
    };

    const File = struct {
        name: [20:0]u8,
        filesize: usize,
        parent: *Node.Directory,
    };
    const Self = @This();
    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        // std.log.err("fmt: {s}, options: {any}", .{ fmt, options });
        _ = options;
        switch (self) {
            .directory => |dir| {
                try writer.print("{s}/\n", .{dir.name});
                // try writer.print("cap: {any}\n", .{dir.children.capacity});
                // std.log.err("{any}", .{dir.children.capacity});
                for (dir.children.items) |child| {
                    try writer.print("{any}", .{child});
                }
            },
            .file => |file| {
                try writer.print("{s}: {} bytes\n", .{ file.name, file.filesize });
            },
        }
    }
};

fn findFirstDir(l: *NodeList, name: []const u8) *Node.Directory {
    for (l.*.items) |*node| switch (node.*) {
        .directory => |*dir| {
            if (std.mem.eql(u8, name, dir.*.name[0..name.len]))
                return dir;
        },
        else => {},
    };
    unreachable;
}

fn cd(current_dir: *Node.Directory, dirname: []const u8, root: *Node.Directory) *Node.Directory {
    if (dirname[0] == '/')
        return root;
    if (dirname[0] == '.')
        return current_dir.*.parent.?;
    // Must be a directory name
    return findFirstDir(&current_dir.*.children, dirname);
}

fn ls(allocator: Allocator, current_dir: *Node.Directory, listed_line: []const u8) !void {
    var split = std.mem.splitScalar(u8, listed_line, ' ');
    const filesize_or_dir = split.next().?;
    const node_name = split.next().?;
    var node_name_owned = std.mem.zeroes([20:0]u8);
    @memcpy(node_name_owned[0..node_name.len], node_name);
    if (filesize_or_dir[0] == 'd') {
        try current_dir.*.children.append(Node{ .directory = .{
            .name = node_name_owned,
            .parent = current_dir,
            .children = NodeList.init(allocator),
        } });
    } else {
        const filesize = input.parseLineTo(usize, filesize_or_dir) catch unreachable;
        try current_dir.*.children.append(Node{ .file = .{
            .name = node_name_owned,
            .parent = current_dir,
            .filesize = filesize,
        } });
    }
}

fn total_size_accumulation(root: *const Node) struct { usize, usize } {
    // Returns the size of the directory, and the accumulator
    switch (root.*) {
        .directory => |*dir| {
            var total_dir_size: usize = 0;
            var accumulator: usize = 0;
            for (dir.*.children.items) |*child_node| {
                const sub_result = total_size_accumulation(child_node);
                total_dir_size += sub_result[0];
                accumulator += sub_result[1];
            }
            if (total_dir_size <= 100000) {
                accumulator += total_dir_size;
            }
            return .{
                total_dir_size,
                accumulator,
            };
        },
        .file => |*file| {
            return .{
                file.filesize,
                0,
            };
        },
    }
}

fn smallest_total_space_passing(root: *const Node, required_space: usize) struct { usize, usize } {
    switch (root.*) {
        .directory => |*dir| {
            var smallest: usize = std.math.maxInt(usize);
            var total_size: usize = 0;
            for (dir.*.children.items) |*child_node| {
                const sub_result = smallest_total_space_passing(child_node, required_space);
                total_size += sub_result[0];
                smallest = @min(smallest, sub_result[1]);
            }
            if (total_size >= required_space) {
                smallest = @min(smallest, total_size);
            }
            return .{
                total_size,
                smallest,
            };
        },
        .file => |*file| {
            return .{
                file.filesize,
                std.math.maxInt(usize),
            };
        },
    }
}

pub fn solve() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    const allocator = arena.allocator();
    defer _ = arena.reset(.free_all);

    var name = std.mem.zeroes([20:0]u8);
    name[0] = '/';
    var root = Node{ .directory = .{
        .name = name,
        .children = NodeList.init(allocator),
    } };
    var current_dir = &root.directory;
    while (input.readLine(35)) |line| {
        // std.log.warn("{any}", .{Node{ .Directory = current_node.* }});
        // std.log.warn("Running command \"{s}\"", .{line});
        if (line[0] == '$') {
            if (line[2] == 'c') {
                current_dir = cd(current_dir, line[5..], &root.directory);
            }
            // If not we are starting ls and don't need to do anything
        } else { // ls line
            try ls(allocator, current_dir, line);
        }
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }
    const res = total_size_accumulation(&root);
    output.part1(res[1]);

    const current_disk_usage = res[0];
    const total_disk_space = 70000000;
    const required_disk_space = 30000000;
    const space_need_to_free = required_disk_space - (total_disk_space - current_disk_usage);
    const space_res = smallest_total_space_passing(&root, space_need_to_free);
    output.part2(space_res[1]);
}
