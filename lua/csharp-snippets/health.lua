local h = vim.health

local M = {}

M.check = function()
    h.start("csharp-snippets")
    local ls, _ = pcall(require, "luasnip")
    local ts, _ = pcall(require, "nvim-treesitter")

    if ls then
        h.ok("luasnip is installed")
    else
        h.error("luasnip is required to register the snippets")
    end

    if ts and vim.treesitter then
        h.ok("nvim-treesitter is installed")

        if not require("nvim-treesitter.parsers").has_parser("c_sharp") then
            h.error("The c_sharp parser is missing. Please run `:TSInstall c_sharp`")
        end
    else
        h.error("nvim-treesitter is required")
    end

    local lsp_client

    for _, client in pairs(vim.lsp.get_clients()) do
        if client.name == "roslyn" or client.name == "omnisharp" then
            lsp_client = client.name
            break
        end
    end

    if lsp_client then
        h.ok("LSP client: " .. lsp_client .. " is installed")
    else
        h.warn(
            "Some features will be unavailable if there is not a LSP client installed for C#. The Roslyn client is recommended. See `:h csharp-snippets-lsp` for more information"
        )
    end
end

return M
