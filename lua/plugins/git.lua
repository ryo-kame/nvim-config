-- ~/.config/nvim/lua/plugins/git.lua
return {
  { "lewis6991/gitsigns.nvim" },
  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
  },
}
