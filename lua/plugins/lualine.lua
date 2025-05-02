-- plugins/lualine.lua
return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("lualine").setup({
      options = {
        theme = "tokyonight", -- 好きなテーマに変えてね
        icons_enabled = true,
        section_separators = { left = '', right = '' },
        component_separators = { left = '', right = '' },
      },
      sections = {
        lualine_a = {'mode'},
        lualine_b = {'branch', 'diff'},
        lualine_c = {'filename'},
        lualine_x = {'encoding', 'fileformat', 'filetype'},
        lualine_y = {'progress'},
        lualine_z = {'location'}
      }
    })
  end,
}
