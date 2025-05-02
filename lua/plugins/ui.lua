-- ~/.config/nvim/lua/plugins/ui.lua

return {
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" }, -- ファイルアイコン
  },
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
  },
}

