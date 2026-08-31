const rl = @import("raylib");
const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const Lesson = @import("Lesson.zig");
const Level = Lesson.Level;
const Transition = @import("main.zig").Transition;
const utils = @import("utils.zig");

lesson: Lesson = undefined,
level: Level = undefined,
correct: u32 = 0,
miss: u32 = 0,
typed_keys: ArrayList(u8),

pub fn init(gpa: Allocator) !@This() {
    return .{
        .typed_keys = try ArrayList(u8).initCapacity(gpa, 50),
    };
}

pub fn deinit(self: *@This(), gpa: Allocator) void {
    self.typed_keys.deinit(gpa);
}

pub fn enter(self: *@This(), gpa: Allocator, data: @FieldType(Transition, "to_play")) !void {
    self.lesson = try .initByLevel(gpa, data.level);
    self.level = data.level;
    self.clearTypedKeys();
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

pub fn update(self: *@This()) !Transition {
    switch (rl.getKeyPressed()) {
        .null => return .none,
        .escape => return .{ .to_select = .{} },
        else => {},
    }

    const key: u8 = @intCast(rl.getCharPressed());

    if (self.lesson.getExercise().transition(key)) {
        self.correct += 1;
    } else {
        self.miss += 1;
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
