const rl = @import("raylib");
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const Level = @import("Lesson.zig").Level;
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

pub fn update(self: *@This(), _: Io) Transition {
    switch (rl.getKeyPressed()) {
        .w, .up => {
            self.cursor = @mod(self.cursor + 2, 3);
            rl.playSound(common.se_cursor);
        },
        .s, .down => {
            self.cursor = @mod(self.cursor + 1, 3);
            rl.playSound(common.se_cursor);
        },
        .space => {
            rl.playSound(common.se_confirm);
            return .{
                .to_setup = .{ .level = @fromBackingInt(self.cursor) },
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
        const level: Level = @fromBackingInt(@intCast(i));
        const y = 220 + 80 * i;
        const color: rl.Color = if (self.cursor == i) .red else .black;
        common.drawText(
            level.toString(),
            .{ .x = 400, .y = y },
            .center_middle,
            36,
            color,
        );
    }

    common.drawCursor(320, 220 + 80 * @as(f32, @floatFromInt(self.cursor)), 160);

    common.drawBlinkingText(
        &.{
            "\u{e006}/\u{e008} or \u{e004}/\u{e003} で移動",
            "\u{e000} で決定",
        },
        .{ .x = 400, .y = 540 },
        .center_middle,
        32,
        .dark_gray,
    );
}
