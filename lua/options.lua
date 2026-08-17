local opt = vim.opt

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

opt.foldcolumn = "1"
opt.signcolumn = "yes"

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
        -- Scrub ANSI color codes and Windows line endings
        lines[i] = line:gsub("\27%[[0-9;mK]+", ""):gsub("\13$", "")
    end
    return paste(lines, phase)
end
