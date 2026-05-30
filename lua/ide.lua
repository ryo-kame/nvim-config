-- ~/.config/nvim/lua/ide.lua

local function open_ide_layout()
  -- 左: ファイルツリー
  local ok, api = pcall(require, "nvim-tree.api")
  if ok then
    api.tree.open()
  end
  -- 下: ターミナルパネル（term / claude をタブ切り替え）
  require("term_panel").show(1, false)
  -- 空の No Name エディタ窓は作らない。ツリーからファイルを開いた瞬間に
  -- nvim-tree が通常エディタ窓を用意する（nvimtree.lua の window_picker で
  -- ターミナル/Overseer 窓を除外しているのでレイアウトは崩れない）。
  -- Gradle タスクパネル(Overseer)も自動では開かず、<leader>ot で都度トグルする。
end

vim.keymap.set("n", "<leader>ui", open_ide_layout, { desc = "IDE レイアウト起動" })
