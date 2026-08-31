const rl = @import("raylib");

const main = @import("main.zig");

pub const TextAlign = enum {
    center_middle,
    left_bottom,
    left_top,
    right_bottom,
    right_top,
};

pub fn drawText(text: [:0]const u8, pos: rl.Vector2, text_align: TextAlign, size: f32, color: rl.Color) void {
    const rect = rl.measureTextEx(main.font, text, size, 0);
    const offset = rl.math.vector2Multiply(rect, switch (text_align) {
        .center_middle => .{ .x = -0.5, .y = -0.5 },
        .left_bottom => .{ .x = 0, .y = -1.0 },
        .left_top => .{ .x = 0, .y = 0 },
        .right_bottom => .{ .x = -1.0, .y = -1.0 },
        .right_top => .{ .x = -1.0, .y = 0 },
    });
    const calculated_pos = rl.math.vector2Add(pos, offset);
    rl.drawTextEx(main.font, text, calculated_pos, size, 0, color);
}
