local api = vim.api
local map = vim.keymap.set
local k = vim.keycode

vim.g.mapleader = " "
vim.g.maplocalleader = " "

local move_screen = "reg_recording() == '' && reg_executing() == '' && v:count == 0 ? 'gKEY' : 'KEY'"
map("n", "j", move_screen:gsub("KEY", "j"), { expr = true })
map("n", "k", move_screen:gsub("KEY", "k"), { expr = true })
map("n", "gj", "j")
map("n", "gk", "k")
map("x", "<", "<gv")
map("x", ">", ">gv")
map({ "n", "x", "o" }, "H", "^")
map({ "n", "x", "o" }, "M", "gM")
map({ "n", "x", "o" }, "L", "$")
map("n", "U", "<C-r>")
map("n", ":", "reg_recording() == '' && reg_executing() == '' ? 'q:i' : ':'", { expr = true })
map("n", "q:", "reg_recording() == '' && reg_executing() == '' ? ':' : 'q:'", { expr = true })
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
map("n", "<Esc>", vim.fn.maparg("<C-l>", "n"))
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
map("n", "<C-b>b", "<C-^>")
map("n", "<C-b><C-b>", "<C-^>")
map("n", "<C-b>n", "<Cmd>new<CR>")
map("n", "<C-b><C-n>", "<Cmd>new<CR>")
-- Vim doesn't like it when I map <C-c> here
map("n", "<C-b>c", "<Cmd>bdelete<CR>")
map("n", "<C-b>w", "<Cmd>bwipeout<CR>")
map("n", "<C-b><C-w>", "<Cmd>bwipeout<CR>")

local function only_buf()
    local current = api.nvim_get_current_buf()
    for _, buf in ipairs(api.nvim_list_bufs()) do
        if buf ~= current and vim.bo[buf].buflisted then
            pcall(api.nvim_buf_delete, buf, {})
        end
    end
end
map("n", "<C-b>o", only_buf)
map("n", "<C-b><C-o>", only_buf)

map("i", "<C-Space>", "<C-x><C-o>")

api.nvim_create_autocmd("FileType", {
    pattern = { "help", "man", "pager" },
    callback = function(ev)
        map("n", "<Esc>", "<C-w>c", { buf = ev.buf })
        map("n", "q", "<C-w>c", { buf = ev.buf })
    end,
})

-- Multicursor extensions
local ns = api.nvim_create_namespace("nvim.multicursor")

map("n", "QQ", function()
    local count = vim.v.count1 - 1
    if count > 0 then
        vim.w.prev_view = vim.fn.winsaveview()
        return ("<Esc>V%djQq=<Cmd>call winrestview(w:prev_view)<CR>"):format(count, count)
    else
        return "Q"
    end
end, { expr = true })

map("n", "Q", function()
    local count = vim.v.count1
    local view = vim.fn.winsaveview()
    vim.o.operatorfunc = function()
        count = count - 1
        api.nvim_feedkeys("`]Q" .. (count > 0 and "." or ""), "nix", false)
        if count <= 0 then vim.fn.winrestview(view) end
    end
    return "<Esc>g@"
end, { expr = true })

map("n", "dQ", function()
    vim.o.operatorfunc = function(mode)
        local from = api.nvim_buf_get_mark(0, "[")
        local to = api.nvim_buf_get_mark(0, "]")
        from = { from[1] - 1, mode == "line" and 0 or from[2] }
        to = { to[1] - 1, mode == "line" and -1 or to[2] }

        for _, mark in ipairs(api.nvim_buf_get_extmarks(0, ns, from, to)) do
            api.nvim_buf_del_extmark(0, ns, mark[1])
        end
    end
    return "g@"
end, { expr = true })

-- zQ{motion}{motion} - performs zq with the second motion within the bounds of the first motion/textobject
-- {count}zQ{motion}  - performs zq with the provided motion on the next `count` lines
map("n", "zQ", function()
    local count = vim.v.count
    if count > 0 then
        return "<Esc>V" .. (count > 1 and (count - 1) .. "j" or "") .. "zq"
    else
        vim.o.operatorfunc = function(mode)
            local keys = { char = "v", line = "V", block = k"<C-v>" }
            api.nvim_feedkeys("`[" .. keys[mode] .. "`]zq", "ni", false)
        end
        return "g@"
    end
end, { expr = true })

-- <Leader>mg{motion} - gathers all lines with multicursors, scattering them one by one relative to the cursor according to the provided motion
-- TODO: Do I need this even?
map({ "n", "x" }, "<Leader>mg", function()
    local from = api.nvim_buf_get_mark(0, "[")
    local to = api.nvim_buf_get_mark(0, "]")
    local diff = { to[1] - from[1], to[2] - from[2] }
    local normal = vim.fn.mode()[1] == "n"

    local texts = {}
    for _, mark in ipairs(api.nvim_buf_get_extmarks(0, ns, 0, -1)) do
        local row, col = unpack(mark)
        local text = normal
            and api.nvim_buf_get_lines(0, row, row, false)
            or table.concat(api.nvim_buf_get_text(0, row, col, row + diff[1], col + diff[2]), "\n") .. "\n"

        table.insert(texts, text)
        api.nvim_buf_del_extmark(0, ns, mark[1])
    end

    local count = vim.v.count1
    local view = vim.fn.winsaveview()
    vim.o.operatorfunc = function()
        count = count - 1
        api.nvim_feedkeys("`]<Cmd>pu\"<CR>" .. (count > 0 and "." or ""), "nix", false)
        if count <= 0 then vim.fn.winrestview(view) end
    end
    return "<Esc>g@"
end, { expr = true })

local function align(opts)
    return function()
        ---@type [vim.api.keyset.get_extmark_item, integer, integer][]
        local mark_cols = vim
            .iter(api.nvim_buf_get_extmarks(0, ns, 0, -1))
            :map(function(mark)
                local _, row, col = unpack(mark)
                local line = api.nvim_buf_get_lines(0, row, row + 1, false)[1]
                local left, right = line:sub(1, col), line:sub(col + 1)
                return mark, left, right
            end)
            :filter(function(_, left, right)
                return left:match("%S+$") or right:match("^%S+")
            end)
            :map(function(mark, left, right)
                local left_col = mark[3] - #left:match("%S*$")
                local right_col = mark[3] + #right:match("^%S*")
                return mark, left_col, right_col
            end)
            :totable()

        ---@type [integer, integer]
        local maxes = vim
            .iter(mark_cols)
            :fold({ 0, 0 }, function(acc, mark_col)
                local _, left_col, right_col = unpack(mark_col)
                local left_max = acc[1] > left_col and acc[1] or left_col
                local right_max = acc[2] > right_col and acc[2] or right_col
                return { left_max, right_max }
            end)

        for _, mark_col in ipairs(mark_cols) do
            local mark, left_col, right_col = unpack(mark_col)
            local left_max, right_max = unpack(maxes)
            local left_spaces, right_spaces = opts.spaces(left_col, left_max, right_col, right_max)

            local row = mark[2]
            if opts.right then api.nvim_buf_set_text(0, row, right_col, row, right_col, { (" "):rep(right_spaces) }) end
            if opts.left then api.nvim_buf_set_text(0, row, left_col, row, left_col, { (" "):rep(left_spaces) }) end
        end
    end
end

map("n", "<Leader>m<", align({
    left = true,
    spaces = function(left, left_max)
        return left_max - left
    end,
}), { desc = "Left align all multicursors by adding or removing whitespace" })

map("n", "<Leader>m>", align({
    left = true,
    spaces = function(_, _, right, right_max)
        return right_max - right
    end,
}), { desc = "Right align all multicursors by adding or removing whitespace" })

map("n", "<Leader>m=", align({
    left = true,
    right = true,
    spaces = function(left, left_max, right, right_max)
        local half = (left_max - left + right_max - right) / 2
        return math.floor(half), math.ceil(half)
    end,
}), { desc = "Center all multicursors by adding or removing whitespace" })
