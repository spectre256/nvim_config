vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.wrap = false
vim.opt.cursorline = true
vim.opt.cmdheight = 0
vim.opt.pumheight = 12
vim.opt.showmode = false
vim.opt.list = true
vim.opt.listchars = { tab = "⇥ ", trail = "⋅" }
vim.opt.fillchars = {
    eob = " ",
    trunc = "…",
    truncrl = "…",
    fold = " ",
    foldopen = "▾",
    foldclose = "▸",
    foldsep = "│",
    foldinner = "║",
}
vim.opt.winborder = "solid"
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.swapfile = false
vim.opt.undofile = true
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldenable = false
vim.opt.foldcolumn = "auto"
vim.opt.foldtext = ""
vim.opt.signcolumn = "yes"
vim.opt.statuscolumn = "%C%s%=%{v:relnum==0 ? v:lnum : v:relnum} " -- Fix left aligned number
vim.opt.laststatus = 3
vim.opt.statusline = table.concat({
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

vim.opt.showtabline = 2
vim.opt.tabline = "%!v:lua.render_tabline()"

local function render_tab(i, tab)
    local win = vim.api.nvim_tabpage_get_win(tab)
    local buf = vim.api.nvim_win_get_buf(win)

    local path = vim.api.nvim_buf_get_name(buf)
    local name = path ~= "" and vim.fn.fnamemodify(path, ":t") or "[No Name]"
    local max_name_len = 20
    name = #name > max_name_len and name:sub(1, max_name_len - 1) .. "…" or name

    local modified = vim.api.nvim_get_option_value("modified", { buf = buf })
    local readonly = vim.api.nvim_get_option_value("readonly", { buf = buf })
    local current = tab == vim.api.nvim_get_current_tabpage()

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
        " %" .. i .. "X" .. hl .. "⮾ %X",
    })

    return str, current
end

function _G.render_tabline()
    local line = ""
    local tabs = vim.api.nvim_list_tabpages()
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
vim.opt.incsearch = true
vim.opt.hlsearch = false
vim.api.nvim_create_autocmd({ "CmdlineEnter", "CmdlineLeave" }, {
    pattern = { "/", "\\?" },
    callback = function(ev)
        vim.opt.hlsearch = ev.event == "CmdlineEnter"
    end,
})

-- TODO: Writing mode settings
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "markdown", "text", "typst", "tex", "plaintex", "help" },
    callback = function()
        vim.opt_local.number = false
        vim.opt_local.relativenumber = false
        vim.opt_local.signcolumn = "no"
        vim.opt_local.statuscolumn = ""
        -- vim.opt_local.textwidth = 80
        -- vim.opt_local.statuscolumn = "%{repeat(' ', (winwidth(0) - &textwidth) / 2)}%<" -- FIXME
        vim.opt_local.cursorline = false
        vim.opt_local.wrap = true
        vim.opt_local.linebreak = true
        vim.opt_local.breakindent = true
        vim.opt_local.spell = true
        vim.opt_local.conceallevel = 2
    end,
})

-- Better terminal mode settings
vim.api.nvim_create_autocmd("TermOpen", {
    callback = function(ev)
        if vim.bo[ev.buf].filetype == "fzf" then return end

        vim.opt_local.statuscolumn = ""
        vim.cmd.startinsert()

        local opts = { buffer = ev.buf }
        vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", opts)
        vim.keymap.set("t", "<C-w>", "<C-\\><C-n><C-w>", opts)
        vim.keymap.set("t", "<C-h>", "<C-\\><C-n><C-w>h", opts)
        vim.keymap.set("t", "<C-j>", "<C-\\><C-n><C-w>j", opts)
        vim.keymap.set("t", "<C-k>", "<C-\\><C-n><C-w>k", opts)
        vim.keymap.set("t", "<C-l>", "<C-\\><C-n><C-w>l", opts)
        vim.keymap.set("t", "<C-n>", "<C-\\><C-n><Cmd>tabnext<CR>", opts)
        vim.keymap.set("t", "<C-p>", "<C-\\><C-n><Cmd>tabprevious<CR>", opts)
    end,
})

-- Get rid of annoying process exited messages
vim.api.nvim_create_autocmd("TermClose", {
    callback = function(ev)
        if vim.v.event.status == 0 and vim.bo[ev.buf].filetype ~= "fzf" then
            vim.api.nvim_buf_delete(ev.buf, { force = true })
        end
    end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function()
        vim.hl.on_yank({ higroup = "Search", timeout = 500 })
    end,
})

vim.opt.updatetime = 500
vim.opt.lazyredraw = true

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.keymap.set("n", "<Leader>w", "<Cmd>silent w!<CR>")
vim.keymap.set("n", "<Leader>q", "<Cmd>silent q!<CR>")
vim.keymap.set("n", "<Leader>x", "<Cmd>silent x!<CR>")
vim.keymap.set("n", "<Leader>W", "<Cmd>silent wa!<CR>")
vim.keymap.set("n", "<Leader>Q", "<Cmd>silent qa!<CR>")
vim.keymap.set("n", "<Leader>X", "<Cmd>silent xa!<CR>")
vim.keymap.set({ "n", "v" }, "<Leader>y", "\"+y")
vim.keymap.set({ "n", "v" }, "<Leader>p", "\"+p")
vim.keymap.set("n", "<Leader>P", "o<Esc>\"+p==")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzz")
vim.keymap.set("n", "N", "Nzz")
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-l>", "<C-w>l")
vim.keymap.set("n", "<C-n>", "<Cmd>tabnext<CR>")
vim.keymap.set("n", "<C-p>", "<Cmd>tabprevious<CR>")
vim.keymap.set("n", "<C-S-n>", "<Cmd>tabnew<CR>")
vim.keymap.set("n", "<C-S-p>", "<Cmd>tabclose<CR>")
vim.keymap.set("n", "<C-S-h>", "<Cmd>leftabove vsplit<CR>")
vim.keymap.set("n", "<C-S-j>", "<Cmd>rightbelow split<CR>")
vim.keymap.set("n", "<C-S-k>", "<Cmd>leftabove split<CR>")
vim.keymap.set("n", "<C-S-l>", "<Cmd>rightbelow vsplit<CR>")
-- TODO: completeopt? menu height?
vim.keymap.set("i", "<C-Space>", "<C-x><C-o>")

vim.pack.add({
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
    "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
    "https://github.com/Wansmer/treesj",
    "https://github.com/kylechui/nvim-surround",
    "https://github.com/windwp/nvim-autopairs",
    "https://github.com/numToStr/Comment.nvim",
    "https://github.com/gbprod/substitute.nvim",
    "https://github.com/stevearc/oil.nvim",
    "https://github.com/lewis6991/gitsigns.nvim",
    "https://github.com/ibhagwan/fzf-lua",
    { src = "https://github.com/rose-pine/neovim", name = "rose-pine" },
    "https://github.com/neovim/nvim-lspconfig",
    "https://github.com/mason-org/mason.nvim",
})

require('vim._core.ui2').enable()

-- Autostart treesitter
vim.api.nvim_create_autocmd("FileType", {
    callback = function()
        pcall(vim.treesitter.start)
        vim.bo.indentexpr = "v:lua.require('nvim-treesitter').indentexpr()"
    end,
})

local sel = require("nvim-treesitter-textobjects.select")
local swap = require("nvim-treesitter-textobjects.swap")
local move = require("nvim-treesitter-textobjects.move")
vim.keymap.set({ "x", "o" }, "af", function() sel.select_textobject("@function.outer", "textobjects") end)
vim.keymap.set({ "x", "o" }, "if", function() sel.select_textobject("@function.inner", "textobjects") end)
vim.keymap.set({ "x", "o" }, "ac", function() sel.select_textobject("@class.outer", "textobjects") end)
vim.keymap.set({ "x", "o" }, "ic", function() sel.select_textobject("@class.inner", "textobjects") end)
vim.keymap.set({ "x", "o" }, "aa", function() sel.select_textobject("@parameter.outer", "textobjects") end)
vim.keymap.set({ "x", "o" }, "ia", function() sel.select_textobject("@parameter.inner", "textobjects") end)
vim.keymap.set({ "x", "o" }, "ai", function() sel.select_textobject("@conditional.outer", "textobjects") end)
vim.keymap.set({ "x", "o" }, "ii", function() sel.select_textobject("@conditional.inner", "textobjects") end)
vim.keymap.set({ "x", "o" }, "gb", function() sel.select_textobject("@comment.outer", "textobjects") end)
vim.keymap.set("n", "<Leader>sf", function() swap.swap_next("@function.outer") end)
vim.keymap.set("n", "<Leader>Sf", function() swap.swap_previous("@function.outer") end)
vim.keymap.set("n", "<Leader>sc", function() swap.swap_next("@class.outer") end)
vim.keymap.set("n", "<Leader>Sc", function() swap.swap_previous("@class.outer") end)
vim.keymap.set("n", "<Leader>sa", function() swap.swap_next("@parameter.inner") end)
vim.keymap.set("n", "<Leader>Sa", function() swap.swap_previous("@parameter.inner") end)
vim.keymap.set("n", "<Leader>si", function() swap.swap_next("@conditional.inner") end)
vim.keymap.set("n", "<Leader>Si", function() swap.swap_previous("@conditional.inner") end)
vim.keymap.set("n", "]f", function() move.goto_next_start("@function.outer", "textobjects") end)
vim.keymap.set("n", "[f", function() move.goto_previous_start("@function.outer","textobjects") end)
vim.keymap.set("n", "]c", function() move.goto_next_start("@class.outer", "textobjects") end)
vim.keymap.set("n", "[c", function() move.goto_previous_start("@class.outer", "textobjects") end)
vim.keymap.set("n", "]p", function() move.goto_next_start("@parameter.inner", "textobjects") end)
vim.keymap.set("n", "[p", function() move.goto_previous_start("@parameter.inner", "textobjects") end)

local repeatable_move = require("nvim-treesitter-textobjects.repeatable_move")
vim.keymap.set({ "n", "x", "o" }, ";", repeatable_move.repeat_last_move)
vim.keymap.set({ "n", "x", "o" }, ",", repeatable_move.repeat_last_move_opposite)
vim.keymap.set({ "n", "x", "o" }, "f", repeatable_move.builtin_f_expr, { expr = true })
vim.keymap.set({ "n", "x", "o" }, "F", repeatable_move.builtin_F_expr, { expr = true })
vim.keymap.set({ "n", "x", "o" }, "t", repeatable_move.builtin_t_expr, { expr = true })
vim.keymap.set({ "n", "x", "o" }, "T", repeatable_move.builtin_T_expr, { expr = true })

local treesj = require("treesj")
treesj.setup({
    use_default_keymaps = false,
    max_join_length = 1024,
})
vim.keymap.set("n", "<Leader>t", treesj.toggle)

require("nvim-surround").setup()
vim.keymap.set("n", "yS", "<Plug>(nvim-surround-normal)$")

require("nvim-autopairs").setup()
require("Comment").setup()

local substitute = require("substitute")
local exchange = require("substitute.exchange")
local range = require("substitute.range")
substitute.setup()
vim.keymap.set("n", "s", substitute.operator, { noremap = true })
vim.keymap.set("n", "ss", substitute.line, { noremap = true })
vim.keymap.set("n", "S", substitute.eol, { noremap = true })
vim.keymap.set("x", "s", substitute.visual, { noremap = true })
vim.keymap.set("n", "<Leader>e", exchange.operator, { noremap = true })
vim.keymap.set("n", "<Leader>ee", exchange.line, { noremap = true })
vim.keymap.set("n", "<Leader>eq", exchange.cancel, { noremap = true })
vim.keymap.set("x", "<Leader>e", exchange.visual, { noremap = true })
-- TODO: Fix this and add more motions?
vim.keymap.set("n", "<Leader>sw", function() exchange.operator({ motion = "w" }) end, { noremap = true })
vim.keymap.set("n", "<Leader>r",  range.operator, { noremap = true })
vim.keymap.set("n", "<Leader>rr", range.word,     { noremap = true })

require("oil").setup()
vim.keymap.set("n", "<Leader>.", "<Cmd>e .<CR>")
vim.keymap.set("n", "<Leader>,", function()
    vim.cmd.e(vim.fs.root(0, {
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

local gitsigns = require("gitsigns")
gitsigns.setup()
vim.keymap.set({"o", "x"}, "ih", "<Cmd>Gitsigns select_hunk<CR>")
vim.keymap.set("n", "]c", function()
    if vim.wo.diff then
        vim.cmd.normal({ "]c", bang = true })
    else
        gitsigns.nav_hunk("next")
    end
end)
vim.keymap.set("n", "[c", function()
    if vim.wo.diff then
        vim.cmd.normal({ "[c", bang = true })
    else
        gitsigns.nav_hunk("prev")
    end
end)
vim.keymap.set('n', '<leader>hs', gitsigns.stage_hunk)
vim.keymap.set('n', '<leader>hr', gitsigns.reset_hunk)
vim.keymap.set('v', '<leader>hs', function()
    gitsigns.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
end)
vim.keymap.set('v', '<leader>hr', function()
    gitsigns.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') })
end)

local fzf_lua = require("fzf-lua")
fzf_lua.setup({
    fzf_colors = true,
    winopts = {
        border = "solid",
        preview = { border = "solid" },
    },
})
vim.keymap.set("n", "<Leader>f", fzf_lua.files)
vim.keymap.set("n", "<Leader>F", fzf_lua.oldfiles)
vim.keymap.set("n", "<Leader>b", fzf_lua.buffers)
vim.keymap.set("n", "<Leader>g", fzf_lua.live_grep_native)
vim.keymap.set("x", "<Leader>g", fzf_lua.grep_visual)
vim.keymap.set("n", "<Leader>h", fzf_lua.helptags)
vim.keymap.set("n", "<Leader>u", fzf_lua.undotree)

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
        CurSearch = { fg = "base", bg = "leaf", inherit = false },
        Search = { fg = "text", bg = "leaf", blend = 20, inherit = false },
        MatchParen = { link = "Search" },
        WinSeparator = { fg = "surface", bg = "base", inherit = false },
        VertSplit = { link = "WinSeparator" },
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

vim.diagnostic.config({
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "⦸",
            [vim.diagnostic.severity.WARN]  = "⊝",
            [vim.diagnostic.severity.HINT]  = "⊛",
            [vim.diagnostic.severity.INFO]  = "⊚",
        },
    },
    virtual_text = true,
    update_in_insert = false,
})

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(ev)
        -- local client = vim.lsp.get_client_by_id(ev.data.client_id)
        -- if client and client.server_capabilities.inlayHintProvider then
        --     vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
        -- end

        local opts = { buffer = ev.buf }
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
        vim.keymap.set("n", "gr", fzf_lua.lsp_references)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, opts)
        vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, opts)
        vim.keymap.set("n", "<Leader>lR", vim.lsp.buf.rename, opts)
        vim.keymap.set("n", "<Leader>la", vim.lsp.buf.code_action, opts)
        vim.keymap.set("n", "<Leader>lf", function() vim.lsp.buf.format({ async = true }) end, opts)
        vim.keymap.set("n", "<Leader>ll", vim.diagnostic.open_float, opts)
        vim.keymap.set("n", "<Leader>ld", fzf_lua.diagnostics_document)
        vim.keymap.set("n", "<Leader>lD", fzf_lua.diagnostics_workspace)
        vim.keymap.set("n", "<Leader>ls", fzf_lua.lsp_document_symbols)
        vim.keymap.set("n", "<Leader>lS", fzf_lua.lsp_workspace_symbols)
        vim.keymap.set("n", "<Leader>li", fzf_lua.lsp_implementations)
    end,
})

local exclude = { "gitlab_duo" }
for _, config in ipairs(vim.lsp.get_configs()) do
    if not vim.tbl_contains(exclude, config.name) then
        vim.lsp.enable(config.name)
    end
end

vim.lsp.config('lua_ls', {
    on_init = function(client)
        if client.workspace_folders then
            local path = client.workspace_folders[1].name
            if
                path ~= vim.fn.stdpath('config')
                and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc'))
            then
                return
            end
        end

        client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
            runtime = {
                version = 'LuaJIT',
                path = {
                    'lua/?.lua',
                    'lua/?/init.lua',
                },
            },
            workspace = {
                checkThirdParty = false,
                library = {
                    vim.env.VIMRUNTIME,
                    vim.api.nvim_get_runtime_file("lua/lspconfig", false)[1],
                },
            },
        })
    end,
    settings = {
        Lua = {},
    },
})

-- TODO: Snippets!!!!
