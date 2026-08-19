local api = vim.api
local opt_local = vim.opt_local

local Statuscolumn = {
    normal = "%C%s%=%{v:virtnum != 0 ? '' : v:relnum == 0 ? v:lnum : v:relnum} ", -- Fix left aligned number
    writing = "%{repeat(' ', (winwidth(0) - &textwidth) / 2)}",
    terminal = "",
    cmdwin = "",
    writing_bufs = {},
}

function Statuscolumn:setup()
    api.nvim_create_autocmd("BufWinEnter", {
        callback = function(ev)
            if vim.bo[ev.buf].filetype == "help" then -- Help buffers are weird
                self.writing_bufs[ev.buf] = true
            end

            if self.writing_bufs[ev.buf] then
                opt_local.statuscolumn = self.writing
            elseif vim.fn.getcmdwintype() ~= "" then
                opt_local.statuscolumn = self.cmdwin
            elseif vim.bo[ev.buf].buftype == "terminal" then
                opt_local.statuscolumn = self.terminal
            else
                opt_local.statuscolumn = self.normal
            end
        end,
    })

    api.nvim_create_autocmd("WinResized", {
        callback = function()
            local wins = vim.v.event.windows or {}

            for _, win in ipairs(wins) do
                local buf = api.nvim_win_get_buf(win)

                if self.writing_bufs[buf] then
                    vim.wo[win].statuscolumn = self.writing
                end
            end
        end,
    })

    api.nvim_create_autocmd("BufDelete", {
        callback = function(ev)
            self.writing_bufs[ev.buf] = nil
        end,
    })
end

function Statuscolumn:setup_writing(buf)
    self.writing_bufs[buf] = true

    opt_local.number = false
    opt_local.relativenumber = false
    opt_local.signcolumn = "no"
    opt_local.foldcolumn = "0"
    opt_local.statuscolumn = self.writing
end

return Statuscolumn
