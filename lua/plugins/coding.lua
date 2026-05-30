-- ~/.config/nvim/lua/plugins/coding.lua

return {
  -- nvim-cmp（補完の本体）
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "hrsh7th/cmp-buffer" },
  { "hrsh7th/cmp-path" },
  { "hrsh7th/cmp-cmdline" },

  -- スニペットエンジン（必要）
  { "L3MON4D3/LuaSnip" },
  { "saadparwaiz1/cmp_luasnip" },

  -- treesitter（構文解析）の定義は lua/plugins/init.lua に集約（重複定義を排除）

  -- コードジャンプ（LSPでOKだけど補強用に optional）
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
}

