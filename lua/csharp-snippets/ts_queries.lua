local query = vim.treesitter.query
local lang = "c_sharp"

return function()
    query.set(
        lang,
        "cssnip_get_fields",
        [[
(
    declaration_list
        (field_declaration
            (modifier)* @mod
            (variable_declaration
                type: (_) @type
                (variable_declarator
                    name: (identifier) @name
                )
            )
        ) @field
)
]]
    )

    query.set(
        lang,
        "cssnip_find_type",
        [[

(_
    name: (identifier) @name
    (#eq? @name "%s")
) @class
]]
    )
end
