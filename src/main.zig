const builtin = @import("builtin");
const rl = @import("raylib");
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const Scene = @import("scene.zig").Scene;
const Transition = @import("scene.zig").Transition;
const Title = @import("Title.zig");
const Select = @import("Select.zig");
const Setup = @import("Setup.zig");
const Play = @import("Play.zig");
const Result = @import("Result.zig");
const common = @import("common.zig");
const loader = @import("loader.zig");
const windows = @import("windows.zig");

var title: Title = undefined;
var select: Select = undefined;
var setup: Setup = undefined;
var play: Play = undefined;
var result: Result = undefined;
var current_scene: Scene = .{ .title = &title };

fn initScenes(gpa: Allocator) !void {
    title = try .init(gpa);
    select = try .init(gpa);
    setup = try .init(gpa);
    play = try .init(gpa);
    result = try .init(gpa);
}

fn deinitScenes(gpa: Allocator) void {
    title.deinit(gpa);
    select.deinit(gpa);
    setup.deinit(gpa);
    play.deinit(gpa);
    result.deinit(gpa);
}

fn update(gpa: Allocator, io: Io) !void {
    const transition = current_scene.update(io);
    if (transition == .none) return;

    current_scene.leave(gpa);
    current_scene = switch (transition) {
        .to_title => .{ .title = &title },
        .to_select => .{ .select = &select },
        .to_setup => .{ .setup = &setup },
        .to_play => .{ .play = &play },
        .to_result => .{ .result = &result },
        .none => unreachable,
    };
    try current_scene.enter(gpa, io, transition);
}

fn draw() void {
    current_scene.draw();
}

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    const io = init.io;

    const screen_width = 800;
    const screen_height = 600;

    rl.initWindow(screen_width, screen_height, "渚タイピング");
    defer rl.closeWindow();

    rl.initAudioDevice();
    defer rl.closeAudioDevice();

    rl.setTargetFPS(60);
    rl.setExitKey(.null);

    if (comptime builtin.os.tag == .windows)
        windows.disableIme();

    try common.init();
    defer common.deinit();

    try loader.init(gpa, io);
    defer loader.deinit();

    try initScenes(gpa);
    defer deinitScenes(gpa);
    defer current_scene.leave(gpa);

    // Main game loop
    while (!rl.windowShouldClose() and !common.should_close) {
        try update(gpa, io);

        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(.ray_white);

        draw();
    }
}
