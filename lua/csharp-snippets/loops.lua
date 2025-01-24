local luasnip = require("luasnip")
local s = luasnip.snippet
local i = luasnip.insert_node
local fmta = require("luasnip.extras.fmt").fmta

local is_in_block = require("csharp-snippets.context").is_in_block
local for_loop = s(
    {
        trig = "for",
        wordTrig = true,
        name = "for loop",
    },
    fmta(
        [[
for (var <variable> = 0; <variable> << <upper>; <variable>++)
{
    <body>
}
]],
        {
            variable = i(1, "i"),
            upper = i(2),
            body = i(0),
        },
        {
            repeat_duplicates = true,
        }
    ),
    {
        show_condition = is_in_block,
    }
)

local itli = s(
    {
        trig = "itli",
        wordTrig = true,
        name = "iterate an IList<>",
    },
    fmta(
        [[
for (var <index> = 0; <index> << <list>.Count; <index>++)
{
    var <item> = <list>[<index>];
    <body>
}
]],
        {
            index = i(1, "i"),
            list = i(2),
            item = i(3, "item"),
            body = i(0),
        },
        {
            repeat_duplicates = true,
        }
    ),
    {
        show_condition = is_in_block,
    }
)

local itar = s(
    {
        trig = "itar",
        wordTrig = true,
        name = "iterate an array",
    },
    fmta(
        [[
for (var <index> = 0; <index> << <list>.Length; <index>++)
{
    var <item> = <list>[<index>];
    <body>
}
]],
        {
            index = i(1, "i"),
            list = i(2),
            item = i(3, "item"),
            body = i(0),
        },
        {
            repeat_duplicates = true,
        }
    ),
    {
        show_condition = is_in_block,
    }
)

local ritar = s(
    {
        trig = "ritar",
        wordTrig = true,
        name = "iterate an array in reverse",
    },
    fmta(
        [[
for (var <index> = <list>.Length - 1; <index> >>= 0; <index>--)
{
    var <item> = <list>[<index>];
    <body>
}
]],
        {
            index = i(1, "i"),
            list = i(2),
            item = i(3, "item"),
            body = i(0),
        },
        {
            repeat_duplicates = true,
        }
    ),
    {
        show_condition = is_in_block,
    }
)

local ritli = s(
    {
        trig = "ritli",
        wordTrig = true,
        name = "iterate an IList<> in reverse",
    },
    fmta(
        [[
for (var <index> = <list>.Count - 1; <index> >>= <list>.Count; <index>--)
{
    var <item> = <list>[<index>];
    <body>
}
]],
        {
            index = i(1, "i"),
            list = i(2),
            item = i(3, "item"),
            body = i(0),
        },
        {
            repeat_duplicates = true,
        }
    ),
    {
        show_condition = is_in_block,
    }
)

local reverse_for_loop = s(
    {
        trig = "forr",
        wordTrig = true,
        name = "for loop in reverse",
    },
    fmta(
        [[
for (var <variable> = <upper> - 1; <variable> >>= 0; <variable>--)
{
    <body>
}
]],
        {
            variable = i(1, "i"),
            upper = i(2),
            body = i(0),
        },
        {
            repeat_duplicates = true,
        }
    ),
    {
        show_condition = is_in_block,
    }
)

local foreach = s(
    {
        trig = "foreach",
        wordTrig = "true",
        name = "foreach block",
    },
    fmta(
        [[
    foreach (var <variable> in <collection>)
    {
        <body>
    }
    ]],
        {
            variable = i(1, "x"),
            collection = i(2),
            body = i(3),
        },
        {
            show_condition = is_in_block,
        }
    )
)

local while_loop = s(
    {
        trig = "while",
        wordTrig = true,
        name = "while loop",
    },
    fmta(
        [[
    while (<expression>)
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
local do_while_loop = s(
    {
        trig = "do",
        wordTrig = true,
        name = "do..while loop",
    },
    fmta(
        [[
    do
f   {
        <body>
    }
    while (<expression>);
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

return {
    for_loop,
    foreach,
    itli,
    itar,
    ritli,
    ritar,
    reverse_for_loop,
    while_loop,
    do_while_loop,
}
