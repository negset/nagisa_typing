const std = @import("std");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const Utf8Iterator = std.unicode.Utf8Iterator;
const Utf8View = std.unicode.Utf8View;

const Transition = struct {
    key: u8,
    next: usize,
};

pub const State = struct {
    fragment_len: usize = undefined, // A positive value means the start of a fragment.
    transitions: []Transition,
    accept: bool = false,

    pub fn deinit(self: State, gpa: Allocator) void {
        gpa.free(self.transitions);
    }

    pub fn transition(self: State, input: u8) ?usize {
        for (self.transitions) |t| {
            if (t.key == input) {
                return t.next;
            }
        }

        return null;
    }
};

const TrieNode = struct {
    children: AutoHashMap(u8, *TrieNode),
    state_id: ?usize = null,

    fn init(gpa: Allocator) !*TrieNode {
        const node = try gpa.create(TrieNode);

        node.* = .{
            .children = .init(gpa),
        };

        return node;
    }

    fn deinit(self: *TrieNode, gpa: Allocator) void {
        var iterator = self.children.iterator();

        while (iterator.next()) |entry| {
            entry.value_ptr.*.deinit(gpa);
        }

        self.children.deinit();
        gpa.destroy(self);
    }

    fn insert(
        self: *TrieNode,
        gpa: Allocator,
        key: []const u8,
    ) !void {
        var node = self;

        for (key) |character| {
            const result = try node.children.getOrPut(character);

            if (!result.found_existing) {
                result.value_ptr.* = try TrieNode.init(gpa);
            }

            node = result.value_ptr.*;
        }
    }
};

const Entry = struct {
    codepoint: u21,
    codepoint2: ?u21 = null,
    keys: []const []const u8,
};

// -----------------------------------------------------------------------------
// Kana table
// -----------------------------------------------------------------------------
//
// https://www.chiba-kc.ac.jp/user/~iseri/siryo/romakana.html
//

const table = [_]Entry{
    // あ行
    .{ .codepoint = 0x3041, .keys = &.{ "la", "xa" } },
    .{ .codepoint = 0x3042, .keys = &.{"a"} },
    .{ .codepoint = 0x3043, .keys = &.{ "li", "xi" } },
    .{ .codepoint = 0x3044, .keys = &.{ "i", "yi" } },
    .{ .codepoint = 0x3044, .codepoint2 = 0x3047, .keys = &.{"ye"} },
    .{ .codepoint = 0x3045, .keys = &.{ "lu", "xu" } },
    .{ .codepoint = 0x3046, .keys = &.{ "u", "wu", "whu" } },
    .{ .codepoint = 0x3046, .codepoint2 = 0x3041, .keys = &.{"wha"} },
    .{ .codepoint = 0x3046, .codepoint2 = 0x3043, .keys = &.{ "whi", "wi" } },
    .{ .codepoint = 0x3046, .codepoint2 = 0x3047, .keys = &.{ "whe", "we" } },
    .{ .codepoint = 0x3046, .codepoint2 = 0x3049, .keys = &.{"who"} },
    .{ .codepoint = 0x3047, .keys = &.{ "le", "xe" } },
    .{ .codepoint = 0x3048, .keys = &.{"e"} },
    .{ .codepoint = 0x3049, .keys = &.{ "lo", "xo" } },
    .{ .codepoint = 0x304a, .keys = &.{"o"} },

    // か行
    .{ .codepoint = 0x304b, .keys = &.{ "ka", "ca" } },
    .{ .codepoint = 0x304c, .keys = &.{"ga"} },
    .{ .codepoint = 0x304d, .keys = &.{"ki"} },
    .{ .codepoint = 0x304d, .codepoint2 = 0x3043, .keys = &.{"kyi"} },
    .{ .codepoint = 0x304d, .codepoint2 = 0x3047, .keys = &.{"kye"} },
    .{ .codepoint = 0x304d, .codepoint2 = 0x3083, .keys = &.{"kya"} },
    .{ .codepoint = 0x304d, .codepoint2 = 0x3085, .keys = &.{"kyu"} },
    .{ .codepoint = 0x304d, .codepoint2 = 0x3087, .keys = &.{"kyo"} },
    .{ .codepoint = 0x304e, .keys = &.{"gi"} },
    .{ .codepoint = 0x304e, .codepoint2 = 0x3043, .keys = &.{"gyi"} },
    .{ .codepoint = 0x304e, .codepoint2 = 0x3047, .keys = &.{"gye"} },
    .{ .codepoint = 0x304e, .codepoint2 = 0x3083, .keys = &.{"gya"} },
    .{ .codepoint = 0x304e, .codepoint2 = 0x3085, .keys = &.{"gyu"} },
    .{ .codepoint = 0x304e, .codepoint2 = 0x3087, .keys = &.{"gyo"} },
    .{ .codepoint = 0x304f, .keys = &.{ "ku", "cu", "qu" } },
    .{ .codepoint = 0x304f, .codepoint2 = 0x3041, .keys = &.{ "qwa", "qa" } },
    .{ .codepoint = 0x304f, .codepoint2 = 0x3043, .keys = &.{ "qwi", "qi", "qyi" } },
    .{ .codepoint = 0x304f, .codepoint2 = 0x3045, .keys = &.{"qwu"} },
    .{ .codepoint = 0x304f, .codepoint2 = 0x3047, .keys = &.{ "qwe", "qe", "qye" } },
    .{ .codepoint = 0x304f, .codepoint2 = 0x3049, .keys = &.{ "qwo", "qo" } },
    .{ .codepoint = 0x3050, .keys = &.{"gu"} },
    .{ .codepoint = 0x3050, .codepoint2 = 0x3041, .keys = &.{"gwa"} },
    .{ .codepoint = 0x3050, .codepoint2 = 0x3043, .keys = &.{"gwi"} },
    .{ .codepoint = 0x3050, .codepoint2 = 0x3045, .keys = &.{"gwu"} },
    .{ .codepoint = 0x3050, .codepoint2 = 0x3047, .keys = &.{"gwe"} },
    .{ .codepoint = 0x3050, .codepoint2 = 0x3049, .keys = &.{"gwo"} },
    .{ .codepoint = 0x3051, .keys = &.{"ke"} },
    .{ .codepoint = 0x3052, .keys = &.{"ge"} },
    .{ .codepoint = 0x3053, .keys = &.{ "ko", "co" } },
    .{ .codepoint = 0x3054, .keys = &.{"go"} },

    // さ行
    .{ .codepoint = 0x3055, .keys = &.{"sa"} },
    .{ .codepoint = 0x3056, .keys = &.{"za"} },
    .{ .codepoint = 0x3057, .keys = &.{ "si", "ci", "shi" } },
    .{ .codepoint = 0x3057, .codepoint2 = 0x3043, .keys = &.{"syi"} },
    .{ .codepoint = 0x3057, .codepoint2 = 0x3047, .keys = &.{ "sye", "she" } },
    .{ .codepoint = 0x3057, .codepoint2 = 0x3083, .keys = &.{ "sya", "sha" } },
    .{ .codepoint = 0x3057, .codepoint2 = 0x3085, .keys = &.{ "syu", "shu" } },
    .{ .codepoint = 0x3057, .codepoint2 = 0x3087, .keys = &.{ "syo", "sho" } },
    .{ .codepoint = 0x3058, .keys = &.{ "zi", "ji" } },
    .{ .codepoint = 0x3058, .codepoint2 = 0x3043, .keys = &.{ "zyi", "jyi" } },
    .{ .codepoint = 0x3058, .codepoint2 = 0x3047, .keys = &.{ "zye", "je", "jhe" } },
    .{ .codepoint = 0x3058, .codepoint2 = 0x3083, .keys = &.{ "zya", "ja", "jya" } },
    .{ .codepoint = 0x3058, .codepoint2 = 0x3085, .keys = &.{ "zyu", "ju", "jyu" } },
    .{ .codepoint = 0x3058, .codepoint2 = 0x3087, .keys = &.{ "zyo", "jo", "jyo" } },
    .{ .codepoint = 0x3059, .keys = &.{"su"} },
    .{ .codepoint = 0x3059, .codepoint2 = 0x3041, .keys = &.{"swa"} },
    .{ .codepoint = 0x3059, .codepoint2 = 0x3043, .keys = &.{"swi"} },
    .{ .codepoint = 0x3059, .codepoint2 = 0x3045, .keys = &.{"swu"} },
    .{ .codepoint = 0x3059, .codepoint2 = 0x3047, .keys = &.{"swe"} },
    .{ .codepoint = 0x3059, .codepoint2 = 0x3049, .keys = &.{"swo"} },
    .{ .codepoint = 0x305a, .keys = &.{"zu"} },
    .{ .codepoint = 0x305b, .keys = &.{ "se", "ce" } },
    .{ .codepoint = 0x305c, .keys = &.{"ze"} },
    .{ .codepoint = 0x305d, .keys = &.{"so"} },
    .{ .codepoint = 0x305e, .keys = &.{"zo"} },

    // た行
    .{ .codepoint = 0x305f, .keys = &.{"ta"} },
    .{ .codepoint = 0x3060, .keys = &.{"da"} },
    .{ .codepoint = 0x3061, .keys = &.{ "ti", "chi" } },
    .{ .codepoint = 0x3061, .codepoint2 = 0x3043, .keys = &.{ "tyi", "cyi" } },
    .{ .codepoint = 0x3061, .codepoint2 = 0x3047, .keys = &.{ "tye", "che", "cye" } },
    .{ .codepoint = 0x3061, .codepoint2 = 0x3083, .keys = &.{ "tya", "cha", "cya" } },
    .{ .codepoint = 0x3061, .codepoint2 = 0x3085, .keys = &.{ "tyu", "chu", "cyu" } },
    .{ .codepoint = 0x3061, .codepoint2 = 0x3087, .keys = &.{ "tyo", "cho", "cyo" } },
    .{ .codepoint = 0x3062, .keys = &.{"di"} },
    .{ .codepoint = 0x3062, .codepoint2 = 0x3043, .keys = &.{"dyi"} },
    .{ .codepoint = 0x3062, .codepoint2 = 0x3047, .keys = &.{"dye"} },
    .{ .codepoint = 0x3062, .codepoint2 = 0x3083, .keys = &.{"dya"} },
    .{ .codepoint = 0x3062, .codepoint2 = 0x3085, .keys = &.{"dyu"} },
    .{ .codepoint = 0x3062, .codepoint2 = 0x3087, .keys = &.{"dyo"} },
    .{ .codepoint = 0x3063, .keys = &.{ "ltu", "xtu", "ltsu", "xtsu" } },
    .{ .codepoint = 0x3064, .keys = &.{ "tu", "tsu" } },
    .{ .codepoint = 0x3064, .codepoint2 = 0x3041, .keys = &.{"tsa"} },
    .{ .codepoint = 0x3064, .codepoint2 = 0x3043, .keys = &.{"tsi"} },
    .{ .codepoint = 0x3064, .codepoint2 = 0x3047, .keys = &.{"tse"} },
    .{ .codepoint = 0x3064, .codepoint2 = 0x3049, .keys = &.{"tso"} },
    .{ .codepoint = 0x3065, .keys = &.{"du"} },
    .{ .codepoint = 0x3066, .keys = &.{"te"} },
    .{ .codepoint = 0x3066, .codepoint2 = 0x3043, .keys = &.{"thi"} },
    .{ .codepoint = 0x3066, .codepoint2 = 0x3047, .keys = &.{"the"} },
    .{ .codepoint = 0x3066, .codepoint2 = 0x3083, .keys = &.{"tha"} },
    .{ .codepoint = 0x3066, .codepoint2 = 0x3085, .keys = &.{"thu"} },
    .{ .codepoint = 0x3066, .codepoint2 = 0x3087, .keys = &.{"tho"} },
    .{ .codepoint = 0x3067, .keys = &.{"de"} },
    .{ .codepoint = 0x3067, .codepoint2 = 0x3043, .keys = &.{"dhi"} },
    .{ .codepoint = 0x3067, .codepoint2 = 0x3047, .keys = &.{"dhe"} },
    .{ .codepoint = 0x3067, .codepoint2 = 0x3083, .keys = &.{"dha"} },
    .{ .codepoint = 0x3067, .codepoint2 = 0x3085, .keys = &.{"dhu"} },
    .{ .codepoint = 0x3067, .codepoint2 = 0x3087, .keys = &.{"dho"} },
    .{ .codepoint = 0x3068, .keys = &.{"to"} },
    .{ .codepoint = 0x3068, .codepoint2 = 0x3041, .keys = &.{"twa"} },
    .{ .codepoint = 0x3068, .codepoint2 = 0x3042, .keys = &.{"twi"} },
    .{ .codepoint = 0x3068, .codepoint2 = 0x3045, .keys = &.{"twu"} },
    .{ .codepoint = 0x3068, .codepoint2 = 0x3047, .keys = &.{"twe"} },
    .{ .codepoint = 0x3068, .codepoint2 = 0x3049, .keys = &.{"two"} },
    .{ .codepoint = 0x3069, .keys = &.{"do"} },
    .{ .codepoint = 0x3069, .codepoint2 = 0x3041, .keys = &.{"dwa"} },
    .{ .codepoint = 0x3069, .codepoint2 = 0x3042, .keys = &.{"dwi"} },
    .{ .codepoint = 0x3069, .codepoint2 = 0x3045, .keys = &.{"dwu"} },
    .{ .codepoint = 0x3069, .codepoint2 = 0x3047, .keys = &.{"dwe"} },
    .{ .codepoint = 0x3069, .codepoint2 = 0x3049, .keys = &.{"dwo"} },

    // な行
    .{ .codepoint = 0x306a, .keys = &.{"na"} },
    .{ .codepoint = 0x306b, .keys = &.{"ni"} },
    .{ .codepoint = 0x306b, .codepoint2 = 0x3043, .keys = &.{"nyi"} },
    .{ .codepoint = 0x306b, .codepoint2 = 0x3047, .keys = &.{"nye"} },
    .{ .codepoint = 0x306b, .codepoint2 = 0x3083, .keys = &.{"nya"} },
    .{ .codepoint = 0x306b, .codepoint2 = 0x3085, .keys = &.{"nyu"} },
    .{ .codepoint = 0x306b, .codepoint2 = 0x3087, .keys = &.{"nyo"} },
    .{ .codepoint = 0x306c, .keys = &.{"nu"} },
    .{ .codepoint = 0x306d, .keys = &.{"ne"} },
    .{ .codepoint = 0x306e, .keys = &.{"no"} },

    // は行
    .{ .codepoint = 0x306f, .keys = &.{"ha"} },
    .{ .codepoint = 0x3070, .keys = &.{"ba"} },
    .{ .codepoint = 0x3071, .keys = &.{"pa"} },
    .{ .codepoint = 0x3072, .keys = &.{"hi"} },
    .{ .codepoint = 0x3072, .codepoint2 = 0x3043, .keys = &.{"hyi"} },
    .{ .codepoint = 0x3072, .codepoint2 = 0x3047, .keys = &.{"hye"} },
    .{ .codepoint = 0x3072, .codepoint2 = 0x3083, .keys = &.{"hya"} },
    .{ .codepoint = 0x3072, .codepoint2 = 0x3085, .keys = &.{"hyu"} },
    .{ .codepoint = 0x3072, .codepoint2 = 0x3087, .keys = &.{"hyo"} },
    .{ .codepoint = 0x3073, .keys = &.{"bi"} },
    .{ .codepoint = 0x3073, .codepoint2 = 0x3043, .keys = &.{"byi"} },
    .{ .codepoint = 0x3073, .codepoint2 = 0x3047, .keys = &.{"bye"} },
    .{ .codepoint = 0x3073, .codepoint2 = 0x3083, .keys = &.{"bya"} },
    .{ .codepoint = 0x3073, .codepoint2 = 0x3085, .keys = &.{"byu"} },
    .{ .codepoint = 0x3073, .codepoint2 = 0x3087, .keys = &.{"byo"} },
    .{ .codepoint = 0x3074, .keys = &.{"pi"} },
    .{ .codepoint = 0x3074, .codepoint2 = 0x3043, .keys = &.{"pyi"} },
    .{ .codepoint = 0x3074, .codepoint2 = 0x3047, .keys = &.{"pye"} },
    .{ .codepoint = 0x3074, .codepoint2 = 0x3083, .keys = &.{"pya"} },
    .{ .codepoint = 0x3074, .codepoint2 = 0x3085, .keys = &.{"pyu"} },
    .{ .codepoint = 0x3074, .codepoint2 = 0x3087, .keys = &.{"pyo"} },
    .{ .codepoint = 0x3075, .keys = &.{ "hu", "fu" } },
    .{ .codepoint = 0x3075, .codepoint2 = 0x3041, .keys = &.{ "fwa", "fa" } },
    .{ .codepoint = 0x3075, .codepoint2 = 0x3043, .keys = &.{ "fwi", "fi", "fyi" } },
    .{ .codepoint = 0x3075, .codepoint2 = 0x3045, .keys = &.{"fwu"} },
    .{ .codepoint = 0x3075, .codepoint2 = 0x3047, .keys = &.{ "fwe", "fe", "fye" } },
    .{ .codepoint = 0x3075, .codepoint2 = 0x3049, .keys = &.{ "fwo", "fo" } },
    .{ .codepoint = 0x3075, .codepoint2 = 0x3083, .keys = &.{"fya"} },
    .{ .codepoint = 0x3075, .codepoint2 = 0x3085, .keys = &.{"fyu"} },
    .{ .codepoint = 0x3075, .codepoint2 = 0x3087, .keys = &.{"fyo"} },
    .{ .codepoint = 0x3076, .keys = &.{"bu"} },
    .{ .codepoint = 0x3077, .keys = &.{"pu"} },
    .{ .codepoint = 0x3078, .keys = &.{"he"} },
    .{ .codepoint = 0x3079, .keys = &.{"be"} },
    .{ .codepoint = 0x307a, .keys = &.{"pe"} },
    .{ .codepoint = 0x307b, .keys = &.{"ho"} },
    .{ .codepoint = 0x307c, .keys = &.{"bo"} },
    .{ .codepoint = 0x307d, .keys = &.{"po"} },

    // ま行
    .{ .codepoint = 0x307e, .keys = &.{"ma"} },
    .{ .codepoint = 0x307f, .keys = &.{"mi"} },
    .{ .codepoint = 0x307f, .codepoint2 = 0x3043, .keys = &.{"myi"} },
    .{ .codepoint = 0x307f, .codepoint2 = 0x3047, .keys = &.{"mye"} },
    .{ .codepoint = 0x307f, .codepoint2 = 0x3083, .keys = &.{"mya"} },
    .{ .codepoint = 0x307f, .codepoint2 = 0x3085, .keys = &.{"myu"} },
    .{ .codepoint = 0x307f, .codepoint2 = 0x3087, .keys = &.{"myo"} },
    .{ .codepoint = 0x3080, .keys = &.{"mu"} },
    .{ .codepoint = 0x3081, .keys = &.{"me"} },
    .{ .codepoint = 0x3082, .keys = &.{"mo"} },

    // や行
    .{ .codepoint = 0x3083, .keys = &.{ "lya", "xya" } },
    .{ .codepoint = 0x3084, .keys = &.{"ya"} },
    .{ .codepoint = 0x3085, .keys = &.{ "lyu", "xyu" } },
    .{ .codepoint = 0x3086, .keys = &.{"yu"} },
    .{ .codepoint = 0x3087, .keys = &.{ "lyo", "xyo" } },
    .{ .codepoint = 0x3088, .keys = &.{"yo"} },

    // ら行
    .{ .codepoint = 0x3089, .keys = &.{"ra"} },
    .{ .codepoint = 0x308a, .keys = &.{"ri"} },
    .{ .codepoint = 0x308a, .codepoint2 = 0x3043, .keys = &.{"ryi"} },
    .{ .codepoint = 0x308a, .codepoint2 = 0x3047, .keys = &.{"rye"} },
    .{ .codepoint = 0x308a, .codepoint2 = 0x3083, .keys = &.{"rya"} },
    .{ .codepoint = 0x308a, .codepoint2 = 0x3085, .keys = &.{"ryu"} },
    .{ .codepoint = 0x308a, .codepoint2 = 0x3087, .keys = &.{"ryo"} },
    .{ .codepoint = 0x308b, .keys = &.{"ru"} },
    .{ .codepoint = 0x308c, .keys = &.{"re"} },
    .{ .codepoint = 0x308d, .keys = &.{"ro"} },

    // わ行
    .{ .codepoint = 0x308e, .keys = &.{ "lwa", "xwa" } },
    .{ .codepoint = 0x308f, .keys = &.{"wa"} },
    .{ .codepoint = 0x3092, .keys = &.{"wo"} },
    .{ .codepoint = 0x3093, .keys = &.{ "n\u{0}", "nn", "n'", "xn" } },

    // ゔ
    .{ .codepoint = 0x3094, .keys = &.{"vu"} },
    .{ .codepoint = 0x3094, .codepoint2 = 0x3041, .keys = &.{"va"} },
    .{ .codepoint = 0x3094, .codepoint2 = 0x3043, .keys = &.{ "vi", "vyi" } },
    .{ .codepoint = 0x3094, .codepoint2 = 0x3047, .keys = &.{ "ve", "vye" } },
    .{ .codepoint = 0x3094, .codepoint2 = 0x3049, .keys = &.{"vo"} },
    .{ .codepoint = 0x3094, .codepoint2 = 0x3083, .keys = &.{"vya"} },
    .{ .codepoint = 0x3094, .codepoint2 = 0x3085, .keys = &.{"vyu"} },
    .{ .codepoint = 0x3094, .codepoint2 = 0x3087, .keys = &.{"vyo"} },

    // ゕゖ
    .{ .codepoint = 0x3095, .keys = &.{ "lka", "xka" } },
    .{ .codepoint = 0x3096, .keys = &.{ "lke", "xke" } },

    // 数字
    .{ .codepoint = 0xff10, .keys = &.{"0"} },
    .{ .codepoint = 0xff11, .keys = &.{"1"} },
    .{ .codepoint = 0xff12, .keys = &.{"2"} },
    .{ .codepoint = 0xff13, .keys = &.{"3"} },
    .{ .codepoint = 0xff14, .keys = &.{"4"} },
    .{ .codepoint = 0xff15, .keys = &.{"5"} },
    .{ .codepoint = 0xff16, .keys = &.{"6"} },
    .{ .codepoint = 0xff17, .keys = &.{"7"} },
    .{ .codepoint = 0xff18, .keys = &.{"8"} },
    .{ .codepoint = 0xff19, .keys = &.{"9"} },

    // 記号
    .{ .codepoint = 0x3001, .keys = &.{","} },
    .{ .codepoint = 0x3002, .keys = &.{"."} },
    .{ .codepoint = 0x300c, .keys = &.{"["} },
    .{ .codepoint = 0x300d, .keys = &.{"]"} },
    .{ .codepoint = 0x30fc, .keys = &.{"-"} },
    .{ .codepoint = 0xff01, .keys = &.{"!"} },
    .{ .codepoint = 0xff06, .keys = &.{"&"} },
    .{ .codepoint = 0xff1f, .keys = &.{"?"} },
    .{ .codepoint = 0xff5e, .keys = &.{"~"} },
};

// -----------------------------------------------------------------------------
// Entry lookup
// -----------------------------------------------------------------------------

fn findEntry(
    codepoint: u21,
    codepoint2: ?u21,
) !*const Entry {
    for (&table) |*entry| {
        if (entry.codepoint == codepoint and
            entry.codepoint2 == codepoint2)
        {
            return entry;
        }
    }

    return error.NotFound;
}

fn findEntryOrFallback(
    codepoint: u21,
    codepoint2: ?u21,
) !*const Entry {
    return findEntry(codepoint, codepoint2) catch
        findEntry(codepoint, null);
}

// -----------------------------------------------------------------------------
// Key expansion
// -----------------------------------------------------------------------------

const ExpandedKeys = struct {
    // Owned backing allocation returned by ArrayList.toOwnedSlice().
    items: []const []const u8,

    // Owns dynamically-created composite key strings.
    owned: ArrayList([]const u8),

    fn deinit(self: *ExpandedKeys, gpa: Allocator) void {
        for (self.owned.items) |key| {
            gpa.free(key);
        }

        self.owned.deinit(gpa);

        // `items` owns the ArrayList backing allocation.
        gpa.free(self.items);
    }
};

fn appendCombinedKey(
    gpa: Allocator,
    keys: *ArrayList([]const u8),
    owned: *ArrayList([]const u8),
    key1: []const u8,
    key2: []const u8,
) !void {
    const combined = try gpa.alloc(
        u8,
        key1.len + key2.len,
    );

    std.mem.copyForwards(
        u8,
        combined[0..key1.len],
        key1,
    );

    std.mem.copyForwards(
        u8,
        combined[key1.len..],
        key2,
    );

    // First add the key to `keys`.
    //
    // If this fails, `combined` is still unowned and must be
    // released here.
    keys.append(gpa, combined) catch |err| {
        gpa.free(combined);
        return err;
    };

    // Now transfer ownership to `owned`.
    //
    // If this fails, remove the entry we just added to `keys`
    // and release the string. This keeps both containers
    // consistent on allocation failure.
    owned.append(gpa, combined) catch |err| {
        _ = keys.pop();
        gpa.free(combined);
        return err;
    };
}

fn expandEntryKeys(
    gpa: Allocator,
    entry: *const Entry,
) !ExpandedKeys {
    var keys = ArrayList([]const u8).empty;

    // `keys` is only temporary while constructing ExpandedKeys.
    // Its backing allocation is transferred with toOwnedSlice().
    defer keys.deinit(gpa);

    var owned = ArrayList([]const u8).empty;

    errdefer {
        for (owned.items) |key| {
            gpa.free(key);
        }

        owned.deinit(gpa);
    }

    // Base keys are borrowed from the static table.
    try keys.appendSlice(gpa, entry.keys);

    if (entry.codepoint2) |codepoint2| {
        const first = try findEntry(
            entry.codepoint,
            null,
        );

        const second = try findEntry(
            codepoint2,
            null,
        );

        for (first.keys) |key1| {
            for (second.keys) |key2| {
                try appendCombinedKey(
                    gpa,
                    &keys,
                    &owned,
                    key1,
                    key2,
                );
            }
        }
    }

    // Transfer ownership of the ArrayList backing allocation
    // to ExpandedKeys.
    const items = try keys.toOwnedSlice(gpa);

    return .{
        .items = items,
        .owned = owned,
    };
}

// -----------------------------------------------------------------------------
// Trie → DFA
// -----------------------------------------------------------------------------

fn assignStateIds(
    gpa: Allocator,
    node: *TrieNode,
    states: *ArrayList(*TrieNode),
) !void {
    // A leaf represents the end of a kana fragment.
    // It does not need its own DFA state.
    if (node.children.count() == 0) {
        return;
    }

    node.state_id = states.items.len;
    try states.append(gpa, node);

    var iterator = node.children.iterator();

    while (iterator.next()) |entry| {
        try assignStateIds(
            gpa,
            entry.value_ptr.*,
            states,
        );
    }
}

fn buildTransitions(
    gpa: Allocator,
    node: *TrieNode,
    next_fragment_state: usize,
) ![]Transition {
    const transitions = try gpa.alloc(
        Transition,
        node.children.count(),
    );

    var index: usize = 0;
    var iterator = node.children.iterator();

    while (iterator.next()) |entry| {
        const child = entry.value_ptr.*;

        transitions[index] = .{
            .key = entry.key_ptr.*,

            // A leaf means that the current kana fragment is
            // complete. Continue at the root of the next fragment.
            .next = child.state_id orelse next_fragment_state,
        };

        index += 1;
    }

    return transitions;
}

fn buildStatesFromKeys(
    gpa: Allocator,
    keys: []const []const u8,
) !ArrayList(State) {
    const root = try TrieNode.init(gpa);
    defer root.deinit(gpa);

    for (keys) |key| {
        try root.insert(gpa, key);
    }

    var nodes = ArrayList(*TrieNode).empty;
    defer nodes.deinit(gpa);

    try assignStateIds(
        gpa,
        root,
        &nodes,
    );

    var states = ArrayList(State).empty;

    errdefer {
        for (states.items) |state| {
            state.deinit(gpa);
        }

        states.deinit(gpa);
    }

    for (nodes.items) |node| {
        const transitions = try buildTransitions(
            gpa,
            node,
            nodes.items.len,
        );

        try states.append(gpa, .{
            .transitions = transitions,
        });
    }

    return states;
}

fn buildEntryStates(
    gpa: Allocator,
    entry: *const Entry,
) !ArrayList(State) {
    var keys = try expandEntryKeys(
        gpa,
        entry,
    );

    defer keys.deinit(gpa);

    return buildStatesFromKeys(
        gpa,
        keys.items,
    );
}

fn buildEntryStatesOwned(
    gpa: Allocator,
    entry: *const Entry,
) ![]State {
    var states = try buildEntryStates(
        gpa,
        entry,
    );

    errdefer {
        for (states.items) |state| {
            state.deinit(gpa);
        }

        states.deinit(gpa);
    }

    return try states.toOwnedSlice(gpa);
}

// -----------------------------------------------------------------------------
// Sokuon
// -----------------------------------------------------------------------------

fn isSokuonConsonant(key: []const u8) bool {
    if (key.len == 0) {
        return false;
    }

    return switch (key[0]) {
        'b',
        'c',
        'd',
        'f',
        'g',
        'h',
        'j',
        'k',
        'l',
        'm',
        'p',
        'q',
        'r',
        's',
        't',
        'v',
        'w',
        'x',
        'y',
        'z',
        => true,

        // `n` is handled separately by the ん rules.
        else => false,
    };
}

fn appendExplicitSokuonKeys(
    gpa: Allocator,
    keys: *ArrayList([]const u8),
    owned: *ArrayList([]const u8),
    next_keys: []const []const u8,
) !void {
    const sokuon = try findEntry(
        0x3063,
        null,
    );

    for (sokuon.keys) |sokuon_key| {
        for (next_keys) |next_key| {
            try appendCombinedKey(
                gpa,
                keys,
                owned,
                sokuon_key,
                next_key,
            );
        }
    }
}

fn appendDoubledConsonantKeys(
    gpa: Allocator,
    keys: *ArrayList([]const u8),
    owned: *ArrayList([]const u8),
    next_keys: []const []const u8,
) !void {
    for (next_keys) |next_key| {
        if (!isSokuonConsonant(next_key)) {
            continue;
        }

        const doubled = try gpa.alloc(
            u8,
            next_key.len + 1,
        );

        std.mem.copyForwards(
            u8,
            doubled[2..],
            next_key[1..],
        );

        doubled[0] = next_key[0];
        doubled[1] = next_key[0];

        // Same ownership pattern as appendCombinedKey():
        // add to `keys`, then transfer ownership to `owned`.
        keys.append(gpa, doubled) catch |err| {
            gpa.free(doubled);
            return err;
        };

        owned.append(gpa, doubled) catch |err| {
            _ = keys.pop();
            gpa.free(doubled);
            return err;
        };
    }
}

fn buildSokuonStates(
    gpa: Allocator,
    next_entry: *const Entry,
) ![]State {
    var next_keys = try expandEntryKeys(
        gpa,
        next_entry,
    );

    defer next_keys.deinit(gpa);

    var keys = ArrayList([]const u8).empty;

    errdefer keys.deinit(gpa);

    var owned = ArrayList([]const u8).empty;

    errdefer {
        for (owned.items) |key| {
            gpa.free(key);
        }

        owned.deinit(gpa);
    }

    // Explicit forms:
    //
    //     ltu + ko  -> ltuko
    //     xtu + ko  -> xtuko
    //     ltsu + ko -> ltsuko
    //     xtsu + ko -> xtsuko
    //
    try appendExplicitSokuonKeys(
        gpa,
        &keys,
        &owned,
        next_keys.items,
    );

    // Standard romaji form:
    //
    //     ko  -> kko
    //     shi -> sshi
    //     chi -> cchi
    //
    try appendDoubledConsonantKeys(
        gpa,
        &keys,
        &owned,
        next_keys.items,
    );

    var states = try buildStatesFromKeys(
        gpa,
        keys.items,
    );

    // buildStatesFromKeys() has copied the key information into
    // its own transition allocations, so the temporary key
    // storage can now be released.
    for (owned.items) |key| {
        gpa.free(key);
    }

    owned.deinit(gpa);
    keys.deinit(gpa);

    errdefer {
        for (states.items) |state| {
            state.deinit(gpa);
        }

        states.deinit(gpa);
    }

    return try states.toOwnedSlice(gpa);
}

// -----------------------------------------------------------------------------
// Input traversal
// -----------------------------------------------------------------------------

fn consumeEntry(
    iterator: *Utf8Iterator,
    codepoint: u21,
) !*const Entry {
    var lookahead = iterator.*;

    if (lookahead.nextCodepoint()) |codepoint2| {
        if (findEntry(codepoint, codepoint2) catch null) |entry| {
            // Consume the second codepoint only when it forms
            // a valid composite entry.
            iterator.* = lookahead;
            return entry;
        }
    }

    return findEntryOrFallback(
        codepoint,
        null,
    );
}

fn consumeSokuonEntry(
    iterator: *Utf8Iterator,
) ?*const Entry {
    var lookahead = iterator.*;

    const codepoint = lookahead.nextCodepoint() orelse {
        return null;
    };

    const entry = consumeEntry(
        &lookahead,
        codepoint,
    ) catch {
        return null;
    };

    // The sokuon DFA contains both っ and the following kana,
    // so commit the lookahead.
    iterator.* = lookahead;

    return entry;
}

fn rejectSingleN(
    next_codepoint: ?u21,
) bool {
    const codepoint = next_codepoint orelse {
        return true;
    };

    return switch (codepoint) {
        // あ行
        0x3042,
        0x3044,
        0x3046,
        0x3048,
        0x304A,

        // な行
        0x306a,
        0x306b,
        0x306c,
        0x306d,
        0x306e,

        // や行
        0x3084,
        0x3086,
        0x3088,

        // ん
        0x3093,
        => true,

        else => false,
    };
}

// -----------------------------------------------------------------------------
// Fragment construction
// -----------------------------------------------------------------------------

const Fragment = struct {
    states: []State,
    len: usize,
};

fn entryLen(entry: *const Entry) usize {
    return if (entry.codepoint2 != null) 2 else 1;
}

fn buildFragment(
    gpa: Allocator,
    iterator: *Utf8Iterator,
    codepoint: u21,
) !Fragment {
    if (codepoint == 0x3063) {
        if (consumeSokuonEntry(iterator)) |next_entry| {
            return .{
                .states = try buildSokuonStates(
                    gpa,
                    next_entry,
                ),
                .len = 1 + entryLen(next_entry),
            };
        }

        // A standalone/final っ uses its ordinary explicit
        // small-kana forms.
        const entry = try findEntryOrFallback(
            codepoint,
            null,
        );

        return .{
            .states = try buildEntryStatesOwned(
                gpa,
                entry,
            ),
            .len = entryLen(entry),
        };
    }

    const entry = try consumeEntry(
        iterator,
        codepoint,
    );

    return .{
        .states = try buildEntryStatesOwned(
            gpa,
            entry,
        ),
        .len = entryLen(entry),
    };
}

// -----------------------------------------------------------------------------
// Fragment concatenation
// -----------------------------------------------------------------------------

fn appendStates(
    gpa: Allocator,
    result: *ArrayList(State),
    states: []const State,
    fragment_len: usize,
    reject_single_n: bool,
) !void {
    const state_offset = result.items.len;

    for (states, 0..) |state, i| {
        var transition_count: usize = 0;

        for (state.transitions) |transition| {
            if (reject_single_n and transition.key == 0) {
                continue;
            }

            transition_count += 1;
        }

        const transitions = try gpa.alloc(
            Transition,
            transition_count,
        );

        for (state.transitions, 0..) |transition, j| {
            if (reject_single_n and transition.key == 0) {
                continue;
            }

            transitions[j] = .{
                .key = transition.key,
                .next = transition.next + state_offset,
            };
        }

        try result.append(gpa, .{
            .fragment_len = if (i == 0) fragment_len else 0,
            .transitions = transitions,
            .accept = state.accept,
        });
    }
}

// -----------------------------------------------------------------------------
// Public API
// -----------------------------------------------------------------------------

pub fn compile(
    gpa: Allocator,
    kana: []const u8,
) ![]State {
    var result = ArrayList(State).empty;

    errdefer {
        for (result.items) |state| {
            state.deinit(gpa);
        }

        result.deinit(gpa);
    }

    var iterator = (try Utf8View.init(kana)).iterator();

    while (iterator.nextCodepoint()) |codepoint| {
        const fragment = try buildFragment(
            gpa,
            &iterator,
            codepoint,
        );

        defer {
            for (fragment.states) |state| {
                state.deinit(gpa);
            }

            gpa.free(fragment.states);
        }

        // Look ahead without consuming the next codepoint.
        const next_codepoint = blk: {
            var lookahead = iterator;
            break :blk lookahead.nextCodepoint();
        };

        try appendStates(
            gpa,
            &result,
            fragment.states,
            fragment.len,
            rejectSingleN(next_codepoint),
        );
    }

    // Every complete input path terminates here.
    // Therefore only the final state is accepting.
    try result.append(gpa, .{
        .transitions = try gpa.alloc(
            Transition,
            0,
        ),
        .accept = true,
        .fragment_len = 0,
    });

    return try result.toOwnedSlice(gpa);
}
