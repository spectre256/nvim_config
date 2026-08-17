local api = vim.api
local map = vim.keymap.set

vim.pack.add({ "https://github.com/neovim/nvim-lspconfig" })

local sev = vim.diagnostic.severity
vim.diagnostic.config({
    signs = {
        text = {
            [sev.ERROR] = "⦸",
            [sev.WARN]  = "⊝",
            [sev.HINT]  = "⊛",
            [sev.INFO]  = "⊚",
        },
    },
    virtual_text = true,
    update_in_insert = false,
})

api.nvim_create_autocmd("LspAttach", {
    callback = function(ev)
        -- vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })

        local buf_opts = { buf = ev.buf }

        local diagnostic_jump = function(opts)
            vim.diagnostic.jump({ count = opts.forward and 1 or -1 })
        end

        local ok, repeatable_move = pcall(require, "nvim-treesitter-textobjects.repeatable_move")
        if ok then diagnostic_jump = repeatable_move.make_repeatable_move(diagnostic_jump) end

        map("n", "]d", function() diagnostic_jump({ forward = true }) end, buf_opts)
        map("n", "[d", function() diagnostic_jump({ forward = false }) end, buf_opts)
        map("n", "gd", vim.lsp.buf.definition, buf_opts)
        map("n", "gD", vim.lsp.buf.declaration, buf_opts)
        map("n", "K", vim.lsp.buf.hover, buf_opts)
        map("n", "<Leader>lR", vim.lsp.buf.rename, buf_opts)
        map("n", "<Leader>la", vim.lsp.buf.code_action, buf_opts)
        map("n", "<Leader>lf", function() vim.lsp.buf.format({ async = true }) end, buf_opts)
        map("n", "<Leader>ll", vim.diagnostic.open_float, buf_opts)

        ok, fzf_lua = pcall(require, "fzf-lua")
        if ok then
            map("n", "gr", fzf_lua.lsp_references, buf_opts)
            map("n", "<Leader>ld", fzf_lua.diagnostics_document, buf_opts)
            map("n", "<Leader>lD", fzf_lua.diagnostics_workspace, buf_opts)
            map("n", "<Leader>ls", fzf_lua.lsp_document_symbols, buf_opts)
            map("n", "<Leader>lS", fzf_lua.lsp_workspace_symbols, buf_opts)
            map("n", "<Leader>li", fzf_lua.lsp_implementations, buf_opts)
        end
    end,
})

local exclude = { "gitlab_duo" }
for _, config in ipairs(vim.lsp.get_configs()) do
    if not vim.tbl_contains(exclude, config.name) then
        vim.lsp.enable(config.name)
    end
end

vim.lsp.config("lua_ls", {
    on_init = function(client)
        if client.workspace_folders then
            local path = client.workspace_folders[1].name
            if
                path ~= vim.fn.stdpath("config")
                and (vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc"))
            then
                return
            end
        end

        client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
            runtime = {
                version = "LuaJIT",
                path = {
                    "lua/?.lua",
                    "lua/?/init.lua",
                },
            },
            workspace = {
                checkThirdParty = false,
                library = {
                    vim.env.VIMRUNTIME,
                    api.nvim_get_runtime_file("lua/lspconfig", false)[1],
                },
            },
        })
    end,
    settings = {
        Lua = {},
    },
})

