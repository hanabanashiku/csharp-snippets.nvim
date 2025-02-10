local luasnip = require("luasnip")
local s = luasnip.snippet
local t = luasnip.text_node
local i = luasnip.insert_node
local f = luasnip.function_node

local ts_utils = require("nvim-treesitter.ts_utils")
local context = require("csharp-snippets.context")
local helpers = require("csharp-snippets.helpers")
local NodeTypes = require("csharp-snippets.NodeTypes")

--- @return string|nil
local function get_logger()
    local q = vim.treesitter.query.parse(
        "c_sharp",
        [[
(
    [
     (field_declaration
       (variable_declaration
         type: (_) @type
         (
            variable_declarator
                name: (identifier) @name
          )
         )
       ) 

       (property_declaration
         type: (_) @type
         name: (identifier) @name
         )

       (record_declaration
         (parameter_list
           (parameter
             type: (_) @type
             name: (identifier) @name
             )
           )
         )

       (struct_declaration
         (parameter_list
           (parameter
             type: (_) @type
             name: (identifier) @name
             )
           )
         )
     ]
    (#match? @type "^I?Logger")
)
    ]]
    )
    local root = ts_utils.get_node_at_cursor()
    root = root and ts_utils.get_root_for_node(root)
    if not root then return nil end

    for id, node in q:iter_captures(root, 0) do
        if q.captures[id] == "name" then return vim.treesitter.get_node_text(node, 0) end
    end
end

--- @return boolean
local function has_logger() return get_logger() ~= nil and context.is_in_block() end

local warning = s({
    trig = "logw",
    wordTrig = true,
    name = "Log warning",
}, {
    f(get_logger, {}),
    t('.LogWarning("'),
    i(1),
    t('");'),
}, {
    show_condition = has_logger,
})

local error = s({
    trig = "loge",
    wordTrig = true,
    name = "Log error",
}, {
    f(get_logger, {}),
    t('.LogError("'),
    i(1),
    t('");'),
}, {
    show_condition = has_logger,
})

local info = s({
    trig = "logi",
    wordTrig = true,
    name = "Log Information",
}, {
    f(get_logger, {}),
    t('.LogInformation("'),
    i(1),
    t('");'),
}, {
    show_condition = has_logger,
})

local trace = s({
    trig = "logt",
    wordTrig = true,
    name = "Log Trace",
}, {
    f(get_logger, {}),
    t('.LogTrace("'),
    i(1),
    t('");'),
}, {
    show_condition = has_logger,
})

return {
    warning,
    error,
    info,
    trace,
}
