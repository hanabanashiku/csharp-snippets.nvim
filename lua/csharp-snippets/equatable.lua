local luasnip = require("luasnip")
local s = luasnip.snippet
local sn = luasnip.snippet_node
local t = luasnip.text_node
local i = luasnip.insert_node
local f = luasnip.function_node
local d = luasnip.dynamic_node
local k = require("luasnip.nodes.key_indexer").new_key
local fmta = require("luasnip.extras.fmt").fmta
local events = require("luasnip.util.events")

local context = require("csharp-snippets.context")
local NodeTypes = require("csharp-snippets.NodeTypes")

local function can_declare_equatable() return context.get_enclosing_class ~= nil end

local function split(str)
    local result = {}
    for part in string.gmatch(str, "([^, ]+)") do
        table.insert(result, part)
    end
    return result
end

local function legacy_hash_code(args)
    local not_implemented = sn(nil, t({ "    throw new NotImplementedException();", "" }))
    if not args or #args == 0 or not args[1] then return not_implemented end
    local fields = split(args[1][1])
    if #fields == 0 then return not_implemented end
    local parts

    if #fields == 1 then
        parts = { t({ "    return " .. fields[1] .. " != null ? " .. fields[1] .. ".GetHashCode() : 0;", "" }) }
    elseif #fields == 2 then
        parts = {
            t({
                "    return",
                "        (",
                "            " .. fields[1] .. " != null ? " .. fields[1] .. ".GetHashCode() : 0) * 397",
                "            ^ (" .. fields[2] .. " != null ? " .. fields[2] .. ".GetHashCode() : 0)",
                "        );",
                "",
            }),
        }
    else
        local strings = { "    var hashCode = " .. fields[1] .. " != null ? " .. fields[1] .. ".GetHashCode() : 0;" }
        table.remove(fields, 1)
        for _, field in ipairs(fields) do
            table.insert(
                strings,
                "        hashCode = (hashCode * 397) ^ (" .. field .. " != null ? " .. field .. ".GetHashCode() : 0);"
            )
        end
        table.insert(strings, "        return hashCode;")
        table.insert(strings, "")
        parts = { t(strings) }
    end

    return sn(nil, parts)
end

local function use_modern()
    local proj = context.get_project_info()
    local combine_method = (proj and proj.latest_core_version and proj.latest_core_version > 2.1) or false
    return combine_method
end

local function hash_code_body()
    local default_fields = context.get_class_fields({ modifiers = { "public" } })
    local field_string = ""
    if default_fields then
        for _, field in ipairs(default_fields) do
            field_string = field_string .. (field_string ~= "" and ", " or "") .. field.name
        end
    end

    if use_modern() then
        return sn(nil, {
            t("return HashCode.Combine("),
            i(1, default_fields, { key = "fields" }),
            t(");"),
        })
    else
        return sn(nil, {
            t("// fields to use: "),
            i(1, default_fields, {
                key = "fields",
            }),
            t({
                "",
                "    unchecked",
                "    {",
                "    ",
            }),
            d(2, legacy_hash_code, { 1 }),
            t({ "    }" }),
        })
    end
end

local function equality_checks(args)
    local not_implemented = sn(nil, t("throw new NotImplementedException();"))
    if not args or #args == 0 or not args[1] then return not_implemented end
    local fields = split(args[1][1])
    if #fields == 0 then return not_implemented end

    local value = "return " .. fields[1] .. " == other." .. fields[1]

    if #fields == 1 then return sn(nil, t(value .. ";")) end

    value = { value }
    local last = 1
    table.remove(fields, 1)
    for _, field in ipairs(fields) do
        last = last + 1
        table.insert(value, "           && " .. field .. " == other." .. field)
    end

    value[last] = value[last] .. ";"
    return sn(nil, t(value))
end

local function ensure_equatable()
    local class = context.get_enclosing_class()
    if not class then return end
    local class_name = vim.treesitter.get_node_text(class:field("name")[1], 0)
    local base_list = nil
    local type_parameter_list = nil
    local parameter_list = nil

    for field in class:iter_children() do
        local type = field:type()
        if type == NodeTypes.CLASS_PARAMETERS then
            parameter_list = field
        elseif type == NodeTypes.BASE_CLASSES then
            base_list = field
        elseif type == NodeTypes.TYPE_PARAMETERS then
            type_parameter_list = field
        end
    end

    local target = base_list or parameter_list or type_parameter_list or class:field("name")[1]
    local _, _, end_row, end_col = target:range()

    local pos = vim.api.nvim_win_get_cursor(0)
    vim.api.nvim_win_set_cursor(0, { end_row + 1, end_col })
    vim.api.nvim_put({
        (target:type() == NodeTypes.BASE_CLASSES and ", " or " : ") .. "IEquatable<" .. class_name .. ">",
        "",
    }, "c", true, false)
    vim.api.nvim_win_set_cursor(0, pos)
end

local function delete_comment_helper()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    for idx, line in ipairs(lines) do
        if line:match("// fields to use:") then
            vim.api.nvim_buf_set_lines(0, idx - 1, idx, false, {})
            return
        end
    end
end

local function finalize()
    vim.api.nvim_create_autocmd("InsertLeave", {
        callback = function()
            ensure_equatable()

            if not use_modern() then delete_comment_helper() end
        end,
        once = true,
    })
end

local equatable = s(
    {
        trig = "ieq",
        wordTrig = true,
        name = "Implement IEquatable<T>",
    },
    fmta(
        [[
        public bool Equals(<class_name>? other)
        {
            if (other is null)
            {
                return false;
            }

            if (ReferenceEquals(this, other))
            {
                return true;
            }

            <equality_checks>
        }

        public override bool Equals(object? obj)
        {
            if (obj is null)
            {
                return false;
            }

            if (ReferenceEquals(this, obj))
            {
                return true;
            }

            return obj.GetType() == GetType() && Equals((<class_name>)obj);
        }

        public override int GetHashCode()
        {
           <hash_code_body>
        }
        ]],
        {
            class_name = f(context.get_class_name),
            hash_code_body = d(1, hash_code_body, {}),
            equality_checks = d(2, equality_checks, k("fields")),
        }
    ),
    {
        show_condition = can_declare_equatable,
        callbacks = {
            [-1] = {
                [events.pre_expand] = finalize,
            },
        },
    }
)

return {
    equatable,
}
