local luasnip = require("luasnip")
local s = luasnip.snippet
local i = luasnip.insert_node
local t = luasnip.text_node
local d = luasnip.dynamic_node
local f = luasnip.function_node
local sn = luasnip.snippet_node
local fmt = require("luasnip.extras.fmt").fmt
local postfix = require("luasnip.extras.postfix").postfix
local context = require("csharp-snippets.context")

local is_not = f(function()
    local pattern_matching = context.get_project_info().lang_version >= 9

    if pattern_matching then
        return "is not"
    else
        return "!="
    end
end, {})

local sb = luasnip.extend_decorator.apply(s, {
    show_condition = context.is_in_block,
})
local sc = luasnip.extend_decorator.apply(s, {
    show_condition = context.is_in_class,
})

local debug_assert = sb({
    trig = "asrt",
    wordTrig = true,
    name = "Make an assertion",
}, {
    t("Debug.Assert("),
    i(0),
    t(");"),
})

local debug_assert_not_null = sb({
    trig = "asrtn",
    wordTrig = true,
    name = "Debug.Assert",
}, {
    t("Debug.Assert("),
    i(1),
    t(" "),
    is_not,
    t(' null, "'),
    i(0),
    t('");'),
})

local write_line = sb({
    trig = "cw",
    wordTrig = true,
    name = "Console.WriteLine",
}, {
    t("Console.WriteLine("),
    i(0),
    t(");"),
})

local write_line_out = sb({
    trig = "out",
    wordTrig = true,
    name = "Print a string",
}, {
    t('Console.Out.WriteLine("'),
    i(0),
    t('");'),
})

local print_variable = sb({
    trig = "outv",
    wordTrig = true,
    name = "Print value of a variable",
}, {
    t('Console.Out.WriteLine("'),
    f(function(args) return args[1] end, { 1 }),
    t(' = {0}", '),
    i(1, "var"),
    t(");"),
})

local throw_new = sb({
    trig = "thr",
    wordTrig = true,
    name = "Throw new",
}, {
    t("throw new "),
    i(1),
    t("Exception("),
    i(2),
    t(");"),
})

local pci = sc({
    trig = "pci",
    wordTrig = true,
    name = "public const int",
}, t("public const int "))

local pcs = sc({
    trig = "pcs",
    wordTrig = true,
    name = "public const string",
}, t("public const string "))

local psr = sc({
    trig = "psr",
    wordTrig = true,
    name = "public static readonly",
}, t("public static readonly"))

-- todo conditons
local cast = postfix({
    trig = ".cast",
    name = "Cast",
}, {
    d(1, function(_, parent) return sn(1, fmt("({})" .. parent.snippet.env.POSTFIX_MATCH .. ";", { i(1) })) end),
})

return {
    debug_assert,
    debug_assert_not_null,
    write_line,
    write_line_out,
    print_variable,
    throw_new,
    pci,
    pcs,
    psr,
    cast,
}
