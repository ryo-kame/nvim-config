-- ~/.config/nvim/lua/ide.lua

-- tree / overseer / 端末 以外の「通常エディタウィンドウ」があるか
local function has_editor_win()
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_config(w).relative == "" then
      local b = vim.api.nvim_win_get_buf(w)
      local ft, bt = vim.bo[b].filetype, vim.bo[b].buftype
      if ft ~= "NvimTree" and ft ~= "OverseerList" and bt ~= "terminal" then
        return true
      end
    end
  end
  return false
end

local function tree_win()
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "NvimTree" then
      return w
    end
  end
end

local function open_ide_layout()
  -- 左: ファイルツリー
  local ok, api = pcall(require, "nvim-tree.api")
  if ok then
    api.tree.open()
  end
  -- `nvim .` 直後は tree しか無いので、ファイルを開く先となる通常エディタ
  -- ウィンドウを tree の右に用意する（これが無いと nvim-tree がファイルを
  -- 下部パネルに開いてしまいレイアウトが崩れる）。
  if not has_editor_win() then
    local t = tree_win()
    if t then
      vim.api.nvim_set_current_win(t)
      vim.cmd("rightbelow vsplit")
      vim.cmd("enew")
    end
  end
  -- 右: Gradle タスクパネル（方向は setup の task_list.direction = "right" に従う）
  vim.cmd("OverseerOpen")
  -- 下: ターミナルパネル（term / claude をタブ切り替え）
  require("term_panel").show(1, false)
end

vim.keymap.set("n", "<leader>ui", open_ide_layout, { desc = "IDE レイアウト起動" })
