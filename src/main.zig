const builtin = @import("builtin");
const rl = @import("raylib");
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const Scene = @import("scene.zig").Scene;
const Transition = @import("scene.zig").Transition;
const Title = @import("title.zig");
const Select = @import("select.zig");
const Play = @import("Play.zig");
const Result = @import("Result.zig");
const windows = @import("windows.zig");

pub var font: rl.Font = undefined;
var title: Title = undefined;
var select: Select = undefined;
var play: Play = undefined;
var result: Result = undefined;
var current_scene: Scene = .{ .title = &title };

fn update(gpa: Allocator, io: Io) !void {
    const transition = switch (current_scene) {
        .title => try title.update(),
        .select => try select.update(),
        .play => try play.update(io),
        .result => try result.update(),
    };

    if (transition == .none) return;

    current_scene.leave(gpa);
    current_scene = switch (transition) {
        .to_title => .{ .title = &title },
        .to_select => .{ .select = &select },
        .to_play => .{ .play = &play },
        .to_result => .{ .result = &result },
        .none => unreachable,
    };
    try current_scene.enter(gpa, io, transition);
}

fn draw() void {
    switch (current_scene) {
        .title => title.draw(),
        .select => select.draw(),
        .play => play.draw(),
        .result => result.draw(),
    }
}

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    const io = init.io;

    const screen_width = 800;
    const screen_height = 600;

    rl.initWindow(screen_width, screen_height, "渚タイピング");
    defer rl.closeWindow();

    font = try rl.loadFont("resources/KosugiMaru-Regular.fnt");
    defer rl.unloadFont(font);

    rl.setTextureFilter(font.texture, .bilinear);
    rl.setTextLineSpacing(20);
    rl.setTargetFPS(60);
    rl.setExitKey(.null);

    if (comptime builtin.os.tag == .windows)
        windows.disableIme();

    title = try .init(gpa);
    defer title.deinit(gpa);
    select = try .init(gpa);
    defer select.deinit(gpa);
    play = try .init(gpa);
    defer play.deinit(gpa);
    result = try .init(gpa);
    defer result.deinit(gpa);

    defer current_scene.leave(gpa);

    // Main game loop
    while (!rl.windowShouldClose()) {
        try update(gpa, io);

        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(.ray_white);

        draw();
    }
}
