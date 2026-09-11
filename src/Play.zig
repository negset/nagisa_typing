const rl = @import("raylib");
const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Io = std.Io;
const Timestamp = Io.Timestamp;

const Lesson = @import("Lesson.zig");
const Level = Lesson.Level;
const Transition = @import("scene.zig").Transition;
const utils = @import("utils.zig");

lesson: Lesson = undefined,
level: Level = undefined,
correct: u32 = 0,
miss: u32 = 0,
start: Timestamp = undefined,
typed_keys: ArrayList(u8),
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
    if (rl.getKeyPressed() == .escape)
        return .{ .to_select = .{} };

    const key: u8 = @intCast(rl.getCharPressed());
    if (key == 0) return .none;

    if (self.lesson.getExercise().transition(key)) {
        self.correct += 1;
        rl.playSound(self.se_correct);
    } else {
        self.miss += 1;
        rl.playSound(self.se_miss);
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

    utils.drawText(ex.display, .{ .x = 400, .y = 240 }, .center_middle, 44, .black);
    utils.drawText(ex.kana, .{ .x = 400, .y = 290 }, .center_middle, 32, .dark_gray);
    utils.drawText(text, .{ .x = 400, .y = 340 }, .center_middle, 32, .black);
}
