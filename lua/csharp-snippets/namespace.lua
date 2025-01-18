local luasnip = require("luasnip")
local s = luasnip.snippet
local sn = luasnip.snippet_node
local i = luasnip.insert_node
local t = luasnip.text_node
local d = luasnip.dynamic_node
local fmta = require("luasnip.extras.fmt").fmta

local ts_utils = require("nvim-treesitter.ts_utils")
local context = require("csharp-snippets.context")

local function file_scoped_supported()
    local editorconfig = context.get_editorconfig() or {}
    if editorconfig["csharp_style_namespace_declarations"] == "block_scoped" then return false end

    local csproj = context.get_project_info()
    if csproj == nil then return false end

    if (csproj.latest_core_version or 0) < 6 then return false end

    return csproj.lang_version >= 10
end

local function namespace_supported()
    local node = ts_utils.get_node_at_cursor()
    if node == nil then return true end

    -- Must be root level or within a namespace
    if
        node:type() ~= "compilation_unit" and (node:parent() ~= nil and node:parent():type() ~= "namespace_declaration")
    then
        return false
    end

    -- Must not be within a file scoped namespace
    for child in ts_utils.get_root_for_node(node):iter_children() do
        if child:type() == "file_scoped_namespace_declaration" then return false end
    end

    return true
end

local function use_file_scoped()
    if not file_scoped_supported() then return false end

    for child in ts_utils.get_root_for_node(ts_utils.get_node_at_cursor()):iter_children() do
        if child:type() == "file_scoped_namespace_declaration" or child:type() == "namespace_declaration" then
            return false
        end
    end

    local node = ts_utils.get_node_at_cursor()
    return node ~= nil and node:type() == "compilation_unit"
end

local function resolve_default_namespace()
    local file = vim.api.nvim_buf_get_name(0)
    local dir = vim.fn.fnamemodify(file, ":h")
    local csproj_path = context.get_csproj()
    local proj_info = context.get_project_info()
    if csproj_path == nil or proj_info == nil then return nil end

    csproj_path = vim.fn.fnamemodify(csproj_path, ":h")
    local diff = dir:gsub(csproj_path, "")

    if diff == "" then return proj_info.default_namespace end

    diff = diff:gsub("/", ".")
    return proj_info.default_namespace .. diff
end

local function namespace()
    local file_scoped = use_file_scoped()
    local default_namespace = resolve_default_namespace()

    if file_scoped then
        return sn(nil, {
            t("namespace "),
            i(1, default_namespace),
            t({ ";", "" }),
            i(0),
        })
    end

    return sn(
        nil,
        fmta(
            [[
    namespace <identifier>
    {
        <body>
    }

    ]],
            {
                identifier = i(1, default_namespace),
                body = i(0),
            }
        )
    )
end

return {
    s({
        trig = "namespace",
        wordTrig = true,
        name = "Namespace",
    }, {
        d(1, namespace, {}),
    }, {
        show_condition = namespace_supported,
    }),
}
