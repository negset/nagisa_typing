const rl = @import("raylib");
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const Level = @import("Lesson.zig").Level;
const Transition = @import("scene.zig").Transition;
const common = @import("common.zig");

level: Level = undefined,
cursor: u8 = 0,
ex_quota: u32 = 20,
limit_time: bool = false,
sudden_death: bool = false,

pub fn init(_: Allocator) !@This() {
    return .{};
}

pub fn deinit(_: *@This(), _: Allocator) void {}

pub fn enter(
    self: *@This(),
    _: Allocator,
    _: Io,
    data: Transition.Data(@This()),
) !void {
    self.level = data.level;
}

pub fn leave(_: *@This(), _: Allocator) void {}

pub fn update(self: *@This()) !Transition {
    switch (rl.getKeyPressed()) {
        .w, .up => {
            self.cursor = @mod(self.cursor + 2, 3);
            rl.playSound(common.se_cursor);
        },
        .s, .down => {
            self.cursor = @mod(self.cursor + 1, 3);
            rl.playSound(common.se_cursor);
        },
        .a, .left => switch (self.cursor) {
            0 => if (self.ex_quota > 10) {
                self.ex_quota -= 10;
                rl.playSound(common.se_cursor);
            },
            1 => if (self.limit_time) {
                self.limit_time = false;
                rl.playSound(common.se_cursor);
            },
            2 => if (self.sudden_death) {
                self.sudden_death = false;
                rl.playSound(common.se_cursor);
            },
            else => {},
        },
        .d, .right => switch (self.cursor) {
            0 => if (self.ex_quota < 30) {
                self.ex_quota += 10;
                rl.playSound(common.se_cursor);
            },
            1 => if (!self.limit_time) {
                self.limit_time = true;
                rl.playSound(common.se_cursor);
            },
            2 => if (!self.sudden_death) {
                self.sudden_death = true;
                rl.playSound(common.se_cursor);
            },
            else => {},
        },
        .space => {
            rl.playSound(common.se_confirm);
            return .{
                .to_play = .{
                    .level = self.level,
                    .ex_quota = self.ex_quota,
                    .limit_time = self.limit_time,
                    .sudden_death = self.sudden_death,
                },
            };
        },
        .escape => {
            rl.playSound(common.se_back);
            return .to_select;
        },
        else => {},
    }

    return .none;
}

pub fn draw(self: *@This()) void {
    common.drawText("プレイ設定", .{ .x = 400, .y = 80 }, .center_middle, 48, .black);

    common.drawText(self.level.toString(), .{ .x = 400, .y = 180 }, .center_middle, 36, .black);

    {
        const color: rl.Color = if (self.cursor == 0) .red else .black;
        common.drawText("出題数:", .{ .x = 180, .y = 270 }, .left_middle, 36, color);
        common.drawText("10", .{ .x = 440, .y = 270 }, .left_middle, 36, if (self.ex_quota == 10) color else .gray);
        common.drawText("20", .{ .x = 530, .y = 270 }, .center_middle, 36, if (self.ex_quota == 20) color else .gray);
        common.drawText("30", .{ .x = 620, .y = 270 }, .right_middle, 36, if (self.ex_quota == 30) color else .gray);
    }
    {
        const color: rl.Color = if (self.cursor == 1) .red else .black;
        common.drawText("時間制限:", .{ .x = 180, .y = 330 }, .left_middle, 36, color);
        common.drawText("OFF", .{ .x = 440, .y = 330 }, .left_middle, 36, if (!self.limit_time) color else .gray);
        common.drawText("ON", .{ .x = 620, .y = 330 }, .right_middle, 36, if (self.limit_time) color else .gray);
    }
    {
        const color: rl.Color = if (self.cursor == 2) .red else .black;
        common.drawText("一発勝負:", .{ .x = 180, .y = 390 }, .left_middle, 36, color);
        common.drawText("OFF", .{ .x = 440, .y = 390 }, .left_middle, 36, if (!self.sudden_death) color else .gray);
        common.drawText("ON", .{ .x = 620, .y = 390 }, .right_middle, 36, if (self.sudden_death) color else .gray);
    }

    common.drawBlinkingText(
        &.{
            "\u{e006}/\u{e008} or \u{e004}/\u{e003} で移動",
            "\u{e005}/\u{e007} or \u{e001}/\u{e002} で変更",
            "\u{e000} で開始",
        },
        .{ .x = 400, .y = 540 },
        .center_middle,
        32,
        .dark_gray,
    );
}
