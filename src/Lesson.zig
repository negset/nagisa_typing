const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;
const Random = std.Random;

const compiler = @import("compiler.zig");
const State = compiler.State;

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

pub const Level = enum(u8) { basic, normal, expert };

// 2 ~ 6
const basic: []const Pair = &.{
    .{ .display = "蟹", .kana = "かに" },
    .{ .display = "土", .kana = "つち" },
    .{ .display = "桃", .kana = "もも" },
    .{ .display = "狸", .kana = "たぬき" },
    .{ .display = "吟味", .kana = "ぎんみ" },
    .{ .display = "酸素", .kana = "さんそ" },
    .{ .display = "土星", .kana = "どせい" },
    .{ .display = "海洋", .kana = "かいよう" },
    .{ .display = "了解", .kana = "りょうかい" },
    .{ .display = "シアター", .kana = "しあたー" },
    .{ .display = "チップス", .kana = "ちっぷす" },
    .{ .display = "傾斜", .kana = "けいしゃ" },
    .{ .display = "通販", .kana = "つうはん" },
    .{ .display = "ロンドン", .kana = "ろんどん" },
    .{ .display = "乗り越える", .kana = "のりこえる" },
    .{ .display = "ウーロン茶", .kana = "うーろんちゃ" },
    .{ .display = "札幌市", .kana = "さっぽろし" },
    .{ .display = "サイリウム", .kana = "さいりうむ" },
    .{ .display = "山手線", .kana = "やまのてせん" },
    .{ .display = "ファミリー", .kana = "ふぁみりー" },
    .{ .display = "海苔", .kana = "のり" },
    .{ .display = "形見", .kana = "かたみ" },
    .{ .display = "お祝い", .kana = "おいわい" },
    .{ .display = "ラーメン屋", .kana = "らーめんや" },
    .{ .display = "チキンカツ", .kana = "ちきんかつ" },
    .{ .display = "マイナンバー", .kana = "まいなんばー" },
    .{ .display = "ブリとハマチ", .kana = "ぶりとはまち" },
    .{ .display = "好き嫌い", .kana = "すききらい" },
    .{ .display = "ヴァイオリン", .kana = "ゔぁいおりん" },
    .{ .display = "凧あげ", .kana = "たこあげ" },
    .{ .display = "スコッチ", .kana = "すこっち" },
    .{ .display = "鍵", .kana = "かぎ" },
    .{ .display = "時と場合", .kana = "ときとばあい" },
    .{ .display = "図画工作", .kana = "ずがこうさく" },
    .{ .display = "再構築", .kana = "さいこうちく" },
    .{ .display = "原文ママ", .kana = "げんぶんまま" },
    .{ .display = "正社員", .kana = "せいしゃいん" },
    .{ .display = "土器", .kana = "どき" },
    .{ .display = "あぜ道", .kana = "あぜみち" },
    .{ .display = "パセリ", .kana = "ぱせり" },
    .{ .display = "東", .kana = "ひがし" },
    .{ .display = "ロンドン", .kana = "ろんどん" },
    .{ .display = "仲間", .kana = "なかま" },
    .{ .display = "注文", .kana = "ちゅうもん" },
    .{ .display = "スキー場", .kana = "すきーじょう" },
    .{ .display = "参観日", .kana = "さんかんび" },
    .{ .display = "単位", .kana = "たんい" },
    .{ .display = "蝋燭", .kana = "ろうそく" },
    .{ .display = "地味", .kana = "じみ" },
    .{ .display = "妻", .kana = "つま" },
    .{ .display = "謝辞", .kana = "しゃじ" },
    .{ .display = "歩く", .kana = "あるく" },
    .{ .display = "スキップ", .kana = "すきっぷ" },
    .{ .display = "月見草", .kana = "つきみそう" },
    .{ .display = "乗務員", .kana = "じょうむいん" },
    .{ .display = "良い調子", .kana = "いいちょうし" },
    .{ .display = "シャンデリア", .kana = "しゃんでりあ" },
    .{ .display = "モーリタニア", .kana = "もーりたにあ" },
    .{ .display = "ツンドラ", .kana = "つんどら" },
    .{ .display = "山", .kana = "やま" },
};

// 7 ~ 10
const normal: []const Pair = &.{
    .{ .display = "サイドステップ", .kana = "さいどすてっぷ" },
    .{ .display = "体験期間", .kana = "たいけんきかん" },
    .{ .display = "中枢神経", .kana = "ちゅうすうしんけい" },
    .{ .display = "乳しぼり体験", .kana = "ちちしぼりたいけん" },
    .{ .display = "コートジボワール", .kana = "こーとじぼわーる" },
    .{ .display = "我田引水", .kana = "がでんいんすい" },
    .{ .display = "ドラッグ＆ドロップ", .kana = "どらっぐ＆どろっぷ" },
    .{ .display = "虻蜂取らず", .kana = "あぶはちとらず" },
    .{ .display = "ちょっと待って！", .kana = "ちょっとまって！" },
    .{ .display = "夏の大三角", .kana = "なつのだいさんかく" },
    .{ .display = "サイコパス診断", .kana = "さいこぱすしんだん" },
    .{ .display = "トップバッター", .kana = "とっぷばったー" },
    .{ .display = "チュートリアル", .kana = "ちゅーとりある" },
    .{ .display = "柔術家", .kana = "じゅうじゅつか" },
    .{ .display = "ストップウォッチ", .kana = "すとっぷうぉっち" },
    .{ .display = "獅子座流星群", .kana = "ししざりゅうせいぐん" },
    .{ .display = "電動自転車", .kana = "でんどうじてんしゃ" },
    .{ .display = "アンガーマネジメント", .kana = "あんがーまねじめんと" },
    .{ .display = "ポートフォリオ", .kana = "ぽーとふぉりお" },
    .{ .display = "とんかつ定食", .kana = "とんかつていしょく" },
    .{ .display = "ご本人登場", .kana = "ごほんにんとうじょう" },
    .{ .display = "順風満帆", .kana = "じゅんぷうまんぱん" },
    .{ .display = "晴れのち曇り", .kana = "はれのちくもり" },
    .{ .display = "クエン酸配合", .kana = "くえんさんはいごう" },
    .{ .display = "株主優待券", .kana = "かぶぬしゆうたいけん" },
    .{ .display = "情報リテラシー", .kana = "じょうほうりてらしー" },
    .{ .display = "ちゃうんちゃう？", .kana = "ちゃうんちゃう？" },
    .{ .display = "スイートポテト", .kana = "すいーとぽてと" },
    .{ .display = "利用者の声", .kana = "りようしゃのこえ" },
    .{ .display = "なすの煮びたし", .kana = "なすのにびたし" },
    .{ .display = "労働基準法", .kana = "ろうどうきじゅんほう" },
    .{ .display = "ヴィンテージ加工", .kana = "ゔぃんてーじかこう" },
    .{ .display = "煙突のついた家", .kana = "えんとつのついたいえ" },
    .{ .display = "コーヒーより紅茶", .kana = "こーひーよりこうちゃ" },
    .{ .display = "月見とろろそば", .kana = "つきみとろろそば" },
    .{ .display = "最高気温３８度", .kana = "さいこうきおん３８ど" },
    .{ .display = "熱い声援", .kana = "あついせいえん" },
    .{ .display = "正直ベース", .kana = "しょうじきべーす" },
    .{ .display = "連絡待ってるよ！", .kana = "れんらくまってるよ！" },
    .{ .display = "エックス線検査", .kana = "えっくすせんけんさ" },
    .{ .display = "最高機密", .kana = "さいこうきみつ" },
    .{ .display = "地図が読めない", .kana = "ちずがよめない" },
    .{ .display = "肩たたき券進呈", .kana = "かたたきけんしんてい" },
    .{ .display = "寝る子は育つ", .kana = "ねるこはそだつ" },
    .{ .display = "いつ見てもキレイだな", .kana = "いつみてもきれいだな" },
    .{ .display = "諦めたら駄目", .kana = "あきらめたらだめ" },
    .{ .display = "コンピューター", .kana = "こんぴゅーたー" },
    .{ .display = "杏仁豆腐", .kana = "あんにんどうふ" },
    .{ .display = "国立図書館", .kana = "こくりつとしょかん" },
    .{ .display = "テレビのリモコン", .kana = "てれびのりもこん" },
    .{ .display = "大将のおすすめ", .kana = "たいしょうのおすすめ" },
    .{ .display = "日焼け止めクリーム", .kana = "ひやけどめくりーむ" },
    .{ .display = "ホッと一息", .kana = "ほっとひといき" },
    .{ .display = "リトマス試験紙", .kana = "りとますしけんし" },
    .{ .display = "華の金曜日", .kana = "はなのきんようび" },
    .{ .display = "ピーナッツバター", .kana = "ぴーなっつばたー" },
    .{ .display = "松明の明かり", .kana = "たいまつのあかり" },
    .{ .display = "血に飢えた獣たち", .kana = "ちにうえたけものたち" },
    .{ .display = "来世は虫が良い", .kana = "らいせはむしがいい" },
    .{ .display = "明日天気にな～れ", .kana = "あしたてんきにな～れ" },
};

// 11 ~
const expert: []const Pair = &.{
    .{ .display = "エレベーターが故障中", .kana = "えれべーたーがこしょうちゅう" },
    .{ .display = "隣の客はよく柿食う客だ", .kana = "となりのきゃくはよくかきくうきゃくだ" },
    .{ .display = "東海道新幹線", .kana = "とうかいどうしんかんせん" },
    .{ .display = "二兎追うものは一兎をも得ず", .kana = "にとおうものはいっとをもえず" },
    .{ .display = "ブルータス、お前もか", .kana = "ぶるーたす、おまえもか" },
    .{ .display = "本日は営業しております", .kana = "ほんじつはえいぎょうしております" },
    .{ .display = "ずっと好きだったのに。", .kana = "ずっとすきだったのに。" },
    .{ .display = "赤パジャマ青パジャマ黄パジャマ", .kana = "あかぱじゃまあおぱじゃまきぱじゃま" },
    .{ .display = "改札を出て左に直進", .kana = "かいさつをでてひだりにちょくしん" },
    .{ .display = "中央卸売市場", .kana = "ちゅうおうおろしうりしじょう" },
    .{ .display = "おすすめの整骨院を教えて", .kana = "おすすめのせいこついんをおしえて" },
    .{ .display = "わかりづらいよ、倒置法は。", .kana = "わかりづらいよ、とうちほうは。" },
    .{ .display = "六方最密充填", .kana = "ろっぽうさいみつじゅうてん" },
    .{ .display = "花火大会は今週の日曜だ", .kana = "はなびたいかいはこんしゅうのにちようだ" },
    .{ .display = "庭でツチノコを見つけたよ", .kana = "にわでつちのこをみつけたよ" },
    .{ .display = "チーズバーガーとポテトとナゲット", .kana = "ちーずばーがーとぽてととなげっと" },
    .{ .display = "今お電話大丈夫ですか？", .kana = "いまおでんわだいじょうぶですか？" },
    .{ .display = "救急救命士の資格を取る", .kana = "きゅうきゅうきゅうめいしのしかくをとる" },
    .{ .display = "１００円ショップでアルバイト", .kana = "１００えんしょっぷであるばいと" },
    .{ .display = "登っても登っても高い山", .kana = "のぼってものぼってもたかいやま" },
    .{ .display = "燃えるゴミと燃えないゴミ", .kana = "もえるごみともえないごみ" },
    .{ .display = "ヴィクトリア朝の遺産", .kana = "ゔぃくとりあちょうのいさん" },
    .{ .display = "百害あって一利なし", .kana = "ひゃくがいあっていちりなし" },
    .{ .display = "塩分過多に気を付ける", .kana = "えんぶんかたにきをつける" },
    .{ .display = "本人評価額は３００万円", .kana = "ほんにんひょうかがくは３００まんえん" },
    .{ .display = "立つ鳥跡を濁さず", .kana = "たつとりあとをにごさず" },
    .{ .display = "最終審査に合格する", .kana = "さいしゅうしんさにごうかくする" },
    .{ .display = "よろしくお願い申し上げます。", .kana = "よろしくおねがいもうしあげます。" },
    .{ .display = "もしもし？聞こえてる？", .kana = "もしもし？きこえてる？" },
    .{ .display = "新人社員研修", .kana = "しんじんしゃいんけんしゅう" },
    .{ .display = "お気持ちだけで結構です", .kana = "おきもちだけでけっこうです" },
    .{ .display = "フリーダイヤル０１２０", .kana = "ふりーだいやる０１２０" },
    .{ .display = "昭和世代と令和世代", .kana = "しょうわせだいとれいわせだい" },
    .{ .display = "意気投合して連絡先を交換", .kana = "いきとうごうしてれんらくさきをこうかん" },
    .{ .display = "公務執行妨害", .kana = "こうむしっこうぼうがい" },
    .{ .display = "フォークリフトを乗り回す", .kana = "ふぉーくりふとをのりまわす" },
    .{ .display = "最寄り駅の一つ手前で降りる", .kana = "もよりえきのひとつてまえでおりる" },
    .{ .display = "地球温暖化対策", .kana = "ちきゅうおんだんかたいさく" },
    .{ .display = "両親の結婚記念日", .kana = "りょうしんのけっこんきねんび" },
    .{ .display = "タイピングには自信があります", .kana = "たいぴんぐにはじしんがあります" },
    .{ .display = "バッティングセンターに通う", .kana = "ばってぃんぐせんたーにかよう" },
    .{ .display = "楽しかった修学旅行", .kana = "たのしかったしゅうがくりょこう" },
    .{ .display = "お土産に木刀を買う", .kana = "おみやげにぼくとうをかう" },
    .{ .display = "いい時計してはりますなぁ", .kana = "いいとけいしてはりますなぁ" },
    .{ .display = "「もういいかい？」「もういいよ」", .kana = "「もういいかい？」「もういいよ」" },
    .{ .display = "ディスカッションで司会を担当", .kana = "でぃすかっしょんでしかいをたんとう" },
    .{ .display = "最近あった嬉しいこと", .kana = "さいきんあったうれしいこと" },
    .{ .display = "長年の疑問が解消する", .kana = "ながねんのぎもんがかいしょうする" },
    .{ .display = "次に会うときはお互い敵だ", .kana = "つぎにあうときはおたがいてきだ" },
    .{ .display = "夜食にカップ焼きそば", .kana = "やしょくにかっぷやきそば" },
    .{ .display = "通勤時間を有効活用", .kana = "つうきんじかんをゆうこうかつよう" },
    .{ .display = "因幡の白兎", .kana = "いなばのしろうさぎ" },
    .{ .display = "桃から生まれた桃太郎", .kana = "ももからうまれたももたろう" },
    .{ .display = "己の無知を自覚する", .kana = "おのれのむちをじかくする" },
    .{ .display = "お子様ランチの旗を集める", .kana = "おこさまらんちのはたをあつめる" },
    .{ .display = "さあ行こう、新たな世界へ！", .kana = "さあいこう、あらたなせかいへ！" },
    .{ .display = "忙しい日々を送るあなたに", .kana = "いそがしいひびをおくるあなたに" },
    .{ .display = "老若男女が楽しめる映画", .kana = "ろうにゃくなんにょがたのしめるえいが" },
    .{ .display = "この先通行止めです", .kana = "このさきつうこうどめです" },
    .{ .display = "コンビニスイーツを買って帰る", .kana = "こんびにすいーつをかってかえる" },
};

const Pair = struct {
    display: [:0]const u8,
    kana: [:0]const u8,
};

fn init(gpa: Allocator, io: Io, pairs: []const Pair) !@This() {
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

pub fn initByLevel(gpa: Allocator, io: Io, level: Level) !@This() {
    return switch (level) {
        .basic => init(gpa, io, basic),
        .normal => init(gpa, io, normal),
        .expert => init(gpa, io, expert),
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
