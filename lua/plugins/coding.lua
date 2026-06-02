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

  -- カーソル下の変数・シンボルと同じものを自動ハイライト
  {
    "RRethy/vim-illuminate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("illuminate").configure({
        -- ハイライトの根拠とする情報源の優先順位:
        -- LSP（意味解析・最も正確）> Tree-sitter > 正規表現（フォールバック）
        providers = { "lsp", "treesitter", "regex" },
        delay = 100, -- カーソル停止からハイライトまでの待ち時間（ms）
        large_file_cutoff = 2000, -- これより大きいファイルでは無効化
        filetypes_denylist = {
          "NvimTree",
          "TelescopePrompt",
          "trouble",
          "lazy",
          "mason",
          "dap-repl",
          "dapui_scopes",
          "dapui_breakpoints",
          "dapui_stacks",
          "dapui_watches",
        },
      })

      -- 同一シンボル間を移動するキーマップ（]r = 次、[r = 前）
      vim.keymap.set("n", "]r", function()
        require("illuminate").goto_next_reference(false)
      end, { desc = "次の同一シンボルへ" })
      vim.keymap.set("n", "[r", function()
        require("illuminate").goto_prev_reference(false)
      end, { desc = "前の同一シンボルへ" })
    end,
  },
}

