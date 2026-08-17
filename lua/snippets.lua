local api = vim.api
local map = vim.keymap.set

-- TODO: General purpose "expand snippet with" keymap

-- Smart unexpanding snippets
local Snippets = {
    rules = {},
    state = {
        ns = api.nvim_create_namespace("snippets"),
        expanded = false,
        deleted = nil,
        marks = { nil, nil },
        last_row = 0,
        last_col = 0,
    },
}

local function toSet(arr)
    local set = {}
    for _, v in ipairs(arr) do
        set[v] = true
    end
    return set
end

function Snippets:add(langs, lhs, rhs, opts)
    if type(langs) ~= "table" then langs = { langs } end
    opts = opts or {}

    for _, lang in ipairs(langs) do
        if not self.rules[lang] then self.rules[lang] = {} end

        table.insert(self.rules[lang], {
            lang = lang,
            lhs = lhs .. "$",
            rhs = rhs,
            include = opts.include and toSet(opts.include),
            exclude = toSet(opts.exclude or {}),
        })
    end
end

function Snippets.snip(lang, lhs, rhs, opts)
    Snippets:add(lang, lhs, rhs, opts)
end

function Snippets.state:reset(bufnr)
    self.deleted = nil
    if self.marks[1] then api.nvim_buf_del_extmark(bufnr, self.ns, self.marks[1]) end
    if self.marks[2] then api.nvim_buf_del_extmark(bufnr, self.ns, self.marks[2]) end
    self.marks = { nil, nil }
end

function Snippets.state:is_saved()
    return self.deleted ~= nil
end

function Snippets.state:save(bufnr, deleted, row1, col1, row2, col2)
    if self:is_saved() then self:reset(bufnr) end

    self.marks[1] = api.nvim_buf_set_extmark(bufnr, self.ns, row1, col1, { right_gravity = false })
    self.marks[2] = api.nvim_buf_set_extmark(bufnr, self.ns, row2, col2, { right_gravity = true })
    self.deleted = deleted
end

function Snippets.state:restore(bufnr)
    if not self:is_saved() then return end

    local row1, col1 = unpack(api.nvim_buf_get_extmark_by_id(bufnr, self.ns, self.marks[1], { details = false }))
    local row2, col2 = unpack(api.nvim_buf_get_extmark_by_id(bufnr, self.ns, self.marks[2], { details = false }))
    api.nvim_buf_set_text(bufnr, row1, col1, row2, col2, { self.deleted })
    api.nvim_win_set_cursor(0, { row1 + 1, col1 + #self.deleted })

    self:reset(bufnr)
end

function Snippets:unexpand_snippet()
    if self.state:is_saved() then
        vim.snippet.stop()
        self.state:restore(0)
        api.nvim_feedkeys(vim.keycode("<Esc>a"), "n", false)
        return true
    else
        return false
    end
end

function Snippets:on_key(ev)
    do
        local ok, parser = pcall(vim.treesitter.get_parser, ev.buf)
        if not ok or not parser then goto skip end

        local tree = parser:parse()[1]
        if not tree then goto skip end

        -- 0-indexed row and col
        local row, col = unpack(api.nvim_win_get_cursor(0))
        row = row - 1

        -- Only expand when adding characters, not removing
        local added_char = row == self.state.last_row and col > self.state.last_col
        self.state.last_row, self.state.last_col = row, col
        if not added_char then goto skip end

        local lang_snippets = self.rules[parser:lang()]
        if not lang_snippets then goto skip end

        -- Subtract one to get node at beginning of cursor, necessary when typing at end of line
        local line = api.nvim_get_current_line():sub(1, col)

        for _, s in ipairs(lang_snippets) do
            local captures = vim.fn.matchlist(line, s.lhs)
            if #captures == 0 then goto continue end

            local match = captures[1]
            local i = col - #match

            -- Check node type just before match to avoid polluting check with typed characters
            local node = tree:root():named_descendant_for_range(row, i - 1, row, i - 1)
            local node_type = node and node:type()
            if s.include and not s.include[node_type] then goto continue end
            if s.exclude[node_type] then goto continue end

            self.state:save(ev.buf, match, row, i, row, col)
            api.nvim_buf_set_text(ev.buf, row, i, row, col, {})

            local rhs
            if type(s.rhs) == "function" then
                rhs = s.rhs(captures)
            else
                rhs = s.rhs:gsub("%$(%d+)", function(num_str)
                    local cap_i = tonumber(num_str)
                    return captures[cap_i + 1]
                end)
            end

            vim.snippet.expand(rhs)
            self.state.expanded = true
            -- Return immediately to avoid unsetting expand
            do return end

            ::continue::
        end
    end

    ::skip::
    self.state.expanded = false
end

function Snippets:setup()
    map({ "i", "s" }, "<C-e>", function()
        if not self:unexpand_snippet() then
            api.nvim_feedkeys(vim.keycode("<C-e>"), "n", false)
        end
    end)

    local ok, npairs = pcall(require, "nvim-autopairs")
    map({ "i", "s" }, "<BS>", function()
        if not (self.state.expanded and self:unexpand_snippet()) then
            api.nvim_feedkeys(ok and npairs.autopairs_bs() or vim.keycode("<BS>"), "n", false)
            snippets.state.expanded = false
        end
    end)
    map({ "i", "s" }, "<Tab>", function()
        if vim.snippet.active({ direction = 1 }) then
            self.state.expanded = false
            vim.snippet.jump(1)
        else
            api.nvim_feedkeys(vim.keycode("<Tab>"), "n", false)
        end
    end)
    map({ "i", "s" }, "<Esc>", function()
        if vim.snippet.active() then vim.snippet.stop() end

        api.nvim_feedkeys(vim.keycode("<Esc>"), "n", false)
    end)

    -- Auto-expand snippets
    api.nvim_create_autocmd("TextChangedI", {
        callback = function(ev) self:on_key(ev) end,
    })
end
