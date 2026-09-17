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

// 2 ~ 6
const basic: []const Pair = &.{
    .{ .display = "蟹", .kana = "かに" },
    .{ .display = "土", .kana = "つち" },
    .{ .display = "桃", .kana = "もも" },
    .{ .display = "狸", .kana = "たぬき" },
    .{ .display = "吟味", .kana = "ぎんみ" },
    .{ .display = "酸素", .kana = "さんそ" },
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
    .{ .display = "お宝", .kana = "おたから" },
    .{ .display = "鯖", .kana = "さば" },
    .{ .display = "短冊", .kana = "たんざく" },
    .{ .display = "観音様", .kana = "かんのんさま" },
    .{ .display = "大丈夫", .kana = "だいじょうぶ" },
    .{ .display = "見つかった", .kana = "みつかった" },
    .{ .display = "シャワー", .kana = "しゃわー" },
    .{ .display = "死屍累々", .kana = "ししるいるい" },
    .{ .display = "名声", .kana = "めいせい" },
    .{ .display = "天秤座", .kana = "てんびんざ" },
    .{ .display = "朝食", .kana = "ちょうしょく" },
    .{ .display = "引き戸", .kana = "ひきど" },
    .{ .display = "牛乳", .kana = "ぎゅうにゅう" },
    .{ .display = "金継ぎ", .kana = "きんつぎ" },
    .{ .display = "報告", .kana = "ほうこく" },
    .{ .display = "クォーツ", .kana = "くぉーつ" },
    .{ .display = "ポシェット", .kana = "ぽしぇっと" },
    .{ .display = "過去", .kana = "かこ" },
    .{ .display = "黄泉", .kana = "よみ" },
    .{ .display = "尼", .kana = "あま" },
    .{ .display = "衛星", .kana = "えいせい" },
    .{ .display = "ロコモコ", .kana = "ろこもこ" },
    .{ .display = "ゴシック", .kana = "ごしっく" },
    .{ .display = "魂", .kana = "たましい" },
    .{ .display = "エンドウ豆", .kana = "えんどうまめ" },
    .{ .display = "金髪", .kana = "きんぱつ" },
    .{ .display = "卵焼き", .kana = "たまごやき" },
    .{ .display = "修行僧", .kana = "しゅぎょうそう" },
    .{ .display = "黒板消し", .kana = "こくばんけし" },
    .{ .display = "節電", .kana = "せつでん" },
    .{ .display = "夜空", .kana = "よぞら" },
    .{ .display = "お財布", .kana = "おさいふ" },
    .{ .display = "缶コーヒー", .kana = "かんこーひー" },
    .{ .display = "タッチペン", .kana = "たっちぺん" },
    .{ .display = "フォロー", .kana = "ふぉろー" },
    .{ .display = "お勘定", .kana = "おかんじょう" },
    .{ .display = "定期券", .kana = "ていきけん" },
    .{ .display = "機種変更", .kana = "きしゅへんこう" },
    .{ .display = "方位磁石", .kana = "ほういじしゃく" },
    .{ .display = "海の家", .kana = "うみのいえ" },
    .{ .display = "熱気球", .kana = "ねつききゅう" },
};

// 7 ~ 11
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
    .{ .display = "ニンニク入れますか？", .kana = "にんにくいれますか？" },
    .{ .display = "快方に向かう", .kana = "かいほうにむかう" },
    .{ .display = "夕張メロン", .kana = "ゆうばりめろん" },
    .{ .display = "野放しにするな", .kana = "のばなしにするな" },
    .{ .display = "食器用洗剤", .kana = "しょっきようせんざい" },
    .{ .display = "ブルータス、お前もか", .kana = "ぶるーたす、おまえもか" },
    .{ .display = "ずっと好きだったのに。", .kana = "ずっとすきだったのに。" },
    .{ .display = "立つ鳥跡を濁さず", .kana = "たつとりあとをにごさず" },
    .{ .display = "公務執行妨害", .kana = "こうむしっこうぼうがい" },
    .{ .display = "フリーダイヤル０１２０", .kana = "ふりーだいやる０１２０" },
    .{ .display = "因幡の白兎", .kana = "いなばのしろうさぎ" },
    .{ .display = "大盛り無料", .kana = "おおもりむりょう" },
    .{ .display = "ノールックパス", .kana = "のーるっくぱす" },
    .{ .display = "みどりの窓口", .kana = "みどりのまどぐち" },
    .{ .display = "みんな友達", .kana = "みんなともだち" },
    .{ .display = "這う這うの体", .kana = "ほうほうのてい" },
    .{ .display = "装備していくかい？", .kana = "そうびしていくかい？" },
    .{ .display = "パスワードを忘れた", .kana = "ぱすわーどをわすれた" },
    .{ .display = "レジ袋有料化", .kana = "れじぶくろゆうりょうか" },
    .{ .display = "高輪ゲートウェイ", .kana = "たかなわげーとうぇい" },
    .{ .display = "二度漬け禁止", .kana = "にどづけきんし" },
    .{ .display = "鬼は外、福は内", .kana = "おにはそと、ふくはうち" },
    .{ .display = "行き場のない怒り", .kana = "いきばのないいかり" },
    .{ .display = "良い子はマネしないでね", .kana = "よいこはまねしないでね" },
    .{ .display = "溜飲を下げる", .kana = "りゅういんをさげる" },
    .{ .display = "緑黄色野菜", .kana = "りょくおうしょくやさい" },
    .{ .display = "有機剥き栗", .kana = "ゆうきむきぐり" },
    .{ .display = "アフタヌーンティー", .kana = "あふたぬーんてぃー" },
    .{ .display = "ひよこ鑑定士", .kana = "ひよこかんていし" },
    .{ .display = "竜の逆鱗", .kana = "りゅうのげきりん" },
    .{ .display = "ポルターガイスト", .kana = "ぽるたーがいすと" },
    .{ .display = "斬り捨て御免", .kana = "きりすてごめん" },
    .{ .display = "学校の七不思議", .kana = "がっこうのななふしぎ" },
    .{ .display = "高度経済成長", .kana = "こうどけいざいせいちょう" },
    .{ .display = "東洋の魔女", .kana = "とうようのまじょ" },
    .{ .display = "大は小を兼ねる", .kana = "だいはしょうをかねる" },
    .{ .display = "良くも悪くも", .kana = "よくもわるくも" },
    .{ .display = "料理のさしすせそ", .kana = "りょうりのさしすせそ" },
    .{ .display = "長所と短所", .kana = "ちょうしょとたんしょ" },
    .{ .display = "そんな馬鹿な！？", .kana = "そんなばかな！？" },
};

// 12 ~
const expert: []const Pair = &.{
    .{ .display = "エレベーターが故障中", .kana = "えれべーたーがこしょうちゅう" },
    .{ .display = "隣の客はよく柿食う客だ", .kana = "となりのきゃくはよくかきくうきゃくだ" },
    .{ .display = "東海道新幹線", .kana = "とうかいどうしんかんせん" },
    .{ .display = "二兎追うものは一兎をも得ず", .kana = "にとおうものはいっとをもえず" },
    .{ .display = "本日は営業しております", .kana = "ほんじつはえいぎょうしております" },
    .{ .display = "赤パジャマ青パジャマ黄パジャマ", .kana = "あかぱじゃまあおぱじゃまきぱじゃま" },
    .{ .display = "改札を出て左に直進", .kana = "かいさつをでてひだりにちょくしん" },
    .{ .display = "中央卸売市場", .kana = "ちゅうおうおろしうりしじょう" },
    .{ .display = "おすすめの整骨院を教えて", .kana = "おすすめのせいこついんをおしえて" },
    .{ .display = "わかりづらいよ、倒置法は。", .kana = "わかりづらいよ、とうちほうは。" },
    .{ .display = "六方最密充填", .kana = "ろっぽうさいみつじゅうてん" },
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
    .{ .display = "最終審査に合格する", .kana = "さいしゅうしんさにごうかくする" },
    .{ .display = "よろしくお願い申し上げます。", .kana = "よろしくおねがいもうしあげます。" },
    .{ .display = "もしもし？聞こえてる？", .kana = "もしもし？きこえてる？" },
    .{ .display = "新人社員研修", .kana = "しんじんしゃいんけんしゅう" },
    .{ .display = "お気持ちだけで結構です", .kana = "おきもちだけでけっこうです" },
    .{ .display = "昭和世代と令和世代", .kana = "しょうわせだいとれいわせだい" },
    .{ .display = "意気投合して連絡先を交換", .kana = "いきとうごうしてれんらくさきをこうかん" },
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
    .{ .display = "桃から生まれた桃太郎", .kana = "ももからうまれたももたろう" },
    .{ .display = "己の無知を自覚する", .kana = "おのれのむちをじかくする" },
    .{ .display = "お子様ランチの旗を集める", .kana = "おこさまらんちのはたをあつめる" },
    .{ .display = "さあ行こう、新たな世界へ！", .kana = "さあいこう、あらたなせかいへ！" },
    .{ .display = "忙しい日々を送るあなたに", .kana = "いそがしいひびをおくるあなたに" },
    .{ .display = "老若男女が楽しめる映画", .kana = "ろうにゃくなんにょがたのしめるえいが" },
    .{ .display = "この先通行止めです", .kana = "このさきつうこうどめです" },
    .{ .display = "コンビニスイーツを買って帰る", .kana = "こんびにすいーつをかってかえる" },
    .{ .display = "朱に交われば赤くなる", .kana = "しゅにまじわればあかくなる" },
    .{ .display = "アラブ首長国連邦", .kana = "あらぶしゅちょうこくれんぽう" },
    .{ .display = "平気な顔で嘘をつく", .kana = "へいきなかおでうそをつく" },
    .{ .display = "幻の二千円札", .kana = "まぼろしのにせんえんさつ" },
    .{ .display = "土曜の午後はカフェで読書", .kana = "どようのごごはかふぇでどくしょ" },
    .{ .display = "東京大阪間は約４００キロ", .kana = "とうきょうおおさかかんはやく４００きろ" },
    .{ .display = "長寿の秘訣は何ですか？", .kana = "ちょうじゅのひけつはなんですか？" },
    .{ .display = "好きの反対は無関心", .kana = "すきのはんたいはむかんしん" },
    .{ .display = "アカマンボウはマグロの代替品", .kana = "あかまんぼうはまぐろのだいたいひん" },
    .{ .display = "昨日全然寝てないわ～", .kana = "きのうぜんぜんねてないわ～" },
    .{ .display = "人気投票第一位", .kana = "にんきとうひょうだいいちい" },
    .{ .display = "筋トレの後のプロテイン", .kana = "きんとれのあとのぷろていん" },
    .{ .display = "電子書籍より紙の本", .kana = "でんししょせきよりかみのほん" },
    .{ .display = "理路整然と論破する", .kana = "りろせいぜんとろんぱする" },
    .{ .display = "このカードを覚えてください", .kana = "このかーどをおぼえてください" },
    .{ .display = "暴君として名を轟かす", .kana = "ぼうくんとしてなをとどろかす" },
    .{ .display = "これ注文通ってますか？", .kana = "これちゅうもんとおってますか？" },
    .{ .display = "水分補給を忘れずに！", .kana = "すいぶんほきゅうをわすれずに！" },
    .{ .display = "究極の料理人を目指す", .kana = "きゅうきょくのりょうりにんをめざす" },
    .{ .display = "今夜は月がきれいですね", .kana = "こんやはつきがきれいですね" },
    .{ .display = "人工知能に全てを委ねる", .kana = "じんこうちのうにすべてをゆだねる" },
    .{ .display = "自己利益より他者貢献", .kana = "じこりえきよりたしゃこうけん" },
    .{ .display = "低気圧で頭痛が酷い", .kana = "ていきあつでずつうがひどい" },
    .{ .display = "開戦の狼煙が上がる", .kana = "かいせんののろしがあがる" },
    .{ .display = "年々夏が熱くなる", .kana = "ねんねんなつがあつくなる" },
    .{ .display = "世界に広がる日本食の魅力", .kana = "せかいにひろがるにほんしょくのみりょく" },
    .{ .display = "執筆活動に専念する", .kana = "しっぴつかつどうにせんねんする" },
    .{ .display = "昼夜逆転の生活", .kana = "ちゅうやぎゃくてんのせいかつ" },
    .{ .display = "タンスの角に小指をぶつける", .kana = "たんすのかどにこゆびをぶつける" },
    .{ .display = "解散の理由は音楽性の違い", .kana = "かいさんのりゆうはおんがくせいのちがい" },
    .{ .display = "教科書を丸暗記して試験に挑む", .kana = "きょうかしょをまるあんきしてしけんにいどむ" },
    .{ .display = "早期発見で一命を取り留める", .kana = "そうきはっけんでいちめいをとりとめる" },
    .{ .display = "この先は未知の領域だ", .kana = "このさきはみちのりょういきだ" },
    .{ .display = "地球外生命体の痕跡", .kana = "ちきゅうがいせいめいたいのこんせき" },
    .{ .display = "進化論の父ダーウィン", .kana = "しんかろんのちちだーうぃん" },
    .{ .display = "必殺パンチをお見舞いする", .kana = "ひっさつぱんちをおみまいする" },
    .{ .display = "領収書は結構です", .kana = "りょうしゅうしょはけっこうです" },
    .{ .display = "最近の流行がわからない", .kana = "さいきんのりゅうこうがわからない" },
    .{ .display = "損害賠償請求", .kana = "そんがいばいしょうせいきゅう" },
    .{ .display = "携帯電話の電源をお切りください", .kana = "けいたいでんわのでんげんをおきりください" },
    .{ .display = "素人質問で恐縮ですが", .kana = "しろうとしつもんできょうしゅくですが" },
    .{ .display = "目の前が真っ暗になった", .kana = "めのまえがまっくらになった" },
    .{ .display = "人間は考える葦である", .kana = "にんげんはかんがえるあしである" },
    .{ .display = "タラバガニはヤドカリの仲間", .kana = "たらばがにはやどかりのなかま" },
    .{ .display = "郵便局はどこですか？", .kana = "ゆうびんきょくはどこですか？" },
    .{ .display = "スイカと花火は夏の風物詩", .kana = "すいかとはなびはなつのふうぶつし" },
    .{ .display = "１％のひらめきと９９％の努力", .kana = "１％のひらめきと９９％の努力" },
};
