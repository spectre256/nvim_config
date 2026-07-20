local opt = vim.opt
local opt_local = vim.opt_local
local api = vim.api
local map = vim.keymap.set

opt.number = true
opt.relativenumber = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.ignorecase = true
opt.smartcase = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false
opt.cursorline = true
opt.cmdheight = 0
opt.cmdwinheight = 1
opt.pumheight = 12
opt.showmode = false
opt.shortmess = "aoOstTWAcCqFS"
opt.list = true
opt.listchars = {
    tab = "⇥ ",
    trail = "⋅",
    leadmultispace = "⎸   ",
}
opt.fillchars = {
    fold = " ",
    foldopen = "▾",
    foldclose = "▸",
    foldsep = "│",
    foldinner = "║",
    diff = "―",
    eob = " ",
    lastline = "…",
    trunc = "…",
    truncrl = "…",
}
opt.winborder = "solid"
opt.splitright = true
opt.splitbelow = true
opt.swapfile = false
opt.undofile = true
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldenable = false
opt.foldcolumn = "auto"
opt.foldtext = "v:lua.render_foldtext()"

local function get_highlighted_row(bufnr, row, trim_space)
    local line = api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1]
    local col = 0

    if trim_space then
        local _, count = line:find("^%s*")
        col = count or col
    end

    local result = {}
    local last_node = nil

    for i = col + 1, #line do
        local text = line:sub(i, i)
        local info = vim.inspect_pos(bufnr, row - 1, i - 1)
        local hls = {}

        for _, t in ipairs(info.syntax) do
            table.insert(hls, t.hl_group)
        end
        for _, t in ipairs(info.treesitter) do
            table.insert(hls, t.hl_group)
        end
        for _, t in ipairs(info.semantic_tokens) do
            table.insert(hls, t.opts.hl_group)
        end

        if last_node and vim.deep_equal(hls, last_node[2]) then
            last_node[1] = last_node[1] .. text
        else
            last_node = { text, hls }
            table.insert(result, last_node)
        end
    end

    return result
end

function _G.render_foldtext()
    local foldstart = vim.v.foldstart
    local foldend = vim.v.foldend
    local bufnr = api.nvim_get_current_buf()

    local first_row = get_highlighted_row(bufnr, foldstart, false)
    local fold_fmt = vim.wo.diff and "  ↵ %d lines " or " ―― %d lines ―― "
    local fold_marker = { string.format(fold_fmt, foldend - foldstart - 1), { "Folded" } }

    local result = first_row
    table.insert(result, fold_marker)

    if not vim.wo.diff then
        local last_row = get_highlighted_row(bufnr, foldend, true)
        table.move(last_row, 1, #last_row, #result + 1, result)
    end

    return result
end

opt.signcolumn = "yes"
opt.laststatus = 3
opt.statusline = table.concat({
    "%{%v:lua.render_mode()%}",
    "%#Statusline# %<%f ",
    "%#Modified#%{&modified ? '●' : ''}",
    "%#Readonly#%{&readonly ? '⊘' : ''}",
    "%#Statusline#%=",
    "%l∶%c ",
})

function _G.render_mode()
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

opt.showtabline = 2
opt.tabline = "%!v:lua.render_tabline()"

local function is_floating(win)
    return api.nvim_win_get_config(win).relative ~= "" or vim.fn.getcmdwintype() ~= ""
end

-- Keep track of last non-floating-window buffer per tab
local tab_last_buf = {}
api.nvim_create_autocmd("BufEnter", {
    callback = function()
        local win = api.nvim_get_current_win()
        if not is_floating(win) then
            local tab = api.nvim_get_current_tabpage()
            local buf = api.nvim_win_get_buf(win)
            tab_last_buf[tab] = buf
        end
    end,
})

local function render_tab(i, tab)
    local win = api.nvim_tabpage_get_win(tab)
    local buf = api.nvim_win_get_buf(win)

    -- Don't change tabline for floating windows
    if is_floating(win) then
        local last_buf = tab_last_buf[tab]
        if api.nvim_buf_is_valid(last_buf) then
            buf = last_buf
        end
    end

    local path = api.nvim_buf_get_name(buf)
    local name = path ~= "" and vim.fn.fnamemodify(path, ":t") or "[No Name]"
    local max_name_len = 20
    name = #name > max_name_len and name:sub(1, max_name_len - 1) .. "…" or name

    local modified = api.nvim_get_option_value("modified", { buf = buf })
    local readonly = api.nvim_get_option_value("readonly", { buf = buf })
    local current = tab == api.nvim_get_current_tabpage()

    local hl = current and "%#TabLineSel#" or "%#TabLine#"
    local symbol = ""
    if modified then
        symbol = current and " %#ModifiedSel#●" or " %#Modified#●"
    elseif readonly then
        symbol = current and " %#ReadonlySel#⊘" or " %#Readonly#⊘"
    end

    local str = table.concat({
        hl .. " ",
        "%" .. i .. "T ",
        name .. "%<",
        symbol,
        " %" .. i .. "X" .. hl .. "× %X",
    })

    return str, current
end

function _G.render_tabline()
    local line = ""
    local tabs = api.nvim_list_tabpages()
    local last_current = false

    for i, tab in ipairs(tabs) do
        local str, current = render_tab(i, tab)
        local sep = current and "▐" or last_current and "▌" or "│"

        if i > 1 then line = line .. sep end
        line = line ..  str
        line = line .. "%#TabLineSep#"

        last_current = current
    end

    if last_current then line = line .. "▌" end

    return line .. "%#TabLineFill#"
end

-- Highlight all while searching, clear on exit
opt.incsearch = true
opt.hlsearch = false
api.nvim_create_autocmd({ "CmdlineEnter", "CmdlineLeave", "CmdwinEnter", "CmdwinLeave" }, {
    pattern = { "/", "\\?" },
    callback = function(ev)
        opt.hlsearch = ev.event == "CmdlineEnter" or ev.event == "CmdwinEnter"
    end,
})

-- Command buffer settings
api.nvim_create_autocmd("CmdwinEnter", {
    callback = function(ev)
        local opts = { buf = ev.buf }
        map("n", "<Esc>", "<C-w>c", opts)
        map("n", ":", ":", opts)
        map("i", "<C-Space>", "<Tab>", { remap =  true, buf = ev.buf })

        opt_local.number = false
        opt_local.relativenumber = false
        opt_local.signcolumn = "no"
        opt_local.foldcolumn = "0"
    end,
})

api.nvim_create_autocmd("FileType", {
    pattern = "help",
    callback = function(ev)
        map("n", "<Esc>", "<C-w>c", { buf = ev.buf })
    end,
})

local writing_bufs = {}
local writing_statuscolumn = "%{repeat(' ', (winwidth(0) - &textwidth) / 2)}"
api.nvim_create_autocmd("FileType", {
    pattern = { "markdown", "text", "typst", "tex", "plaintex", "help", "man" },
    callback = function(ev)
        writing_bufs[ev.buf] = true

        opt_local.number = false
        opt_local.relativenumber = false
        opt_local.signcolumn = "no"
        opt_local.foldcolumn = "0"
        opt_local.statuscolumn = writing_statuscolumn
        opt_local.textwidth = 80
        opt_local.cursorline = false
        opt_local.wrap = true
        opt_local.linebreak = true
        opt_local.breakindent = true
        opt_local.spell = true
        opt_local.conceallevel = 2
    end,
})

api.nvim_create_autocmd("BufWinEnter", {
    callback = function(ev)
        if vim.bo[ev.buf].filetype == "help" then -- Help buffers are weird
            writing_bufs[ev.buf] = true
        end

        if writing_bufs[ev.buf] then
            opt_local.statuscolumn = writing_statuscolumn
        elseif vim.fn.getcmdwintype() ~= "" then
            opt_local.statuscolumn = " "
        elseif vim.bo[ev.buf].buftype == "terminal" then
            return -- Set by TermOpen autocmd
        else
            opt_local.statuscolumn = "%C%s%=%{v:virtnum != 0 ? '' : v:relnum == 0 ? v:lnum : v:relnum} " -- Fix left aligned number
        end
    end,
})

api.nvim_create_autocmd("WinResized", {
    callback = function()
        local wins = vim.v.event.windows or {}

        for _, win in ipairs(wins) do
            local buf = api.nvim_win_get_buf(win)

            if writing_bufs[buf] then
                vim.wo[win].statuscolumn = writing_statuscolumn
            end
        end
    end,
})

api.nvim_create_autocmd("BufDelete", {
    callback = function(ev)
        writing_bufs[ev.buf] = nil
    end,
})

-- Better terminal mode settings
api.nvim_create_autocmd("TermOpen", {
    callback = function(ev)
        if vim.bo[ev.buf].filetype == "fzf" then return end

        vim.opt_local.statuscolumn = ""
        vim.cmd.startinsert()

        local opts = { buf = ev.buf }
        map("t", "<Esc>", "<C-\\><C-n>", opts)
        map("t", "<C-w>", "<C-\\><C-n><C-w>", opts)
        map("t", "<C-h>", "<C-\\><C-n><C-w>h", opts)
        map("t", "<C-j>", "<C-\\><C-n><C-w>j", opts)
        map("t", "<C-k>", "<C-\\><C-n><C-w>k", opts)
        map("t", "<C-l>", "<C-\\><C-n><C-w>l", opts)
        map("t", "<C-n>", "<C-\\><C-n><Cmd>tabnext<CR>", opts)
        map("t", "<C-p>", "<C-\\><C-n><Cmd>tabprevious<CR>", opts)
    end,
})

-- Get rid of annoying process exited messages
api.nvim_create_autocmd("TermClose", {
    callback = function(ev)
        if vim.v.event.status == 0 and api.nvim_buf_is_valid(ev.buf) and vim.bo[ev.buf].filetype ~= "fzf" then
            api.nvim_buf_delete(ev.buf, { force = true })
        end
    end,
})

api.nvim_create_autocmd("TextYankPost", {
    callback = function()
        vim.hl.on_yank({ higroup = "Search", timeout = 500 })
    end,
})

opt.updatetime = 500

-- Don't show messages for anything below an error
local notify = vim.notify
local lev = vim.log.levels
---@diagnostic disable-next-line: duplicate-set-field
vim.notify = function(msg, level, opts)
    if (level or lev.INFO) < lev.ERROR then return end

    notify(msg, level, opts)
end

local paste = vim.paste
---@diagnostic disable-next-line: duplicate-set-field
vim.paste = function(lines, phase)
    for i, line in ipairs(lines) do
        -- Scrub ANSI color codes
        lines[i] = line:gsub("\27%[[0-9;mK]+", "")
        -- Scrub Windows CR characters
        lines[i] = line:gsub("\13$", "")
    end
    return paste(lines, phase)
end

vim.g.mapleader = " "
vim.g.maplocalleader = " "

map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true })
map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true })
map("x", "<", "<gv")
map("x", ">", ">gv")
map({ "n", "x", "o" }, "H", "^")
map({ "n", "x", "o" }, "M", "gm")
map({ "n", "x", "o" }, "L", "$")
map("n", "U", "<C-r>")
map("n", ":", "q:i")
map("n", "q:", ":")
map("o", "{", "V{")
map("o", "}", "V}")
map("n", "<Leader>w", "<Cmd>silent w!<CR>")
map("n", "<Leader>q", "<Cmd>silent q!<CR>")
map("n", "<Leader>x", "<Cmd>silent x!<CR>")
map("n", "<Leader>W", "<Cmd>silent wa!<CR>")
map("n", "<Leader>Q", "<Cmd>silent qa!<CR>")
map("n", "<Leader>X", "<Cmd>silent xa!<CR>")
map({ "n", "v" }, "<Leader>y", "\"+y")
map({ "n", "v" }, "<Leader>p", "\"+p")
map("n", "<Leader>P", "o<Esc>\"+p==")
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzz")
map("n", "N", "Nzz")
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")
map("n", "<C-n>", "<Cmd>tabnext<CR>")
map("n", "<C-p>", "<Cmd>tabprevious<CR>")
map("n", "<C-S-n>", "<Cmd>tabnew<CR>")
map("n", "<C-S-p>", "<Cmd>tabclose<CR>")
map("n", "<C-S-h>", "<Cmd>leftabove vsplit<CR>")
map("n", "<C-S-j>", "<Cmd>rightbelow split<CR>")
map("n", "<C-S-k>", "<Cmd>leftabove split<CR>")
map("n", "<C-S-l>", "<Cmd>rightbelow vsplit<CR>")
map("n", "<C-b><C-b>", "<C-^>")
map("n", "<C-b>n", "<Cmd>new<CR>")
map("n", "<C-b>c", "<Cmd>bdelete<CR>")
map("n", "<C-b>w", "<Cmd>bwipeout<CR>")
map("n", "<C-b>o", function()
    local current = api.nvim_get_current_buf()
    for _, buf in ipairs(api.nvim_list_bufs()) do
        if buf ~= current and vim.bo[buf].buflisted then
            pcall(api.nvim_buf_delete, buf, {})
        end
    end
end)
map("i", "<C-Space>", "<C-x><C-o>")

vim.pack.add({
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
    "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
    "https://github.com/Wansmer/treesj",
    "https://github.com/kylechui/nvim-surround",
    "https://github.com/windwp/nvim-autopairs",
    "https://github.com/numToStr/Comment.nvim",
    "https://github.com/gbprod/substitute.nvim",
    "https://github.com/stevearc/oil.nvim",
    "https://github.com/ibhagwan/fzf-lua",
    "https://github.com/lewis6991/gitsigns.nvim",
    "https://github.com/sindrets/diffview.nvim",
    "https://github.com/NeogitOrg/neogit",
    { src = "https://github.com/rose-pine/neovim", name = "rose-pine" },
    "https://github.com/neovim/nvim-lspconfig",
    "https://github.com/mason-org/mason.nvim",
})

require("vim._core.ui2").enable()

-- Autostart treesitter
api.nvim_create_autocmd("FileType", {
    callback = function()
        pcall(vim.treesitter.start)
        vim.bo.indentexpr = "v:lua.require('nvim-treesitter').indentexpr()"
    end,
})

local sel = require("nvim-treesitter-textobjects.select")
local swap = require("nvim-treesitter-textobjects.swap")
local move = require("nvim-treesitter-textobjects.move")
map({ "x", "o" }, "af", function() sel.select_textobject("@function.outer", "textobjects") end)
map({ "x", "o" }, "if", function() sel.select_textobject("@function.inner", "textobjects") end)
map({ "x", "o" }, "ac", function() sel.select_textobject("@class.outer", "textobjects") end)
map({ "x", "o" }, "ic", function() sel.select_textobject("@class.inner", "textobjects") end)
-- TODO: Delete trailing whitespace?
map({ "x", "o" }, "aa", function() sel.select_textobject("@parameter.outer", "textobjects") end)
map({ "x", "o" }, "ia", function() sel.select_textobject("@parameter.inner", "textobjects") end)
map({ "x", "o" }, "ai", function() sel.select_textobject("@conditional.outer", "textobjects") end)
map({ "x", "o" }, "ii", function() sel.select_textobject("@conditional.inner", "textobjects") end)
map({ "x", "o" }, "gb", function() sel.select_textobject("@comment.outer", "textobjects") end)
map({ "x", "o" }, "al", function() sel.select_textobject("@assignment.lhs", "textobjects") end)
map({ "x", "o" }, "ar", function() sel.select_textobject("@assignment.rhs", "textobjects") end)
map("o", "ae", "<Cmd>keepjumps normal! mzggVG<CR><Cmd>keepjumps silent! normal! `zzz<CR>", { silent = true })
map("x", "ae", ":<C-u>keepjumps normal! mzggVG<CR>", { silent = true })
map("n", "<Leader>sf", function() swap.swap_next("@function.outer") end)
map("n", "<Leader>Sf", function() swap.swap_previous("@function.outer") end)
map("n", "<Leader>sc", function() swap.swap_next("@class.outer") end)
map("n", "<Leader>Sc", function() swap.swap_previous("@class.outer") end)
map("n", "<Leader>sa", function() swap.swap_next("@parameter.inner") end)
map("n", "<Leader>Sa", function() swap.swap_previous("@parameter.inner") end)
map("n", "<Leader>si", function() swap.swap_next("@conditional.inner") end)
map("n", "<Leader>Si", function() swap.swap_previous("@conditional.inner") end)
map({ "n", "x", "o" }, "]f", function() move.goto_next_start("@function.outer", "textobjects") end)
map({ "n", "x", "o" }, "[f", function() move.goto_previous_start("@function.outer","textobjects") end)
map({ "n", "x", "o" }, "]c", function() move.goto_next_start("@class.outer", "textobjects") end)
map({ "n", "x", "o" }, "[c", function() move.goto_previous_start("@class.outer", "textobjects") end)
map({ "n", "x", "o" }, "]p", function() move.goto_next_start("@parameter.inner", "textobjects") end)
map({ "n", "x", "o" }, "[p", function() move.goto_previous_start("@parameter.inner", "textobjects") end)

local repeatable_move = require("nvim-treesitter-textobjects.repeatable_move")
map({ "n", "x", "o" }, ";", repeatable_move.repeat_last_move)
map({ "n", "x", "o" }, ",", repeatable_move.repeat_last_move_opposite)
map({ "n", "x", "o" }, "f", repeatable_move.builtin_f_expr, { expr = true })
map({ "n", "x", "o" }, "F", repeatable_move.builtin_F_expr, { expr = true })
map({ "n", "x", "o" }, "t", repeatable_move.builtin_t_expr, { expr = true })
map({ "n", "x", "o" }, "T", repeatable_move.builtin_T_expr, { expr = true })

local treesj = require("treesj")
treesj.setup({
    use_default_keymaps = false,
    max_join_length = 1024,
})
map("n", "<Leader>t", treesj.toggle)

require("nvim-surround").setup()
-- TODO: Can I make a "surround with conditional" keybind? then yS would put it on a newline too? that'd be so cool!
map("n", "yH", "<Plug>(nvim-surround-normal)^")
map("n", "yL", "<Plug>(nvim-surround-normal)$")

local npairs = require("nvim-autopairs")
npairs.setup({
    map_bs = false, -- Integrates with snippet unexpansion
})
require("Comment").setup()

local substitute = require("substitute")
local exchange = require("substitute.exchange")
local range = require("substitute.range")
substitute.setup()
map("n", "s", substitute.operator, { noremap = true })
map("n", "ss", substitute.line, { noremap = true })
map("n", "S", substitute.eol, { noremap = true })
map("x", "s", substitute.visual, { noremap = true })
map("n", "<Leader>e", exchange.operator, { noremap = true })
map("n", "<Leader>ee", exchange.line, { noremap = true })
map("n", "<Leader>eq", exchange.cancel, { noremap = true })
map("x", "<Leader>e", exchange.visual, { noremap = true })
-- TODO: Fix this and add more motions?
map("n", "<Leader>sw", function() exchange.operator({ motion = "w" }) end, { noremap = true })
map("n", "<Leader>r",  range.operator, { noremap = true })
map("n", "<Leader>rr", range.word, { noremap = true })

require("oil").setup()
map("n", "<Leader>.", "<Cmd>edit .<CR>")
map("n", "<Leader>,", function()
    vim.cmd.edit(vim.fs.root(0, {
        {
            ".git",
            "flake.nix",
        },
        {
            "go.mod",
            "Cargo.toml",
            "pyproject.toml",
        },
    }))
end)

local fzf_lua = require("fzf-lua")
fzf_lua.setup({
    fzf_colors = true,
    winopts = {
        border = "solid",
        preview = { border = "solid" },
    },
})
map("n", "<Leader>f", fzf_lua.files)
map("n", "<Leader>F", fzf_lua.oldfiles)
map("n", "<Leader>b", fzf_lua.buffers)
map("n", "<Leader>/", fzf_lua.live_grep_native)
map("x", "<Leader>/", fzf_lua.grep_visual)
map("n", "<Leader>H", fzf_lua.helptags)
map("n", "<Leader>u", fzf_lua.undotree)
map("n", "<Leader>gs", fzf_lua.git_status)
map("n", "<Leader>gh", fzf_lua.git_hunks)
map("n", "<Leader>gl", fzf_lua.git_commits)
map("n", "<Leader>cd", function()
    fzf_lua.fzf_exec("fd --type d --hidden --exclude .git", {
        actions = {
            default = function(selected, opts)
                local dir = selected[1] or opts.last_query
                if not dir or dir == "" then return end

                vim.fn.mkdir(dir, "p")
                vim.cmd.cd(dir)
                vim.cmd.edit(".")
            end,
        },
    })
end)

local gitsigns = require("gitsigns")
gitsigns.setup()
map({"o", "x"}, "ah", "<Cmd>Gitsigns select_hunk<CR>")
local goto_hunk = repeatable_move.make_repeatable_move(function(opts)
    if vim.wo.diff then
        vim.cmd.normal({ opts.forward and "]h" or "[h", bang = true })
    else
        gitsigns.nav_hunk(opts.forward and "next" or "prev", { navigation_message = false })
    end
end)
map("n", "]h", function() goto_hunk({ forward = true }) end)
map("n", "[h", function() goto_hunk({ forward = false }) end)
map("n", "<Leader>hs", gitsigns.stage_hunk)
map("n", "<Leader>hr", gitsigns.reset_hunk)
map("x", "<Leader>hs", function()
    gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
end)
map("x", "<Leader>hr", function()
    gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
end)
map("n", "<Leader>hp", gitsigns.preview_hunk)
map("n", "<Leader>hi", gitsigns.preview_hunk_inline)
map("n", "<Leader>hS", gitsigns.stage_buffer)
map("n", "<Leader>hR", gitsigns.reset_buffer)
map("n", "<Leader>hb", function()
  gitsigns.blame_line({ full = true })
end)
map("n", "<Leader>hd", gitsigns.diffthis)
map("n", "<Leader>hD", function() gitsigns.diffthis("~1") end)
map("n", "<Leader>hq", gitsigns.setqflist)
map("n", "<Leader>hQ", function() gitsigns.setqflist("all") end)

local diffview = require("diffview")
diffview.setup()

local neogit = require("neogit")
neogit.setup({
    integrations = {
        diffview = true,
        fzf_lua = true,
    },
    signs = {
        hunk = { "", "" },
        item = { "▾", "▸" },
        section= { "▾", "▸" },
    }
})
map("n", "<Leader>gg", neogit.open)
map("n", "<Leader>gc", function() neogit.open({ "commit" }) end)
map("n", "<Leader>gp", function() neogit.open({ "push" }) end)

require("rose-pine").setup({
    variant = "main",
    styles = {
        bold = false,
        italic = false,
    },
    highlight_groups = {
        ["@function.builtin"] = { bold = true },
        ["@variable.builtin"] = { bold = true },
        ["@keyword"] = { italic = true },
        ["@keyword.import"] = { italic = true },
        ["@keyword.repeat"] = { italic = true },
        ["@keyword.return"] = { italic = true },
        ["@keyword.exception"] = { italic = true },
        ["@keyword.conditional"] = { italic = true },
        ["@keyword.conditional.ternary"] = { italic = true },
        ["@markup.italic"] = { italic = true },
        CurSearch = { fg = "base", bg = "leaf", inherit = false },
        Search = { fg = "text", bg = "leaf", blend = 20, inherit = false },
        MatchParen = { link = "Search" },
        WinSeparator = { fg = "surface", bg = "base", inherit = false },
        VertSplit = { link = "WinSeparator" },
        Folded = { fg = "highlight_med" },
        NonText = { fg = "highlight_low" },
        Modified = { fg = "pine", bg = "surface" },
        ModifiedSel = { fg = "pine", bg = "base" },
        Readonly = { fg = "love", bg = "surface" },
        ReadonlySel = { fg = "love", bg = "base" },
        TabLine = { link = "TabLineFill" },
        TabLineSel = { fg = "text", bg = "base" },
        TabLineSep = { fg = "base", bg = "surface" },
        TabLineFill = { fg = "muted", bg = "surface" },
        StatusLineTerm = { link = "StatusLine" },
        StatusLineTermNC = { link = "StatusLineNC" },
        NormalMode = { fg = "text" },
        VisualMode = { fg = "foam" },
        SelectMode = { fg = "foam" },
        InsertMode = { fg = "rose" },
        ReplaceMode = { fg = "iris" },
        CommandMode = { fg = "gold" },
        ShellMode = { fg = "love" },
        TerminalMode = { fg = "pine" },
    },
})
vim.cmd.colorscheme("rose-pine")

require("mason").setup()

local sev = vim.diagnostic.severity
vim.diagnostic.config({
    signs = {
        text = {
            [sev.ERROR] = "⦸",
            [sev.WARN]  = "⊝",
            [sev.HINT]  = "⊛",
            [sev.INFO]  = "⊚",
        },
    },
    virtual_text = true,
    update_in_insert = false,
})

api.nvim_create_autocmd("LspAttach", {
    callback = function(ev)
        -- vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })

        local buf_opts = { buf = ev.buf }
        local diagnostic_jump = repeatable_move.make_repeatable_move(function(opts)
            vim.diagnostic.jump({ count = opts.forward and 1 or -1 })
        end)
        map("n", "]d", function() diagnostic_jump({ forward = true }) end, buf_opts)
        map("n", "[d", function() diagnostic_jump({ forward = false }) end, buf_opts)
        map("n", "gd", vim.lsp.buf.definition, buf_opts)
        map("n", "gD", vim.lsp.buf.declaration, buf_opts)
        map("n", "gr", fzf_lua.lsp_references, buf_opts)
        map("n", "K", vim.lsp.buf.hover, buf_opts)
        map("n", "<Leader>lR", vim.lsp.buf.rename, buf_opts)
        map("n", "<Leader>la", vim.lsp.buf.code_action, buf_opts)
        map("n", "<Leader>lf", function() vim.lsp.buf.format({ async = true }) end, buf_opts)
        map("n", "<Leader>ll", vim.diagnostic.open_float, buf_opts)
        map("n", "<Leader>ld", fzf_lua.diagnostics_document, buf_opts)
        map("n", "<Leader>lD", fzf_lua.diagnostics_workspace, buf_opts)
        map("n", "<Leader>ls", fzf_lua.lsp_document_symbols, buf_opts)
        map("n", "<Leader>lS", fzf_lua.lsp_workspace_symbols, buf_opts)
        map("n", "<Leader>li", fzf_lua.lsp_implementations, buf_opts)
    end,
})

local exclude = { "gitlab_duo" }
for _, config in ipairs(vim.lsp.get_configs()) do
    if not vim.tbl_contains(exclude, config.name) then
        vim.lsp.enable(config.name)
    end
end

vim.lsp.config("lua_ls", {
    on_init = function(client)
        if client.workspace_folders then
            local path = client.workspace_folders[1].name
            if
                path ~= vim.fn.stdpath("config")
                and (vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc"))
            then
                return
            end
        end

        client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
            runtime = {
                version = "LuaJIT",
                path = {
                    "lua/?.lua",
                    "lua/?/init.lua",
                },
            },
            workspace = {
                checkThirdParty = false,
                library = {
                    vim.env.VIMRUNTIME,
                    api.nvim_get_runtime_file("lua/lspconfig", false)[1],
                },
            },
        })
    end,
    settings = {
        Lua = {},
    },
})

-- TODO: Add snippets
-- TODO: General purpose "expand snippet with" keymap
local snippets = {
    lua = {
        lo = "local ",
        fu = "function",
        ret = "return ",
        req = "require(\"${0}\")",
        ["function("] = "function(${1})\n\t${0}\nend",
        ["function "] = "function ${1:name}(${2:args})\n\t${0}\nend", -- TODO: Fix integration with autopairs
        fo = "for ",
        ["for i"] = "for ${1:i} = ${2:1}, ${3:stop} do\n\t${0}\nend",
        ["for k"] = "for ${1:k}, ${2:v} in pairs(${3:table}) do\n\t${0}\nend",
        ["for _"] = "for ${1:_}, ${2:v} in ipairs(${3:table}) do\n\t${0}\nend",
        ["if"] = "if ${1} then\n\t${2}\n${3:end}",
        el = "else",
        ["else "] = "else\n\t${0}\nend",
        elsei = "elseif ${1} then\n\t${2}\n${3:end}",
    },
    python = {

-- Smart unexpanding snippets
_G.snippets = {
    langs = {},
}

local function toSet(arr)
    local set = {}
    for _, v in ipairs(arr) do
        set[v] = true
    end
    return set
end

function snippets:add(langs, lhs, rhs, opts)
    if type(langs) ~= "table" then langs = { langs } end

    for _, lang in ipairs(langs) do
        if not self.langs[lang] then self.langs[lang] = {} end

        table.insert(self.langs[lang], {
            lang = lang,
            lhs = lhs .. "$",
            rhs = rhs,
            include = opts.include and toSet(opts.include),
            exclude = toSet(opts.exclude or {}),
        })
    end
end

local function snip(lang, lhs, rhs, opts)
    snippets:add(lang, lhs, rhs, opts)
end

_G.snippet_state = {
    ns = api.nvim_create_namespace("snippets"),
    expanded = false,
    deleted = nil,
    marks = { nil, nil },
    last_row = 0,
    last_col = 0,
}

function snippet_state:reset(bufnr)
    self.deleted = nil
    if self.marks[1] then api.nvim_buf_del_extmark(bufnr, self.ns, self.marks[1]) end
    if self.marks[2] then api.nvim_buf_del_extmark(bufnr, self.ns, self.marks[2]) end
    self.marks = { nil, nil }
end

function snippet_state:is_saved()
    return self.deleted ~= nil
end

function snippet_state:save(bufnr, deleted, row1, col1, row2, col2)
    if self:is_saved() then self:reset(bufnr) end

    self.marks[1] = api.nvim_buf_set_extmark(bufnr, self.ns, row1, col1, { right_gravity = false })
    self.marks[2] = api.nvim_buf_set_extmark(bufnr, self.ns, row2, col2, { right_gravity = true })
    self.deleted = deleted
end

function snippet_state:restore(bufnr)
    if not self:is_saved() then return end

    local row1, col1 = unpack(api.nvim_buf_get_extmark_by_id(bufnr, self.ns, self.marks[1], { details = false }))
    local row2, col2 = unpack(api.nvim_buf_get_extmark_by_id(bufnr, self.ns, self.marks[2], { details = false }))
    api.nvim_buf_set_text(bufnr, row1, col1, row2, col2, { self.deleted })
    api.nvim_win_set_cursor(0, { row1 + 1, col1 + #self.deleted })

    self:reset(bufnr)
end

local function unexpand_snippet()
    if snippet_state:is_saved() then
        vim.snippet.stop()
        snippet_state:restore(0)
        api.nvim_feedkeys(vim.keycode("<Esc>a"), "n", false)
        return true
    else
        return false
    end
end
map({ "i", "s" }, "<C-e>", function()
    if not unexpand_snippet() then
        api.nvim_feedkeys(vim.keycode("<C-e>"), "n", false)
    end
end)

map({ "i", "s" }, "<BS>", function()
    if not (snippet_state.expanded and unexpand_snippet()) then
        api.nvim_feedkeys(npairs.autopairs_bs(), "n", false)
        snippet_state.expanded = false
    end
end)
map({ "i", "s" }, "<Tab>", function()
    if vim.snippet.active({ direction = 1 }) then
        snippet_state.expanded = false
        vim.snippet.jump(1)
    else
        api.nvim_feedkeys(vim.keycode("<Tab>"), "n", false)
    end
end)
map({ "i", "s" }, "<Esc>", function()
    if vim.snippet.active() then vim.snippet.stop() end

    api.nvim_feedkeys(vim.keycode("<Esc>"), "n", false)
end)

-- Auto-expand snippets
api.nvim_create_autocmd("TextChangedI", {
    callback = function(ev)
        local ok, parser = pcall(vim.treesitter.get_parser, ev.buf)
        if not ok or not parser then return nil end

        local tree = parser:parse()[1]
        if not tree then return nil end

        -- 0-indexed row and col
        local row, col = unpack(api.nvim_win_get_cursor(0))
        row = row - 1

        -- Only expand when adding characters, not removing
        local added_char = row == snippet_state.last_row and col > snippet_state.last_col
        snippet_state.last_row, snippet_state.last_col = row, col
        if not added_char then return end

        -- Subtract one to get node at beginning of cursor, necessary when typing at end of line
        local lang_snippets = snippets.langs[parser:lang()]
        if not lang_snippets then return end

        local line = api.nvim_get_current_line():sub(1, col)

        for _, s in pairs(lang_snippets) do
            local captures = vim.fn.matchlist(line, s.lhs)
            if #captures == 0 then goto continue end

            local match = captures[1]
            local i = col - #match

            -- Check node type just before match to avoid polluting check with typed characters
            local node = tree:root():named_descendant_for_range(row, i - 1, row, i - 1)
            local node_type = node and node:type()
            if s.include and not s.include[node_type] then goto continue end
            if s.exclude[node_type] then goto continue end

            snippet_state:save(ev.buf, match, row, i, row, col)
            api.nvim_buf_set_text(ev.buf, row, i, row, col, {})

            local rhs = type(s.rhs) == "function" and s.rhs(captures) or s.rhs
            vim.snippet.expand(rhs)
            snippet_state.expanded = true
            -- Return immediately to avoid unsetting expand
            do return end

            ::continue::
        end

        snippet_state.expanded = false
    end,
})

--TODO: Test multiple langs
snip("lua", [[\<lo]], "local ", { include = { "block", "chunk", "function_declaration" } })
snip("lua", [[\v<local ((\w|\d|_)+(,\s+(\w|\d|_)+)*) ]], function(captures)
    return string.format("local %s = ", captures[2])
end, { include = { "block", "chunk", "function_declaration" } })
