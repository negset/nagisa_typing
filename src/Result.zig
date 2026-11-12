const rl = @import("raylib");
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const Transition = @import("scene.zig").Transition;
const common = @import("common.zig");

title: [:0]const u8 = undefined,
score: [:0]const u8 = undefined,
completed: [:0]const u8 = undefined,
input: [:0]const u8 = undefined,
max_combo: [:0]const u8 = undefined,
time: [:0]const u8 = undefined,
kps: [:0]const u8 = undefined,

pub fn init(_: Allocator) !@This() {
    return .{};
}

pub fn deinit(_: *@This(), _: Allocator) void {}

fn calcScore(data: Transition.Data(@This())) i64 {
    var score: i64 = switch (data.level) {
        .basic => 50,
        .normal => 75,
        .expert => 100,
    };
    const bonus = @divTrunc(score, 5);
    if (data.limit_time) score += bonus;
    if (data.sudden_death) score += bonus;
    score *= data.completed;
    score += data.combo_bonus;

    var ac: f32 = 0.0;
    if (data.correct + data.miss > 0) {
        ac = @floatFromInt(data.correct);
        ac /= @floatFromInt(data.correct + data.miss);
        ac *= ac;
    }

    var tc: f32 = switch (data.level) {
        .basic => 2.0,
        .normal => 4.0,
        .expert => 6.0,
    };
    tc *= @floatFromInt(data.completed);
    tc *= @floatFromInt(std.time.ms_per_s);
    tc /= @floatFromInt(data.time.toMilliseconds());
    tc = @sqrt(tc);

    score = @intFromFloat(@as(f32, @floatFromInt(score)) * tc * ac);

    return score;
}

pub fn enter(
    self: *@This(),
    gpa: Allocator,
    _: Io,
    data: Transition.Data(@This()),
) !void {
    const suffix = if (data.limit_time and data.sudden_death)
        " (時間制限＆一発勝負)"
    else if (data.limit_time)
        " (時間制限)"
    else if (data.sudden_death)
        " (一発勝負)"
    else
        "";
    self.title = try std.fmt.allocPrintSentinel(
        gpa,
        "{s}{s}",
        .{ data.level.toString(), suffix },
        0,
    );
    self.score = try std.fmt.allocPrintSentinel(gpa, "{d:.0}", .{calcScore(data)}, 0);
    self.completed = try std.fmt.allocPrintSentinel(gpa, "{}/{}", .{ data.completed, data.ex_quota }, 0);
    self.input = try std.fmt.allocPrintSentinel(gpa, "正 {} 誤 {}", .{ data.correct, data.miss }, 0);
    self.max_combo = try std.fmt.allocPrintSentinel(gpa, "{}", .{data.max_combo}, 0);
    self.time = try std.fmt.allocPrintSentinel(gpa, "{f}", .{data.time}, 0);
    self.kps = try std.fmt.allocPrintSentinel(gpa, "{d:.3} KPS", .{data.kps}, 0);
}

pub fn leave(self: *@This(), gpa: Allocator) void {
    gpa.free(self.title);
    gpa.free(self.score);
    gpa.free(self.completed);
    gpa.free(self.input);
    gpa.free(self.max_combo);
    gpa.free(self.time);
    gpa.free(self.kps);
}

pub fn update(_: *@This(), _: Io) Transition {
    if (rl.getKeyPressed() == .space) {
        rl.playSound(common.se_confirm);
        return .to_select;
    }

    return .none;
}

pub fn draw(self: *@This()) void {
    common.drawText("成績", .{ .x = 400, .y = 80 }, .center_middle, 48, .black);
    common.drawText(self.title, .{ .x = 400, .y = 170 }, .center_middle, 32, .black);
    common.drawText("スコア:", .{ .x = 180, .y = 235 }, .left_middle, 32, .black);
    common.drawText(self.score, .{ .x = 620, .y = 235 }, .right_middle, 32, .black);
    common.drawText("完了した問題:", .{ .x = 180, .y = 280 }, .left_middle, 32, .black);
    common.drawText(self.completed, .{ .x = 620, .y = 280 }, .right_middle, 32, .black);
    common.drawText("入力:", .{ .x = 180, .y = 325 }, .left_middle, 32, .black);
    common.drawText(self.input, .{ .x = 620, .y = 325 }, .right_middle, 32, .black);
    common.drawText("最大コンボ:", .{ .x = 180, .y = 370 }, .left_middle, 32, .black);
    common.drawText(self.max_combo, .{ .x = 620, .y = 370 }, .right_middle, 32, .black);
    common.drawText("経過時間:", .{ .x = 180, .y = 415 }, .left_middle, 32, .black);
    common.drawText(self.time, .{ .x = 620, .y = 415 }, .right_middle, 32, .black);
    common.drawText("入力速度:", .{ .x = 180, .y = 460 }, .left_middle, 32, .black);
    common.drawText(self.kps, .{ .x = 620, .y = 460 }, .right_middle, 32, .black);
    common.drawBlinkingText(&.{"\u{e000} で次の画面へ"}, .{ .x = 400, .y = 540 }, .center_middle, 32, .dark_gray);
}
