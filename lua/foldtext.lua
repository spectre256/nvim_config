local opt = vim.opt
local api = vim.api

local Foldtext = {}

function Foldtext.setup()
    opt.foldtext = "v:lua.require('foldtext').render()"
end

local function get_highlighted_row(bufnr, row, trim_space)
    local line = api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1]
    local col = 0

    if trim_space then
        local _, count = line:find("^%s*")
        col = count or col
    end

    local result = {}
    local last_node = nil

    for i = col + 1, #line do
        local text = line:sub(i, i)
        local info = vim.inspect_pos(bufnr, row - 1, i - 1)
        local hls = {}

        for _, t in ipairs(info.syntax) do
            table.insert(hls, t.hl_group)
        end
        for _, t in ipairs(info.treesitter) do
            table.insert(hls, t.hl_group)
        end
        for _, t in ipairs(info.semantic_tokens) do
            table.insert(hls, t.opts.hl_group)
        end

        if last_node and vim.deep_equal(hls, last_node[2]) then
            last_node[1] = last_node[1] .. text
        else
            last_node = { text, hls }
            table.insert(result, last_node)
        end
    end

    return result
end

function Foldtext.render()
    local foldstart = vim.v.foldstart
    local foldend = vim.v.foldend
    local bufnr = api.nvim_get_current_buf()

    local first_row = get_highlighted_row(bufnr, foldstart, false)
    local fold_fmt = vim.wo.diff and "  ↵ %d lines " or " ―― %d lines ―― "
    local fold_marker = { string.format(fold_fmt, foldend - foldstart - 1), { "Folded" } }

    local result = first_row
    table.insert(result, fold_marker)

    if not vim.wo.diff then
        local last_row = get_highlighted_row(bufnr, foldend, true)
        table.move(last_row, 1, #last_row, #result + 1, result)
    end

    return result
end

return Foldtext
