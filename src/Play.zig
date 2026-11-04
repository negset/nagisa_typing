const rl = @import("raylib");
const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Io = std.Io;
const Duration = Io.Duration;
const Timestamp = Io.Timestamp;
const Utf8Iterator = std.unicode.Utf8Iterator;

const Lesson = @import("Lesson.zig");
const Level = Lesson.Level;
const Transition = @import("scene.zig").Transition;
const common = @import("common.zig");

level: Level = undefined,
ex_quota: u32 = undefined,
limit_time: bool = undefined,
sudden_death: bool = undefined,

lesson: Lesson = undefined,

correct: u32 = 0,
miss: u32 = 0,
completed: u32 = 0,
combo: u32 = 0,
max_combo: u32 = 0,
combo_bonus: u32 = 0,
game_over: bool = false,

combo_text: [:0]const u8 = undefined,
combo_text_buf: [16]u8 = undefined,
combo_alpha: f32 = 0,
damage_alpha: f32 = 0,
typed_keys: ArrayList(u8),

start: Timestamp = undefined,
deadline: Timestamp = undefined,
remaining: Duration = undefined,

kana_iter: Utf8Iterator = undefined,
highlight: rl.Rectangle = undefined,

se_correct: rl.Sound = undefined,
se_miss: rl.Sound = undefined,

const time_limit = 5500;

const UpdateExerciseResult = enum {
    no_input,
    incorrect_input,
    updated,
    completed,
    timeout,
};

pub fn init(gpa: Allocator) !@This() {
    return .{
        .typed_keys = try .initCapacity(gpa, 50),
        .se_correct = try rl.loadSound("res/se/correct.ogg"),
        .se_miss = try rl.loadSound("res/se/miss.ogg"),
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
    self.level = data.level;
    self.ex_quota = data.ex_quota;
    self.limit_time = data.limit_time;
    self.sudden_death = data.sudden_death;
    self.lesson = try .init(gpa, io, data.level, data.ex_quota);
    self.correct = 0;
    self.miss = 0;
    self.completed = 0;
    self.combo = 0;
    self.max_combo = 0;
    self.combo_bonus = 0;
    self.game_over = false;
    self.combo_alpha = 0;
    self.damage_alpha = 0;
    self.clearTypedKeys();
    self.resetHighlight();
    self.start = .now(io, .awake);
    self.remaining = .fromMilliseconds(time_limit);
    self.deadline = self.start.addDuration(self.remaining);
}

pub fn leave(self: *@This(), gpa: Allocator) void {
    self.lesson.deinit(gpa);
}

fn onCorrectInput(self: *@This(), key: u8) void {
    self.correct += 1;
    rl.playSound(self.se_correct);
    self.appendTypedKeys(key);
}

fn onIncorrectInput(self: *@This()) void {
    self.miss += 1;
    rl.playSound(self.se_miss);
    self.damage_alpha = 0.3;
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

fn isExerciseTimeout(self: *@This(), io: Io) bool {
    if (!self.limit_time) return false;
    self.remaining = Timestamp.now(io, .awake).durationTo(self.deadline);
    return self.remaining.nanoseconds < 0;
}

fn isExerciseComplete(self: *@This()) bool {
    return self.lesson.getExercise().getState().accept;
}

fn updateExercise(self: *@This(), io: Io) UpdateExerciseResult {
    if (self.isExerciseTimeout(io)) {
        self.combo = 0;
        if (self.sudden_death) self.game_over = true;
        return .timeout;
    }

    const key: u8 = @intCast(rl.getCharPressed());
    if (key == 0) return .no_input;

    const ex = self.lesson.getExercise();

    if (ex.getState().transition(key)) |next| {
        ex.current_state = next;
        self.onCorrectInput(key);

        const len = ex.getState().fragment_len;
        if (len > 0) {
            self.incrementCombo();
            self.updateHighlight(len);
        }

        if (self.isExerciseComplete()) {
            self.completed += 1;
            return .completed;
        } else {
            return .updated;
        }
    }

    // Epsilon transition.
    switch (key) {
        'a', 'i', 'u', 'e', 'o', 'y' => {},
        else => if (ex.getState().transition(0)) |epsilon| {
            if (ex.states[epsilon].transition(key)) |next| {
                ex.current_state = next;
                self.onCorrectInput(key);
                self.incrementCombo();
                self.updateHighlight(ex.states[epsilon].fragment_len);

                if (self.isExerciseComplete()) {
                    self.completed += 1;
                    return .completed;
                } else {
                    return .updated;
                }
            }
        },
    }

    self.onIncorrectInput();
    self.combo = 0;
    if (self.sudden_death) self.game_over = true;
    return .incorrect_input;
}

fn goNextExercise(self: *@This()) bool {
    if (self.lesson.current_exercise < self.lesson.exercises.len - 1) {
        self.lesson.current_exercise += 1;
        self.lesson.getExercise().current_state = 0;
        return true;
    }
    return false;
}

fn incrementCombo(self: *@This()) void {
    self.combo += 1;
    self.max_combo = @max(self.max_combo, self.combo);

    if (self.combo > 0 and @mod(self.combo, 10) == 0) {
        self.combo_text = std.fmt.bufPrintSentinel(
            &self.combo_text_buf,
            "{} COMBO!!",
            .{self.combo},
            0,
        ) catch @panic("No space at combo_text_buf.");

        self.combo_bonus += @intFromFloat(@sqrt(@as(f32, @floatFromInt(100 * self.combo))));
        self.combo_alpha = 2.0;
    }
}

fn resetHighlight(self: *@This()) void {
    const ex = self.lesson.getExercise();
    const view = std.unicode.Utf8View.init(ex.kana) catch @panic("Utf8View error.");
    self.kana_iter = view.iterator();

    const font = common.font;
    const size = 32;
    const padding = 4;
    const dimensions = rl.measureTextEx(font, ex.kana, size, 0);
    const pos = rl.Vector2.init(400, 290).add(dimensions.scale(-0.5));

    self.highlight = .init(pos.x, pos.y - padding, 0, dimensions.y + padding * 2);

    self.updateHighlight(ex.states[0].fragment_len);
}

fn updateHighlight(self: *@This(), len: usize) void {
    self.highlight.x += self.highlight.width;
    self.highlight.width = 0;

    const font = common.font;
    const size = 32;
    const scale_factor = @as(f32, @floatFromInt(size)) / @as(f32, @floatFromInt(font.baseSize));

    for (0..len) |_| {
        const codepoint = self.kana_iter.nextCodepoint().?;
        const index: usize = @intCast(rl.getGlyphIndex(font, @intCast(codepoint)));
        const advance_x = font.glyphs[index].advanceX;
        const width = scale_factor *
            if (advance_x == 0) font.recs[index].width else @as(f32, @floatFromInt(advance_x));

        self.highlight.width += width;
    }
}

pub fn update(self: *@This(), io: Io) Transition {
    self.combo_alpha = @max(0.0, self.combo_alpha - rl.getFrameTime() * 2.0);
    self.damage_alpha = @max(0.0, self.damage_alpha - rl.getFrameTime() * 1.0);

    if (rl.getKeyPressed() == .escape) {
        rl.playSound(common.se_back);
        return .to_select;
    }

    switch (self.updateExercise(io)) {
        .no_input,
        .updated,
        => return .none,

        .incorrect_input,
        => if (self.game_over) {} else return .none,

        .completed,
        .timeout,
        => {},
    }

    if (self.goNextExercise() and !self.game_over) {
        self.clearTypedKeys();
        self.resetHighlight();
        self.deadline = Timestamp.now(io, .awake).addDuration(.fromMilliseconds(time_limit));
    } else {
        const time = Timestamp.untilNow(self.start, io, .awake);
        const kps = std.time.ns_per_s * @as(
            f32,
            @floatFromInt(self.correct),
        ) / @as(
            f32,
            @floatFromInt(time.nanoseconds),
        );

        // Go to result scene.
        return .{
            .to_result = .{
                .level = self.level,
                .ex_quota = self.ex_quota,
                .limit_time = self.limit_time,
                .sudden_death = self.sudden_death,
                .correct = self.correct,
                .miss = self.miss,
                .completed = self.completed,
                .max_combo = self.max_combo,
                .combo_bonus = self.combo_bonus,
                .time = time,
                .kps = kps,
            },
        };
    }

    return .none;
}

pub fn draw(self: *@This()) void {
    const ex = self.lesson.getExercise();
    const text = self.typed_keys.items[0 .. self.typed_keys.items.len - 1 :0];

    if (self.combo_alpha > 0) {
        common.drawText(
            self.combo_text,
            .{ .x = 400, .y = 40 },
            .center_middle,
            24,
            rl.fade(.red, self.combo_alpha),
        );
    }

    rl.drawRectangleRounded(self.highlight, 0.5, 8, .yellow);

    common.drawText(ex.display, .{ .x = 400, .y = 240 }, .center_middle, 44, .black);
    common.drawText(ex.kana, .{ .x = 400, .y = 290 }, .center_middle, 32, .dark_gray);
    common.drawText(text, .{ .x = 400, .y = 340 }, .center_middle, 32, .black);

    if (self.limit_time) {
        const width: i32 = @intCast(@divTrunc(500 * self.remaining.toMilliseconds(), time_limit));
        rl.drawRectangle(
            400 - @divTrunc(width, 2),
            550,
            width,
            10,
            .green,
        );
    }

    if (self.damage_alpha > 0.0) {
        rl.drawRectangle(
            0,
            0,
            rl.getScreenWidth(),
            rl.getScreenHeight(),
            rl.fade(.red, self.damage_alpha),
        );
    }
}
