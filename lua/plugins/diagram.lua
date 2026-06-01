-- ~/.config/nvim/lua/plugins/diagram.lua
--
-- mermaid 等の図を Neovim バッファ内にインライン画像として表示する。
--   image.nvim   : ターミナルへの画像描画（Ghostty = Kitty graphics protocol）
--   diagram.nvim : ```mermaid ブロックを mmdc でレンダリングして image.nvim に渡す
--
-- 前提ツール: ImageMagick(magick CLI) と mermaid-cli(mmdc)。
-- ※ image.nvim は magick_cli プロセッサを使うため luarocks 不要
--   （lazy の rocks 機能は init.lua で無効化済み）。

return {
  {
    "3rd/image.nvim",
    opts = {
      backend = "kitty", -- Ghostty は Kitty graphics protocol 対応
      processor = "magick_cli", -- luarocks を使わず ImageMagick CLI で処理する
      integrations = {
        -- 図のレンダリングは diagram.nvim に任せるので markdown 統合は無効化（二重描画回避）
        markdown = { enabled = false },
      },
      max_width = 100,
      max_height = 25,
      window_overlap_clear_enabled = true, -- 補完ポップアップ等と重なったら一時的に消す
    },
  },
  {
    "3rd/diagram.nvim",
    dependencies = { "3rd/image.nvim" },
    ft = { "markdown" },
    -- integrations にはモジュールを渡す必要があり、プラグインのロード後に require したいので
    -- opts ではなく config 関数で setup する。
    config = function()
      require("diagram").setup({
        integrations = {
          require("diagram.integrations.markdown"),
        },
        renderer_options = {
          mermaid = {
            theme = "forest", -- default / forest / dark / neutral から選択
          },
        },
      })
    end,
  },
}
