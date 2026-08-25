if vim.g.snippets_lua then return end
vim.g.snippets_lua = true

local snip = require("snippets")

snip:lang("lua", {
    ident = "!%keyword & %a [a-zA-Z0-9_]*",
    keyword = "('local' / 'break' / 'return' / 'goto' / 'function' / 'not' / 'and' / 'or' / 'if' / 'then' / 'else' / 'for' / 'in' / 'while' / 'repeat' / 'do' / 'end') ![a-zA-Z0-9_]",
    number = "%d+",
    str = [['"' [^"]* '"']],
    expr = "%ident / %number / %str", -- TODO: Ok yes obviously lua is more complicated than this
    lval = "%ident (%s* '.' %ident / %s* '[' %s* %expr %s* ']')*",
    lhs = "('local' %s+)? %lval (%s* ',' %s* %lval)*",
    rval = "%lhs %s* '=' %s*",
    block = "%s*", -- TODO: Single lines with nested blocks?
})

snip("lua", "'lo'", "local ", { "block" })
snip("lua", "%lhs %s", "%0= ", { "block" })
snip("lua", "'fu'", "function", { "block", "rval" })
snip("lua", "'function' %s", "function ${1:name}(${2:args})\n\t${0}\nend", { "block" })
snip("lua", "'function('", "function(${1})\n\t${0}\nend", { "block", "rval" }) -- TODO: Fix integration with autopairs
snip("lua", "{'function' (%s+ %lval)? %s* '(' [^()]* ')'} %s", "%1\n\t${0}\nend", { "block", "rval" })
snip("lua", "'req'", [[require("${0}")]], { "block", "rval" })
snip("lua", "'fo'", "for ", { "block" })
snip("lua", "'for i'", "for ${1:i} = ${2:1}, ${3:stop} do\n\t${0}\nend", { "block" })
snip("lua", "'for k'", "for ${1:k}, ${2:v} in pairs(${3:table}) do\n\t${0}\nend", { "block" })
snip("lua", "'for _'", "for ${1:_}, ${2:v} in ipairs(${3:table}) do\n\t${0}\nend", { "block" })
snip("lua", "'if'", "if ${1} then\n\t${2}\n${3:end}", { "block" })
snip("lua", "'el'", "else", { "block" })
snip("lua", "'else' %s", "else\n\t${0}\nend", { "block" })
snip("lua", "'elsei'", "elseif ${1} then\n\t${2}\n${3:end}", { "block" })
snip("lua", "'ret'", "return ", { "block" })
snip("lua", "'br'", "break", { "block" })
