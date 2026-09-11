const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;
const Duration = Io.Duration;

const Title = @import("title.zig");
const Select = @import("select.zig");
const Play = @import("Play.zig");
const Result = @import("Result.zig");
const Level = @import("Lesson.zig").Level;

pub const Scene = union(enum) {
    title: *Title,
    select: *Select,
    play: *Play,
    result: *Result,

    pub fn enter(self: Scene, gpa: Allocator, io: Io, t: Transition) !void {
        switch (self) {
            .title => |scene| try scene.enter(gpa, io, t.to_title),
            .select => |scene| try scene.enter(gpa, io, t.to_select),
            .play => |scene| try scene.enter(gpa, io, t.to_play),
            .result => |scene| try scene.enter(gpa, io, t.to_result),
        }
    }

    pub fn leave(self: Scene, gpa: Allocator) void {
        switch (self) {
            .title => |scene| scene.leave(gpa),
            .select => |scene| scene.leave(gpa),
            .play => |scene| scene.leave(gpa),
            .result => |scene| scene.leave(gpa),
        }
    }
};

pub const Transition = union(enum) {
    none,
    to_title: Data(Title),
    to_select: Data(Select),
    to_play: Data(Play),
    to_result: Data(Result),

    pub fn Data(comptime T: type) type {
        return switch (T) {
            Title => void,
            Select => struct { cursor: u8 = 0 },
            Play => struct { level: Level },
            Result => struct { level: Level, correct: u32, miss: u32, time: Duration },
            else => @compileError("Unknown scene type."),
        };
    }
};
