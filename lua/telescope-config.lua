-- ~/.config/nvim/lua/telescope-config.lua

require("telescope").setup({
  defaults = {
    layout_strategy = "horizontal",
    layout_config = {
      preview_width = 0.6,
    },
    file_ignore_patterns = { "node_modules", "%.git/" },
  },
})

