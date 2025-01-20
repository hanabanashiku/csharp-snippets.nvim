vim.api.nvim_create_autocmd("BufReadPost", {
    pattern = "*.cs",
    callback = function()
        -- check if buffer is empty
        if vim.fn.empty(vim.fn.getline(1)) ~= 1 or vim.fn.line("$") ~= 1 then
            return
        end

        local file_path = vim.fn.expand("%:p")
        local file_name = vim.fn.expand("%:t")
        local ls = require("luasnip")
        ls.snip_expand(_G["Namespace_Snippet"])

        -- Check if the namespace was file scoped or not and move accordingly
        local file_scoped = vim.fn.getline(2) ~= "{"
        vim.api.nvim_win_set_cursor(0, {3, file_scoped and 1 or 5})

        if file_path:match("[Ee]num") then
            ls.snip_expand(_G[""])
        elseif file_name:sub(0, 1) == "I" then
            ls.snip_expand(_G["Interface_Snippet"])
        -- elseif file_name:match("[Tt]ests?") then
        --     ls.snip_expand(_G["Test_Snippet"])
        else
            ls.snip_expand(_G["Class_Snippet"])
        end
    end
})
