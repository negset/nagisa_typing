const rl = @import("raylib");
const std = @import("std");
const Allocator = std.mem.Allocator;

const Transition = @import("main.zig").Transition;
const utils = @import("utils.zig");

pub fn init(_: Allocator) !@This() {
    return .{};
}

pub fn deinit(_: *@This(), _: Allocator) void {}

pub fn enter(_: *@This(), _: Allocator, _: @FieldType(Transition, "to_title")) !void {}

pub fn leave(_: *@This(), _: Allocator) void {}

pub fn update(_: *@This()) !Transition {
    if (rl.getKeyPressed() == .space)
        return .{ .to_select = .{} };

    return .none;
}

pub fn draw(_: *@This()) void {
    utils.drawText("渚タイピング", .{ .x = 400, .y = 200 }, .center_middle, 48, .black);
    utils.drawText("SPACE ではじめる", .{ .x = 400, .y = 400 }, .center_middle, 36, .dark_gray);
    utils.drawText("(c) 2026 negset", .{ .x = 400, .y = 540 }, .center_middle, 24, .dark_gray);
}
