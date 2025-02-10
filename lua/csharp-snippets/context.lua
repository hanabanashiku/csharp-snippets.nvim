local ts_utils = require("nvim-treesitter.ts_utils")
local lsts = require("luasnip.extras._treesitter")
local NodeTypes = require("csharp-snippets.NodeTypes")
local ts = vim.treesitter

local info_cache = {}
local function get_or_add(csproj_path, key, value_source)
    if info_cache[csproj_path] == nil then info_cache[csproj_path] = {} end

    if info_cache[csproj_path][key] == nil then info_cache[csproj_path][key] = value_source() end

    return info_cache[csproj_path][key]
end

---@return TSNode?
local function get_enclosing_node()
    local function matches(node)
        local type = node:type()
        return type == NodeTypes.CLASS
            or type == NodeTypes.ENUM
            or type == NodeTypes.INTERFACE
            or type == NodeTypes.STRUCT
            or type == NodeTypes.RECORD
            or type == NodeTypes.METHOD
            or type == NodeTypes.PROPERTY
            or type == NodeTypes.FIELD
            or type == NodeTypes.INDEX
            or type == NodeTypes.EVENT
            or type == NodeTypes.CONSTRUCTOR
            or type == NodeTypes.DESTRUCTOR
            or type == NodeTypes.OPERATOR
            or type == NodeTypes.DELEGATE
    end

    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local root = vim.treesitter.get_node({ pos = { row, col } })
    if not root then return nil end
    local node = lsts.find_first_parent(root, matches)

    if not node then return nil end

    local start_row, _, end_row, _ = node:range()
    if start_row == row and end_row >= row then return node end
end

--- @return TSNode?
local function get_enclosing_class()
    local node = ts_utils.get_node_at_cursor()
    if not node then return nil end

    return lsts.find_first_parent(node, function(n)
        local type = n:type()
        return type == NodeTypes.CLASS or type == NodeTypes.RECORD or type == NodeTypes.STRUCT
    end)
end

--- @return string?
local function get_class_name()
    local class = get_enclosing_class()
    if class == nil then return nil end

    local name = class:field("name")[1]
    return ts.get_node_text(name, 0)
end

---@param opts { modifiers: string[]? }?
---@return { name:string, type:string, modifiers:string[], node:TSNode }[]
local function get_class_fields(opts)
    local q = ts.query.get("c_sharp", "cssnip_get_fields")

    local class = get_enclosing_class()
    if not class then return {} end

    local fields = {}
    local current = nil

    local function verify()
        if not current then return end
        local o = opts or {}

        if o.modifiers then
            for _, m in ipairs(o.modifiers) do
                local found = false
                for _, nm in ipairs(current.modifiers) do
                    if m == nm then
                        found = true
                        break
                    end
                end

                if not found then
                    current = nil
                    return
                end
            end
        end

        table.insert(fields, current)
        current = nil
    end

    for id, node in q:iter_captures(class, 0) do
        local name = q.captures[id]
        local text = vim.treesitter.get_node_text(node, 0)
        if name == "field" then
            verify()
            current = {
                node = node,
                name = "",
                type = "object",
                modifiers = {},
            }
        elseif current and name == "mod" then
            table.insert(current.modifiers, text)
        elseif current and name == "type" then
            current.type = text
        elseif current and name == "name" then
            current.name = text
        end
    end
    verify()
    return fields
end

---@param name string
---@return boolean
local function has_type_defined(name)
    local node = ts_utils.get_node_at_cursor()
    if node == nil then return false end
    local root = ts_utils.get_root_for_node(node)
    local q = vim.treesitter.query.parse(
        "c_sharp",
        ([[
    (_
    name: (identifier) @name
    (#eq? @name "%s")
    ) @class
    ]]):format(name)
    )

    return q:iter_captures(root, 0)() ~= nil
end

---@return boolean
local function is_in_class() return get_enclosing_class() ~= nil end

---@return boolean
local function is_in_block()
    local node = ts_utils.get_node_at_cursor()
    return node ~= nil and node:type() == NodeTypes.BLOCK
end

---@return string?
local function get_sln()
    local current_path = vim.fn.expand("%:p:h")
    while current_path ~= "/" do
        local sln_files = vim.fn.globpath(current_path, "*.sln", false, true)
        if #sln_files > 0 then return sln_files[1] end
        current_path = vim.fn.fnamemodify(current_path, ":h")
    end
end

---@return string?
local function get_csproj()
    local current_path = vim.fn.expand("%:p:h")
    while current_path ~= "/" do
        local csproj_files = vim.fn.globpath(current_path, "*.csproj", false, true)
        if #csproj_files > 0 then return csproj_files[1] end
        current_path = vim.fn.fnamemodify(current_path, ":h")
    end
    return nil
end

---@return table<string, string>[]|nil
local get_editorconfig = function()
    local current_path = vim.fn.expand("%:p:h")
    local file = nil
    while current_path ~= "/" do
        local editorconfig_files = vim.fn.globpath(current_path, ".editorconfig", false, true)
        if #editorconfig_files > 0 then
            file = editorconfig_files[1]
            break
        end
        current_path = vim.fn.fnamemodify(current_path, ":h")
    end

    if file == nil then return nil end

    local handle = io.open(file, "r")
    if handle == nil then return nil end
    local rules = {}
    local is_csharp = false

    for line in handle:lines("a") do
        if not is_csharp then is_csharp = line:match("[*.cs]") ~= nil end

        if is_csharp then
            local key, value = line:match("([^=]+)%s?=%s?([^#]+)")
            if key ~= nil and value ~= nil then rules[key] = value end
        end
    end
    handle:close()

    return rules
end

---@return {target_frameworks: string[], lang_version: integer, latest_core_version: integer?, default_namespace: string }?
local function get_project_info()
    local csproj = get_csproj()
    if csproj == nil then return nil end

    return get_or_add(csproj, "project_info", function()
        local file = io.open(csproj, "r")
        if file == nil then return nil end

        local project = file:read("a")
        file:close()

        local frameworks = project:match("<TargetFrameworks?>(.+)</TargetFrameworks?>") or ""
        local all_frameworks = {}
        for str in frameworks:gmatch("[^;]+") do
            table.insert(all_frameworks, str)
        end

        local language_version = project:match("<LangVersion>(.+)</LangVersion>")
        if language_version == nil then language_version = "latest" end
        if
            language_version == "latest"
            or language_version == "latestMajor"
            or language_version == "default"
            or language_version == "preview"
        then
            language_version = 9999
        else
            language_version = tonumber(language_version)
        end

        local latest_core_version = nil
        for _, framework in ipairs(all_frameworks) do
            local version = framework:match("net(%d+%.%d)")
            if version ~= nil then latest_core_version = math.max((latest_core_version or 0), tonumber(version)) end
        end

        return {
            target_frameworks = all_frameworks,
            lang_version = language_version,
            latest_core_version = latest_core_version,
            default_namespace = project:match("<RootNamespace>(.+)</RootNamespace>")
                or vim.fn.fnamemodify(csproj, ":t:r"),
        }
    end)
end

---@return {name: string, version: integer}[]
local function list_packages()
    -- run dotnet cli to get packages
    local csproj_path = get_csproj()
    if csproj_path == nil then return {} end

    return get_or_add(csproj_path, "packages", function()
        local handle = io.popen("dotnet list " .. csproj_path .. " package --format json")
        if handle == nil then return {} end
        local result = vim.json.decode(handle:read("*a"))
        handle:close()

        local packages = {}

        for _, proj in ipairs(result["projects"]) do
            for _, package in ipairs(proj["frameworks"][1]["topLevelPackages"]) do
                -- vim.print(package)
                table.insert(packages, {
                    name = package.id,
                    version = tonumber(package.resolvedVersion:match("^%d+")),
                })
            end
        end

        return packages
    end)
end

---@return "NUnit"|"NUnit.Framework.Legacy"|"XUnit"|"MSTest"|nil
local function get_test_library()
    local csproj_path = get_csproj()

    return get_or_add(csproj_path, "test_library", function()
        local packages = list_packages()
        local test_library = nil

        for _, package in ipairs(packages) do
            local name = package.name
            if name == "NUnit" then
                if package.version < 3 then
                    test_library = "NUnit.Framework.Legacy"
                else
                    test_library = "NUnit"
                end
                break
            end

            if name == "XUnit" or name == "MSTest" then
                test_library = name
                break
            end
        end
        return test_library
    end)
end

---@return boolean
local function has_lsp()
    for _, client in ipairs(vim.lsp.get_clients()) do
        if client.name == "roslyn" or client.name == "omnisharp" then return true end
    end

    return false
end

-- pre-populate the cache to prevent snippet lag
vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*.cs",
    callback = function()
        local csproj = get_csproj()

        if csproj == nil or info_cache[csproj] ~= nil then return end

        get_project_info()
        list_packages()

        if csproj:match("[Tt]ests?") then get_test_library() end
    end,
})

vim.api.nvim_create_autocmd("FileChangedShellPost", {
    pattern = "*.csproj",
    callback = function(ev)
        local csproj = ev.file
        info_cache[csproj] = nil
    end,
})

return {
    get_class_name = get_class_name,
    is_in_class = is_in_class,
    is_in_block = is_in_block,
    get_class_fields = get_class_fields,
    get_enclosing_class = get_enclosing_class,
    get_enclosing_node = get_enclosing_node,
    has_type_defined = has_type_defined,
    get_sln = get_sln,
    get_csproj = get_csproj,
    get_project_info = get_project_info,
    list_packages = list_packages,
    get_editorconfig = get_editorconfig,
    get_test_library = get_test_library,
    has_lsp = has_lsp,
}
