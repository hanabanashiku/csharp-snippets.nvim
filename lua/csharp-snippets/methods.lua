local luasnip = require("luasnip")
local s = luasnip.snippet
local c = luasnip.choice_node
local t = luasnip.text_node
local i = luasnip.insert_node
local fmta = require("luasnip.extras.fmt").fmta
local ts_utils = require("nvim-treesitter.ts_utils")
local context = require("csharp-snippets.context")
local NodeTypes = require("csharp-snippets.NodeTypes")

local sc = luasnip.extend_decorator.apply(s, {
    show_condition = function()
        local node = ts_utils.get_node_at_cursor()
        return node == nil or node:type() == NodeTypes.DECLARATIONS or node:type() == NodeTypes.FILE
    end,
})

local method = sc(
    {
        trig = "()",
        wordTrig = true,
        name = "Method",
    },
    fmta(
        [[
    <modifiers><static><return_type> <name>(<parameters>)
    {
        <body>
    }
    ]],
        {
            modifiers = c(1, {
                t("public "),
                t("private "),
                t("protected "),
                t("internal "),
            }),
            static = c(2, {
                t(""),
                t("static "),
                t("abstract "),
                t("virtual "),
            }),
            return_type = i(3),
            name = i(4),
            parameters = i(5),
            body = i(0),
        }
    )
)

local property = sc(
    {
        trig = "prop",
        wordTrig = true,
        name = "Property",
    },
    fmta(
        [[
    <modifiers> <return_type> <name> { get; set; }
    ]],
        {
            modifiers = c(1, {
                t("public "),
                t("private "),
                t("protected "),
                t("internal "),
            }),
            return_type = i(2),
            name = i(3),
        }
    )
)

local getter = sc(
    {
        trig = "propg",
        wordTrig = true,
        name = "Property Getter",
    },
    fmta(
        [[
    <modifiers> <return_type> <name> { get; }
    ]],
        {
            modifiers = c(1, {
                t("public "),
                t("private "),
                t("protected "),
                t("internal "),
            }),
            return_type = i(2),
            name = i(3),
        }
    )
)

local main = s(
    {
        trig = "main",
        wordTrig = true,
        name = "Main method",
    },
    fmta(
        [[
    public static void Main(string[] args)
    {
        <body>
    }
    ]],
        {
            body = i(0),
        }
    ),
    {
        show_condition = function() return context.get_class_name() == "Program" and not context.is_in_block() end,
    }
)

return {
    method,
    property,
    getter,
    main,
}
