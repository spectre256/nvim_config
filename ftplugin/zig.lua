if vim.g.snippets_zig then return end
vim.g.snippets_zig = true

local snip = require("snippets")

-- TODO: Functions, structs, unions, enums
-- TODO: Switch-body snippets (else =>, _ =>, arm =>) need a ctx that knows the
-- enclosing construct
snip:lang("zig", {
    ident = "[a-zA-Z_] [a-zA-Z0-9_]*",
    type = "[^ =]+ (' ' [^ =]+)*",
    lhs = "('pub' %s+)? ('const' / 'var') %s+ %ident (':' %s* %type)?",
    rval = "%lhs %s* '=' %s*",
    parens = "p <- '(' [^()]* (p [^()]*)* ')'",
    arg = "(!(%s* [,)]) (%parens / [^(),]))+",
    forhead = "'for' %s* '(' %s* {| {%arg} (%s* ',' %s* {%arg})* |} %s* ')'",
    block = "%s*",
})

snip("zig", "'co'", "const ", { "block" })
snip("zig", "'va'", "var ", { "block" })
snip("zig", "'pu'", "pub ", { "block" })
snip("zig", "%lhs %s", "%0= ${0};", { "block" })
snip("zig", "'imp'", [[@import("${1:std}");]], { "rval" })
snip("zig", "'const std'", [[const std = @import("std");]] .. "\n\n", { "block" })
snip("zig", "'const Se'", "const Self = @This();\n\n", { "block" })
snip("zig", "'ret'", "return ${0};", { "block" })
snip("zig", "'br'", "break ${0};", { "block" })
snip("zig", "'cn'", "continue ${0};", { "block" })
snip("zig", "'tr'", "try ", { "block", "rval" })
snip("zig", "'ca'", "catch ", { "block" })
snip("zig", "'catch' %s* '|'", "%0${1:err}| {\n\t${0}\n}", { "any" })
snip("zig", "'def'", "defer ", { "block" })
snip("zig", "'err'", "errdefer ", { "block" })
snip("zig", "'if'", "if (${1})", { "block" })
snip("zig", "'if' %s* %parens %s", "%0{${1}}${0}", { "any" })
snip("zig", "'el'", "else", { "block" })
snip("zig", "'else' %s", "else {\n\t${1}\n}${0}", { "block" })
snip("zig", "'elsei'", "else if (${1}) {\n\t${2}\n}${0}", { "block" })
snip("zig", "'sw'", "switch (${1}) {\n\t${0}\n}", { "block", "rval" })
snip("zig", "'fo'", "for (${0})", { "block", "rval" })
snip("zig", "%forhead %s", function(args)
    local indices = { "i", "j", "k" }
    local index_count = 0
    local names = vim.iter(ipairs(args))
        :map(function(i, arg)
            local name = "_"
            if arg:find("..", 1, true) then
                index_count = index_count + 1
                name = indices[index_count] or "_"
            end

            return string.format("${%d:%s}", i, name)
        end)
        :join(", ")

    return string.format("for (%s) |%s| {\n\t${0}\n}", table.concat(args, ", "), names)
end, { "block" })
snip("zig", "'wh'", "while (${1:true})", { "block", "rval" })
snip("zig", "{'while' %s* %parens} %s* ':'", "%1 : (${1:i += 1}) {\n\t${0}\n}", { "block" })
snip("zig", "{'while' %s* %parens} %s* '|'", "%1 |${1:_}| {\n\t${0}\n}", { "block" })
snip("zig", "'while' %s* %parens %s", "%0{\n\t${0}\n}", { "block" })
