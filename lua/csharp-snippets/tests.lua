local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local i = ls.insert_node
local d = ls.dynamic_node
local fmta = require("luasnip.extras.fmt").fmta

local ts_utils = require("nvim-treesitter.ts_utils")
local context = require("csharp-snippets.context")

local test_library = nil

local function get_test_library()
    if test_library ~= nil then
        return test_library
    end

    local proj = context.get_project_info()
    if proj == nil then return false end
    local packages = proj.list_packages()

    for _, package in ipairs(packages) do
        if package == "NUnit" or package == "XUnit" or package == "MSTest" then
            test_library = package
            return package
        end
    end
    return nil
end


local function can_create_fixture()
    local node = ts_utils.get_node_at_cursor()
    return node == nil or node:type() == "declaration_list"
end

local function is_nunit()
    return get_test_library() == "NUnit"
end

local function is_xunit()
    return get_test_library() == "XUnit"
end

local function is_mstest()
    return get_test_library() == "MSTest"
end

local function get_default_fixture_name()
    local path = vim.api.nvim_buf_get_name(0)
    local name = vim.fn.fnamemodify(path, ":t:r")
    if context.has_type_defined(name) then return sn(nil, i(1)) end
    return sn(nil, i(1, name))
end

local nunit_fixture = s(
    {
        trig = "fixture",
        wordTrig = true,
        name = "NUnit test fixture"
    },
    fmta([[
        [TestFixture]
        public class <identifier>
        {
            <body>
        }

    ]], {
        identifier = d(1, get_default_fixture_name, {}),
        body = i(0)
    }),
    {
        show_condition = function()
            return is_nunit and can_create_fixture
        end
    }
)

local nunit_setup = s(
    {
        trig = "setup",
        wordTrig = true,
        name = "NUnit SetUp"
    },
    fmta([[
    [SetUp]
    public void SetUp()
    {
        <body>
    }
    ]],
    {
        body = i(0)
    }),
    {
        show_condition = function()
            return is_nunit() and not context.has_type_defined("SetUp")
        end
    }
)

local nunit_teardown = s(
    {
        trig = "teardown",
        wordTrig = true,
        name = "NUnit TearDown"
    },
    fmta([[
    [TearDown]
    public void TearDown()
    {
        <body>
    }
    ]],
    {
        body = i(0)
    }),
    {
        show_condition = function()
            return is_nunit() and not context.has_type_defined("TearDown")
        end
    }
)

local nunit_otsetup = s(
    {
        trig = "otsetup",
        wordTrig = true,
        name = "NUnit OneTimeSetUp"
    },
    fmta([[
    [OneTimeSetUp]
    public void OneTimeSetUp()
    {
        <body>
    }
    ]],
    {
        body = i(0)
    }),
    {
        show_condition = function()
            return is_nunit() and not context.has_type_defined("OneTimeSetUp")
        end
    }
)

local nunit_otteardown = s(
    {
        trig = "otteardown",
        wordTrig = true,
        name = "NUnit OneTimeSetUp"
    },
    fmta([[
    [OneTimeTearDown]
    public void OneTimeTearDown()
    {
        <body>
    }
    ]],
    {
        body = i(0)
    }),
    {
        show_condition = function()
            return is_nunit() and not context.has_type_defined("OneTimeTearDown")
        end
    }
)

local nunit_test = s(
    {
        trig = "test",
        wordTrig = true,
        name = "NUnit test"
    },
    fmta([[
    [Test]
    public void <identifier>()
    {
        <body>
    }
    ]], {
        identifier = i(1),
        body = i(0)
    }),
    {
        show_condition = function()
            return is_nunit and context.is_in_class()
        end
    }
)

local nunit_test_async = s(
    {
        trig = "testa",
        wordTrig = true,
        name = "NUnit async test"
    },
    fmta([[
    [Test]
    public async Task <identifier>()
    {
        <body>
    }
    ]], {
        identifier = i(1),
        body = i(0)
    }),
    {
        show_condition = function()
            return is_nunit and context.is_in_class()
        end
    }
)

return {
    nunit_fixture,
    nunit_setup,
    nunit_teardown,
    nunit_otsetup,
    nunit_otteardown,
    nunit_test,
    nunit_test_async
    -- todo asserts
}
