const rl = @import("raylib");
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const Transition = @import("scene.zig").Transition;
const common = @import("common.zig");

level: [:0]const u8 = undefined,
correct: [:0]const u8 = undefined,
miss: [:0]const u8 = undefined,
time: [:0]const u8 = undefined,
speed: [:0]const u8 = undefined,

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
    const level_name = switch (data.level) {
        .basic => "BASIC",
        .normal => "NORMAL",
        .expert => "EXPERT",
    };

    const kps = std.time.ns_per_s * @as(f64, @floatFromInt(data.correct)) / @as(f64, @floatFromInt(data.time.nanoseconds));

    self.level = try std.fmt.allocPrintSentinel(gpa, "{s}", .{level_name}, 0);
    self.correct = try std.fmt.allocPrintSentinel(gpa, "{}", .{data.correct}, 0);
    self.miss = try std.fmt.allocPrintSentinel(gpa, "{}", .{data.miss}, 0);
    self.time = try std.fmt.allocPrintSentinel(gpa, "{f}", .{data.time}, 0);
    self.speed = try std.fmt.allocPrintSentinel(gpa, "{d:.3} KPS", .{kps}, 0);
}

pub fn leave(self: *@This(), gpa: Allocator) void {
    gpa.free(self.level);
    gpa.free(self.correct);
    gpa.free(self.miss);
    gpa.free(self.time);
    gpa.free(self.speed);
}

pub fn update(_: *@This()) !Transition {
    if (rl.getKeyPressed() == .space) {
        return .to_select;
    }

    return .none;
}

pub fn draw(self: *@This()) void {
    common.drawText("成績", .{ .x = 400, .y = 80 }, .center_middle, 48, .black);
    common.drawText("レベル:", .{ .x = 200, .y = 180 }, .left_top, 36, .black);
    common.drawText(self.level, .{ .x = 600, .y = 180 }, .right_top, 36, .black);
    common.drawText("正しいタイプ:", .{ .x = 200, .y = 225 }, .left_top, 36, .black);
    common.drawText(self.correct, .{ .x = 600, .y = 225 }, .right_top, 36, .black);
    common.drawText("ミスタイプ:", .{ .x = 200, .y = 270 }, .left_top, 36, .black);
    common.drawText(self.miss, .{ .x = 600, .y = 270 }, .right_top, 36, .black);
    common.drawText("時間:", .{ .x = 200, .y = 315 }, .left_top, 36, .black);
    common.drawText(self.time, .{ .x = 600, .y = 315 }, .right_top, 36, .black);
    common.drawText("速度:", .{ .x = 200, .y = 360 }, .left_top, 36, .black);
    common.drawText(self.speed, .{ .x = 600, .y = 360 }, .right_top, 36, .black);
    common.drawText("SPACE で次の画面へ", .{ .x = 400, .y = 540 }, .center_middle, 32, .dark_gray);
}
