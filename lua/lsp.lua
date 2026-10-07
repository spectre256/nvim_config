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
    virtual_text = {
        format = function(diagnostic)
            return diagnostic.message:match("[^\n]*"):gsub("%.$", " ")
        end,
    },
    update_in_insert = false,
})

api.nvim_create_autocmd("LspAttach", {
    callback = function(ev)
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
        map("n", "<Leader>lq", vim.diagnostic.setqflist, buf_opts)
        map("n", "<Leader>lh", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
        end, buf_opts)

        local ok, fzf_lua = pcall(require, "fzf-lua")
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

vim.lsp.config("clangd", {
    cmd = { "clangd", "--experimental-modules-support", "--header-insertion=never" },
})

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

local exclude = { gitlab_duo = true }
vim.schedule(function()
    local names = vim
        .iter(vim.lsp.get_configs())
        :map(function(config) return config.name end)
        :filter(function(name) return not exclude[name] end)
        :totable()

    vim.lsp.enable(names)
end)
