local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local i = ls.insert_node
local d = ls.dynamic_node
local c = ls.choice_node
local t = ls.text_node
local fmta = require("luasnip.extras.fmt").fmta
local ts_utils = require("nvim-treesitter.ts_utils")

local context = require("csharp-snippets.context")

local function get_file_name()
    local path = vim.api.nvim_buf_get_name(0)
    return vim.fn.fnamemodify(path, ":t:r")
end

local function get_default_name()
    local name = get_file_name()

    if context.has_type_defined(name) then return sn(nil, i(1)) end

    return sn(nil, i(1, name))
end

local function get_default_interface_name()
    local name = get_file_name()
    if name:sub(0, 1) ~= "I" then name = "I" .. name end

    if context.has_type_defined(name) then return sn(nil, { t("I"), i(1) }) end

    return sn(nil, i(1, name))
end

local function can_create_type()
    local node = ts_utils.get_node_at_cursor()
    return node == nil or node:type() == "declaration_list" or node:type() == "compilation_unit"
end

local class = s(
    {
        trig = "class",
        wordTrig = true,
        name = "Class",
    },
    fmta(
        [[
    <modifiers><static>class <identifier>
    {
        <body>
    }
    ]],
        {
            modifiers = c(2, {
                t("public "),
                t("private "),
                t("abstract "),
                t("internal "),
                t("protected "),
                t(""),
            }),
            static = c(3, {
                t(""),
                t("static "),
                t("sealed "),
                t("unsafe "),
            }),
            identifier = d(1, get_default_name, {}),
            body = i(0),
        }
    ),
    {
        show_condition = can_create_type,
    }
)

local struct = s(
    {
        trig = "struct",
        wordTrig = true,
        name = "Struct",
    },
    fmta(
        [[
    <modifiers><ref>struct <identifier>
    {
        <body>
    }
    ]],
        {
            modifiers = c(3, {
                t("public "),
                t("private "),
                t("protected "),
                t("internal "),
                t(""),
            }),
            ref = c(4, {
                t(""),
                t("readonly "),
                t("ref "),
                t("partial "),
            }),
            identifier = d(2, get_default_name, {}),
            body = i(1),
        }
    ),
    {
        show_condition = can_create_type,
    }
)

local interface = s(
    {
        trig = "interface",
        wordTrig = false,
        name = "Interface",
    },
    fmta(
        [[
    <modifiers><partial>interface <identifier>
    {
        <body>
    }
    ]],
        {
            modifiers = c(2, {
                t("public "),
                t("private "),
                t("protected "),
                t("internal "),
                t(""),
            }),
            partial = c(3, {
                t(""),
                t("partial "),
                t("unsafe "),
            }),
            identifier = d(4, get_default_interface_name, {}),
            body = i(1),
        }
    ),
    {
        show_condition = can_create_type,
    }
)

local enum = s(
    {
        trig = "enum",
        wordTrig = true,
        name = "Enum",
    },
    fmta(
        [[
    <modifier>enum <identifier><base>
    {
        <body>
    }
    ]],
        {
            modifier = c(3, {
                t("public "),
                t("protected "),
                t("private "),
                t("internal "),
                t(""),
            }),
            identifier = d(2, get_default_name, {}),
            base = c(4, {
                t(""),
                t(" : long"),
                t(" : byte"),
                t(" : uint"),
                t(" : short"),
                t(" : ushort"),
                t(" : ulong"),
                t(" : sbyte"),
            }),
            body = i(1),
        }
    ),
    {
        show_condition = can_create_type,
    }
)

Class_Snippet = class
Enum_Snippet = enum
Interface_Snippet = interface

return {
    class,
    struct,
    interface,
    enum,
}
