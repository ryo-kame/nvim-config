-- plugins/init.lua
return {
  -- ファイルツリー
  { "nvim-tree/nvim-tree.lua", dependencies = { "nvim-tree/nvim-web-devicons" } },

  -- ステータスライン
  { "nvim-lualine/lualine.nvim" },

  -- LSP関連
  { "neovim/nvim-lspconfig" },
  { "williamboman/mason.nvim" },
  { "williamboman/mason-lspconfig.nvim" },

  -- コード補完
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "L3MON4D3/LuaSnip" },
  { "saadparwaiz1/cmp_luasnip" },

  -- シンタックスハイライト
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },

  -- Fuzzy finder
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },

  -- テーマ
  { "catppuccin/nvim", name = "catppuccin", priority = 1000 },

  {
  "pmizio/typescript-tools.nvim",
  dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
  opts = {},
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
    require("nvim-autopairs").setup({})
    end,
  },
  -- trouble.nvim の追加
  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = true
  },
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
    require("bufferline").setup({})
    end,
  },
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      require("toggleterm").setup({
        open_mapping = [[<C-\>]], -- Ctrl+\ でトグル
        direction = "horizontal", -- 横方向（下）に表示
        size = 15, -- 高さ（お好みで調整）
        shade_terminals = true, -- 少し背景を暗く
        start_in_insert = true, -- 開いたらすぐ入力モード
        persist_size = true, -- サイズ記憶
      })
    end
  }
}

