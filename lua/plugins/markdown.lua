-- ~/.config/nvim/lua/plugins/markdown.lua
--
-- render-markdown.nvim: Markdown をバッファ内でそのまま装飾表示する。
-- 編集しながら常時レンダリングされる（モード切り替え不要）。
-- treesitter の markdown / markdown_inline パーサに依存（lua/treesitter.lua で install 済み）。

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons", -- 見出しなどのアイコン表示用
    },
    ft = { "markdown" },
    opts = {
      -- カーソルがある行だけ生の Markdown 記法を表示し、他行は装飾したまま編集できる
      anti_conceal = { enabled = true },
    },
  },
}
