local api = vim.api
local map = vim.keymap.set

vim.pack.add({
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
    "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
    "https://github.com/Wansmer/treesj",
})

-- Autostart treesitter
api.nvim_create_autocmd("FileType", {
    callback = function()
        local start_ok = pcall(vim.treesitter.start)
        local ts_ok = pcall(require, "nvim-treesitter")
        if start_ok and ts_ok then
            vim.bo.indentexpr = "v:lua.require('nvim-treesitter').indentexpr()"
        end
    end,
})

local ok, sel = pcall(require, "nvim-treesitter-textobjects.select")
if ok then
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
end

local ok, swap = pcall(require, "nvim-treesitter-textobjects.swap")
if ok then
    map("n", "<Leader>sf", function() swap.swap_next("@function.outer") end)
    map("n", "<Leader>Sf", function() swap.swap_previous("@function.outer") end)
    map("n", "<Leader>sc", function() swap.swap_next("@class.outer") end)
    map("n", "<Leader>Sc", function() swap.swap_previous("@class.outer") end)
    map("n", "<Leader>sa", function() swap.swap_next("@parameter.inner") end)
    map("n", "<Leader>Sa", function() swap.swap_previous("@parameter.inner") end)
    map("n", "<Leader>si", function() swap.swap_next("@conditional.inner") end)
    map("n", "<Leader>Si", function() swap.swap_previous("@conditional.inner") end)
end

local ok, move = pcall(require, "nvim-treesitter-textobjects.move")
if ok then
    map({ "n", "x", "o" }, "]f", function() move.goto_next_start("@function.outer", "textobjects") end)
    map({ "n", "x", "o" }, "[f", function() move.goto_previous_start("@function.outer","textobjects") end)
    map({ "n", "x", "o" }, "]c", function() move.goto_next_start("@class.outer", "textobjects") end)
    map({ "n", "x", "o" }, "[c", function() move.goto_previous_start("@class.outer", "textobjects") end)
    map({ "n", "x", "o" }, "]p", function() move.goto_next_start("@parameter.inner", "textobjects") end)
    map({ "n", "x", "o" }, "[p", function() move.goto_previous_start("@parameter.inner", "textobjects") end)
end

local ok, repeatable_move = pcall(require, "nvim-treesitter-textobjects.repeatable_move")
if ok then
    map({ "n", "x", "o" }, ";", repeatable_move.repeat_last_move)
    map({ "n", "x", "o" }, ",", repeatable_move.repeat_last_move_opposite)
    map({ "n", "x", "o" }, "f", repeatable_move.builtin_f_expr, { expr = true })
    map({ "n", "x", "o" }, "F", repeatable_move.builtin_F_expr, { expr = true })
    map({ "n", "x", "o" }, "t", repeatable_move.builtin_t_expr, { expr = true })
    map({ "n", "x", "o" }, "T", repeatable_move.builtin_T_expr, { expr = true })

    local cycles = {
        a = {
            cmd = "argument",
            info = function()
                return vim.fn.argidx() + 1, vim.fn.argc()
            end,
        },
        b = {
            cmd = "buffer",
            info = function()
                local current = api.nvim_get_current_buf()
                local bufs = vim.iter(api.nvim_list_bufs())
                    :filter(function(buf) return vim.bo[buf].buflisted end)
                    :totable()
                local i = vim.iter(ipairs(bufs))
                    :find(function(_, buf) return buf == current end)
                return i, #bufs
            end,
        },
        l = {
            cmd = "ll",
            info = function()
                local list = vim.fn.getloclist(0, { idx = 0, size = 0 })
                return list.idx, list.size
            end,
        },
        q = {
            cmd = "cc",
            info = function()
                local list = vim.fn.getqflist({ idx = 0, size = 0 })
                return list.idx, list.size
            end,
        },
    }

    for key, cycle in pairs(cycles) do
        local move_fn = repeatable_move.make_repeatable_move(function(opts)
            local i, size = cycle.info()
            local count = vim.v.count1 * (opts.forward and 1 or -1)
            local new_i = (i + count - 1) % size + 1
            pcall(vim.cmd, new_i .. cycle.cmd)
        end)

        map("n", "]" .. key, function() move_fn({ forward = true }) end)
        map("n", "[" .. key, function() move_fn({ forward = false }) end)
    end
end

local ok, treesj = pcall(require, "treesj")
if ok then
    treesj.setup({
        use_default_keymaps = false,
        max_join_length = 1024,
    })

    map("n", "<Leader>t", treesj.toggle)
end
