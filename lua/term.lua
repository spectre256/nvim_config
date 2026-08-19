local opt_local = vim.opt_local
local api = vim.api
local map = vim.keymap.set

-- Better terminal mode settings
api.nvim_create_autocmd("TermOpen", {
    callback = function(ev)
        if vim.bo[ev.buf].filetype == "fzf" then return end

        opt_local.statuscolumn = ""
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
    pattern = { "help", "pager" },
    callback = function(ev)
        map("n", "<Esc>", "<C-w>c", { buf = ev.buf })
    end,
})

local Statuscolumn = require("statuscolumn")

api.nvim_create_autocmd("FileType", {
    pattern = { "markdown", "text", "typst", "tex", "plaintex", "help", "man" },
    callback = function(ev)
        Statuscolumn:setup_writing(ev.buf)

        opt_local.textwidth = 80
        opt_local.cursorline = false
        opt_local.wrap = true
        opt_local.linebreak = true
        opt_local.breakindent = true
        opt_local.spell = true
        opt_local.conceallevel = 2
    end,
})
