const rl = @import("raylib");

pub var font: rl.Font = undefined;
pub var se_confirm: rl.Sound = undefined;
pub var se_back: rl.Sound = undefined;
pub var request_exit = false;

pub fn init() !void {
    font = try rl.loadFont("resources/font/KosugiMaru.fnt");
    rl.setTextureFilter(font.texture, .bilinear);
    rl.setTextLineSpacing(20);
    se_confirm = try rl.loadSound("resources/se/confirm.ogg");
    se_back = try rl.loadSound("resources/se/back.ogg");
}

pub fn deinit() void {
    font.unload();
    se_confirm.unload();
    se_back.unload();
}

pub const TextAlign = enum {
    center_middle,
    left_bottom,
    left_top,
    right_bottom,
    right_top,
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
        .center_middle => .{ .x = -0.5, .y = -0.5 },
        .left_bottom => .{ .x = 0, .y = -1.0 },
        .left_top => .{ .x = 0, .y = 0 },
        .right_bottom => .{ .x = -1.0, .y = -1.0 },
        .right_top => .{ .x = -1.0, .y = 0 },
    });
    rl.drawTextEx(font, text, pos.add(offset), size, 0, color);
}
