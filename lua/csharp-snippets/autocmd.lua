-- vim.api.nvim_create_autocmd("BufReadPost", {
--     pattern = "*.cs",
--     callback = function(ev)
--         -- check if buffer is empty
--         if vim.fn.empty(vim.fn.getline(1)) ~= 1 or vim.fn.line("$") ~= 1 then
--             return
--         end
--
--         -- local file_path = vim.fn.expand("%:p")
--         -- local file_name = vim.fn.expand("%:t")
--         local ls = require("luasnip")
--         local namespace = _G.Namespace_Snippet
--         vim.print(namespace)
--
--         ls.snip_expand(namespace)
--
--         -- if file_path:match("[Ee]num") then
--         -- end
--
--     end
-- })

return {
    test = function ()
                -- local ls = require("luasnip")
                -- local namespace = _G["Namespace_Snippet"]
                -- ls.snip_expand(namespace)
                -- namespace:jump_into(0)
    end
}
