const Exercise = struct {
    display: [:0]const u8,
    kana: [:0]const u8,
};

pub const exercises: []const Exercise = &.{
    .{ .display = "こんにちは、世界！", .kana = "こんにちは、せかい！" },
    .{ .display = "隣の客はよく柿食う客だ", .kana = "となりのきゃくはよくかきくうきゃくだ" },
    .{ .display = "東海道新幹線", .kana = "とうかいどうしんかんせん" },
    .{ .display = "毒食わば皿まで", .kana = "どくくわばさらまで" },
    .{ .display = "コートジボワール", .kana = "こーとじぼわーる" },
};
