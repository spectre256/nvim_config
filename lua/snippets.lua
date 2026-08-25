local api = vim.api
local map = vim.keymap.set
local lpeg = vim.lpeg
local k = vim.keycode

-- TODO: General purpose "expand snippet with" keymap

-- Smart unexpanding snippets
local Snippets = {
    langs = {},
    rules = {},
    patterns = {},
    state = {
        ns = api.nvim_create_namespace("snippets"),
        expanded = false,
        deleted = nil,
        marks = { nil, nil },
        last_row = 0,
        last_col = 0,
    },
}
setmetatable(Snippets, Snippets)

function make_defs(rules)
    local defs = {}
    for name, _ in pairs(rules) do
        defs[name] = lpeg.V(name)
    end
    return defs
end

function Snippets:lang(langs, rules)
    local defs = make_defs(rules)
    for rule_name, rule in pairs(rules) do
        if type(rule) == "string" then
            rules[rule_name] = vim.re.compile(rule, defs)
        end
    end
    rules.empty = rules.empty or lpeg.P(true)

    if type(langs) ~= "table" then langs = { langs } end
    for _, lang in ipairs(langs) do
        self.langs[lang] = rules
    end
end

function Snippets:build(lang)
    if not self.rules[lang] then return nil end


    -- Create set of alternations per context
    local at_cursor = lpeg.Cmt(lpeg.Carg(1), function(_, pos, col) return pos == col + 1 end)
    local branches = {}
    for _, rule in ipairs(self.rules[lang]) do
        pattern = rule.lhs / rule.rhs * at_cursor

        for _, ctx in ipairs(rule.ctx) do
            branches[ctx] = branches[ctx] and branches[ctx] + pattern or pattern
        end
    end

    -- Combine into single pattern
    local combined = vim.iter(branches)
        :fold(lpeg.P(false), function(acc, ctx, pattern)
            return acc + lpeg.V(ctx) * pattern
        end)
    combined = lpeg.Ct(lpeg.Cg(combined, "match") * lpeg.Cg(lpeg.Cp(), "pos"))

    -- Build grammar
    local grammar = vim.tbl_extend("error", { "top", top = combined }, self.langs[lang])
    return lpeg.P(grammar)
end

function Snippets:pattern(lang)
    if not self.patterns[lang] then self.patterns[lang] = Snippets:build(lang) end
    return self.patterns[lang]
end

function Snippets:add(langs, lhs, rhs, opts)
    if type(langs) ~= "table" then langs = { langs } end
    opts = vim.tbl_extend("keep", opts or {}, { ctx = { "empty" } })

    for _, lang in ipairs(langs) do
        if not self.rules[lang] then self.rules[lang] = {} end
        local computed_lhs = type(lhs) == "string" and vim.re.compile(lhs, make_defs(self.langs[lang])) or lhs

        table.insert(self.rules[lang], {
            lang = lang,
            lhs = computed_lhs,
            rhs = rhs,
            ctx = opts.ctx,
        })
    end
end

function Snippets:__call(langs, lhs, rhs, opts)
    self:add(langs, lhs, rhs, opts)
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
        api.nvim_feedkeys(k"<Esc>a", "n", false)
        return true
    else
        return false
    end
end

function Snippets:on_key(ev)
    -- 0-indexed row and col
    local row, col = unpack(api.nvim_win_get_cursor(0))
    row = row - 1

    -- Only expand when adding characters, not removing
    local added_char = row == self.state.last_row and col > self.state.last_col
    self.state.last_row, self.state.last_col = row, col
    if not added_char then return end

    local pattern = self:pattern(vim.bo[ev.buf].filetype)
    if not pattern then return end

    local line = api.nvim_get_current_line()
    local result = pattern:match(line, 1, col)
    if result then
        self.state:save(ev.buf, line:sub(1, col), row, 0, row, col)
        api.nvim_buf_set_text(ev.buf, row, 0, row, col, {})
        vim.snippet.expand(result.match)
        self.state.expanded = true
    else
        self.state.expanded = false
    end
end

function Snippets:setup()
    map({ "i", "s" }, "<C-e>", function()
        if not self:unexpand_snippet() then
            api.nvim_feedkeys(k"<C-e>", "n", false)
        end
    end)

    local ok, npairs = pcall(require, "nvim-autopairs")
    map({ "i", "s" }, "<BS>", function()
        if not (self.state.expanded and self:unexpand_snippet()) then
            api.nvim_feedkeys(ok and npairs.autopairs_bs() or k"<BS>", "n", false)
            self.state.expanded = false
        end
    end)

    map({ "i", "s" }, "<Tab>", function()
        if vim.snippet.active({ direction = 1 }) then
            self.state.expanded = false
            vim.snippet.jump(1)
        else
            api.nvim_feedkeys(k"<Tab>", "n", false)
        end
    end)

    map({ "i", "s" }, "<Esc>", function()
        if vim.snippet.active() then vim.snippet.stop() end

        api.nvim_feedkeys(k"<Esc>", "n", false)
    end)

    -- Auto-expand snippets
    api.nvim_create_autocmd("TextChangedI", {
        callback = function(ev) self:on_key(ev) end,
    })
end

return Snippets
