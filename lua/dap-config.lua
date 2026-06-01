-- ~/.config/nvim/lua/dap-config.lua
-- 言語非依存の DAP コア設定。
-- 各言語固有の adapter / configurations は ftplugin/<lang>.lua 側で定義する
-- （Java は ftplugin/java.lua）。

local dap_ok, dap = pcall(require, "dap")
if not dap_ok then
  return
end

local dapui_ok, dapui = pcall(require, "dapui")
if dapui_ok then
  dapui.setup()

  -- セッション開始で UI を開き、終了で閉じる
  dap.listeners.before.attach.dapui_config = function()
    dapui.open()
  end
  dap.listeners.before.launch.dapui_config = function()
    dapui.open()
  end
  dap.listeners.before.event_terminated.dapui_config = function()
    dapui.close()
  end
  dap.listeners.before.event_exited.dapui_config = function()
    dapui.close()
  end
end

local vt_ok, vt = pcall(require, "nvim-dap-virtual-text")
if vt_ok then
  vt.setup()
end

-- ブレークポイントなどの sign 表示
vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DapBreakpoint", numhl = "" })
vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DapBreakpoint", numhl = "" })
vim.fn.sign_define("DapBreakpointRejected", { text = "○", texthl = "DapBreakpoint", numhl = "" })
vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DapStopped", numhl = "" })
vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = "#e51400" })
vim.api.nvim_set_hl(0, "DapStopped", { fg = "#98c379" })

-- 汎用キーマップ（全 filetype）
local map = vim.keymap.set
map("n", "<F5>", function() dap.continue() end, { desc = "DAP: 開始/継続" })
map("n", "<F10>", function() dap.step_over() end, { desc = "DAP: ステップオーバー" })
map("n", "<F11>", function() dap.step_into() end, { desc = "DAP: ステップイン" })
map("n", "<F12>", function() dap.step_out() end, { desc = "DAP: ステップアウト" })
map("n", "<leader>db", function() dap.toggle_breakpoint() end, { desc = "DAP: ブレークポイント切替" })
map("n", "<leader>dB", function()
  dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { desc = "DAP: 条件付きブレークポイント" })
map("n", "<leader>dr", function() dap.repl.open() end, { desc = "DAP: REPL を開く" })
map("n", "<leader>dt", function() dap.terminate() end, { desc = "DAP: セッション終了" })
if dapui_ok then
  map("n", "<leader>du", function() dapui.toggle() end, { desc = "DAP: UI 表示切替" })
end
