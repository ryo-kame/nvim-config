-- ~/.config/nvim/lua/plugins/dap.lua
-- デバッグ（DAP）関連プラグイン。設定本体は lua/dap-config.lua。
return {
  -- DAP クライアント本体
  { "mfussenegger/nvim-dap" },

  -- デバッグ UI（変数 / コールスタック / ブレークポイント一覧 / REPL）
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
  },

  -- 行末に変数値をインライン表示
  {
    "theHamsta/nvim-dap-virtual-text",
    dependencies = { "mfussenegger/nvim-dap" },
  },
}
