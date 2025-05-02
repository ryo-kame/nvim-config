-- ~/.config/nvim/init.lua

-- ランタイムパスに lazy.nvim を追加
vim.opt.rtp:prepend(vim.fn.stdpath("config") .. "/lazy/lazy.nvim")

-- lazy.nvim のプラグイン読み込み
require("lazy").setup("plugins")

-- プラグインごとの設定ファイル読み込み（必要なら個別ファイルに分けておくと整理しやすい）
require("lsp")
require("cmp-config")
require("treesitter")
require("nvimtree")
require("telescope-config")
require("bufferline").setup({
  options = {
    mode = "buffers", -- or "tabs"
    separator_style = "slant", -- "thin" や "padded_slant" もあり
    diagnostics = "nvim_lsp",  -- LSPエラーも表示できる
  }
})
-- 基本設定
vim.o.number = true
vim.o.relativenumber = true
vim.o.termguicolors = true
vim.o.clipboard = "unnamedplus"
vim.opt.fileencodings = { "utf-8", "cp932", "sjis", "euc-jp", "iso-2022-jp" }
vim.cmd("syntax enable")
-- カラースキーム設定（tokyonight + 透過）
vim.opt.termguicolors = true
require("tokyonight").setup({
  style = "night",
  transparent = true,
  styles = {
    sidebars = "transparent",
    floats = "transparent",
  },
})
vim.cmd([[colorscheme tokyonight]])
-- 未使用のシンボルを見やすくする（例：少し明るいグレーにする）
vim.api.nvim_set_hl(0, "@lsp.typemod.unused", { fg = "#7f849c" }) 
-- Telescope キーマップ
vim.keymap.set("n", "<C-p>", "<cmd>Telescope find_files<CR>")
vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<CR>")
vim.keymap.set("n", "<leader>/", "<cmd>Telescope current_buffer_fuzzy_find<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<CR>")
vim.keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<CR>")
vim.o.updatetime = 250
vim.cmd [[autocmd CursorHold * lua vim.diagnostic.open_float(nil, { focusable = false })]]
vim.o.wrap = false
-- 次のバッファ（ファイル）に移動
vim.keymap.set("n", "<Tab>", ":bnext<CR>", { noremap = true, silent = true })
-- 前のバッファに移動
vim.keymap.set("n", "<S-Tab>", ":bprevious<CR>", { noremap = true, silent = true })
-- TypeScript / JavaScript 用のインデント設定
vim.o.autoindent = true
vim.o.smartindent = true
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
  callback = function()
    vim.bo.tabstop = 2       -- タブを何文字分に見せるか
    vim.bo.shiftwidth = 2    -- 自動インデントで使う幅
    vim.bo.softtabstop = 2   -- <Tab>/<BS> の挙動を調整
    vim.bo.expandtab = true  -- タブをスペースに変換
  end,
})
