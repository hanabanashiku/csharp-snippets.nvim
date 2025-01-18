local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local isn = ls.indent_snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local events = require("luasnip.util.events")
local ai = require("luasnip.nodes.absolute_indexer")
local extras = require("luasnip.extras")
local l = extras.lambda
local rep = extras.rep
local p = extras.partial
local m = extras.match
local n = extras.nonempty
local dl = extras.dynamic_lambda
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local conds = require("luasnip.extras.expand_conditions")
local postfix = require("luasnip.extras.postfix").postfix
local types = require("luasnip.util.types")
local parse = require("luasnip.util.parser").parse_snippet
local ms = ls.multi_snippet
local k = require("luasnip.nodes.key_indexer").new_key

local context = require("csharp-snippets.context")

local function format_parameter_name(name)
    if name:sub(0, 1) == "_" then
        return name:sub(2)
    end

    return name
end

local function build_constructor_parameters()
    local fields = context.get_class_fields()

    if fields == nil or #fields == 0 then return "" end

    local parameters = ""
    for idx, field in ipairs(fields) do
        local comma = idx == #fields and "" or ", "
        local name = format_parameter_name(field.name)
        parameters = parameters .. field.type .. " " .. name .. comma
    end

    return parameters
end

local function build_constructor_body()
    local fields = context.get_class_fields()
    local body = ""
    local first = true

    if fields == nil or #fields == 0 then return body end

    for _, field in ipairs(fields) do
        if not first then
            body = body .. "\n"
        else
            first = false
        end

        local parameter_name = format_parameter_name(field.name)
        local this = parameter_name ~= field.name and "" or "this."
        body = this .. body .. field.name .. " = " .. parameter_name .. ";"
    end

    return body
end

return {
    s(
        {
            trig = "ctor",
            wordTrig = true,
            name = "Constructor",
        },
        fmta(
            [[
    public <name>()
    {
        <body>
    }

    ]],
            {
                name = f(context.get_class_name, {}),
                body = i(0),
            }
        ),
        {
            condition = context.is_in_class,
        }
    ),

    s(
        {
            trig = "ctorf",
            wordTrig = true,
            name = "Constructor with fields",
        },
        fmta(
            [[
    public <name>(<parameters>)
    {
        <body>
    }

    ]],
            {
                name = f(context.get_class_name, {}),
                parameters = f(build_constructor_parameters, {}),
                body = f(build_constructor_body, {})
            }
        ),
        {
            condition = function() return context.is_in_class() and #context.get_class_fields() > 0 end,
        }
    ),

    s(
        {
            trig = "~",
            wordTrig = true,
            name = "Destructor",
        },
        fmta(
            [[
        ~<name>()
        {
            <body>
        }

        ]],
            {
                name = f(context.get_class_name, {}),
                body = i(0),
            }
        ),
        {
            condition = context.is_in_class,
        }
    ),
}
