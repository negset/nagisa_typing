const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;
const Random = std.Random;

const compiler = @import("compiler.zig");
const State = compiler.State;
const loader = @import("loader.zig");
const Pair = loader.Pair;

exercises: []Exercise,
current_exercise: usize = 0,

pub const Exercise = struct {
    display: [:0]const u8,
    kana: [:0]const u8,
    states: []State,
    current_state: usize = 0,

    pub fn init(
        gpa: Allocator,
        display: [:0]const u8,
        kana: [:0]const u8,
    ) !@This() {
        return .{
            .display = display,
            .kana = kana,
            .states = try compiler.compile(gpa, kana),
        };
    }

    pub fn deinit(self: @This(), gpa: Allocator) void {
        for (self.states) |state| {
            state.deinit(gpa);
        }
        gpa.free(self.states);
    }

    pub fn getState(self: @This()) State {
        return self.states[self.current_state];
    }
};

pub const Level = enum(u8) {
    basic,
    normal,
    expert,

    pub fn toString(self: Level) [:0]const u8 {
        return switch (self) {
            .basic => "BASIC",
            .normal => "NORMAL",
            .expert => "EXPERT",
        };
    }

    pub fn path(self: Level) []const u8 {
        return "resources/" ++ self.toString() ++ ".csv";
    }
};

pub fn init(gpa: Allocator, io: Io, level: Level) !@This() {
    const pairs = loader.getPairs(level);

    const rand_source: Random.IoSource = .{ .io = io };
    const rand = rand_source.interface();

    var indices = try gpa.alloc(usize, pairs.len);
    defer gpa.free(indices);

    for (indices, 0..) |_, i| {
        indices[i] = i;
    }

    rand.shuffle(usize, indices);

    const ex_quota = @min(pairs.len, 20);
    const exercises = try gpa.alloc(Exercise, ex_quota);
    errdefer gpa.free(exercises);

    for (indices[0..ex_quota], 0..) |index, i| {
        const pair = pairs[index];
        exercises[i] = try .init(gpa, pair.display, pair.kana);
    }

    return .{
        .exercises = exercises,
    };
}

pub fn deinit(self: @This(), gpa: Allocator) void {
    for (self.exercises) |exercise| {
        exercise.deinit(gpa);
    }
    gpa.free(self.exercises);
}

pub fn getExercise(self: @This()) *Exercise {
    return &self.exercises[self.current_exercise];
}
