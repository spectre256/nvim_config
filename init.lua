require("options")
require("lsp")
require("foldtext").setup()
require("tabline").setup()
require("statusline").setup()
require("statuscolumn"):setup()
require("term")
require("mappings")
require("treesitter")
require("ui")
require("fs")
require("git")
require("workflows").setup()
local snippets = require("snippets")
snippets:setup()
local snip = snippets.snip

local lval_opts = { include = {
    -- Lua
    "block",
    "chunk",
    "ERROR", -- Replaces chunk when parse fails
    "function_declaration",
    "function_definition",
    "if_statement",
    "else_statement",
    "while_statement",
    "do_statement",
    -- Zig
    "source_file",
    "struct_declaration",
    "union_declaration",
    "enum_declaration",
    -- Typescript
    "program",
    "statement_block",
    "class_body",
} }
local rval_opts = { include = {
    "assignment_declaration",
    "assignment_statement",
    "variable_declaration",
} }
local xval_opts = { include = vim.list_extend(vim.deepcopy(lval_opts.include), rval_opts.include) }

-- Lua
snip("lua", "lo", "local ", lval_opts)
snip("lua", "fu", "function", xval_opts)
snip("lua", "function ", "function ${1:name}(${2:args})\n\t${0}\nend")
snip("lua", "function(", "function(${1})\n\t${0}\nend") -- TODO: Fix integration with autopairs
snip("lua", [[\vlocal (\w+(, \w+)*) ]], "$0= ")
snip("lua", "req", [[require("${0}")]], xval_opts)
snip("lua", "fo", "for ", lval_opts)
snip("lua", "for i", "for ${1:i} = ${2:1}, ${3:stop} do\n\t${0}\nend", lval_opts)
snip("lua", "for k", "for ${1:k}, ${2:v} in pairs(${3:table}) do\n\t${0}\nend", lval_opts)
snip("lua", "for _", "for ${1:_}, ${2:v} in ipairs(${3:table}) do\n\t${0}\nend", lval_opts)
snip("lua", "if", "if ${1} then\n\t${2}\n${3:end}", lval_opts)
snip("lua", "el", "else", lval_opts)
snip("lua", "else ", "else\n\t${0}\nend", lval_opts)
snip("lua", "elsei", "elseif ${1} then\n\t${2}\n${3:end}", lval_opts)
snip("lua", "ret", "return ", lval_opts)
snip("lua", "br", "break", lval_opts)

snip({ "lua", "zig", "c", "cpp", "rust", "go" }, "ret", "return ", lval_opts)
snip({ "lua", "zig", "c", "cpp", "rust", "go" }, "br", "break", lval_opts)

-- TODO: Functions, structs, unions, enums, defer, errdefer
local for_opts = { include = { "ERROR", "for_statement", "for_expression" } }
local sw_opts = { include = { "switch_expression" } }

-- Zig
-- TODO: Functions, structs, unions, enums
snip("zig", "co", "const ", lval_opts)
snip("zig", "va", "var ", lval_opts)
snip("zig", [[\v(const|var)? ?\w+(: *\S*[^,])? ]], "$0= ${0};", lval_opts)
snip("zig", "imp", "@import(\"${1:std}\");", rval_opts)
snip("zig", "const std", "const std = @import(\"std\");\n\n", lval_opts)
snip("zig", "const Se", "const Self = @This();\n\n", lval_opts)
snip("zig", "pu", "pub ", lval_opts)
snip("zig", "ret", "return ${0};", lval_opts)
snip("zig", "br", "break ${0};", lval_opts)
snip("zig", "cn", "continue ${0};", lval_opts)
snip("zig", "tr", "try ", lval_opts)
snip("zig", "ca", "catch ", lval_opts)
snip("zig", "catch |", "$0${1:err}| {\n\t${0}\n}", lval_opts)
snip("zig", "def", "defer ", lval_opts)
snip("zig", "err", "errdefer ", lval_opts)
snip("zig", "if", "if (${1})", lval_opts)
snip("zig", "if ([^()]*) ", "$0{\n\t${2}\n}${0}", lval_opts)
snip("zig", "if (.*)|", "$0{\n\t${2}\n}${0}", lval_opts)
snip("zig", "el", "else", lval_opts)
snip("zig", "else ", "else {\n\t${1}\n}${0}", lval_opts)
snip("zig", "elsei", "else if (${1}) {\n\t${2}\n}${0}", lval_opts)
snip("zig", "sw", "switch (${1}) {\n\t${0}\n}", xval_opts)
snip("zig", "el", "else => ${1},${0}", sw_opts)
snip("zig", "_", "_ => ${1},${0}", sw_opts)
snip("zig", [[\v\w+(, \w+)* ]], "$0=> ${0},", sw_opts)
snip("zig", "fo", "for (${0})", xval_opts)
snip("zig", [[\v(\d+)\.]], "$0.", for_opts)
snip("zig", [[\v\S* \.]], "$0. ", for_opts)
snip("zig", [[\vfor \(([^,]+)((, [^,]+)*)\) ]], function(captures)
    local args = { captures[2], unpack(vim.fn.split(captures[3], ",")) }
    local index_count = 0
    local indices = { "i", "j", "k" }
    local arg_str = vim.iter(ipairs(args))
        :map(function(i, arg)
            local str = nil
            if arg:match("^%s*%S+%s*%.%.") then
                index_count = index_count + 1
                str = indices[index_count]
            end

            return string.format("${%d:%s}", i, str or "_")
        end)
        :join(", ")

    return string.format("%s|%s| {\n\t${0}\n}", captures[1], arg_str)
end)
snip("zig", "wh", "while (${1:true})", xval_opts)
snip("zig", "while ([^()]*) ", "$0{\n\t${0}\n}", xval_opts)
snip("zig", "\\(while (.*)\\):", "$1 : (${1:i += 1}) {\n\t${0}\n}", xval_opts)
snip("zig", "\\(while (.*)\\)|", "$1 |${1:_}| {\n\t${0}\n}", xval_opts)

snip("haskell", "fn", "${1:name} :: ${2:type}\n${1:name} ${3:args} = ${0}")
