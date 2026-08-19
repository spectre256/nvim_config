local api = vim.api

vim.pack.add({ { src = "https://github.com/rose-pine/neovim", name = "rose-pine" } })

local ok, ui2 = pcall(require, "vim._core.ui2")
if ok then ui2.enable() end

local ok, rose_pine = pcall(require, "rose-pine")
if ok then
    rose_pine.setup({
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
end

api.nvim_create_autocmd("TextYankPost", {
    callback = function()
        vim.hl.on_yank({ higroup = "Search", timeout = 500 })
    end,
})
