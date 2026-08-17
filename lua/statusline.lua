local opt = vim.opt

local Statusline = {}

function Statusline.setup()
    opt.laststatus = 3
    opt.statusline = table.concat({
        "%{%v:lua.require('statusline').render_mode()%}",
        "%#Statusline# %<%f ",
        "%#Modified#%{&modified ? '●' : ''}",
        "%#Readonly#%{&readonly ? '⊘' : ''}",
        "%#Statusline#%=",
        "%l∶%c ",
    })
end

function Statusline.render_mode()
    local modes = {
        n      = "%#NormalMode#▌NORMAL",
        v      = "%#VisualMode#▌VISUAL",
        V      = "%#VisualMode#▌VISUAL",
        [""] = "%#VisualMode#▌VISUAL",
        s      = "%#SelectMode#▌SELECT",
        S      = "%#SelectMode#▌SELECT",
        [""] = "%#SelectMode#▌SELECT",
        i      = "%#InsertMode#▌INSERT",
        R      = "%#ReplaceMode#▌REPLACE",
        c      = "%#CommandMode#▌COMMAND",
        ["!"]  = "%#ShellMode#▌SHELL",
        t      = "%#TerminalMode#▌TERM",
    }

    return modes[vim.fn.mode():sub(1, 1)] or ""
end

return Statusline
