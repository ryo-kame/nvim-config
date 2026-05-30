-- ~/.config/nvim/lua/term_panel.lua
-- 画面下部に固定された「ターミナルパネル」。
-- 1 つのウィンドウ内で複数のターミナル（term / claude など）を winbar 上の
-- タブで切り替える。VS Code の下部パネルに近い操作感を狙ったもの。
--
-- claudecode.nvim へはカスタムプロバイダ（M.provider()）を渡す。プロバイダは
-- claudecode から受け取った cmd_string / env_table をそのまま termopen に渡すため、
-- ClaudeCodeSend や diff 承認などの WebSocket 連携機能はそのまま使える。

local M = {}

local state = {
  win = nil, -- パネルウィンドウの id（非表示時は nil）
  height = 15, -- パネルの高さ（行）
  items = {}, -- 順序付きタブ: { name=, cmd=（table）, env=, buf= }
  current = 1, -- 現在表示中のタブ index
}

M._state = state -- デバッグ用に公開

-- ---------------------------------------------------------------------------
-- 内部ヘルパー
-- ---------------------------------------------------------------------------

local function win_valid()
  return state.win ~= nil and vim.api.nvim_win_is_valid(state.win)
end

local function buf_valid(item)
  return item ~= nil and item.buf ~= nil and vim.api.nvim_buf_is_valid(item.buf)
end

local function claude_item()
  for i, it in ipairs(state.items) do
    if it.name == "claude" then
      return i, it
    end
  end
end

-- buf がパネルのいずれかの端末バッファか
local function is_panel_item_buf(buf)
  for _, it in ipairs(state.items) do
    if it.buf == buf then
      return true
    end
  end
  return false
end

-- パネル外の「通常エディタウィンドウ」を探す（tree / overseer / 端末 / フロートは除外）
local SKIP_FT = { NvimTree = true, OverseerList = true, ["neo-tree"] = true, qf = true }
local function find_editor_win()
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if w ~= state.win and vim.api.nvim_win_get_config(w).relative == "" then
      local b = vim.api.nvim_win_get_buf(w)
      if not SKIP_FT[vim.bo[b].filetype] and vim.bo[b].buftype ~= "terminal" then
        return w
      end
    end
  end
end

local function find_tree_win()
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "NvimTree" then
      return w
    end
  end
end

-- 通常エディタウィンドウへフォーカスを移し、その win id を返す。無ければ作る。
-- telescope / nvim-tree からファイルを開く前に呼ぶことで、ファイルが tree や
-- 下部パネルに開いてレイアウトが崩れる（パネルが全幅でなくなる）のを防ぐ。
function M.goto_editor()
  local editor = find_editor_win()
  if not editor then
    local tree = find_tree_win()
    if tree then
      vim.api.nvim_set_current_win(tree)
      vim.cmd("rightbelow vsplit") -- tree の右に新規ウィンドウ
    elseif win_valid() then
      vim.api.nvim_set_current_win(state.win)
      vim.cmd("aboveleft split") -- パネルの上に新規ウィンドウ
    else
      vim.cmd("vsplit")
    end
    vim.cmd("enew")
    editor = vim.api.nvim_get_current_win()
  end
  vim.api.nvim_set_current_win(editor)
  return editor
end

-- "claude --flag" のような文字列を termopen 用の table に変換（native プロバイダ準拠）
local function split_cmd(cmd_string)
  if type(cmd_string) == "table" then
    return cmd_string
  end
  if cmd_string:find(" ", 1, true) then
    return vim.split(cmd_string, " ", { plain = true, trimempty = false })
  end
  return { cmd_string }
end

-- winbar 用のタブ表示文字列（statusline 構文）。winbar から毎回呼ばれる。
function M.winbar()
  local parts = {}
  for i, it in ipairs(state.items) do
    local label = string.format("  %d:%s  ", i, it.name)
    if i == state.current then
      parts[#parts + 1] = "%#TabLineSel#" .. label .. "%#TabLineFill#"
    else
      parts[#parts + 1] = "%#TabLine#" .. label .. "%#TabLineFill#"
    end
  end
  return table.concat(parts)
end

-- パネルウィンドウを用意（無ければ下部に全幅の水平分割で作成）
local function ensure_win()
  if win_valid() then
    return
  end
  state._guard = true -- 作成時に一瞬入る通常バッファをガードが追い出さないよう抑止
  local prev = vim.api.nvim_get_current_win()
  vim.cmd("botright " .. state.height .. "split")
  local w = vim.api.nvim_get_current_win()
  state.win = w
  vim.wo[w].winfixheight = true
  vim.wo[w].number = false
  vim.wo[w].relativenumber = false
  vim.wo[w].signcolumn = "no"
  vim.wo[w].winbar = "%!v:lua.require'term_panel'.winbar()"
  -- フォーカス制御は呼び出し側（show）に任せ、一旦元のウィンドウへ戻す
  if vim.api.nvim_win_is_valid(prev) then
    vim.api.nvim_set_current_win(prev)
  end
  state._guard = false
end

-- item のターミナルを新規起動し、パネルに表示する
local function spawn(item)
  ensure_win()
  state._guard = true -- enew の空バッファをガードが追い出さないよう抑止
  vim.api.nvim_win_call(state.win, function()
    vim.cmd("enew")
    local buf = vim.api.nvim_get_current_buf()
    vim.fn.termopen(item.cmd, {
      env = item.env,
      on_exit = function()
        item.buf = nil
        vim.schedule(function()
          M.refresh()
        end)
      end,
    })
    item.buf = buf
    vim.bo[buf].bufhidden = "hide"
    vim.bo[buf].buflisted = false -- bufferline のタブには出さない
  end)
  state._guard = false
end

-- ---------------------------------------------------------------------------
-- 公開 API
-- ---------------------------------------------------------------------------

-- タブを登録（同名があれば既存を返す）。戻り値: index, item
function M.register(item)
  for i, it in ipairs(state.items) do
    if it.name == item.name then
      return i, it
    end
  end
  state.items[#state.items + 1] = item
  return #state.items, state.items[#state.items]
end

-- index のタブを表示。focus=false なら表示のみでフォーカスは移さない。
function M.show(idx, focus)
  local item = state.items[idx]
  if not item then
    return
  end
  state.current = idx
  ensure_win()
  if buf_valid(item) then
    vim.api.nvim_win_set_buf(state.win, item.buf)
  else
    spawn(item)
  end
  if win_valid() then
    vim.wo[state.win].winbar = "%!v:lua.require'term_panel'.winbar()"
  end
  if focus ~= false and win_valid() then
    vim.api.nvim_set_current_win(state.win)
    vim.cmd("startinsert")
  end
end

-- パネルの開閉トグル（バッファ/プロセスは保持）
function M.toggle()
  if win_valid() then
    vim.api.nvim_win_close(state.win, false)
    state.win = nil
  else
    M.show(state.current or 1, true)
  end
end

-- タブ送り（dir=1 で次、dir=-1 で前）
function M.cycle(dir)
  local n = #state.items
  if n == 0 then
    return
  end
  local idx = ((state.current - 1 + (dir or 1)) % n) + 1
  M.show(idx, true)
end

-- winbar の再描画と、現在タブのプロセス終了時の後始末
function M.refresh()
  if not win_valid() then
    return
  end
  local item = state.items[state.current]
  if not buf_valid(item) then
    -- 現在のタブが終了 → term(1) にフォールバック。それも無ければパネルを閉じる
    if state.current ~= 1 and state.items[1] then
      M.show(1, false)
    else
      vim.api.nvim_win_close(state.win, false)
      state.win = nil
    end
  else
    vim.wo[state.win].winbar = "%!v:lua.require'term_panel'.winbar()"
  end
end

-- ---------------------------------------------------------------------------
-- claudecode.nvim 用カスタムプロバイダ
-- ---------------------------------------------------------------------------

-- claude タブを起動／表示
function M.claude_open(cmd_string, env, focus)
  local idx, item = claude_item()
  if not item then
    idx, item = M.register({ name = "claude", cmd = split_cmd(cmd_string), env = env })
  elseif not buf_valid(item) then
    -- 既存バッファが死んでいれば再起動できるよう cmd/env を更新
    item.cmd = split_cmd(cmd_string)
    item.env = env
  end
  M.show(idx, focus)
end

local function showing_claude()
  local _, item = claude_item()
  return win_valid()
    and item ~= nil
    and buf_valid(item)
    and vim.api.nvim_win_get_buf(state.win) == item.buf
end

local function hide_panel()
  if win_valid() then
    vim.api.nvim_win_close(state.win, false)
    state.win = nil
  end
end

-- claudecode が要求するプロバイダ table を返す
function M.provider()
  return {
    setup = function() end,
    open = function(cmd, env, _cfg, focus)
      M.claude_open(cmd, env, focus)
    end,
    close = function()
      if showing_claude() then
        hide_panel()
      end
    end,
    -- ClaudeCode: claude 表示中なら隠す、そうでなければ claude を表示
    simple_toggle = function(cmd, env, _cfg)
      if showing_claude() then
        hide_panel()
      else
        M.claude_open(cmd, env, true)
      end
    end,
    -- ClaudeCodeFocus: claude にフォーカス中なら隠す、未フォーカスならフォーカス、無ければ起動
    focus_toggle = function(cmd, env, _cfg)
      if showing_claude() then
        if vim.api.nvim_get_current_win() == state.win then
          hide_panel()
        else
          vim.api.nvim_set_current_win(state.win)
          vim.cmd("startinsert")
        end
      else
        M.claude_open(cmd, env, true)
      end
    end,
    toggle = function(cmd, env, _cfg)
      if showing_claude() then
        hide_panel()
      else
        M.claude_open(cmd, env, true)
      end
    end,
    get_active_bufnr = function()
      local _, item = claude_item()
      return buf_valid(item) and item.buf or nil
    end,
    is_available = function()
      return true
    end,
  }
end

-- ---------------------------------------------------------------------------
-- セットアップ（init.lua から呼ぶ）
-- ---------------------------------------------------------------------------

-- パネルウィンドウは端末専用・最下部固定にしたい。nvim-tree などが通常ファイルを
-- パネルに開こうとしたら、それを上部の通常エディタウィンドウへ追い出し、パネルには
-- 端末を戻す。これで claude / term タブは常に画面下部に留まる。
local function setup_guard()
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = vim.api.nvim_create_augroup("TermPanelGuard", { clear = true }),
    callback = function(ev)
      if state._guard or not win_valid() then
        return
      end
      if vim.api.nvim_get_current_win() ~= state.win then
        return
      end
      if is_panel_item_buf(ev.buf) then
        return -- 正規の端末バッファならそのまま
      end
      state._guard = true
      pcall(function()
        local intruder = ev.buf
        -- パネルには現在タブの端末を戻す
        local item = state.items[state.current]
        if buf_valid(item) then
          vim.api.nvim_win_set_buf(state.win, item.buf)
        end
        -- 侵入してきたバッファは通常エディタウィンドウへ。無ければ作る。
        local editor = find_editor_win()
        if not editor then
          local tree = find_tree_win()
          if tree then
            vim.api.nvim_set_current_win(tree)
            vim.cmd("rightbelow vsplit") -- tree の右に新規ウィンドウ
          else
            vim.api.nvim_set_current_win(state.win)
            vim.cmd("aboveleft split") -- パネルの上に新規ウィンドウ
          end
          editor = vim.api.nvim_get_current_win()
        end
        vim.api.nvim_set_current_win(editor)
        vim.api.nvim_win_set_buf(editor, intruder)
      end)
      state._guard = false
    end,
  })
end

function M.setup(opts)
  opts = opts or {}
  state.height = opts.height or state.height
  setup_guard()

  -- 1 番目のタブとしてシェルを登録（起動は初表示時に遅延）
  M.register({ name = "term", cmd = { vim.o.shell }, env = nil })

  local map = vim.keymap.set
  map({ "n", "t" }, "<C-\\>", function()
    M.toggle()
  end, { desc = "ターミナルパネル開閉" })
  map("n", "<leader>tt", function()
    M.cycle(1)
  end, { desc = "パネル: 次のタブ" })
  map("n", "<leader>tT", function()
    M.cycle(-1)
  end, { desc = "パネル: 前のタブ" })
  map("n", "<leader>t1", function()
    M.show(1, true)
  end, { desc = "パネル: term タブ" })
  map("n", "<leader>t2", function()
    M.show(2, true)
  end, { desc = "パネル: claude タブ" })
end

return M
