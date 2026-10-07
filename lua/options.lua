local opt = vim.opt
local api = vim.api

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

-- Highlight all while searching, clear on exit
opt.incsearch = true
opt.hlsearch = false
api.nvim_create_autocmd({ "CmdlineEnter", "CmdlineLeave", "CmdwinEnter", "CmdwinLeave" }, {
    pattern = { "/", "\\?" },
    callback = function(ev)
        opt.hlsearch = ev.event == "CmdlineEnter" or ev.event == "CmdwinEnter"
    end,
})

-- Update leadmultispace based on shiftwidth/tabstop
local function update_leadmultispace(ev)
    -- Need a real bufnr for the loop's check
    local buf = ev.buf == 0 and api.nvim_get_current_buf() or ev.buf
    local shiftwidth = vim.bo[buf].shiftwidth > 0
        and vim.bo[buf].shiftwidth
        or vim.bo[buf].tabstop

    for _, win in ipairs(api.nvim_list_wins()) do
        if api.nvim_win_get_buf(win) == buf then
            api.nvim_win_call(win, function()
                vim.opt_local.listchars:append({
                    leadmultispace = "⎸" .. (" "):rep(shiftwidth - 1),
                })
            end)
        end
    end
end

api.nvim_create_autocmd("OptionSet", {
    pattern = { "shiftwidth", "tabstop" },
    callback = update_leadmultispace,
})
api.nvim_create_autocmd("BufWinEnter", {
    callback = update_leadmultispace,
})
