local map = vim.keymap.set

vim.pack.add({
    "https://github.com/ibhagwan/fzf-lua",
    "https://github.com/stevearc/oil.nvim",
})

local ok, oil = pcall(require, "oil")
if ok then oil.setup() end

map("n", "<Leader>.", "<Cmd>edit .<CR>")
map("n", "<Leader>,", function()
    vim.cmd.edit(vim.fs.root(0, {
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

local ok, fzf_lua = pcall(require, "fzf-lua")
if ok then
    fzf_lua.setup({
        fzf_colors = true,
        winopts = {
            border = "solid",
            preview = { border = "solid" },
        },
    })
    fzf_lua.register_ui_select()

    map("n", "<Leader>f", fzf_lua.files)
    map("n", "<Leader>F", fzf_lua.oldfiles)
    map("n", "<Leader>b", fzf_lua.buffers)
    map("n", "<Leader>/", fzf_lua.live_grep_native)
    map("x", "<Leader>/", fzf_lua.grep_visual)
    map("n", "<Leader>H", fzf_lua.helptags)
    map("n", "<Leader>M", fzf_lua.manpages)
    map("n", "<Leader>u", fzf_lua.undotree)

    map("n", "<Leader>cd", function()
        fzf_lua.fzf_exec("fd --type d --hidden --exclude .git", {
            actions = {
                default = function(selected, opts)
                    local dir = selected[1] or opts.last_query
                    if not dir or dir == "" then return end

                    vim.fn.mkdir(dir, "p")
                    vim.cmd.cd(dir)
                    vim.cmd.edit(".")
                end,
            },
        })
    end)
end

