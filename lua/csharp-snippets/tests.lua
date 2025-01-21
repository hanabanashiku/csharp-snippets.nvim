local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local i = ls.insert_node
local t = ls.text_node
local c = ls.choice_node
local d = ls.dynamic_node
local fmta = require("luasnip.extras.fmt").fmta

local ts_utils = require("nvim-treesitter.ts_utils")
local context = require("csharp-snippets.context")

local function can_create_fixture()
    local type
    local node = ts_utils.get_node_at_cursor()
    if node ~= nil then type = node:type() else type = nil end
    return type == nil or type =="declaration_list" or type == "compilation_unit"
end

local function is_nunit()
    return context.get_test_library() == "NUnit"
end

local function is_nunit_legacy()
    return context.get_test_library() == "NUnit.Framework.Legacy"
end

local function is_xunit()
    return context.get_test_library() == "XUnit"
end

local function is_mstest()
    return context.get_test_library() == "MSTest"
end

local function get_default_fixture_name()
    local path = vim.api.nvim_buf_get_name(0)
    local name = vim.fn.fnamemodify(path, ":t:r")
    if context.has_type_defined(name) then return sn(nil, i(1)) end
    return sn(nil, i(1, name))
end

local aaa = s(
    {
        trig = "aaa",
        wordTrig = true,
        name = "Arrange Act Assert"
    },
    {
        t({"// Arrange", ""}),
        i(1),
        t({"", "// Act", ""}),
        i(2),
        t({"", "// Assert"}),
        i(3)
    },
    {
        show_condition = function()
            return context.get_test_library() ~= nil and context.is_in_block()
        end
    }
)

local fixture = "fixture"
local setup = "setup"
local teardown = "teardown"
local onetime = "ot"
local test = "test"

local nunit = {}

local nunit_fixture = s(
    {
        trig = fixture,
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
            return (is_nunit() or is_nunit_legacy()) and can_create_fixture()
        end
    }
)
table.insert(nunit, nunit_fixture)

table.insert(nunit, s(
    {
        trig = setup,
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
            return (is_nunit() or is_nunit_legacy()) and not context.has_type_defined("SetUp")
        end
    }
))

table.insert(nunit, s(
    {
        trig = teardown,
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
            return (is_nunit() or is_nunit_legacy()) and not context.has_type_defined("TearDown")
        end
    }
))

table.insert(nunit, s(
    {
        trig = onetime..setup,
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
            return (is_nunit() or is_nunit_legacy()) and not context.has_type_defined("OneTimeSetUp")
        end
    }
))

table.insert(nunit, s(
    {
        trig = onetime..teardown,
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
            return (is_nunit() or is_nunit_legacy()) and not context.has_type_defined("OneTimeTearDown")
        end
    }
))

table.insert(nunit, s(
    {
        trig = test,
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
            return (is_nunit() or is_nunit_legacy()) and context.is_in_class()
        end
    }
))

table.insert(nunit, s(
    {
        trig = test.."a",
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
))

local asserts = {
    {trig = "asrtt", value = "True"},
    {trig = "asrtf", value = "False"},
    {trig = "asrtn", value = "Null"},
    {trig = "asrtnn", value = "NotNull", v3 = "Not.Null" },
    {trig = "asrtempty", value = "Empty", legacy = "IsEmpty"},
    {trig = "asrtnempty", value = "NotEmpty", v3 = "Not.Empty", legacy = "IsNotEmpty"},
    {trig = "asrtz", value = "Zero" },
    {trig = "asrtnz", value = "NotZero", v3 = "Not.Zero" },
}

for _, assert in ipairs(asserts) do
    table.insert(nunit, s(
    {
        trig = assert.trig,
        wordTrig = true,
        name = "Assert "..assert.value
    },
    {
        t("Assert.That("),
        i(0),
        t(", Is."..(assert.v3 or assert.value)..");")
    },
    {
        show_condition = function()
            return is_nunit() and context.is_in_block()
        end
    }
    ))

    table.insert(nunit, s(
    {
        trig = assert.trig,
        wordTrig = true,
        name = "Assert "..assert.value
    },
    {
        t("Assert."..(assert.legacy or assert.value).."("),
        i(0),
        t(");")
    },
    {
        show_condition = function()
            return is_nunit_legacy() and context.is_in_block()
        end
    }
    ))
end

table.insert(nunit, s(
    {
        trig = "asrte",
        wordTrig = true,
        name = "Assert Equal"
    },
    {
        t("Assert.That("),
        i(1),
        t(", Is.EqualTo("),
        i(2),
        t("));")
    },
    {
        show_condition = function()
            return is_nunit() and context.is_in_block()
        end
    }
))

table.insert(nunit, s(
    {
        trig = "asrte",
        wordTrig = true,
        name = "Assert Equal"
    },
    {
        t("Assert.AreEqual("),
        i(1),
        t(", "),
        i(2),
        t(");")
    },
    {
        show_condition = function()
            return is_nunit_legacy() and context.is_in_block()
        end
    }
))

table.insert(nunit, s(
    {
        trig = "asrtne",
        wordTrig = true,
        name = "Assert Not Equal"
    },
    {
        t("Assert.That("),
        i(1),
        t(", Is.Not.EqualTo("),
        i(2),
        t("));")
    },
    {
        show_condition = function()
            return is_nunit() and context.is_in_block()
        end
    }
))

table.insert(nunit, s(
    {
        trig = "asrtne",
        wordTrig = true,
        name = "Assert Not Equal"
    },
    {
        t("Assert.AreNotEqual("),
        i(1),
        t(", "),
        i(2),
        t(");")
    },
    {
        show_condition = function()
            return is_nunit_legacy() and context.is_in_block()
        end
    }
))

table.insert(nunit, s(
    {
        trig = "asrt",
        wordTrig = true,
        name = "Assert"
    },
    {
        t("Assert.That("),
        i(1),
        t(", "),
        c(2, {
            t("Is."),
            t("Is.Not."),
            t("Has."),
            t("Has.No."),
            t("Contains."),
            t("Does."),
            t("Does.Not."),
            i(2)
        }),
        i(3),
        t(");")
    },
    {
        show_condition = function()
            return is_nunit() and context.is_in_block()
        end
    }
))
table.insert(nunit, s(
    {
        trig = "asrt",
        wordTrig = true,
        name = "Assert"
    },
    {
        t("Assert."),
        i(1),
        t("("),
        i(2),
        t(");")
    },
    {
        show_condition = function()
            return is_nunit_legacy() and context.is_in_block()
        end
    }
))

local snippets = {aaa}

for _, snip in ipairs(nunit) do table.insert(snippets, snip) end

Test_Fixture_Snippets = {
    NUnit = nunit_fixture,
    ["NUnit.Framework.Legacy"] = nunit_fixture,
}

return snippets
