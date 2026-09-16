const rl = @import("raylib");
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const Transition = @import("scene.zig").Transition;
const common = @import("common.zig");

pub fn init(_: Allocator) !@This() {
    return .{};
}

pub fn deinit(_: *@This(), _: Allocator) void {}

pub fn enter(
    _: *@This(),
    _: Allocator,
    _: Io,
    _: Transition.Data(@This()),
) !void {}

pub fn leave(_: *@This(), _: Allocator) void {}

pub fn update(_: *@This()) !Transition {
    switch (rl.getKeyPressed()) {
        .space => {
            rl.playSound(common.se_confirm);
            return .to_select;
        },
        .escape => {
            common.request_exit = true;
        },
        else => {},
    }

    return .none;
}

pub fn draw(_: *@This()) void {
    common.drawText("渚タイピング", .{ .x = 400, .y = 200 }, .center_middle, 48, .black);
    common.drawText("SPACE ではじめる", .{ .x = 400, .y = 400 }, .center_middle, 36, .dark_gray);
    common.drawText("© 2026 negset", .{ .x = 400, .y = 540 }, .center_middle, 24, .dark_gray);
}
