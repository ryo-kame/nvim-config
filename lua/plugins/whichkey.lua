-- ~/.config/nvim/lua/plugins/whichkey.lua
-- リーダーキーを押すと使用可能なキーマップをポップアップ表示する
return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      -- プレフィックスにグループ名を付けて一覧を見やすくする
      spec = {
        { "<leader>a", group = "AI/Claude Code" },
        { "<leader>f", group = "find (telescope)" },
      },
    },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer Local Keymaps (which-key)",
      },
    },
  },
}
