local map = vim.keymap.set

vim.pack.add({
    "https://github.com/lewis6991/gitsigns.nvim",
    "https://github.com/sindrets/diffview.nvim",
    "https://github.com/NeogitOrg/neogit",
})

local ok, fzf_lua = pcall(require, "fzf-lua")
if ok then
    map("n", "<Leader>gs", fzf_lua.git_status)
    map("n", "<Leader>gh", fzf_lua.git_hunks)
    map("n", "<Leader>gl", fzf_lua.git_commits)
end

ok, gitsigns = pcall(require, "gitsigns")
if ok then
    gitsigns.setup()
    map({"o", "x"}, "ah", "<Cmd>Gitsigns select_hunk<CR>")

    local goto_hunk = function(opts)
        if vim.wo.diff then
            vim.cmd.normal({ opts.forward and "]h" or "[h", bang = true })
        else
            gitsigns.nav_hunk(opts.forward and "next" or "prev", { navigation_message = false })
        end
    end

    ok, repeatable_move = pcall(require, "nvim-treesitter-textobjects.repeatable_move")
    if ok then goto_hunk = repeatable_move.make_repeatable_move(goto_hunk) end

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
end

ok, diffview = pcall(require, "diffview")
if ok then diffview.setup() end

local ok, neogit = pcall(require, "neogit")
if ok then
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
end
