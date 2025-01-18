local ls = require("luasnip")

local function setup()
    ls.add_snippets("cs", require("csharp-snippets.ctor"))
    ls.add_snippets("cs", require("csharp-snippets.types"))
    ls.add_snippets("cs", require("csharp-snippets.namespace"))
end

return {
    setup = setup,
}
