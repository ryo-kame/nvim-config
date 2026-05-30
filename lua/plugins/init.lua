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
  { "nvim-treesitter/nvim-treesitter", branch = "master", build = ":TSUpdate" },

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
  -- 端末は lua/term_panel.lua の「ターミナルパネル」に統一したため
  -- toggleterm.nvim は撤去（<C-\> はパネル開閉に再割り当て）
}

