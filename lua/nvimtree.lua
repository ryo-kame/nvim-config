-- ~/.config/nvim/lua/nvimtree.lua

require("nvim-tree").setup({
  view = {
    width = 30,
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
})

-- ~/.config/nvim/lua/nvimtree.lua の末尾に追加

vim.keymap.set("n", "<C-n>", ":NvimTreeToggle<CR>", { noremap = true, silent = true })

