const std = @import("std");
const rlz = @import("raylib_zig");
const emsdk = rlz.emsdk;
const version = @import("build.zig.zon").version;

/// raylib's `emsdk.emccStep` always invokes `emcc.py`, which can't be spawned
/// directly on Windows. Point the underlying run step at `emcc.bat` instead.
fn fixEmccOnWindows(b: *std.Build, emcc_step: *std.Build.Step) !void {
    if (@import("builtin").os.tag != .windows) return;
    for (emcc_step.dependencies.items) |dep| {
        const run = dep.cast(std.Build.Step.Run) orelse continue;
        run.argv.items[0].lazy_path.lazy_path = try emsdk.path(
            b,
            "upstream/emscripten/emcc.bat",
        );
        return;
    }
    return error.EmccRunStepNotFound;
}

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });

    // raylib's build script bails out before creating its artifact when one of
    // its lazy dependencies hasn't been fetched yet. Propagate so the build
    // runner fetches them and reruns us.
    if (b.graph.needed_lazy_dependencies.count() != 0)
        return error.LazyDependencyNeeded;

    const raylib = raylib_dep.module("raylib");

    const raylib_artifact = raylib_dep.artifact("raylib");

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe_mod.addImport("raylib", raylib);

    const options = b.addOptions();
    options.addOption([]const u8, "version", version);
    exe_mod.addOptions("build_config", options);

    const run_step = b.step("run", "Run the app");

    // Web exports are completely separate.
    if (target.query.os_tag == .emscripten) {
        const wasm = b.addLibrary(.{
            .name = "nagisa_typing",
            .root_module = exe_mod,
        });

        const install_dir: std.Build.InstallDir = .{ .custom = "web" };
        const emcc_flags = emsdk.emccDefaultFlags(b.allocator, .{
            .optimize = optimize,
            .asyncify = !std.mem.endsWith(u8, wasm.name, "web"),
        });
        const emcc_settings = emsdk.emccDefaultSettings(b.allocator, .{
            .optimize = optimize,
        });

        const emcc_step = try emsdk.emccStep(b, &.{}, &.{ raylib_artifact, wasm }, .{
            .optimize = optimize,
            .flags = emcc_flags,
            .settings = emcc_settings,
            .shell_file_path = b.path("src/shell.html"),
            .install_dir = install_dir,
            .preload_paths = &.{.{
                .src_path = b.path("resources"),
                .virtual_path = "resources",
            }},
            .out_file_name = wasm.name,
        });
        try fixEmccOnWindows(b, emcc_step);

        const emrun_step = try emsdk.emrunStep(
            b,
            b.graph.path(.install_prefix, b.fmt("{s}.html", .{wasm.name})),
            &.{},
        );

        emrun_step.dependOn(emcc_step);
        run_step.dependOn(emrun_step);

        b.getInstallStep().dependOn(emcc_step);
    } else {
        const exe = b.addExecutable(.{
            .name = "nagisa_typing",
            .root_module = exe_mod,
        });

        if (optimize != .debug) {
            exe.subsystem = .windows;
        }

        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());

        run_step.dependOn(&run_cmd.step);
    }
}
