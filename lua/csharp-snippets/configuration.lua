local luasnip = require("luasnip")
local s = luasnip.snippet
local f = luasnip.function_node
local i = luasnip.insert_node
local fmta = require("luasnip.extras.fmt").fmta
local context = require("csharp-snippets.context")

local launchSettings = s(
    {
        trig = "launchSettings",
        wordTrig = false,
        name = "Launch settings.json",
    },
    fmta(
        [[
        {
            "$schema": "http://json.schemastore.org/launchsettings.json",
            "profiles": {
                "<project_name>": {
                    "commandName": "Project",
                    "dotnetRunMessages": true,
                    "launchBrowser": true,
                    "launchUrl": "swagger",
                    "applicationUrl": "https://localhost:<https_port>;http://localhost:<http_port>",
                    "environmentVariables": {
                        "ASPNETCORE_ENVIRONMENT": "Development"
                    }
                }
            }
        }
        ]],
        {
            project_name = f(function() return context.get_project_info().default_namespace end),
            https_port = i(1, "5001"),
            http_port = i(2, "5000"),
        }
    ),
    {
        show_condition = function()
            local file_name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t:r")
            return string.lower(file_name) == "launchsettings" and context.get_csproj() ~= nil
        end,
    }
)
_G["LaunchSettings_Snippet"] = launchSettings

return { launchSettings }
