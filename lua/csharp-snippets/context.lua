local ts_utils = require("nvim-treesitter.ts_utils")
local ts = vim.treesitter

local function get_enclosing_class()
    local node = ts_utils.get_node_at_cursor()
    while node do
        if node:type() == "class_declaration" then return node end
        node = node:parent()
    end
    return nil
end

local function get_class_name()
    local class = get_enclosing_class()
    if class == nil then return nil end

    local name = class:field("name")[1]
    return ts.get_node_text(name, 0)
end

local function get_class_fields()
    local class = get_enclosing_class()
    if class == nil then return nil end

    local body = class:field("body")[1]
    local fields = {}
    for child in body:iter_children() do
        local variable = child:child(child:child_count() - 2)
        if child:type() == "field_declaration" and variable ~= nil then
            table.insert(fields, {
                type = vim.treesitter.get_node_text(variable:field("type")[1], 0),
                name = vim.treesitter.get_node_text(variable:child(1):field("name")[1], 0),
                node = child,
            })
        end
    end

    return fields
end

local function has_type_defined(name)
    local node = ts_utils.get_node_at_cursor()

    if node == nil then
        return false
    end

    local root = ts_utils.get_root_for_node(node)

    for declaration in root:iter_children() do
        vim.print(declaration:type())
        if vim.treesitter.get_node_text(declaration:field("name")[1], 0) == name then
            return true
        end
    end

    return false
end

local function is_in_class() return get_class_name() ~= nil end

return {
    get_class_name = get_class_name,
    is_in_class = is_in_class,
    get_class_fields = get_class_fields,
    has_type_defined = has_type_defined,
}
