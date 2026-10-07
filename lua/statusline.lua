local opt = vim.opt
local api = vim.api

local Statusline = {}

function Statusline.setup()
    vim.g.qf_disable_statusline = true
    opt.laststatus = 3
    opt.statusline = table.concat({
        "%{%v:lua.require('statusline').render_mode()%}",
        "%#Statusline# %<%f ",
        "%#Modified#%{&modified ? '●' : ''}",
        "%#Readonly#%{&readonly ? '⊘' : ''}",
        "%#Statusline#%=%S ",
        "%#Recording#%{reg_recording() != '' ? ' @' . reg_recording() . ' ' : ''}",
        "%{%v:lua.require('statusline').render_cursors()%}",
        "%#Statusline# %l∶%c ",
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

function Statusline.render_cursors()
    local ns = api.nvim_create_namespace("nvim.multicursor")
    local num_cursors = #api.nvim_buf_get_extmarks(0, ns, 0, -1)
    if num_cursors == 0 then return "" end

    local cursors = ({ "·", "꞉", "⁖", "⁘", "⁙" })[num_cursors]
        or ("%d"):format(num_cursors)
    local following = vim.bo.follow and "⌖" or "○"
    return ("%%#MultiCursors# %s %s "):format(following, cursors)
end

return Statusline
