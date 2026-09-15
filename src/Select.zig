const rl = @import("raylib");
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const Transition = @import("scene.zig").Transition;
const common = @import("common.zig");

cursor: u8 = 0,

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

pub fn update(self: *@This()) !Transition {
    switch (rl.getKeyPressed()) {
        .w, .up => self.cursor = @mod(self.cursor + 2, 3),
        .s, .down => self.cursor = @mod(self.cursor + 1, 3),
        .space => return .{
            .to_play = .{ .level = @enumFromInt(self.cursor) },
        },
        .escape => return .to_title,
        else => {},
    }

    return .none;
}

pub fn draw(self: *@This()) void {
    common.drawText("レベル選択", .{ .x = 400, .y = 80 }, .center_middle, 48, .black);
    common.drawText("BASIC", .{ .x = 400, .y = 220 }, .center_middle, 36, if (self.cursor == 0) .red else .black);
    common.drawText("NORMAL", .{ .x = 400, .y = 300 }, .center_middle, 36, if (self.cursor == 1) .red else .black);
    common.drawText("EXPERT", .{ .x = 400, .y = 380 }, .center_middle, 36, if (self.cursor == 2) .red else .black);
    common.drawText("↑/↓ or w/s で選択    SPACE で決定", .{ .x = 400, .y = 540 }, .center_middle, 32, .dark_gray);
}
