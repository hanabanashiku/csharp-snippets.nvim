-- Register all the snippets in snippets.lua
local snippets = require("csharp-snippets.snippets")
local ls = require("luasnip")

local function setup()
    ls.add_snippets("cs", snippets)
end

return {
    setup = setup
}