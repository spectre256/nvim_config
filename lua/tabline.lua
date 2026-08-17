local opt = vim.opt
local api = vim.api

local Tabline = {}

-- Keep track of last non-floating-window buffer per tab
local tab_last_buf = {}

local function is_floating(win)
    return api.nvim_win_get_config(win).relative ~= "" or vim.fn.getcmdwintype() ~= ""
end

function Tabline.setup()
    opt.showtabline = 2
    opt.tabline = "%!v:lua.require('tabline').render()"

    api.nvim_create_autocmd("BufEnter", {
        callback = function()
            local win = api.nvim_get_current_win()
            if not is_floating(win) then
                local tab = api.nvim_get_current_tabpage()
                local buf = api.nvim_win_get_buf(win)
                tab_last_buf[tab] = buf
            end
        end,
    })
end

local function render_tab(i, tab)
    local win = api.nvim_tabpage_get_win(tab)
    local buf = api.nvim_win_get_buf(win)

    -- Don't change tabline for floating windows
    if is_floating(win) then
        local last_buf = tab_last_buf[tab]
        if last_buf and api.nvim_buf_is_valid(last_buf) then
            buf = last_buf
        end
    end

    local max_name_len = 20
    local path = api.nvim_buf_get_name(buf)
    local is_dir = path:match("^oil://")
    local name = vim.fn.fnamemodify(path, is_dir and ":s?oil://??:~:." or ":t")
    name = name ~= "" and name or (is_dir and "./" or "[No Name]")
    name = #name <= max_name_len and name or name:sub(1, max_name_len - 1) .. "…"

    local modified = api.nvim_get_option_value("modified", { buf = buf })
    local readonly = api.nvim_get_option_value("readonly", { buf = buf })
    local current = tab == api.nvim_get_current_tabpage()

    local hl = current and "%#TabLineSel#" or "%#TabLine#"
    local symbol = ""
    if modified then
        symbol = current and " %#ModifiedSel#●" or " %#Modified#●"
    elseif readonly then
        symbol = current and " %#ReadonlySel#⊘" or " %#Readonly#⊘"
    end

    local str = table.concat({
        hl .. " ",
        "%" .. i .. "T ",
        name .. "%<",
        symbol,
        " %" .. i .. "X" .. hl .. "× %X",
    })

    return str, current
end

function Tabline.render()
    local line = ""
    local tabs = api.nvim_list_tabpages()
    local last_current = false

    for i, tab in ipairs(tabs) do
        local str, current = render_tab(i, tab)
        local sep = current and "▐" or last_current and "▌" or "│"

        if i > 1 then line = line .. sep end
        line = line ..  str
        line = line .. "%#TabLineSep#"

        last_current = current
    end

    if last_current then line = line .. "▌" end

    return line .. "%#TabLineFill#"
end

return Tabline
