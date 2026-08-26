local map = vim.keymap.set

vim.pack.add({
    "https://github.com/kylechui/nvim-surround",
    "https://github.com/windwp/nvim-autopairs",
    "https://github.com/numToStr/Comment.nvim",
    "https://github.com/gbprod/substitute.nvim",
})

local ok, surround = pcall(require, "nvim-surround")
if ok then
    surround.setup()

    -- TODO: Can I make a "surround with conditional" keybind? then yS would put it on a newline too? that'd be so cool!
    map("n", "yH", "<Plug>(nvim-surround-normal)^")
    map("n", "yL", "<Plug>(nvim-surround-normal)$")
end

local ok, npairs = pcall(require, "nvim-autopairs")
if ok then
    npairs.setup({
        map_bs = false, -- Integrates with snippet unexpansion
    })
end

local ok, comment = pcall(require, "Comment")
if ok then comment.setup() end

local ok, substitute = pcall(require, "substitute")
if ok then
    substitute.setup()

    map("n", "s", substitute.operator, { noremap = true })
    map("n", "ss", substitute.line, { noremap = true })
    map("n", "S", substitute.eol, { noremap = true })
    map("x", "s", substitute.visual, { noremap = true })
end

local ok, exchange = pcall(require, "substitute.exchange")
if ok then
    map("n", "<Leader>e", exchange.operator, { noremap = true })
    map("n", "<Leader>ee", exchange.line, { noremap = true })
    map("n", "<Leader>eq", exchange.cancel, { noremap = true })
    map("x", "<Leader>e", exchange.visual, { noremap = true })
end

local ok, range = pcall(require, "substitute.range")
if ok then
    map("n", "<Leader>r",  range.operator, { noremap = true })
    map("n", "<Leader>rr", range.word, { noremap = true })
end
