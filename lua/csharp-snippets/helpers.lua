---@param node TSNode
---@param type string
---@return TSNode|nil
local function field_by_type(node, type)
    if node == nil or type == nil then return nil end

    for child in node:iter_children() do
        if child:type() == type then return child end
    end

    return nil
end

---@param node TSNode
---@param name string
---@return TSNode|nil
local function field_by_name(node, name)
    if node == nil or type == nil then return nil end

    local fields = node:field(name)
    if #fields == 0 then return nil end
    return fields[1]
end

return {
    field_by_type = field_by_type,
    field_by_name = field_by_name,
}
