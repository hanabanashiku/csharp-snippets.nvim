local luasnip = require("luasnip")
local s = luasnip.snippet
local d = luasnip.dynamic_node
local t = luasnip.text_node
local i = luasnip.insert_node
local sn = luasnip.snippet_node

local function get_declaration()
    local function matches(node)
        if node == nil then return false end
        local type = node:type()
        if
            type == "class_declaration"
            or type == "enum_declaration"
            or type == "interface_declaration"
            or type == "struct_declaration"
            or type == "record_declaration"
            or type == "method_declaration"
            or type == "property_declaration"
            or type == "constructor_declaration"
            or type == "operator_declaration"
        then
            return true
        end
        return false
    end

    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local root = vim.treesitter.get_node({ pos = { row, col } })
    if not root then return nil end
    local parent = root:parent()

    if parent ~= nil and matches(parent) and vim.treesitter.get_range(parent)[1] == row then return root:parent() end

    for node in root:iter_children() do
        local start_row, _, end_row, _ = node:range()
        if start_row == row and end_row >= row and matches(node) then return node end
    end

    return nil
end

local function get_parameters(node)
    local parameters = nil

    local function populate(parameters_field)
        parameters = {}
        for parameter in parameters_field:iter_children() do
            if parameter:type() == "parameter" then
                table.insert(parameters, {
                    name = vim.treesitter.get_node_text(parameter:field("name")[1], 0),
                    type = vim.treesitter.get_node_text(parameter:field("type")[1], 0),
                })
            end
        end
    end

    if node == nil then return nil end
    if #node:field("parameters") > 0 then populate(node:field("parameters")[1]) end

    for child in node:iter_children() do
        if child:type() == "parameter_list" then
            populate(child)
            break
        end
    end

    return parameters
end

local function get_exceptions(node)
    local block = node:field("body")
    if #block == 0 or block[1]:type() ~= "block" then return {} end

    block = block[1]
    local exception = {}

    -- todo
    return exception
end

local has_return = function(node)
    local type = node:type()

    if type == "operator_declaration" then
        return true
    elseif type ~= "method_declaration" then
        return false
    end

    local return_type = node:field("returns")
    return #return_type > 0 and vim.treesitter.get_node_text(return_type[1], 0) ~= "void"
end

local xmldoc = s(
    {
        trig = "///",
        wordTrig = true,
        name = "XMLDoc",
    },
    d(1, function()
        local node = get_declaration()
        local parameters = get_parameters(node)
        local returns = has_return(node)
        local exceptions = get_exceptions(node)
        local parts = {
            t({ "/// <summary>", "///  " }),
            i(1),
            t({ "", "/// </summary>" }),
        }

        if parameters ~= nil then
            for idx, param in ipairs(parameters) do
                table.insert(parts, t({ "", '/// <param name="' .. param.name .. '">' }))
                table.insert(parts, i(idx + 1))
                table.insert(parts, t({ "</param>" }))
            end
        end

        if returns then
            table.insert(parts, t({ "", "/// <returns>" }))
            table.insert(parts, i(#parameters + 2))
            table.insert(parts, t({ "</returns>" }))
        end

        if #exceptions > 0 then
            for idx, exception in ipairs(exceptions) do
                table.insert(parts, t({ "", '/// <exception cref="' .. exception .. '">' }))
                table.insert(parts, i(#parameters + 2 + (returns and 1 or 0) + idx))
                table.insert(parts, t({ "</exception>" }))
            end
        end

        return sn(nil, parts)
    end, {}),
    {
        show_condition = function() return get_declaration() ~= nil end,
    }
)

return {
    xmldoc,
}
