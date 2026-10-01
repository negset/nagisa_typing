const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Io = std.Io;
const zig_csv = @import("zig_csv");
const STable = zig_csv.StructuredTable(
    struct {
        display: []const u8,
        kana: []const u8,
    },
);

const Level = @import("Lesson.zig").Level;

pub const Pair = struct {
    display: [:0]const u8,
    kana: [:0]const u8,

    fn init(gpa: Allocator, display: []const u8, kana: []const u8) !@This() {
        return .{
            .display = try gpa.dupeSentinel(u8, display, 0),
            .kana = try gpa.dupeSentinel(u8, kana, 0),
        };
    }

    fn deinit(self: *@This(), gpa: Allocator) void {
        gpa.free(self.display);
        gpa.free(self.kana);
    }
};

const level_len = std.meta.fields(Level).len;
pub var pairs_array: [level_len][]Pair = undefined;

fn load(gpa: Allocator, io: Io, comptime path: []const u8) ![]Pair {
    const content = try Io.Dir.cwd().readFileAlloc(
        io,
        path,
        gpa,
        .limited(2 * 1024 * 1024), // Max 2 MiB.
    );
    defer gpa.free(content);

    var table: STable = .init(gpa, .default());
    defer table.deinit();

    try table.parse(content);

    const count = table.getRowCount();
    var result: ArrayList(Pair) = try .initCapacity(gpa, count);

    for (0..count) |i| {
        switch (try table.getRow(i)) {
            .ok => |ok| {
                result.appendAssumeCapacity(try .init(
                    gpa,
                    ok.value.display,
                    ok.value.kana,
                ));
            },
            .@"error" => @panic("Unexpected table row."),
        }
    }

    return result.toOwnedSliceAssert();
}

pub fn loadAll(gpa: Allocator, io: Io) !void {
    inline for (std.meta.fields(Level), 0..) |field, i| {
        const level: Level = @enumFromInt(field.value);
        pairs_array[i] = try load(gpa, io, level.path());

        errdefer {
            for (pairs_array[i]) |*pair| pair.deinit(gpa);
            gpa.free(pairs_array[i]);
        }
    }
}

pub fn getPairs(level: Level) []const Pair {
    return pairs_array[@intFromEnum(level)];
}

pub fn deinit(gpa: Allocator) void {
    for (pairs_array) |level_pairs| {
        for (level_pairs) |*pair| pair.deinit(gpa);
        gpa.free(level_pairs);
    }
}
