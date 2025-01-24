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
    -- vim.print(row, col)
    local root = vim.treesitter.get_node({ pos = { row, col } })
    if not root then return nil end
    local parent = root:parent()

    if parent ~= nil and matches(parent) and vim.treesitter.get_range(parent)[1] == row then return root:parent() end

    for node in root:iter_children() do
        local start_row, _, end_row, _ = node:range()
        -- vim.print(node:type(), start_row, end_row)
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

return {
    get_declaration = get_declaration,
    get_parameters = get_parameters,
}
