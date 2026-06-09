-- plugins/sql.lua
-- ~/.config/nvim/lua/plugins/sql.lua
--
-- SQL / データベースクライアント（SQL Server 想定）
-- vim-dadbod 本体 + UI + 補完の 3 点セット。
--
-- SQL Server には実用的な専用 LSP が事実上ないため、接続中 DB の実スキーマを
-- 直接引いて補完する vim-dadbod-completion が最も実用的（方言に依存しない）。
-- cmp への組み込みは lua/cmp-config.lua 側で SQL 系バッファに対して行う。
--
-- 接続情報はこのリポジトリ（dotfiles）に残さない方針：
--   1) 環境変数 DBUI_URL があれば "dev" 接続として自動登録
--   2) なければ DBUI サイドバーで `A`（DBUIAddConnection）を押して対話的に追加。
--      保存先は vim.g.db_ui_save_location（= リポジトリ外の data ディレクトリ）。
--
-- SQL Server の接続 URL 例: sqlserver://user:password@host:1433
-- ※ dadbod は SQL Server 接続に Microsoft の sqlcmd を使用する。
--   未導入なら: brew install sqlcmd

return {
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      { "tpope/vim-dadbod", lazy = true },
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
    },
    cmd = {
      "DBUI",
      "DBUIToggle",
      "DBUIAddConnection",
      "DBUIFindBuffer",
    },
    keys = {
      { "<leader>Db", "<cmd>DBUIToggle<CR>", desc = "DB: UI 表示切替" },
      { "<leader>Df", "<cmd>DBUIFindBuffer<CR>", desc = "DB: バッファ検索" },
      { "<leader>Da", "<cmd>DBUIAddConnection<CR>", desc = "DB: 接続を追加" },
    },
    init = function()
      -- nerd font アイコン（このリポジトリは nvim-web-devicons 導入済み）
      vim.g.db_ui_use_nerd_fonts = 1
      -- クエリ履歴・対話追加した接続の保存先。リポジトリ外の data ディレクトリ。
      vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/db_ui"
      -- 環境変数があれば dev 接続を自動登録（認証情報はリポジトリに残さない）
      if vim.env.DBUI_URL and vim.env.DBUI_URL ~= "" then
        vim.g.dbs = { { name = "dev", url = vim.env.DBUI_URL } }
      end
    end,
  },
}
