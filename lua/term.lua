local api = vim.api
local map = vim.keymap.set

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
