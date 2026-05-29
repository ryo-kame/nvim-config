-- ~/.config/nvim/lua/ide.lua

local function open_ide_layout()
  -- 左: ファイルツリー
  local ok, api = pcall(require, "nvim-tree.api")
  if ok then
    api.tree.open()
  end
  -- 右: Gradle タスクパネル（方向は setup の task_list.direction = "right" に従う）
  vim.cmd("OverseerOpen")
  -- 下: ターミナル
  vim.cmd("ToggleTerm direction=horizontal")
end

vim.keymap.set("n", "<leader>ui", open_ide_layout, { desc = "IDE レイアウト起動" })
