const rl = @import("raylib");
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const Level = @import("Lesson.zig").Level;
const Transition = @import("scene.zig").Transition;
const common = @import("common.zig");

cursor: u8 = 0,
se_cursor: rl.Sound = undefined,

pub fn init(_: Allocator) !@This() {
    return .{
        .se_cursor = try rl.loadSound("resources/se/cursor.ogg"),
    };
}

pub fn deinit(self: *@This(), _: Allocator) void {
    self.se_cursor.unload();
}

pub fn enter(
    _: *@This(),
    _: Allocator,
    _: Io,
    _: Transition.Data(@This()),
) !void {}

pub fn leave(_: *@This(), _: Allocator) void {}

pub fn update(self: *@This()) !Transition {
    switch (rl.getKeyPressed()) {
        .w, .up => {
            self.cursor = @mod(self.cursor + 2, 3);
            rl.playSound(self.se_cursor);
        },
        .s, .down => {
            self.cursor = @mod(self.cursor + 1, 3);
            rl.playSound(self.se_cursor);
        },
        .space => {
            rl.playSound(common.se_confirm);
            return .{
                .to_play = .{ .level = @enumFromInt(self.cursor) },
            };
        },
        .escape => {
            rl.playSound(common.se_back);
            return .to_title;
        },
        else => {},
    }

    return .none;
}

pub fn draw(self: *@This()) void {
    common.drawText("レベル選択", .{ .x = 400, .y = 80 }, .center_middle, 48, .black);

    inline for (0..3) |i| {
        const level: Level = @enumFromInt(i);
        const color: rl.Color = if (self.cursor == i) .red else .black;
        common.drawText(
            level.toString(),
            .{ .x = 400, .y = 220 + i * 80 },
            .center_middle,
            36,
            color,
        );
    }

    common.drawText(
        "↑/↓ or w/s で選択    SPACE で決定",
        .{ .x = 400, .y = 540 },
        .center_middle,
        32,
        .dark_gray,
    );
}
