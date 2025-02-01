local ls = require("luasnip")

local function setup()
    ls.add_snippets("cs", require("csharp-snippets.ctor"))
    ls.add_snippets("cs", require("csharp-snippets.types"))
    ls.add_snippets("cs", require("csharp-snippets.namespace"))
    ls.add_snippets("cs", require("csharp-snippets.loops"))
    ls.add_snippets("cs", require("csharp-snippets.blocks"))
    ls.add_snippets("cs", require("csharp-snippets.tests"))
    ls.add_snippets("cs", require("csharp-snippets.xmldoc"))
    ls.add_snippets("cs", require("csharp-snippets.equatable"))
    ls.add_snippets("json", require("csharp-snippets.configuration"))

    require("csharp-snippets.autocmd")
end

return {
    setup = setup,
}
