const rl = @import("raylib");
const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Io = std.Io;
const Timestamp = Io.Timestamp;

const Lesson = @import("Lesson.zig");
const Level = Lesson.Level;
const Transition = @import("scene.zig").Transition;
const common = @import("common.zig");

lesson: Lesson = undefined,
level: Level = undefined,
correct: u32 = 0,
miss: u32 = 0,
damage_flash: f32 = 0,
typed_keys: ArrayList(u8),
start: Timestamp = undefined,
se_correct: rl.Sound = undefined,
se_miss: rl.Sound = undefined,

pub fn init(gpa: Allocator) !@This() {
    return .{
        .typed_keys = try .initCapacity(gpa, 50),
        .se_correct = try rl.loadSound("resources/se/correct.ogg"),
        .se_miss = try rl.loadSound("resources/se/miss.ogg"),
    };
}

pub fn deinit(self: *@This(), gpa: Allocator) void {
    self.typed_keys.deinit(gpa);
    self.se_correct.unload();
    self.se_miss.unload();
}

pub fn enter(
    self: *@This(),
    gpa: Allocator,
    io: Io,
    data: Transition.Data(@This()),
) !void {
    self.lesson = try .initByLevel(gpa, io, data.level);
    self.level = data.level;
    self.correct = 0;
    self.miss = 0;
    self.clearTypedKeys();
    self.start = .now(io, .awake);
}

pub fn leave(self: *@This(), gpa: Allocator) void {
    self.lesson.deinit(gpa);
}

fn appendTypedKeys(self: *@This(), key: u8) void {
    _ = self.typed_keys.pop(); // Pop sentinel.
    self.typed_keys.appendAssumeCapacity(key);
    self.typed_keys.appendAssumeCapacity(0); // Append sentinel.
}

fn clearTypedKeys(self: *@This()) void {
    self.typed_keys.clearRetainingCapacity();
    self.typed_keys.appendAssumeCapacity(0); // Append sentinel.
}

pub fn update(self: *@This(), io: Io) !Transition {
    self.damage_flash = @max(0.0, self.damage_flash - rl.getFrameTime() * 1.0);

    if (rl.getKeyPressed() == .escape) {
        return .to_select;
    }

    const key: u8 = @intCast(rl.getCharPressed());
    if (key == 0) return .none;

    if (self.lesson.getExercise().transition(key)) {
        self.correct += 1;
        rl.playSound(self.se_correct);
    } else {
        self.miss += 1;
        rl.playSound(self.se_miss);
        self.damage_flash = 0.3;
        return .none;
    }

    self.appendTypedKeys(key);

    if (self.lesson.getExercise().getState().accept) {
        if (!self.lesson.goNextExercise()) {
            // Go to result scene.
            return .{
                .to_result = .{
                    .level = self.level,
                    .correct = self.correct,
                    .miss = self.miss,
                    .time = Timestamp.untilNow(self.start, io, .awake),
                },
            };
        }

        self.clearTypedKeys();
    }

    return .none;
}

pub fn draw(self: *@This()) void {
    const ex = self.lesson.getExercise();
    const text = self.typed_keys.items[0 .. self.typed_keys.items.len - 1 :0];

    common.drawText(ex.display, .{ .x = 400, .y = 240 }, .center_middle, 44, .black);
    drawActiveKanaRect(ex.kana, ex.getState().fragment_index, ex.getState().fragment_len);
    common.drawText(ex.kana, .{ .x = 400, .y = 290 }, .center_middle, 32, .dark_gray);
    common.drawText(text, .{ .x = 400, .y = 340 }, .center_middle, 32, .black);

    if (self.damage_flash > 0.0) {
        rl.drawRectangle(
            0,
            0,
            rl.getScreenWidth(),
            rl.getScreenHeight(),
            rl.fade(.red, self.damage_flash),
        );
    }
}

fn drawActiveKanaRect(text: [:0]const u8, active_index: usize, active_len: usize) void {
    const font = common.font;
    const size = 32;
    const padding = 4;
    const scale_factor = @as(f32, @floatFromInt(size)) / @as(f32, @floatFromInt(font.baseSize));
    const box = rl.measureTextEx(font, text, size, 0);
    const pos = rl.Vector2.init(400, 290).add(box.scale(-0.5));

    var i: usize = 0;
    var kana_index: usize = 0;
    var byte_count: i32 = undefined;
    var active_rect: rl.Rectangle = .init(pos.x, pos.y - padding, 0, box.y + padding * 2);
    while (i < text.len) : ({
        i += @intCast(byte_count);
        kana_index += 1;
    }) {
        const codepoint = rl.getCodepointNext(text[i.. :0], &byte_count);
        const index: usize = @intCast(rl.getGlyphIndex(font, codepoint));
        const advance_x = font.glyphs[index].advanceX;
        const width = scale_factor *
            if (advance_x == 0) font.recs[index].width else @as(f32, @floatFromInt(advance_x));

        if (kana_index < active_index) {
            active_rect.x += width;
        } else if (kana_index < active_index + active_len) {
            active_rect.width += width;
        } else break;
    }

    rl.drawRectangleRounded(active_rect, 0.5, 8, .yellow);
}
