local function is_buffer_not_empty() return vim.fn.empty(vim.fn.getline(1)) ~= 1 or vim.fn.line("$") ~= 1 end

return function()
    vim.api.nvim_create_autocmd("BufReadPost", {
        pattern = "*.cs",
        callback = function()
            if is_buffer_not_empty() then return end

            local file_path = vim.fn.expand("%:p")
            local file_name = vim.fn.expand("%:t")
            local ls = require("luasnip")
            ls.snip_expand(_G["Namespace_Snippet"])

            -- Check if the namespace was file scoped or not and move accordingly
            local file_scoped = vim.fn.getline(2) ~= "{"
            vim.api.nvim_win_set_cursor(0, { 3, file_scoped and 1 or 5 })
            local context = require("csharp-snippets.context")

            if file_path:match("[Ee]num") then
                ls.snip_expand(_G[""])
            elseif file_path:match("Attribute.cs$") then
                ls.snip_expand(_G["Attribute_Snippet"])
            elseif file_path:match("Controller.cs$") then
                ls.snip_expand(_G["Controller_Snippet"])
            elseif file_name:sub(0, 1) == "I" then
                ls.snip_expand(_G["Interface_Snippet"])
            elseif file_name:match("[Tt]ests?") and context.get_test_library() ~= nil then
                ls.snip_expand(_G["Test_Fixture_Snippets"][context.get_test_library()])
            else
                ls.snip_expand(_G["Class_Snippet"])
            end
        end,
    })

    vim.api.nvim_create_autocmd("BufReadPost", {
        pattern = { "launchSettings.json" },
        callback = function()
            if is_buffer_not_empty() then return end
            local ls = require("luasnip")
            ls.snip_expand(_G["LaunchSettings_Snippet"])
        end,
    })
end
