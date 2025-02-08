local luasnip = require("luasnip")
local s = luasnip.snippet
local i = luasnip.insert_node
local t = luasnip.text_node
local f = luasnip.function_node
local fmta = require("luasnip.extras.fmt").fmta
local context = require("csharp-snippets.context")

local is_not = f(function()
    local pattern_matching = context.get_project_info().lang_version >= 9

    if pattern_matching then
        return "is not"
    else
        return "!="
    end
end, {})

local debug_assert = s({
    trig = "asrt",
    wordTrig = true,
    name = "Make an assertion",
}, {
    t("Debug.Assert("),
    i(0),
    t(");"),
}, {
    show_condition = context.is_in_block,
})

local debug_assert_not_null = s({
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
}, {
    show_condition = context.is_in_block,
})

local write_line = s({
    trig = "cw",
    wordTrig = true,
    name = "Console.WriteLine",
}, {
    t("Console.WriteLine("),
    i(0),
    t(");"),
}, {
    show_condition = context.is_in_block,
})

local write_line_out = s({
    trig = "out",
    wordTrig = true,
    name = "Print a string",
}, {
    t('Console.Out.WriteLine("'),
    i(0),
    t('");'),
}, {
    show_condition = context.is_in_block,
})

local print_variable = s({
    trig = "outv",
    wordTrig = true,
    name = "Print value of a variable",
}, {
    t('Console.Out.WriteLine("'),
    f(function(args) return args[1] end, { 1 }),
    t(' = {0}", '),
    i(1, "var"),
    t(");"),
}, {
    show_condition = context.is_in_block,
})

local throw_new = s({
    trig = "thr",
    wordTrig = true,
    name = "Throw new",
}, {
    t("throw new "),
    i(1),
    t("Exception("),
    i(2),
    t(");"),
}, {
    show_condition = context.is_in_block,
})

return {
    debug_assert,
    debug_assert_not_null,
    write_line,
    write_line_out,
    print_variable,
    throw_new,
}
