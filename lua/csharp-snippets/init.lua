local ls = require("luasnip")

local M = {}

function M.setup()
    if not vim.treesitter then
        vim.notify("Treesitter not found", vim.log.levels.WARN)
        return
    elseif not require("nvim-treesitter.parsers").has_parser("c_sharp") then
        vim.cmd("TSInstall c_sharp")
    end

    require("csharp-snippets.ts_queries")()

    ls.add_snippets("cs", require("csharp-snippets.ctor"))
    ls.add_snippets("cs", require("csharp-snippets.types"))
    ls.add_snippets("cs", require("csharp-snippets.namespace"))
    ls.add_snippets("cs", require("csharp-snippets.loops"))
    ls.add_snippets("cs", require("csharp-snippets.blocks"))
    ls.add_snippets("cs", require("csharp-snippets.tests"))
    ls.add_snippets("cs", require("csharp-snippets.xmldoc"))
    ls.add_snippets("cs", require("csharp-snippets.equatable"))
    ls.add_snippets("cs", require("csharp-snippets.logging"))
    ls.add_snippets("cs", require("csharp-snippets.statements"))
    ls.add_snippets("json", require("csharp-snippets.configuration"))

    require("csharp-snippets.autocmd")()
end

return M
