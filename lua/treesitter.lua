-- ~/.config/nvim/lua/treesitter.lua

require("nvim-treesitter.configs").setup({
  ensure_installed = { "lua", "typescript", "python", "json", "html", "css" },
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
  indent = {
    enable = true,
  },
})

