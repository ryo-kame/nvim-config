# Spring Boot DAP Debugging Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Neovim で Spring Boot プロジェクトに対し IntelliJ 相当のブレークポイントデバッグ（attach・dap-ui・JUnit テストデバッグ）を行えるようにする。

**Architecture:** nvim-dap を DAP クライアントとし、jdtls がバンドルとして内包する java-debug-adapter / java-test を `init_options.bundles` 経由で読み込む。言語非依存の DAP コア（dap-ui / virtual-text / signs / 汎用キーマップ）を `lua/dap-config.lua` に置き、Java 固有の配線（bundles・`setup_dap()`・attach 構成・テストキーマップ）を `ftplugin/java.lua` に置く。デバッグ対象 JVM は overseer の `bootRun (debug-jvm)` タスクで起動し、ポート 5005 に attach する。

**Tech Stack:** Neovim (Lua), lazy.nvim, mason.nvim / mason-registry, nvim-jdtls, mfussenegger/nvim-dap, rcarriga/nvim-dap-ui (+ nvim-neotest/nvim-nio), theHamsta/nvim-dap-virtual-text, overseer.nvim, Gradle (`bootRun --debug-jvm`).

---

## 前提（実装環境）

- 作業ディレクトリ: `~/.config/nvim`
- ブランチ: `feature/spring-boot-dap-debug`（設計ドキュメントをコミット済み）
- 検証コマンドの基本形（ヘッドレス読み込み確認）:
  - `nvim --headless -c 'lua print("OK:", pcall(require, "<module>"))' -c 'qa'`
  - lazy/mason の同期: `nvim --headless "+Lazy! sync" +qa`
- このリポジトリに自動テスト基盤は無いため、各タスクの「検証」はヘッドレス読み込み・`:Lazy`/`:Mason` 状態確認・実機デバッグで行う。

---

## ファイル構成

| 種別 | パス | 責務 |
|---|---|---|
| 新規 | `lua/plugins/dap.lua` | nvim-dap / nvim-dap-ui(+nvim-nio) / nvim-dap-virtual-text のプラグイン宣言 |
| 新規 | `lua/dap-config.lua` | 言語非依存の DAP コア（dap-ui/virtual-text setup・signs・自動開閉・汎用キーマップ） |
| 変更 | `init.lua` | `require("dap-config")` を追加 |
| 変更 | `lua/lsp.lua` | mason-registry で `java-debug-adapter` / `java-test` を ensure install |
| 変更 | `ftplugin/java.lua` | bundles 読込・`setup_dap()`・`dap.configurations.java`・テストデバッグキーマップ |
| 変更 | `lua/tasks.lua` | overseer Gradle テンプレートに `bootRun (debug-jvm)` を追加 |
| 変更 | `lua/plugins/whichkey.lua` | `<leader>d` グループ「debug (DAP)」を追加 |

---

## Task 1: DAP プラグインの宣言

**Files:**
- Create: `lua/plugins/dap.lua`

- [ ] **Step 1: プラグイン宣言ファイルを作成**

`lua/plugins/dap.lua`:

```lua
-- ~/.config/nvim/lua/plugins/dap.lua
-- デバッグ（DAP）関連プラグイン。設定本体は lua/dap-config.lua。
return {
  -- DAP クライアント本体
  { "mfussenegger/nvim-dap" },

  -- デバッグ UI（変数 / コールスタック / ブレークポイント一覧 / REPL）
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
  },

  -- 行末に変数値をインライン表示
  {
    "theHamsta/nvim-dap-virtual-text",
    dependencies = { "mfussenegger/nvim-dap" },
  },
}
```

- [ ] **Step 2: プラグインを同期**

Run: `nvim --headless "+Lazy! sync" +qa`
Expected: エラー出力なしで終了。`lazy-lock.json` に `nvim-dap` / `nvim-dap-ui` / `nvim-dap-virtual-text` / `nvim-nio` が追記される。

- [ ] **Step 3: 読み込みを確認**

Run: `nvim --headless -c 'lua print("dap:", pcall(require, "dap"))' -c 'lua print("dapui:", pcall(require, "dapui"))' -c 'lua print("vt:", pcall(require, "nvim-dap-virtual-text"))' -c 'qa'`
Expected: `dap: true` / `dapui: true` / `vt: true` が出力される。

- [ ] **Step 4: コミット**

```bash
git add lua/plugins/dap.lua lazy-lock.json
git commit -m "feat: add nvim-dap, dap-ui, dap-virtual-text plugin declarations

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: mason で java-debug-adapter / java-test を ensure install

**Files:**
- Modify: `lua/lsp.lua`

- [ ] **Step 1: mason-registry の ensure ブロックを追加**

`lua/lsp.lua` の先頭、`require("mason").setup()` の直後（`require("mason-lspconfig").setup({...})` の前）に以下を挿入する。

挿入前（現状の冒頭）:

```lua
-- MasonでLSPサーバーを管理
require("mason").setup()

require("mason-lspconfig").setup({
```

挿入後:

```lua
-- MasonでLSPサーバーを管理
require("mason").setup()

-- LSP サーバーではない Java デバッグ用パッケージを ensure install する。
-- これらはバンドルとして jdtls(ftplugin/java.lua) に読み込まれる。
-- mason-lspconfig の ensure_installed には載らないため registry を直接使う。
local function ensure_mason_packages(packages)
  local ok, registry = pcall(require, "mason-registry")
  if not ok then
    return
  end
  registry.refresh(function()
    for _, name in ipairs(packages) do
      local found, pkg = pcall(registry.get_package, name)
      if found and not pkg:is_installed() then
        pkg:install()
      end
    end
  end)
end
ensure_mason_packages({ "java-debug-adapter", "java-test" })

require("mason-lspconfig").setup({
```

- [ ] **Step 2: 設定全体が読み込めることを確認**

Run: `nvim --headless -c 'lua print("lsp:", pcall(require, "lsp"))' -c 'qa'`
Expected: `lsp: true`（`lua/lsp.lua` がエラーなく評価される）。

- [ ] **Step 3: インストールをトリガし完了を待って確認**

Run: `nvim --headless "+Lazy! sync" +qa`（プラグイン前提を満たすため）に続けて通常の `nvim` を一度起動し、`:Mason` で `java-debug-adapter` と `java-test` が installed になることを確認する。
ヘッドレスでの確認例:
`nvim --headless -c 'lua local r=require("mason-registry"); r.refresh(function() print("java-debug-adapter:", r.is_installed("java-debug-adapter")); print("java-test:", r.is_installed("java-test")) end)' -c 'sleep 30' -c 'qa'`
Expected: 初回は install が走るため `false`→数十秒後に installed。再実行で `true` / `true`。

> 補足: 初回インストールは非同期。`:Mason` UI で進捗を確認するのが確実。

- [ ] **Step 4: コミット**

```bash
git add lua/lsp.lua
git commit -m "feat: ensure java-debug-adapter and java-test via mason-registry

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: 言語非依存の DAP コア設定

**Files:**
- Create: `lua/dap-config.lua`
- Modify: `init.lua`

- [ ] **Step 1: DAP コア設定ファイルを作成**

`lua/dap-config.lua`:

```lua
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
```

- [ ] **Step 2: init.lua から読み込む**

`init.lua` の `require("lsp")` の直後に `require("dap-config")` を追加する。

変更前:

```lua
require("lsp")
require("cmp-config")
```

変更後:

```lua
require("lsp")
require("dap-config")
require("cmp-config")
```

- [ ] **Step 3: 読み込みと sign 定義を確認**

Run: `nvim --headless -c 'lua print("dap-config:", pcall(require, "dap-config"))' -c 'lua print("sign:", vim.fn.sign_getdefined("DapBreakpoint")[1] ~= nil)' -c 'qa'`
Expected: `dap-config: true` / `sign: true`。

- [ ] **Step 4: 汎用キーマップの存在を確認**

Run: `nvim --headless -c 'lua require("dap-config")' -c 'lua local m = vim.fn.maparg("<leader>db", "n"); print("db mapped:", m ~= "")' -c 'qa'`
Expected: `db mapped: true`。

- [ ] **Step 5: コミット**

```bash
git add lua/dap-config.lua init.lua
git commit -m "feat: add language-agnostic DAP core (dap-ui, virtual-text, keymaps)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: which-key に `<leader>d` グループを追加

**Files:**
- Modify: `lua/plugins/whichkey.lua`

- [ ] **Step 1: グループ定義を追加**

`lua/plugins/whichkey.lua` の `spec` 内に `<leader>d` グループを追加する。

変更前:

```lua
      spec = {
        { "<leader>a", group = "AI/Claude Code" },
        { "<leader>f", group = "find (telescope)" },
      },
```

変更後:

```lua
      spec = {
        { "<leader>a", group = "AI/Claude Code" },
        { "<leader>d", group = "debug (DAP)" },
        { "<leader>f", group = "find (telescope)" },
      },
```

- [ ] **Step 2: which-key 設定が読み込めることを確認**

Run: `nvim --headless "+Lazy! load which-key.nvim" -c 'lua print("wk:", pcall(require, "which-key"))' -c 'qa'`
Expected: `wk: true`（エラーなし）。

- [ ] **Step 3: コミット**

```bash
git add lua/plugins/whichkey.lua
git commit -m "feat: add <leader>d debug group to which-key

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: jdtls に bundles・setup_dap・attach 構成・テストキーマップを追加

**Files:**
- Modify: `ftplugin/java.lua`

- [ ] **Step 1: ftplugin/java.lua を更新**

以下が更新後の `ftplugin/java.lua` 全文。`mason_path` を流用してデバッグ用 jar をグロブし `init_options.bundles` に渡す。`on_attach` で `setup_dap()` と Java の attach 構成、テストデバッグのキーマップを設定する。

```lua
-- ~/.config/nvim/ftplugin/java.lua

local jdtls_ok, jdtls = pcall(require, "jdtls")
if not jdtls_ok then
  return
end

local root_markers = {
  "gradlew", "mvnw", ".git",
  "settings.gradle", "settings.gradle.kts",
  "build.gradle", "build.gradle.kts", "pom.xml",
}
local root_dir = require("jdtls.setup").find_root(root_markers)
if root_dir == nil or root_dir == "" then
  return
end

local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
local workspace_dir = vim.fn.stdpath("cache") .. "/jdtls/" .. project_name

local mason_path = vim.fn.stdpath("data") .. "/mason/packages/jdtls"
local launcher_jar = vim.fn.glob(mason_path .. "/plugins/org.eclipse.equinox.launcher_*.jar")
-- jdtls がまだインストールされていなければ何もしない
if launcher_jar == nil or launcher_jar == "" then
  return
end

-- OS/アーキテクチャに応じた jdtls の config ディレクトリを選ぶ
local uname = vim.loop.os_uname()
local is_arm = uname.machine:match("arm") ~= nil or uname.machine:match("aarch64") ~= nil
local config_dir
if uname.sysname == "Darwin" then
  config_dir = is_arm and "config_mac_arm" or "config_mac"
elseif uname.sysname == "Linux" then
  config_dir = is_arm and "config_linux_arm" or "config_linux"
else
  config_dir = "config_win"
end

-- 補完用 capabilities（cmp-nvim-lsp があれば利用）
local capabilities = vim.lsp.protocol.make_client_capabilities()
local cmp_ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
if cmp_ok then
  capabilities = cmp_lsp.default_capabilities(capabilities)
end

-- デバッグ用バンドル（java-debug-adapter + java-test）を mason から収集する。
-- これらを init_options.bundles に渡すと jdtls がデバッグアダプタを内包し、
-- jdtls.setup_dap() で dap.adapters.java が登録される。
local mason_pkgs = vim.fn.stdpath("data") .. "/mason/packages"
local bundles = {}
local debug_jar = vim.fn.glob(
  mason_pkgs .. "/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar", true)
if debug_jar ~= "" then
  table.insert(bundles, debug_jar)
end
local test_jars = vim.fn.glob(mason_pkgs .. "/java-test/extension/server/*.jar", true)
if test_jars ~= "" then
  vim.list_extend(bundles, vim.split(test_jars, "\n"))
end

local config = {
  cmd = {
    "java",
    "-Declipse.application=org.eclipse.jdt.ls.core.id1",
    "-Dosgi.bundles.defaultStartLevel=4",
    "-Declipse.product=org.eclipse.jdt.ls.core.product",
    "-Dlog.protocol=true",
    "-Dlog.level=ALL",
    "-Xmx1g",
    "-javaagent:" .. mason_path .. "/lombok.jar",
    "--add-modules=ALL-SYSTEM",
    "--add-opens", "java.base/java.util=ALL-UNNAMED",
    "--add-opens", "java.base/java.lang=ALL-UNNAMED",
    "-jar", launcher_jar,
    "-configuration", mason_path .. "/" .. config_dir,
    "-data", workspace_dir,
  },
  root_dir = root_dir,
  capabilities = capabilities,
  settings = { java = {} },
  init_options = { bundles = bundles },
  on_attach = function(client, bufnr)
    local opts = { buffer = bufnr }
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

    -- デバッグ: dap.adapters.java と既定のメインクラス構成を登録
    jdtls.setup_dap({ hotcodereplace = "auto" })

    -- Spring Boot などへ attach する構成（bootRun --debug-jvm のポート 5005）
    local dap_ok, dap = pcall(require, "dap")
    if dap_ok then
      dap.configurations.java = {
        {
          type = "java",
          request = "attach",
          name = "Attach to bootRun (5005)",
          hostName = "127.0.0.1",
          port = 5005,
        },
      }
    end

    -- テストのデバッグ実行（buffer-local）
    vim.keymap.set("n", "<leader>dn", function()
      jdtls.test_nearest_method()
    end, vim.tbl_extend("force", opts, { desc = "DAP: 近傍のテストをデバッグ" }))
    vim.keymap.set("n", "<leader>dT", function()
      jdtls.test_class()
    end, vim.tbl_extend("force", opts, { desc = "DAP: テストクラスをデバッグ" }))
  end,
}

jdtls.start_or_attach(config)
```

- [ ] **Step 2: ftplugin がエラーなく評価されることを確認（jdtls 未起動でも安全に return すること）**

Run: `nvim --headless -c 'edit /tmp/__dap_check.java' -c 'sleep 2' -c 'lua print("loaded java ftplugin without error")' -c 'qa'`
Expected: `loaded java ftplugin without error` が出る（root が見つからない一時ファイルでは早期 return し、エラーにならない）。

- [ ] **Step 3: 実プロジェクトで attach 構成が登録されることを確認（手動）**

実際の Spring Boot プロジェクト内の Java ファイルを開き、jdtls 起動後に以下を実行:
Run: `:lua print(vim.inspect(require'dap'.configurations.java))`
Expected: `Attach to bootRun (5005)` を含む構成が表示される。
Run: `:lua print(require'dap'.adapters.java ~= nil)`
Expected: `true`（`setup_dap()` によりアダプタ登録済み）。

- [ ] **Step 4: コミット**

```bash
git add ftplugin/java.lua
git commit -m "feat: wire java-debug/java-test bundles and attach config into jdtls

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 6: overseer に `bootRun (debug-jvm)` タスクを追加

**Files:**
- Modify: `lua/tasks.lua`

- [ ] **Step 1: Gradle テンプレートにデバッグ起動エントリを追加**

`lua/tasks.lua` の generator 内、`gradle_tasks` ループの後・`gradle <custom>` エントリの前に以下を挿入する。

変更前（該当箇所）:

```lua
    local ret = {}
    for _, task in ipairs(gradle_tasks) do
      table.insert(ret, {
        name = "gradle " .. task,
        builder = function()
          return { cmd = { gradle_cmd() }, args = { task }, components = { "default" } }
        end,
      })
    end
    -- 任意の Gradle タスクを入力して実行
    table.insert(ret, {
```

変更後:

```lua
    local ret = {}
    for _, task in ipairs(gradle_tasks) do
      table.insert(ret, {
        name = "gradle " .. task,
        builder = function()
          return { cmd = { gradle_cmd() }, args = { task }, components = { "default" } }
        end,
      })
    end
    -- デバッグ用: bootRun を JVM デバッグ有効（既定でポート 5005, suspend=y）で起動。
    -- 起動後、Java バッファで <F5> → "Attach to bootRun (5005)" で接続する。
    table.insert(ret, {
      name = "gradle bootRun (debug-jvm)",
      builder = function()
        return { cmd = { gradle_cmd() }, args = { "bootRun", "--debug-jvm" }, components = { "default" } }
      end,
    })
    -- 任意の Gradle タスクを入力して実行
    table.insert(ret, {
```

- [ ] **Step 2: tasks.lua が読み込めることを確認**

Run: `nvim --headless -c 'lua print("tasks:", pcall(require, "tasks"))' -c 'qa'`
Expected: `tasks: true`。

- [ ] **Step 3: Gradle プロジェクトでタスクが一覧に出ることを確認（手動）**

Gradle プロジェクトのディレクトリで `nvim` を起動し `<leader>or`（`:OverseerRun`）を実行。
Expected: 候補に `gradle bootRun (debug-jvm)` が表示される。

- [ ] **Step 4: コミット**

```bash
git add lua/tasks.lua
git commit -m "feat: add overseer gradle bootRun (debug-jvm) task

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 7: エンドツーエンド手動検証（実機 Spring Boot プロジェクト）

**Files:** なし（検証のみ・コミット不要）

- [ ] **Step 1: プラグイン/パッケージの導入確認**

`nvim` を起動し:
- `:Lazy` → `nvim-dap` / `nvim-dap-ui` / `nvim-dap-virtual-text` / `nvim-nio` が installed。
- `:Mason` → `java-debug-adapter` / `java-test` が installed。
Expected: すべて導入済み。

- [ ] **Step 2: JVM をデバッグ起動**

Spring Boot プロジェクトを開き `<leader>or` →「gradle bootRun (debug-jvm)」を選択。
Expected: overseer パネルでタスクが走り、`Listening for transport dt_socket at address: 5005` 相当のログ後にアプリ起動待ち（suspend=y）になる。

- [ ] **Step 3: attach してブレークポイントで停止**

任意のコントローラ/サービスのメソッド行で `<leader>db`（ブレークポイント設置、`●` が表示される）→ Java バッファで `<F5>` →「Attach to bootRun (5005)」を選択。
Expected: dap-ui が自動で開き、アプリが起動。該当エンドポイントへリクエストするとブレークポイントで停止し、`▶` 行と変数ペインが表示される。`<F10>/<F11>/<F12>` でステップ実行できる。

- [ ] **Step 4: テストのデバッグ実行**

任意の JUnit テストファイルを開き、テストメソッド内にブレークポイントを置き `<leader>dn`。
Expected: そのテストがデバッグ起動し、ブレークポイントで停止する。`<leader>dT` でテストクラス全体をデバッグ起動できる。

- [ ] **Step 5: which-key 確認**

ノーマルモードで `<leader>d` を押す。
Expected: 「debug (DAP)」グループ配下に `db`/`dB`/`dr`/`dt`/`du` と、Java バッファでは `dn`/`dT` が表示される。

---

## Self-Review

**Spec coverage（spec の各項目 → 対応タスク）:**
- Attach 運用 → Task 5（`dap.configurations.java` attach）、Task 6（bootRun --debug-jvm）、Task 7 Step 2–3
- フル UI（dap-ui + virtual-text）→ Task 1（宣言）、Task 3（setup・自動開閉）
- テストデバッグ（java-test）→ Task 2（ensure）、Task 5（bundles・`<leader>dn`/`<leader>dT`）
- overseer タスク → Task 6
- 案A の構成分離（dap-config コア / ftplugin 固有）→ Task 3 / Task 5
- mason-registry ensure（新規プラグイン不使用）→ Task 2
- which-key グループ → Task 4
- キーマップ表（汎用/Java 固有）→ Task 3 / Task 5
- 検証手順 → Task 7
- ギャップ: なし

**Placeholder scan:** TBD/TODO・「適切に」等の曖昧表現なし。全コードステップに実コードを記載。✓

**Type/名前整合:** `dap.configurations.java` / `dap.adapters.java`（`setup_dap()` が登録）、`jdtls.test_nearest_method()` / `jdtls.test_class()`、sign 名 `DapBreakpoint`/`DapStopped`、キー `<leader>d*`、overseer タスク名 `gradle bootRun (debug-jvm)` がタスク間で一致。✓
