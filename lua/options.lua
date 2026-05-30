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

-- ターミナルモードのキーマップ（エディタ⇔ターミナルの行き来を快適に）
vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "term://*",
  callback = function()
    local opts = { buffer = 0 }
    vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], opts)       -- Esc でターミナルモードを抜ける
    vim.keymap.set("t", "<C-h>", [[<C-\><C-n><C-w>h]], opts) -- 左のウィンドウへ
    vim.keymap.set("t", "<C-j>", [[<C-\><C-n><C-w>j]], opts) -- 下のウィンドウへ
    vim.keymap.set("t", "<C-k>", [[<C-\><C-n><C-w>k]], opts) -- 上のウィンドウへ
    vim.keymap.set("t", "<C-l>", [[<C-\><C-n><C-w>l]], opts) -- 右のウィンドウへ
  end,
})
