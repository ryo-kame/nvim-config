-- ~/.config/nvim/lua/ide.lua

local function open_ide_layout()
  -- 左: ファイルツリー
  local ok, api = pcall(require, "nvim-tree.api")
  if ok then
    api.tree.open()
  end
  -- 右: Gradle タスクパネル（方向は setup の task_list.direction = "right" に従う）
  vim.cmd("OverseerOpen")
  -- 下: ターミナルパネル（term / claude をタブ切り替え）
  require("term_panel").show(1, false)
end

vim.keymap.set("n", "<leader>ui", open_ide_layout, { desc = "IDE レイアウト起動" })
