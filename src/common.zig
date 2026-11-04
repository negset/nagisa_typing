const builtin = @import("builtin");
const std = @import("std");
const pi = std.math.pi;
const rl = @import("raylib");

pub var font: rl.Font = undefined;
pub var se_confirm: rl.Sound = undefined;
pub var se_back: rl.Sound = undefined;
pub var se_cursor: rl.Sound = undefined;
pub var should_close = false;

pub fn init() !void {
    font = try rl.loadFont("res/font/KosugiMaru.fnt");
    rl.setTextureFilter(font.texture, .bilinear);
    rl.setTextLineSpacing(20);
    se_confirm = try rl.loadSound("res/se/confirm.ogg");
    se_back = try rl.loadSound("res/se/back.ogg");
    se_cursor = try rl.loadSound("res/se/cursor.ogg");
}

pub fn deinit() void {
    font.unload();
    se_confirm.unload();
    se_back.unload();
    se_cursor.unload();
}

pub const TextAlign = enum {
    center_top,
    center_middle,
    center_bottom,
    left_top,
    left_middle,
    left_bottom,
    right_top,
    right_middle,
    right_bottom,
};

pub fn drawText(
    text: [:0]const u8,
    pos: rl.Vector2,
    text_align: TextAlign,
    size: f32,
    color: rl.Color,
) void {
    const rect = rl.measureTextEx(font, text, size, 0);
    const offset = rect.multiply(switch (text_align) {
        .center_top => .{ .x = -0.5, .y = 0 },
        .center_middle => .{ .x = -0.5, .y = -0.5 },
        .center_bottom => .{ .x = -0.5, .y = -1.0 },
        .left_top => .{ .x = 0, .y = 0 },
        .left_middle => .{ .x = 0, .y = -0.5 },
        .left_bottom => .{ .x = 0, .y = -1.0 },
        .right_top => .{ .x = -1.0, .y = 0 },
        .right_middle => .{ .x = -1.0, .y = -0.5 },
        .right_bottom => .{ .x = -1.0, .y = -1.0 },
    });
    rl.drawTextEx(font, text, pos.add(offset), size, 0, color);
}

pub fn drawBlinkingText(
    texts: []const [:0]const u8,
    pos: rl.Vector2,
    text_align: TextAlign,
    size: f32,
    color: rl.Color,
) void {
    if (texts.len == 0) return;

    const time = rl.getTime();
    const duration = 2.0;
    const phase = @mod(time, duration * @as(f64, @floatFromInt(texts.len)));
    const index: usize = @intFromFloat(@floor(phase / duration));
    const alpha: f32 = @floatCast(@abs(@sin(pi * time / duration)));

    drawText(texts[index], pos, text_align, size, color.fade(alpha));
}

pub fn drawCursor(
    x: f32,
    y: f32,
    width: f32,
) void {
    const time = rl.getTime();
    const duration = 0.5;
    const offset: f32 = @floatCast(5 * @sin(pi * time / duration));
    drawText("▶", .{ .x = x - offset, .y = y }, .right_middle, 20, .red);
    drawText("◀", .{ .x = x + width + offset, .y = y }, .left_middle, 20, .red);
}

pub fn requestExit() void {
    if (comptime builtin.os.tag != .emscripten)
        should_close = true;
}
