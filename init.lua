-- ~/.config/nvim/init.lua

vim.g.mapleader = ","
-- lazy.nvim の self-bootstrap（自動で clone）
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- lazy.nvim のプラグイン読み込み
-- image.nvim は magick_cli プロセッサ（ImageMagick CLI）を使うため luarocks 不要。
-- lazy の rocks 機能が hererocks を勝手に導入しようとするのを無効化する。
require("lazy").setup("plugins", { rocks = { enabled = false } })

-- プラグインごとの設定ファイル読み込み（必要なら個別ファイルに分けておくと整理しやすい）
require("options")
require("term_panel").setup() -- 下部ターミナルパネル（term / claude をタブ切り替え）
require("lsp")
require("dap-config")
require("cmp-config")
require("treesitter")
require("nvimtree")
require("telescope-config")
require("git")
require("tasks")
require("ide")
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

-- 未使用のシンボルを見やすくする（例：少し明るいグレーにする）
vim.api.nvim_set_hl(0, "@lsp.typemod.unused", { fg = "#7f849c" })

-- Telescope キーマップ
-- ツリーや下部パネルにフォーカスがある状態で起動すると、ファイルがそこに開いて
-- レイアウトが崩れる（パネルが全幅でなくなる）。起動前に通常エディタウィンドウへ
-- フォーカスを移すことで、ファイルは必ずエディタ側に開く。
local function in_editor(fn)
  return function()
    require("term_panel").goto_editor()
    fn()
  end
end
local builtin = function(name, opts)
  return function()
    require("telescope.builtin")[name](opts)
  end
end
vim.keymap.set("n", "<C-p>", in_editor(builtin("find_files")))
vim.keymap.set("n", "<leader>fp", in_editor(builtin("find_files")), { desc = "ファイル名検索（<C-p>と同じ）" })
vim.keymap.set("n", "<leader>fg", in_editor(builtin("live_grep")))
vim.keymap.set("n", "<leader>/", in_editor(builtin("current_buffer_fuzzy_find")), { noremap = true, silent = true })
vim.keymap.set("n", "<leader>fb", in_editor(builtin("buffers")))
vim.keymap.set("n", "<leader>fh", in_editor(builtin("help_tags")))
vim.keymap.set("n", "<leader>fa", in_editor(builtin("find_files", {
  hidden = true,
  no_ignore = true,
})), { desc = "すべてのファイルを表示（.gitignore無視も含む）" })

vim.o.updatetime = 250
vim.cmd [[autocmd CursorHold * lua vim.diagnostic.open_float(nil, { focusable = false })]]

vim.o.wrap = false

-- 次のバッファ（ファイル）に移動
vim.keymap.set("n", "<Tab>", ":bnext<CR>", { noremap = true, silent = true })
-- 前のバッファに移動
vim.keymap.set("n", "<S-Tab>", ":bprevious<CR>", { noremap = true, silent = true })
-- バッファ（タブ）を閉じる
vim.keymap.set("n", "<leader>bd", ":bdelete<CR>", { noremap = true, silent = true, desc = "バッファを閉じる" })
-- 今のバッファ以外を全部閉じる
vim.keymap.set("n", "<leader>bo", ":%bd|e#|bd#<CR>", { noremap = true, silent = true, desc = "他のバッファを閉じる" })

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

-- Yank時に自動でMacのクリップボードにもコピー
vim.api.nvim_set_keymap('v', 'y', '"+y', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'yy', '"+yy', { noremap = true, silent = true })
-- Insertモードで jj を押すと ESC + 英語入力に切り替える
-- vim.keymap.set('v', 'jk', '<Esc>', { noremap = true, silent = true })
vim.keymap.set("n", "<leader>r", function()
  require("nvim-tree.api").tree.change_root_to_node()
end, { desc = "nvim-tree: Change root to selected node" })
