local luasnip = require("luasnip")
local s = luasnip.snippet
local t = luasnip.text_node
local i = luasnip.insert_node
local f = luasnip.function_node

local context = require("csharp-snippets.context")
local helpers = require("csharp-snippets.helpers")
local NodeTypes = require("csharp-snippets.NodeTypes")

--- @return string|nil
local function get_logger()
    local class = context.get_enclosing_class()
    if not class then return nil end
    local body = helpers.field_by_name(class, "body")
    local parameters = helpers.field_by_type(class, NodeTypes.CLASS_PARAMETERS)

    if body then
        for child in body:iter_children() do
            local type = helpers.field_by_name(child, "type")
            if type and vim.treesitter.get_node_text(type, 0):match("I?Logger") then
                local name = helpers.field_by_name(child, "name")
                return name and vim.treesitter.get_node_text(name, 0)
            elseif child:type() == NodeTypes.FIELD then
                local var = helpers.field_by_type(child, NodeTypes.VARIABLE)
                type = var and helpers.field_by_name(var, "type")
                if var and type and vim.treesitter.get_node_text(type, 0):match("I?Logger") then
                    local declarator = helpers.field_by_type(var, NodeTypes.VARIABLE_DECLARATOR)
                    local name = declarator and helpers.field_by_name(declarator, "name")
                    return name and vim.treesitter.get_node_text(name, 0)
                end
            end
        end
    end

    if class:type() == NodeTypes.RECORD and parameters ~= nil then
        for child in parameters:iter_children() do
            local type = helpers.field_by_name(child, "type")
            if type and vim.treesitter.get_node_text(type, 0):match("I?Logger") then
                return vim.treesitter.get_node_text(type, 0)
            end
        end
    end

    return nil
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
