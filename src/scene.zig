const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;
const Duration = Io.Duration;

const Title = @import("Title.zig");
const Select = @import("Select.zig");
const Setup = @import("Setup.zig");
const Play = @import("Play.zig");
const Result = @import("Result.zig");
const Level = @import("Lesson.zig").Level;

pub const Scene = union(enum) {
    title: *Title,
    select: *Select,
    setup: *Setup,
    play: *Play,
    result: *Result,

    pub fn enter(self: Scene, gpa: Allocator, io: Io, t: Transition) !void {
        switch (self) {
            .title => |title| try title.enter(gpa, io, t.to_title),
            .select => |select| try select.enter(gpa, io, t.to_select),
            .setup => |setup| try setup.enter(gpa, io, t.to_setup),
            .play => |play| try play.enter(gpa, io, t.to_play),
            .result => |result| try result.enter(gpa, io, t.to_result),
        }
    }

    pub fn leave(self: Scene, gpa: Allocator) void {
        switch (self) {
            .title => |title| title.leave(gpa),
            .select => |select| select.leave(gpa),
            .setup => |setup| setup.leave(gpa),
            .play => |play| play.leave(gpa),
            .result => |result| result.leave(gpa),
        }
    }

    pub fn update(self: @This(), io: Io) Transition {
        return switch (self) {
            .title => |title| title.update(io),
            .select => |select| select.update(io),
            .setup => |setup| setup.update(io),
            .play => |play| play.update(io),
            .result => |result| result.update(io),
        };
    }

    pub fn draw(self: @This()) void {
        switch (self) {
            .title => |title| title.draw(),
            .select => |select| select.draw(),
            .setup => |setup| setup.draw(),
            .play => |play| play.draw(),
            .result => |result| result.draw(),
        }
    }
};

pub const Transition = union(enum) {
    none,
    to_title: Data(Title),
    to_select: Data(Select),
    to_setup: Data(Setup),
    to_play: Data(Play),
    to_result: Data(Result),

    pub fn Data(comptime T: type) type {
        return switch (T) {
            Title => void,
            Select => void,
            Setup => struct { level: Level },
            Play => struct {
                level: Level,
                ex_quota: u32,
                limit_time: bool,
                sudden_death: bool,
            },
            Result => struct {
                level: Level,
                ex_quota: u32,
                limit_time: bool,
                sudden_death: bool,
                correct: u32,
                miss: u32,
                completed: u32,
                max_combo: u32,
                combo_bonus: u32,
                time: Duration,
                kps: f32,
            },
            else => @compileError("Unknown scene type."),
        };
    }
};
