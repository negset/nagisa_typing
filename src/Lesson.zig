exercises: []Exercise,
current_exercise: usize = 0,

const std = @import("std");
const Allocator = std.mem.Allocator;

const compiler = @import("compiler.zig");
const State = compiler.State;

pub const Exercise = struct {
    display: [:0]const u8,
    kana: [:0]const u8,
    states: []State,
    current_state: usize = 0,

    pub fn init(
        gpa: Allocator,
        comptime display: [:0]const u8,
        comptime kana: [:0]const u8,
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

    pub fn transition(self: *@This(), key: u8) bool {
        var current = self.getState();

        if (current.transition(key)) |next| {
            self.current_state = next;
            return true;
        }

        // Epsilon transition.
        if (current.transition(0)) |epsilon| {
            current = self.states[epsilon];

            if (current.transition(key)) |next| {
                self.current_state = next;
                return true;
            }
        }

        return false;
    }
};

pub const Level = enum { basic, normal, expert };

fn init(gpa: Allocator, args: anytype) !@This() {
    const exercises = try gpa.alloc(Exercise, args.len);
    inline for (args, 0..) |pair, i| {
        const display, const kana = pair;
        exercises[i] = try .init(gpa, display, kana);
    }
    return .{
        .exercises = exercises,
    };
}

fn initBasic(gpa: Allocator) !@This() {
    return init(gpa, .{
        .{ "蟹", "かに" },
        .{ "土", "つち" },
        .{ "桃", "もも" },
        .{ "狸", "たぬき" },
        .{ "吟味", "ぎんみ" },
        .{ "酸素", "さんそ" },
        .{ "土星", "どせい" },
        .{ "海洋", "かいよう" },
        .{ "了解", "りょうかい" },
        .{ "シアター", "しあたー" },
        .{ "チップス", "ちっぷす" },
        .{ "傾斜", "けいしゃ" },
        .{ "通販", "つうはん" },
        .{ "ロンドン", "ろんどん" },
        .{ "乗り越える", "のりこえる" },
        .{ "ウーロン茶", "うーろんちゃ" },
        .{ "札幌市", "さっぽろし" },
        .{ "サイリウム", "さいりうむ" },
        .{ "山手線", "やまのてせん" },
        .{ "ファミリー", "ふぁみりー" },
    });
}

fn initNormal(gpa: Allocator) !@This() {
    return init(gpa, .{
        .{ "サイドステップ", "さいどすてっぷ" },
        .{ "体験期間", "たいけんきかん" },
        .{ "中枢神経", "ちゅうすうしんけい" },
        .{ "乳しぼり体験", "ちちしぼりたいけん" },
        .{ "コートジボワール", "こーとじぼわーる" },
        .{ "我田引水", "がでんいんすい" },
        .{ "ドラッグ＆ドロップ", "どらっぐ＆どろっぷ" },
        .{ "虻蜂取らず", "あぶはちとらず" },
        .{ "ちょっと待って！", "ちょっとまって！" },
        .{ "夏の大三角", "なつのだいさんかく" },
        .{ "サイコパス診断", "さいこぱすしんだん" },
        .{ "トップバッター", "とっぷばったー" },
        .{ "チュートリアル", "ちゅーとりある" },
        .{ "柔術家", "じゅうじゅつか" },
        .{ "ストップウォッチ", "すとっぷうぉっち" },
        .{ "獅子座流星群", "ししざりゅうせいぐん" },
        .{ "電動自転車", "でんどうじてんしゃ" },
        .{ "アンガーマネジメント", "あんがーまねじめんと" },
        .{ "ポートフォリオ", "ぽーとふぉりお" },
        .{ "とんかつ定食", "とんかつていしょく" },
    });
}

fn initExpert(gpa: Allocator) !@This() {
    return init(gpa, .{
        .{ "エレベーターが故障中", "えれべーたーがこしょうちゅう" },
        .{ "隣の客はよく柿食う客だ", "となりのきゃくはよくかきくうきゃくだ" },
        .{ "東海道新幹線", "とうかいどうしんかんせん" },
        .{ "二兎追うものは一兎をも得ず", "にとおうものはいっとをもえず" },
        .{ "ブルータス、お前もか", "ぶるーたす、おまえもか" },
        .{ "本日は営業しております", "ほんじつはえいぎょうしております" },
        .{ "ずっと好きだったのに。", "ずっとすきだったのに。" },
        .{ "赤パジャマ青パジャマ黄パジャマ", "あかぱじゃまあおぱじゃまきぱじゃま" },
        .{ "改札を出て左に直進", "かいさつをでてひだりにちょくしん" },
        .{ "中央卸売市場", "ちゅうおうおろしうりしじょう" },
        .{ "おすすめの整骨院を紹介して", "おすすめのせいこついんをしょうかいして" },
        .{ "わかりづらいよ、倒置法は。", "わかりづらいよ、とうちほうは。" },
        .{ "六方最密充填", "ろっぽうさいみつじゅうてん" },
        .{ "花火大会は今週の日曜だ", "はなびたいかいはこんしゅうのにちようだ" },
        .{ "庭でツチノコを見つけたよ", "にわでつちのこをみつけたよ" },
        .{ "チーズバーガーとポテトとナゲット", "ちーずばーがーとぽてととなげっと" },
        .{ "今お電話大丈夫ですか？", "いまおでんわだいじょうぶですか？" },
        .{ "救急救命士の資格を取る", "きゅうきゅうきゅうめいしのしかくをとる" },
        .{ "１００円ショップでアルバイト", "１００えんしょっぷであるばいと" },
        .{ "登っても登っても高い山", "のぼってものぼってもたかいやま" },
    });
}

pub fn initByLevel(gpa: Allocator, level: Level) !@This() {
    return switch (level) {
        .basic => initBasic(gpa),
        .normal => initNormal(gpa),
        .expert => initExpert(gpa),
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

pub fn goNextExercise(self: *@This()) bool {
    self.getExercise().current_state = 0;
    if (self.current_exercise < self.exercises.len - 1) {
        self.current_exercise += 1;
        return true;
    }
    return false;
}
