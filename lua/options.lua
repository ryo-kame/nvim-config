vim.opt.termguicolors = true
vim.opt.winblend = 0 -- ウィンドウの不透明度
vim.opt.pumblend = 0 -- ポップアップメニューの不透明度

-- ウィンドウ分割の境界を太い線にする（エディタ／ターミナルの境目をはっきりさせる）
vim.opt.fillchars = {
  horiz = "━",
  horizup = "┻",
  horizdown = "┳",
  vert = "┃",
  vertleft = "┫",
  vertright = "┣",
  verthoriz = "╋",
}

-- ノーマルモードでのウィンドウ移動（tree / editor / terminal を快適に行き来）
vim.keymap.set("n", "<C-h>", "<C-w>h", { silent = true, desc = "左のウィンドウへ" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { silent = true, desc = "下のウィンドウへ" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { silent = true, desc = "上のウィンドウへ" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { silent = true, desc = "右のウィンドウへ" })

-- bufferline（上のバッファタブ）切り替え
vim.keymap.set("n", "<S-l>", "<cmd>BufferLineCycleNext<CR>", { silent = true, desc = "次のバッファタブ" })
vim.keymap.set("n", "<S-h>", "<cmd>BufferLineCyclePrev<CR>", { silent = true, desc = "前のバッファタブ" })

-- 現在のバッファを閉じる（bufdelete.nvim でウィンドウ／tree のレイアウトを維持）
-- 未保存があれば中止。<leader>BD（,BD）は破棄して強制的に閉じる。
vim.keymap.set("n", "<leader>bd", function() require("bufdelete").bufdelete(0, false) end, { silent = true, desc = "バッファを閉じる（窓維持）" })
vim.keymap.set("n", "<leader>bD", function() require("bufdelete").bufdelete(0, true) end, { silent = true, desc = "バッファを強制的に閉じる" })

-- ノーマルモードでのウィンドウリサイズ（Ctrl + 矢印で押した分だけ調整）
vim.keymap.set("n", "<C-Up>", "<cmd>resize +2<CR>", { silent = true, desc = "ウィンドウ高さ+" })
vim.keymap.set("n", "<C-Down>", "<cmd>resize -2<CR>", { silent = true, desc = "ウィンドウ高さ-" })
vim.keymap.set("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { silent = true, desc = "ウィンドウ幅-" })
vim.keymap.set("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { silent = true, desc = "ウィンドウ幅+" })

-- ターミナルモードのキーマップ（エディタ⇔ターミナルの行き来を快適に）
vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "term://*",
  callback = function()
    local opts = { buffer = 0 }
    vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], vim.tbl_extend("force", opts, { desc = "ターミナルモードを抜ける" }))
    vim.keymap.set("t", "<C-h>", [[<C-\><C-n><C-w>h]], vim.tbl_extend("force", opts, { desc = "左のウィンドウへ" }))
    vim.keymap.set("t", "<C-j>", [[<C-\><C-n><C-w>j]], vim.tbl_extend("force", opts, { desc = "下のウィンドウへ" }))
    vim.keymap.set("t", "<C-k>", [[<C-\><C-n><C-w>k]], vim.tbl_extend("force", opts, { desc = "上のウィンドウへ" }))
    vim.keymap.set("t", "<C-l>", [[<C-\><C-n><C-w>l]], vim.tbl_extend("force", opts, { desc = "右のウィンドウへ" }))
  end,
})
