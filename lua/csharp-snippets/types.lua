local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local i = ls.insert_node
local d = ls.dynamic_node
local c = ls.choice_node
local t = ls.text_node
local f = ls.function_node
local k = require("luasnip.nodes.key_indexer").new_key
local fmta = require("luasnip.extras.fmt").fmta
local ts_utils = require("nvim-treesitter.ts_utils")

local NodeTypes = require("csharp-snippets.NodeTypes")
local context = require("csharp-snippets.context")

local function get_file_name()
    local path = vim.api.nvim_buf_get_name(0)
    return vim.fn.fnamemodify(path, ":t:r")
end

local function get_default_name()
    local name = get_file_name()

    if context.has_type_defined(name) then return sn(nil, i(1, "", { key = "identifier" })) end

    return sn(nil, i(1, name, { key = "identifier" }))
end

local function get_default_interface_name()
    local name = get_file_name()
    if name:sub(0, 1) ~= "I" then name = "I" .. name end

    if context.has_type_defined(name) then return sn(nil, { t("I"), i(1) }) end

    return sn(nil, i(1, name))
end

local function can_create_type()
    local node = ts_utils.get_node_at_cursor()
    return node == nil or node:type() == NodeTypes.DECLARATIONS or node:type() == NodeTypes.FILE
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

local controller = s(
    {
        trig = "controller",
        wordTrig = true,
        name = "Asp.NET Core Controller",
    },
    fmta(
        [[
    <api_attribute>
    <modifiers><static>class <identifier> : <base>
    {
        <body>
    }
    ]],
        {
            api_attribute = c(5, {
                t("[ApiController]"),
                t({}),
            }),
            modifiers = c(3, {
                t("public "),
                t("private "),
                t("abstract "),
                t("internal "),
                t("protected "),
                t(""),
            }),
            static = c(4, {
                t(""),
                t("static "),
                t("sealed "),
                t("unsafe "),
            }),
            identifier = d(1, get_default_name, {}),
            base = i(2, "Controller"),
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

local attribute = s(
    {
        trig = "attribute",
        wordTrig = true,
        name = "Attribute",
    },
    fmta(
        [[
    [AttributeUsage(AttributeTargets.<target>, Inherited = <inherited>, AllowMultiple = <allow_multiple>)]
    <modifier>sealed class <identifier> : Attribute
    {
        <body>
    }
    ]],
        {
            target = c(1, {
                t("Class"),
                t("Enum"),
                t("Parameter"),
                t("Property"),
                t("Method"),
                t("Assembly"),
                t("Module"),
                t("Struct"),
                t("Constructor"),
                t("Field"),
                t("Event"),
                t("Interface"),
                t("Delegate"),
                t("ReturnValue"),
                t("GenericParameter"),
                t("All"),
            }),
            inherited = c(2, {
                t("false"),
                t("true"),
            }),
            allow_multiple = c(3, {
                t("false"),
                t("true"),
            }),
            modifier = c(4, {
                t("public "),
                t("private "),
                t("protected "),
                t("internal "),
                t(""),
            }),
            identifier = d(5, get_default_name, {}),
            body = i(0),
        }
    ),
    {
        show_condition = can_create_type,
    }
)

local exception = s({
    trig = "ex",
    wordTrig = true,
    name = "Exception",
}, {
    t("public class "),
    d(1, get_default_name, {}),
    t({
        " : Exception",
        "{",
        "",
    }),
    t("    public "),
    f(function(args) return args[1] end, k("identifier")),
    t("()"),
    t({ "", "    {", "" }),
    t("        "),
    i(2),
    t({ "", "    }", "", "" }),
    t("    public "),
    f(function(args) return args[1] end, k("identifier")),
    t("(string message) : base(message)"),
    t({ "", "    {", "" }),
    t("        "),
    i(3),
    t({ "", "    }", "" }),
    t("    public "),
    f(function(args) return args[1] end, k("identifier")),
    t("(string message, Exception inner) : base(message, inner)"),
    t({ "", "    {", "" }),
    t("        "),
    i(4),
    t({ "", "    }", "" }),
    t("}"),
}, {
    show_condition = can_create_type,
})

Class_Snippet = class
Controller_Snippet = controller
Enum_Snippet = enum
Interface_Snippet = interface
Attribute_Snippet = attribute
Exception_Snippet = exception

return {
    class,
    controller,
    struct,
    interface,
    enum,
    attribute,
    exception,
}
