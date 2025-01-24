local luasnip = require("luasnip")
local s = luasnip.snippet
local i = luasnip.insert_node
local fmta = require("luasnip.extras.fmt").fmta
local ts_utils = require("nvim-treesitter.ts_utils")
local context = require("csharp-snippets.context")

local is_in_block = context.is_in_block

local function is_in_switch()
    local node = ts_utils.get_node_at_cursor()
    return node ~= nil and node:type() == "switch_body"
end

local function show_switch_expression()
    local proj = context.get_project_info()

    if proj == nil then return false end

    return is_in_block() and proj.lang_version >= 8
end

local if_block = s(
    {
        trig = "if",
        wordTrig = true,
        name = "if statement",
    },
    fmta(
        [[
    if (<expression>)
    {
        <body>
    }
    ]],
        {
            expression = i(1),
            body = i(0),
        }
    ),
    {
        show_condition = is_in_block,
    }
)

local else_if = s(
    {
        trig = "elif",
        wordTrig = true,
        name = "else if statement",
    },
    fmta(
        [[
    else if (<expression>)
    {
        <body>
    }
    ]],
        {
            expression = i(1),
            body = i(0),
        }
    ),
    {
        show_condition = is_in_block,
    }
)

local else_block = s(
    {
        trig = "else",
        wordTrig = true,
        name = "else statement",
    },
    fmta(
        [[
    else
    {
        <body>
    }
    ]],
        {
            body = i(0),
        }
    ),
    {
        show_condition = is_in_block,
    }
)

local ternary = s(
    {
        trig = "?:",
        wordTrig = true,
        name = "Ternary expression",
    },
    fmta(
        [[
    <expression> ? <a> : <b>;
    ]],
        {
            expression = i(1),
            a = i(2),
            b = i(3),
        }
    ),
    {
        show_condition = is_in_block,
    }
)

local switch = s(
    {
        trig = "switch",
        wordTrig = true,
        name = "switch statement",
    },
    fmta(
        [[
    switch (<variable>)
    {
        <body>
    }
]],
        {
            variable = i(1),
            body = i(0),
        }
    ),
    {
        show_condition = is_in_block,
    }
)

local case = s(
    {
        trig = "case",
        wordTrig = true,
        name = "switch case statement",
    },
    fmta(
        [[
    case <case>:
        <body>
        break;
]],
        {
            case = i(1),
            body = i(0),
        }
    ),
    {
        show_condition = is_in_switch,
    }
)

local default = s(
    {
        trig = "default",
        wordTrig = true,
        name = "switch default statement",
    },
    fmta(
        [[
    default:
        <body>
        break;
]],
        {
            body = i(0),
        }
    ),
    {
        show_condition = is_in_switch,
    }
)

local switch_expression = s(
    {
        trig = "switche",
        wordTrig = true,
        name = "switch expression",
    },
    fmta(
        [[
    <variable> switch {
        _ =>> <default>
    };
]],
        {
            variable = i(1),
            default = i(0),
        }
    ),
    {
        show_condition = show_switch_expression,
    }
)

local lock = s(
    {
        trig = "lock",
        wordTrig = true,
        name = "lock statement",
    },
    fmta(
        [[
    lock (<variable>)
    {
        <body>
    }
]],
        {
            variable = i(1),
            body = i(0),
        }
    ),
    {
        show_condition = is_in_block,
    }
)

local using = s(
    {
        trig = "using",
        wordTrig = true,
        name = "using statement",
    },
    fmta(
        [[
    using (<variable>)
    {
        <body>
    }
]],
        {
            variable = i(1),
            body = i(0),
        }
    ),
    {
        show_condition = is_in_block,
    }
)

local checked = s(
    {
        trig = "checked",
        wordTrig = true,
        name = "checked statement",
    },
    fmta(
        [[
    checked
    {
        <body>
    }
]],
        {
            body = i(0),
        }
    ),
    {
        show_condition = is_in_block,
    }
)

local unchecked = s(
    {
        trig = "unchecked",
        wordTrig = true,
        name = "unchecked statement",
    },
    fmta(
        [[
    unchecked
    {
        <body>
    }
]],
        {
            body = i(0),
        }
    ),
    {
        show_condition = is_in_block,
    }
)

local try = s(
    {
        trig = "try",
        wordTrig = true,
        name = "try catch",
    },
    fmta(
        [[
    try {
        <body>
    }
    catch (<type> <ex>)
    {
        <catch>
    }
]],
        {
            body = i(0),
            type = i(2, "Exception"),
            ex = i(3, "e"),
            catch = i(1),
        }
    ),
    {
        show_condition = is_in_block,
    }
)

local tryf = s(
    {
        trig = "tryf",
        wordTrig = true,
        name = "try finally",
    },
    fmta(
        [[
    try {
        <body>
    }
    finally {
        <finally>
    }
]],
        {
            body = i(1),
            finally = i(0),
        }
    ),
    {
        show_condition = is_in_block,
    }
)

return {
    if_block,
    else_if,
    else_block,
    ternary,
    switch,
    case,
    default,
    switch_expression,
    lock,
    using,
    checked,
    unchecked,
    try,
    tryf,
}
