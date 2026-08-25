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
    ns = api.nvim_create_namespace("snippets"),
    state = {},
}
setmetatable(Snippets, Snippets)

local function make_defs(rules)
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

    rules = vim.tbl_extend("keep", rules, {
        empty = lpeg.P(true),
        any = function(rule) return rule + lpeg.P(1) * lpeg.V("any") end,
    })

    if type(langs) ~= "table" then langs = { langs } end
    for _, lang in ipairs(langs) do
        self.langs[lang] = rules
    end
end

function Snippets:add(langs, lhs, rhs, opts)
    if type(langs) ~= "table" then langs = { langs } end

    opts = opts or {}
    local include = vim.list_extend(vim.list_slice(opts), opts.include or {})
    if #include == 0 then include = { "empty" } end
    -- TODO: Implement
    local exclude = opts.exclude

    for _, lang in ipairs(langs) do
        if not self.rules[lang] then self.rules[lang] = {} end
        local computed_lhs = type(lhs) == "string" and vim.re.compile(lhs, make_defs(self.langs[lang])) or lhs

        for _, ctx in ipairs(include) do
            assert(self.langs[lang][ctx])
        end

        table.insert(self.rules[lang], {
            lang = lang,
            lhs = computed_lhs,
            rhs = rhs,
            include = include,
            exclude = exclude,
        })
    end
end

function Snippets:__call(langs, lhs, rhs, opts)
    self:add(langs, lhs, rhs, opts)
end

function Snippets:build(lang)
    if not self.rules[lang] then return nil end
    if not self.langs[lang] then self:lang(lang) end

    -- Create set of alternations per context
    local at_cursor = lpeg.Cmt(lpeg.Carg(1), function(_, pos, col) return pos == col + 1 end)
    local branches = {}
    for _, rule in ipairs(self.rules[lang]) do
        local pattern = lpeg.Cg(lpeg.Cp(), "start") * lpeg.Cg(rule.lhs / rule.rhs, "match") * at_cursor

        for _, ctx in ipairs(rule.include) do
            branches[ctx] = branches[ctx] and branches[ctx] + pattern or pattern
        end
    end

    -- Combine into single pattern
    local combined = vim.iter(branches)
        :fold(lpeg.P(false), function(acc, ctx, pattern)
            if type(self.langs[lang][ctx]) == "function" then return acc + lpeg.V(ctx) end
            return acc + lpeg.V(ctx) * pattern
        end)
    combined = lpeg.Ct(combined)

    -- Build grammar
    local grammar = vim.tbl_extend("error", { "top", top = combined }, self.langs[lang])
    for ctx, rule in pairs(grammar) do
        if type(rule) == "function" then
            grammar[ctx] = rule(branches[ctx] or lpeg.P(false))
        end
    end

    return lpeg.P(grammar)
end

function Snippets:pattern(lang)
    if not self.patterns[lang] then self.patterns[lang] = self:build(lang) end
    return self.patterns[lang]
end

function Snippets:reset(buf)
    local state = self.state[buf]
    for _, frame in ipairs((state and state.frames) or {}) do
        if frame.marks[1] then api.nvim_buf_del_extmark(buf, self.ns, frame.marks[1]) end
        if frame.marks[2] then api.nvim_buf_del_extmark(buf, self.ns, frame.marks[2]) end
    end

    state = {
        last_tick = 0,
        last_row = 0,
        last_col = 0,
        expanded = false,
        frames = {},
        frame_i = 1,
    }

    self.state[buf] = state
    return state
end

function Snippets:buf_state(buf)
    buf = buf or api.nvim_get_current_buf()
    return self.state[buf] or self:reset(buf)
end

function Snippets:has_undo(buf)
    buf = buf or api.nvim_get_current_buf()
    local state = self.state[buf]
    return state and state.frame_i > 1
end

function Snippets:has_redo(buf)
    buf = buf or api.nvim_get_current_buf()
    local state = self.state[buf]
    return state and state.frame_i - 1 < #state.frames
end

function Snippets:save(buf, deleted, row1, col1, row2, col2)
    local new_frame = {
        marks = {},
        deleted = deleted,
    }

    new_frame.marks[1] = api.nvim_buf_set_extmark(buf, self.ns, row1, col1, { right_gravity = false })
    new_frame.marks[2] = api.nvim_buf_set_extmark(buf, self.ns, row2, col2, { right_gravity = true })

    local state = self:buf_state(buf)

    -- Cut off frames after current save point, clobber with new frame
    local old_frames = vim.list_slice(state.frames, state.frame_i)
    state.frames = vim.list_slice(state.frames, 1, state.frame_i - 1)
    for _, frame in ipairs(old_frames) do
        if frame.marks[1] then api.nvim_buf_del_extmark(buf, self.ns, frame.marks[1]) end
        if frame.marks[2] then api.nvim_buf_del_extmark(buf, self.ns, frame.marks[2]) end
    end

    table.insert(state.frames, new_frame)
    state.frame_i = state.frame_i + 1
end

function Snippets:restore(buf, action)
    buf = buf or api.nvim_get_current_buf()

    local is_undo = action ~= "redo" -- Undo if "undo" or nil, otherwise redo
    if not (is_undo and self:has_undo(buf) or not is_undo and self:has_redo(buf)) then return false end
    vim.snippet.stop()

    local state = self:buf_state(buf)

    state.frame_i = state.frame_i + (is_undo and -1 or 0)
    local frame = state.frames[state.frame_i]
    state.frame_i = state.frame_i + (is_undo and 0 or 1)
    state.expanded = not is_undo

    local row1, col1 = unpack(api.nvim_buf_get_extmark_by_id(buf, self.ns, frame.marks[1], { details = false }))
    local row2, col2 = unpack(api.nvim_buf_get_extmark_by_id(buf, self.ns, frame.marks[2], { details = false }))

    -- Undo/redo just swaps deleted and existing text
    local deleted = frame.deleted
    frame.deleted = api.nvim_buf_get_text(buf, row1, col1, row2, col2, {})
    api.nvim_buf_set_text(buf, row1, col1, row2, col2, deleted)

    api.nvim_win_set_cursor(0, { row1 + #deleted, col1 + #deleted[#deleted] })

    return true
end

function Snippets:on_key(ev)
    -- 0-indexed row and col
    local row, col = unpack(api.nvim_win_get_cursor(0))
    row = row - 1

    -- Only expand when adding characters, not removing
    local state = self:buf_state(ev.buf)
    local added_char = row == state.last_row and col > state.last_col
    state.last_row, state.last_col = row, col
    if not added_char then return end
    state.expanded = false

    local pattern = self:pattern(vim.bo[ev.buf].filetype)
    if not pattern then return end

    local line = api.nvim_get_current_line()
    local result = pattern:match(line, 1, col)
    if result then
        local start = result.start - 1
        -- TODO: Multi-line handling
        self:save(ev.buf, { line:sub(result.start, col) }, row, start, row, col)
        api.nvim_buf_set_text(ev.buf, row, start, row, col, {})
        vim.snippet.expand(result.match)
        state.expanded = true
    end
end

function Snippets:setup()
    map({ "i", "s" }, "<C-e>", function()
        if not self:restore(nil, "undo") then
            api.nvim_feedkeys(k"<C-e>", "n", false)
        end
    end)

    map({ "i", "s" }, "<C-y>", function()
        if not self:restore(nil, "redo") then
            api.nvim_feedkeys(k"<C-y>", "n", false)
        end
    end)

    local ok, npairs = pcall(require, "nvim-autopairs")
    map({ "i", "s" }, "<BS>", function()
        local buf = api.nvim_get_current_buf()
        local state = self:buf_state(buf)
        if not (state.expanded and self:restore(buf, "undo")) then
            api.nvim_feedkeys(ok and npairs.autopairs_bs() or k"<BS>", "n", false)
        end
    end)

    map({ "i", "s" }, "<Tab>", function()
        if vim.snippet.active({ direction = 1 }) then
            local buf = api.nvim_get_current_buf()
            self:buf_state(buf).expanded = false
            vim.snippet.jump(1)
        else
            api.nvim_feedkeys(k"<Tab>", "n", false)
        end
    end)

    map({ "i", "s" }, "<Esc>", function()
        if vim.snippet.active() then vim.snippet.stop() end

        api.nvim_feedkeys(k"<Esc>", "n", false)
    end)

    api.nvim_create_autocmd({ "InsertEnter", "CursorMovedI" }, {
        callback = function(ev)
            local tick = api.nvim_buf_get_changedtick(ev.buf)
            local state = self:buf_state(ev.buf)
            if ev.event == "InsertEnter" or tick == state.last_tick then
                local row, col = unpack(api.nvim_win_get_cursor(0))
                state.last_row, state.last_col = row - 1, col
            end
            state.last_tick = tick
        end,
    })

    api.nvim_create_autocmd("TextChangedI", {
        callback = function(ev) self:on_key(ev) end,
    })

    api.nvim_create_autocmd("BufDelete", {
        callback = function(ev) self.state[ev.buf] = nil end,
    })
end

return Snippets
