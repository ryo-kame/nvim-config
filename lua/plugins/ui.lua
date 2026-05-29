-- ~/.config/nvim/lua/plugins/ui.lua

return {
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" }, -- ファイルアイコン
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha",
        transparent_background = true,
        -- 透過背景だと区切り線が見えにくいので明るい色で太く描画する
        custom_highlights = function(colors)
          return {
            WinSeparator = { fg = colors.blue, bold = true },
          }
        end,
        integrations = {
          nvimtree = true,
          treesitter = true,
          telescope = { enabled = true },
          native_lsp = { enabled = true },
          gitsigns = true,
          cmp = true,
          bufferline = true,
          mason = true,
        },
      })
      vim.cmd.colorscheme("catppuccin")
    end,
  },
}
