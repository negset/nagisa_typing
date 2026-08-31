const rl = @import("raylib");
const std = @import("std");
const Allocator = std.mem.Allocator;

const Transition = @import("main.zig").Transition;
const utils = @import("utils.zig");

level: [:0]const u8 = undefined,
correct: [:0]const u8 = undefined,
miss: [:0]const u8 = undefined,

pub fn init(_: Allocator) !@This() {
    return .{};
}

pub fn deinit(_: *@This(), _: Allocator) void {}

pub fn enter(self: *@This(), gpa: Allocator, data: @FieldType(Transition, "to_result")) !void {
    self.level = try std.fmt.allocPrintSentinel(gpa, "{s}", .{switch (data.level) {
        .basic => "BASIC",
        .normal => "NORMAL",
        .expert => "EXPERT",
    }}, 0);
    self.correct = try std.fmt.allocPrintSentinel(gpa, "{}", .{data.correct}, 0);
    self.miss = try std.fmt.allocPrintSentinel(gpa, "{}", .{data.miss}, 0);
}

pub fn leave(self: *@This(), gpa: Allocator) void {
    gpa.free(self.level);
    gpa.free(self.correct);
    gpa.free(self.miss);
}

pub fn update(_: *@This()) !Transition {
    if (rl.getKeyPressed() == .space)
        return .{ .to_select = .{} };

    return .none;
}

pub fn draw(self: *@This()) void {
    utils.drawText("成績", .{ .x = 400, .y = 80 }, .center_middle, 48, .black);
    utils.drawText("レベル:", .{ .x = 200, .y = 180 }, .left_top, 36, .black);
    utils.drawText(self.level, .{ .x = 600, .y = 180 }, .right_top, 36, .black);
    utils.drawText("正しいタイプ:", .{ .x = 200, .y = 225 }, .left_top, 36, .black);
    utils.drawText(self.correct, .{ .x = 600, .y = 225 }, .right_top, 36, .black);
    utils.drawText("ミスタイプ:", .{ .x = 200, .y = 270 }, .left_top, 36, .black);
    utils.drawText(self.miss, .{ .x = 600, .y = 270 }, .right_top, 36, .black);
    utils.drawText("SPACE で次の画面へ", .{ .x = 400, .y = 540 }, .center_middle, 32, .dark_gray);
}
