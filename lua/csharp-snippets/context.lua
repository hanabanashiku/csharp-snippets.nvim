local ts_utils = require("nvim-treesitter.ts_utils")
local ts = vim.treesitter

local function get_enclosing_class()
    local node = ts_utils.get_node_at_cursor()
    while node do
        if node:type() == "class_declaration" then return node end
        node = node:parent()
    end
    return nil
end

local function get_class_name()
    local class = get_enclosing_class()
    if class == nil then return nil end

    local name = class:field("name")[1]
    return ts.get_node_text(name, 0)
end

local function get_class_fields()
    local class = get_enclosing_class()
    if class == nil then return nil end

    local body = class:field("body")[1]
    local fields = {}
    for child in body:iter_children() do
        local variable = child:child(child:child_count() - 2)
        if child:type() == "field_declaration" and variable ~= nil then
            table.insert(fields, {
                type = vim.treesitter.get_node_text(variable:field("type")[1], 0),
                name = vim.treesitter.get_node_text(variable:child(1):field("name")[1], 0),
                node = child,
            })
        end
    end

    return fields
end

local function has_type_defined(name)
    local node = ts_utils.get_node_at_cursor()

    if node == nil then return false end

    local root = ts_utils.get_root_for_node(node)

    for declaration in root:iter_children() do
        vim.print(declaration:type())
        if vim.treesitter.get_node_text(declaration:field("name")[1], 0) == name then return true end
    end

    return false
end

local function is_in_class() return get_class_name() ~= nil end

local function get_sln()
    local current_path = vim.fn.expand("%:p:h")
    while current_path ~= "/" do
        local sln_files = vim.fn.globpath(current_path, "*.sln", false, true)
        if #sln_files > 0 then return sln_files[1] end
        current_path = vim.fn.fnamemodify(current_path, ":h")
    end
    return nil
end

local function get_csproj()
    local current_path = vim.fn.expand("%:p:h")
    while current_path ~= "/" do
        local csproj_files = vim.fn.globpath(current_path, "*.csproj", false, true)
        if #csproj_files > 0 then return csproj_files[1] end
        current_path = vim.fn.fnamemodify(current_path, ":h")
    end
    return nil
end

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

    if file == nil then
        return nil
    end

    local handle = io.open(file, "r")
    if handle == nil then return nil end
    local rules = {}
    local is_csharp = false

    for line in handle:lines("a") do
        if not is_csharp then
            is_csharp = line:match("[*.cs]") ~= nil
        end

        if is_csharp then
            local key, value = line:match("([^=]+)%s?=%s?([^#]+)")
            if key ~= nil and value ~= nil then
                rules[key] = value
            end
        end
    end
    handle:close()

    return rules
end

local function get_project_info()
    local csproj = get_csproj()
    if csproj == nil then return nil end

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
    if language_version == "latest" or language_version == "latestMajor" or language_version == "default" or language_version == "preview" then
        language_version = 9999
    else
        language_version = tonumber(language_version)
    end

    local latest_core_version = nil
    for _, framework in ipairs(all_frameworks) do
        local version = framework:match("net(%d+%.%d)")
        if version ~= nil then latest_core_version = math.max((latest_core_version or 0), tonumber(version)) end
    end

    local function list_packages()
        -- run dotnet cli to get packages
        local handle = io.popen("dotnet list " .. csproj .. " package --format json")
        if handle == nil then return {} end
        local result = vim.json.decode(handle:read("*a"))
        handle:close()

        local packages = {}

        for _, project in ipairs(result["projects"]) do
            for _, package in ipairs(project["frameworks"][1]["topLevelPackages"]) do
                table.insert(packages, package["id"])
            end
        end

        return packages
    end

    return {
        target_frameworks = all_frameworks,
        lang_version = language_version,
        latest_core_version = latest_core_version,
        list_packages = list_packages,
        default_namespace = project:match("<RootNamespace>(.+)</RootNamespace>") or vim.fn.fnamemodify(csproj, ":t:r"),
    }
end

return {
    get_class_name = get_class_name,
    is_in_class = is_in_class,
    get_class_fields = get_class_fields,
    has_type_defined = has_type_defined,
    get_sln = get_sln,
    get_csproj = get_csproj,
    get_project_info = get_project_info,
    get_editorconfig = get_editorconfig
}
