local ls = require("luasnip")

local function setup()
    ls.add_snippets("cs", require("csharp-snippets.ctor"))
    ls.add_snippets("cs", require("csharp-snippets.types"))
end

return {
    setup = setup,
}
