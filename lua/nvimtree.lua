-- ~/.config/nvim/lua/nvimtree.lua

require("nvim-tree").setup({
  view = {
    -- 画面全体の幅に対する割合で指定（tree 3割・ファイル窓 7割）
    width = "30%",
    side = "left",
    relativenumber = true,
  },
  renderer = {
    highlight_git = true,
    icons = {
      show = {
        git = true,
        folder = true,
        file = true,
      },
    },
  },
  git = {
    enable = true,
  },
  actions = {
    open_file = {
      -- ファイルは tree / ターミナル / Overseer 以外の通常エディタ窓に開く。
      -- 該当する窓が無ければ nvim-tree が新しく split を作るので、下部の
      -- ターミナルパネルにファイルが開いてレイアウトが崩れるのを防ぐ。
      window_picker = {
        enable = true,
        exclude = {
          filetype = { "NvimTree", "OverseerList", "notify", "qf", "diff" },
          buftype = { "terminal", "nofile", "help" },
        },
      },
    },
  },
})

-- ~/.config/nvim/lua/nvimtree.lua の末尾に追加

vim.keymap.set("n", "<C-n>", ":NvimTreeToggle<CR>", { noremap = true, silent = true, desc = "ファイルツリーを開閉" })

