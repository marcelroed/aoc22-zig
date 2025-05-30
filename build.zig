const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) !void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    // Find all solution files
    // var files = std.ArrayList([]const u8).init(b.allocator);
    // defer files.deinit();

    // var dir = try std.fs.cwd().openIterableDir("src/solutions", .{});
    // var it = dir.iterate();
    // while (try it.next()) |file| {
    //     if (file.kind != .file) continue; // Ignore subdirs
    //     try files.append(b.dupe(split: {
    //         var split = std.mem.splitScalar(u8, file.name, '.');
    //         const num_string = split.next() orelse unreachable;
    //         break :split num_string;
    //     }));
    // }

    // var options = b.addOptions();
    // options.addOption([]const []const u8, "files", files.items);

    // const solutions = b.createModule(.{ .source_file = .{.path} });
    // const module = b.createModule(
    //     .{ .source_file = .{ .path = "src/solutions/01.zig" } },
    // );

    const exe = b.addExecutable(.{
        .name = "aoc22-zig",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // const input_module = b.createModule(.{ .source_file = .{ .path = "src/input.zig" } });
    // const output_module = b.createModule(.{ .source_file = .{ .path = "src/output.zig" } });
    // exe.addModule("input", input_module);
    // exe.addModule("output", output_module);

    // exe.addModule("sols", module);

    // exe.addOptions("options", options);

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
