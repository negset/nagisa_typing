const std = @import("std");
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
const Diagnostics = std.zon.parse.Diagnostics;
const Io = std.Io;

const Level = @import("Lesson.zig").Level;

pub const Schema = [][2][:0]const u8;

var arena_allocator: ArenaAllocator = undefined;
const level_len = std.enums.values(Level).len;
pub var data: [level_len]Schema = undefined;

pub fn init(gpa: Allocator, io: Io) !void {
    arena_allocator = .init(gpa);

    inline for (std.enums.values(Level)) |level| {
        const path = comptime level.path();
        data[@intFromEnum(level)] = try load(gpa, io, path);
    }
}

pub fn deinit() void {
    arena_allocator.deinit();
}

pub fn getData(level: Level) Schema {
    return data[@intFromEnum(level)];
}

fn load(gpa: Allocator, io: Io, path: []const u8) !Schema {
    const arena = arena_allocator.allocator();

    const source = try Io.Dir.cwd().readFileAllocOptions(
        io,
        path,
        gpa,
        .limited(2 * 1024 * 1024), // Max 2 MiB.
        .of(u8),
        0,
    );
    defer gpa.free(source);

    var diagnostics: Diagnostics = undefined;
    return std.zon.parse.fromSlice(Schema, .{
        .gpa = gpa,
        .arena = arena,
        .source = source,
        .diagnostics = &diagnostics,
    }) catch |err| switch (err) {
        error.OutOfMemory => return err,
        error.ParseZon => {
            diagnostics.log(path);
            return err;
        },
    };
}
