-- ~/.config/nvim/lua/git.lua

local gitsigns = require("gitsigns")

gitsigns.setup({
  signs = {
    add = { text = "+" },
    change = { text = "~" },
    delete = { text = "_" },
    topdelete = { text = "‾" },
    changedelete = { text = "~" },
  },
  current_line_blame = false,
})

require("diffview").setup({})

local map = vim.keymap.set
map("n", "<leader>gh", function() gitsigns.nav_hunk("next") end, { desc = "次の変更へ移動" })
map("n", "<leader>gH", function() gitsigns.nav_hunk("prev") end, { desc = "前の変更へ移動" })
map("n", "<leader>gp", gitsigns.preview_hunk, { desc = "変更をプレビュー" })
map("n", "<leader>gb", function() gitsigns.blame_line({ full = true }) end, { desc = "行 blame" })
map("n", "<leader>gd", "<cmd>DiffviewOpen<CR>", { desc = "差分ビューを開く" })
map("n", "<leader>gc", "<cmd>DiffviewClose<CR>", { desc = "差分ビューを閉じる" })
