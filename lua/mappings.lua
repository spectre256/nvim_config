local api = vim.api
local map = vim.keymap.set

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

api.nvim_create_autocmd("FileType", {
    pattern = { "help", "pager" },
    callback = function(ev)
        map("n", "<Esc>", "<C-w>c", { buf = ev.buf })
    end,
})
