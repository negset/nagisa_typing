const rl = @import("raylib");
const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Io = std.Io;
const Timestamp = Io.Timestamp;
const Utf8Iterator = std.unicode.Utf8Iterator;

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
kana_iter: Utf8Iterator = undefined,
highlight: rl.Rectangle = undefined,
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
    try self.resetHighlight();
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

fn resetHighlight(self: *@This()) !void {
    const kana = self.lesson.getExercise().kana;
    self.kana_iter = (try std.unicode.Utf8View.init(kana)).iterator();

    const font = common.font;
    const size = 32;
    const padding = 4;
    const dimensions = rl.measureTextEx(font, kana, size, 0);
    const pos = rl.Vector2.init(400, 290).add(dimensions.scale(-0.5));

    self.highlight = .init(pos.x, pos.y - padding, 0, dimensions.y + padding * 2);

    self.updateHighlight();
}

fn updateHighlight(self: *@This()) void {
    self.highlight.x += self.highlight.width;
    self.highlight.width = 0;

    const font = common.font;
    const size = 32;
    const scale_factor = @as(f32, @floatFromInt(size)) / @as(f32, @floatFromInt(font.baseSize));

    for (0..self.lesson.getExercise().getState().fragment_len) |_| {
        const codepoint = self.kana_iter.nextCodepoint().?;
        const index: usize = @intCast(rl.getGlyphIndex(font, @intCast(codepoint)));
        const advance_x = font.glyphs[index].advanceX;
        const width = scale_factor *
            if (advance_x == 0) font.recs[index].width else @as(f32, @floatFromInt(advance_x));

        self.highlight.width += width;
    }
}

pub fn update(self: *@This(), io: Io) !Transition {
    const ex = self.lesson.getExercise();

    self.damage_flash = @max(0.0, self.damage_flash - rl.getFrameTime() * 1.0);

    if (rl.getKeyPressed() == .escape) {
        return .to_select;
    }

    const key: u8 = @intCast(rl.getCharPressed());
    if (key == 0) return .none; // No key is pressed.

    if (ex.transition(key)) {
        self.correct += 1;
        rl.playSound(self.se_correct);

        self.appendTypedKeys(key);

        if (ex.getState().fragment_len > 0) {
            self.updateHighlight();
        }

        if (ex.getState().accept) {
            if (self.lesson.goNextExercise()) {
                self.clearTypedKeys();
                try self.resetHighlight();
            } else {
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
        }
    } else {
        self.miss += 1;
        rl.playSound(self.se_miss);
        self.damage_flash = 0.3;
    }

    return .none;
}

pub fn draw(self: *@This()) void {
    const ex = self.lesson.getExercise();
    const text = self.typed_keys.items[0 .. self.typed_keys.items.len - 1 :0];

    rl.drawRectangleRounded(self.highlight, 0.5, 8, .yellow);

    common.drawText(ex.display, .{ .x = 400, .y = 240 }, .center_middle, 44, .black);
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
