const rl = @import("raylib");
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const Transition = @import("scene.zig").Transition;
const common = @import("common.zig");

level: [:0]const u8 = undefined,
correct: [:0]const u8 = undefined,
miss: [:0]const u8 = undefined,
max_combo: [:0]const u8 = undefined,
time: [:0]const u8 = undefined,
kps: [:0]const u8 = undefined,
score: [:0]const u8 = undefined,

pub fn init(_: Allocator) !@This() {
    return .{};
}

pub fn deinit(_: *@This(), _: Allocator) void {}

pub fn enter(
    self: *@This(),
    gpa: Allocator,
    _: Io,
    data: Transition.Data(@This()),
) !void {
    self.level = data.level.toString();
    self.correct = try std.fmt.allocPrintSentinel(gpa, "{}", .{data.correct}, 0);
    self.miss = try std.fmt.allocPrintSentinel(gpa, "{}", .{data.miss}, 0);
    self.max_combo = try std.fmt.allocPrintSentinel(gpa, "{}", .{data.max_combo}, 0);
    self.time = try std.fmt.allocPrintSentinel(gpa, "{f}", .{data.time}, 0);
    self.kps = try std.fmt.allocPrintSentinel(gpa, "{d:.3} KPS", .{data.kps}, 0);
    self.score = try std.fmt.allocPrintSentinel(gpa, "{}", .{data.score}, 0);
}

pub fn leave(self: *@This(), gpa: Allocator) void {
    gpa.free(self.correct);
    gpa.free(self.miss);
    gpa.free(self.max_combo);
    gpa.free(self.time);
    gpa.free(self.kps);
    gpa.free(self.score);
}

pub fn update(_: *@This()) !Transition {
    if (rl.getKeyPressed() == .space) {
        rl.playSound(common.se_confirm);
        return .to_select;
    }

    return .none;
}

pub fn draw(self: *@This()) void {
    common.drawText("成績", .{ .x = 400, .y = 80 }, .center_middle, 48, .black);
    common.drawText("レベル:", .{ .x = 180, .y = 160 }, .left_top, 32, .black);
    common.drawText(self.level, .{ .x = 620, .y = 160 }, .right_top, 32, .black);
    common.drawText("正しい入力:", .{ .x = 180, .y = 205 }, .left_top, 32, .black);
    common.drawText(self.correct, .{ .x = 620, .y = 205 }, .right_top, 32, .black);
    common.drawText("ミス入力:", .{ .x = 180, .y = 250 }, .left_top, 32, .black);
    common.drawText(self.miss, .{ .x = 620, .y = 250 }, .right_top, 32, .black);
    common.drawText("最大コンボ:", .{ .x = 180, .y = 295 }, .left_top, 32, .black);
    common.drawText(self.max_combo, .{ .x = 620, .y = 295 }, .right_top, 32, .black);
    common.drawText("経過時間:", .{ .x = 180, .y = 340 }, .left_top, 32, .black);
    common.drawText(self.time, .{ .x = 620, .y = 340 }, .right_top, 32, .black);
    common.drawText("入力速度:", .{ .x = 180, .y = 385 }, .left_top, 32, .black);
    common.drawText(self.kps, .{ .x = 620, .y = 385 }, .right_top, 32, .black);
    common.drawText("スコア:", .{ .x = 180, .y = 430 }, .left_top, 32, .black);
    common.drawText(self.score, .{ .x = 620, .y = 430 }, .right_top, 32, .black);
    common.drawText("SPACE で次の画面へ", .{ .x = 400, .y = 540 }, .center_middle, 32, .dark_gray);
}
