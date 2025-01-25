local luasnip = require("luasnip")
local s = luasnip.snippet
local d = luasnip.dynamic_node
local t = luasnip.text_node
local i = luasnip.insert_node
local sn = luasnip.snippet_node
local ts_utils = require("nvim-treesitter.ts_utils")

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

local function get_exceptions(declaration)
    local block = declaration:field("body")
    if #block == 0 or block[1]:type() ~= "block" then return {} end

    block = block[1]

    local function iterate(node)
        if node == nil then return {} end

        if node:type() == "throw_statement" then
            local child = node:child(1)
            if child:type() == "object_creation_expression" then
                return { vim.treesitter.get_node_text(child:field("type")[1], 0) }
            end

            -- throwing a variable
            if child:type() == "identifier" then
                if #vim.lsp.get_clients() == 0 then return {} end

                local start_row, start_col = child:start()
                local params = {
                    textDocument = vim.lsp.util.make_text_document_params(0),
                    position = {
                        line = start_row,
                        character = start_col,
                    },
                }
                local definition = vim.lsp.buf_request_sync(0, "textDocument/definition", params, 1000)
                if definition == nil then return {} end
                for _, definition_item in pairs(definition) do
                    if definition_item.result and definition_item.result[1] then
                        definition_item = definition_item.result[1]
                        local range = definition_item.targetRange or definition_item.range

                        local definition_node = vim.treesitter.get_node({
                            pos = {
                                range.start.line,
                                range.start.character + 1,
                            },
                        })

                        while definition_node ~= nil do
                            local type = definition_node:field("type")
                            if #type > 0 then return { vim.treesitter.get_node_text(type[1], 0) } end

                            definition_node = definition_node:parent()
                        end
                    end
                end
                return {}
            end

            -- "throw;" - must be a catch block
            if child:type() == ";" then
                local parent = node:parent()
                while parent ~= nil do
                    local type = parent:type()
                    if type == "catch_clause" then
                        vim.print(parent:child(1):type())
                        local exception_type = parent:child(1):field("type")
                        local default = vim.fn.search("using System;", "w") > 0 and "Exception" or "System.Exception"
                        return {
                            #exception_type > 0 and vim.treesitter.get_node_text(exception_type[1], 0) or default,
                        }
                    end

                    parent = parent:parent()
                end
            end

            return {}
        end

        local exceptions = {}
        local seen = {}
        for child in node:iter_children() do
            for _, ex in ipairs(iterate(child)) do
                if not seen[ex] then
                    table.insert(exceptions, ex)
                    seen[ex] = true
                end
            end
        end

        return exceptions
    end

    return iterate(block)
end

local get_return = function(node)
    local type = node:type()
    local return_type

    if type == "operator_declaration" then
        return_type = node:field("type")
    elseif type == "method_declaration" then
        return_type = node:field("returns")
    else
        return_type = {}
    end

    local return_text = #return_type > 0 and vim.treesitter.get_node_text(return_type[1], 0) or nil

    if return_text == "void" or return_text == "Task" or return_text == "ValueTask" then return nil end
    return return_text
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
        local returns = get_return(node)
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

        if returns ~= nil then
            table.insert(parts, t({ "", "/// <returns>" }))
            table.insert(parts, i(#parameters + 2))
            table.insert(parts, t({ "</returns>" }))
        end

        if #exceptions > 0 then
            for idx, exception in ipairs(exceptions) do
                table.insert(parts, t({ "", '/// <exception cref="' .. exception .. '">' }))
                table.insert(parts, i(#parameters + 1 + (returns and 1 or 0) + idx))
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
