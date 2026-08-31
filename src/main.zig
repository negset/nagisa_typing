const builtin = @import("builtin");
const rl = @import("raylib");
const std = @import("std");
const Allocator = std.mem.Allocator;

const all_chars = @import("chars.zig").all_chars;
const Title = @import("title.zig");
const Select = @import("select.zig");
const Play = @import("Play.zig");
const Result = @import("Result.zig");
const Level = @import("Lesson.zig").Level;
const windows = @import("windows.zig");

const Scene = union(enum) {
    title: *Title,
    select: *Select,
    play: *Play,
    result: *Result,

    fn enter(self: Scene, gpa: Allocator, t: Transition) !void {
        switch (self) {
            .title => |scene| try scene.enter(gpa, t.to_title),
            .select => |scene| try scene.enter(gpa, t.to_select),
            .play => |scene| try scene.enter(gpa, t.to_play),
            .result => |scene| try scene.enter(gpa, t.to_result),
        }
    }

    fn leave(self: Scene, gpa: Allocator) void {
        switch (self) {
            .title => |scene| scene.leave(gpa),
            .select => |scene| scene.leave(gpa),
            .play => |scene| scene.leave(gpa),
            .result => |scene| scene.leave(gpa),
        }
    }
};

pub const Transition = union(enum) {
    none,
    to_title,
    to_select: struct { cursor: u8 = 0 },
    to_play: struct { level: Level },
    to_result: struct { level: Level, correct: u32, miss: u32 },
};

pub var font: rl.Font = undefined;
var title: Title = undefined;
var select: Select = undefined;
var play: Play = undefined;
var result: Result = undefined;
var current_scene: Scene = .{ .title = &title };

fn update(gpa: Allocator) !void {
    const transition = switch (current_scene) {
        .title => try title.update(),
        .select => try select.update(),
        .play => try play.update(),
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
    try current_scene.enter(gpa, transition);
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
    const screen_width = 800;
    const screen_height = 600;

    rl.initWindow(screen_width, screen_height, "渚タイピング");
    defer rl.closeWindow();

    if (comptime builtin.os.tag == .windows)
        windows.disableIme();

    const codepoints = try rl.loadCodepoints(all_chars);
    // font = try rl.loadFontEx("resources/KosugiMaru-Regular.ttf", 48, codepoints);
    font = try rl.loadFont("resources/KosugiMaru-Regular.fnt");
    rl.unloadCodepoints(codepoints);
    defer rl.unloadFont(font);

    rl.setTextureFilter(font.texture, .bilinear);
    rl.setTextLineSpacing(20);
    rl.setTargetFPS(60);
    rl.setExitKey(.null);

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
        try update(gpa);

        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(.ray_white);

        draw();
    }
}
