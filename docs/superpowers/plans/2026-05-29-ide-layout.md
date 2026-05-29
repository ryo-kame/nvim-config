# IDE レイアウト (IntelliJ 風) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Neovim を IntelliJ 風の IDE レイアウト（左ツリー・下ターミナル・右 Gradle・Git 差分表示・catppuccin 統一・Java LSP）にする。

**Architecture:** lazy.nvim ベースの既存設定に、新規プラグイン spec を `lua/plugins/` に、設定本体を `lua/`（と `ftplugin/`）に追加し `init.lua` から require する。既存の nvim-tree（左）/ toggleterm（下）はそのまま活かす。

**Tech Stack:** lazy.nvim, catppuccin, gitsigns.nvim, diffview.nvim, nvim-jdtls, overseer.nvim, mason

---

## 検証コマンドについて

設定リポジトリのため自動テストは無い。各タスクでは「設定を編集 → ヘッドレス起動でエラーが出ないことを確認 → コミット」を1サイクルとする。

ヘッドレス検証コマンド（設定をロードして即終了。Lua エラーがあれば stderr に出る）:

```bash
nvim --headless "+qa" 2>&1 | head -40
```

期待: 何も出力されない（エラーが無い）。プラグイン未取得の場合は次のタスクの `Lazy! sync` 後に再確認する。

---

## Task 1: 新規プラグイン spec を追加して取得する

**Files:**
- Create: `lua/plugins/git.lua`
- Create: `lua/plugins/java.lua`
- Create: `lua/plugins/tasks.lua`

- [ ] **Step 1: gitsigns / diffview の spec を作成**

`lua/plugins/git.lua`:

```lua
-- ~/.config/nvim/lua/plugins/git.lua
return {
  { "lewis6991/gitsigns.nvim" },
  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
  },
}
```

- [ ] **Step 2: nvim-jdtls の spec を作成**

`lua/plugins/java.lua`:

```lua
-- ~/.config/nvim/lua/plugins/java.lua
return {
  { "mfussenegger/nvim-jdtls" },
}
```

- [ ] **Step 3: overseer の spec を作成**

`lua/plugins/tasks.lua`:

```lua
-- ~/.config/nvim/lua/plugins/tasks.lua
return {
  { "stevearc/overseer.nvim" },
}
```

- [ ] **Step 4: プラグインを取得する**

Run:

```bash
nvim --headless "+Lazy! sync" "+qa" 2>&1 | tail -20
```

Expected: gitsigns.nvim / diffview.nvim / nvim-jdtls / overseer.nvim が installed と表示され、エラーで終了しない。

- [ ] **Step 5: ロード確認**

Run:

```bash
nvim --headless "+lua print(pcall(require,'gitsigns'), pcall(require,'diffview'), pcall(require,'overseer'), pcall(require,'jdtls'))" "+qa" 2>&1 | head
```

Expected: `true true true true`（4つとも require 成功）。

- [ ] **Step 6: コミット**

```bash
git add lua/plugins/git.lua lua/plugins/java.lua lua/plugins/tasks.lua lazy-lock.json
git commit -m "feat: add gitsigns, diffview, nvim-jdtls, overseer plugin specs"
```

---

## Task 2: テーマを catppuccin に統一する

**Files:**
- Modify: `lua/plugins/ui.lua`
- Modify: `init.lua`（tokyonight ブロック削除）
- Modify: `lua/plugins/lualine.lua`（theme 変更）

- [ ] **Step 1: ui.lua を catppuccin 設定に書き換える**

`lua/plugins/ui.lua` を以下で全置換（tokyonight spec を catppuccin に差し替え）:

```lua
-- ~/.config/nvim/lua/plugins/ui.lua

return {
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" }, -- ファイルアイコン
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha",
        transparent_background = true,
        integrations = {
          nvimtree = true,
          treesitter = true,
          telescope = { enabled = true },
          native_lsp = { enabled = true },
          gitsigns = true,
          cmp = true,
          bufferline = true,
          mason = true,
        },
      })
      vim.cmd.colorscheme("catppuccin")
    end,
  },
}
```

- [ ] **Step 2: init.lua から tokyonight の setup と colorscheme を削除**

`init.lua` の以下のブロックを削除する:

```lua
-- カラースキーム設定（tokyonight + 透過）
require("tokyonight").setup({
  style = "night",
  transparent = true,
  styles = {
    sidebars = "transparent",
    floats = "transparent",
  },
})
vim.cmd([[colorscheme tokyonight]])
```

（直後の `vim.api.nvim_set_hl(0, "@lsp.typemod.unused", ...)` 行は残す。catppuccin の colorscheme は ui.lua の config で適用済みのため、init.lua 側での colorscheme 指定は不要。）

- [ ] **Step 3: lualine の theme を catppuccin に変更**

`lua/plugins/lualine.lua` の以下を変更:

変更前:
```lua
        theme = "tokyonight", -- 好きなテーマに変えてね
```
変更後:
```lua
        theme = "catppuccin", -- 好きなテーマに変えてね
```

- [ ] **Step 4: 起動エラーが無いことを確認**

Run:

```bash
nvim --headless "+qa" 2>&1 | head -40
```

Expected: エラー出力なし。

- [ ] **Step 5: colorscheme が catppuccin になっていることを確認**

Run:

```bash
nvim --headless "+lua print(vim.g.colors_name)" "+qa" 2>&1 | head
```

Expected: `catppuccin`。

- [ ] **Step 6: コミット**

```bash
git add lua/plugins/ui.lua init.lua lua/plugins/lualine.lua
git commit -m "feat: unify theme to catppuccin (mocha)"
```

---

## Task 3: Git 差分表示 (gitsigns + diffview) を設定する

**Files:**
- Create: `lua/git.lua`
- Modify: `init.lua`（require 追加）

- [ ] **Step 1: gitsigns / diffview の設定とキーマップを作成**

`lua/git.lua`:

```lua
-- ~/.config/nvim/lua/git.lua

local gitsigns = require("gitsigns")

gitsigns.setup({
  signs = {
    add = { text = "+" },
    change = { text = "~" },
    delete = { text = "_" },
    topdelete = { text = "‾" },
    changedelete = { text = "~" },
  },
  current_line_blame = false,
})

require("diffview").setup({})

local map = vim.keymap.set
map("n", "<leader>gh", function() gitsigns.nav_hunk("next") end, { desc = "次の変更へ移動" })
map("n", "<leader>gH", function() gitsigns.nav_hunk("prev") end, { desc = "前の変更へ移動" })
map("n", "<leader>gp", gitsigns.preview_hunk, { desc = "変更をプレビュー" })
map("n", "<leader>gb", function() gitsigns.blame_line({ full = true }) end, { desc = "行 blame" })
map("n", "<leader>gd", "<cmd>DiffviewOpen<CR>", { desc = "差分ビューを開く" })
map("n", "<leader>gc", "<cmd>DiffviewClose<CR>", { desc = "差分ビューを閉じる" })
```

- [ ] **Step 2: init.lua から require する**

`init.lua` の既存の require 群（`require("telescope-config")` の直後）に追加:

変更前:
```lua
require("telescope-config")
```
変更後:
```lua
require("telescope-config")
require("git")
```

- [ ] **Step 3: 起動エラーが無いことを確認**

Run:

```bash
nvim --headless "+qa" 2>&1 | head -40
```

Expected: エラー出力なし。

- [ ] **Step 4: gitsigns / diffview コマンドが存在することを確認**

Run:

```bash
nvim --headless "+lua print(vim.fn.exists(':DiffviewOpen'), pcall(require,'gitsigns'))" "+qa" 2>&1 | head
```

Expected: `2 true`（`:DiffviewOpen` が定義済み = 2、gitsigns require 成功 = true）。

- [ ] **Step 5: コミット**

```bash
git add lua/git.lua init.lua
git commit -m "feat: add git diff display (gitsigns + diffview)"
```

---

## Task 4: Gradle タスクパネル (overseer) を設定する

**Files:**
- Create: `lua/tasks.lua`
- Modify: `init.lua`（require 追加）

- [ ] **Step 1: overseer の設定・Gradle テンプレート・キーマップを作成**

`lua/tasks.lua`:

```lua
-- ~/.config/nvim/lua/tasks.lua

local overseer = require("overseer")

overseer.setup({
  task_list = {
    direction = "right",
    min_width = 40,
  },
})

-- ./gradlew があればそれを、無ければ gradle を使う
local function gradle_cmd()
  if vim.fn.filereadable("./gradlew") == 1 then
    return "./gradlew"
  end
  return "gradle"
end

local gradle_tasks = { "build", "test", "run", "clean", "bootRun" }
for _, task in ipairs(gradle_tasks) do
  overseer.register_template({
    name = "gradle " .. task,
    builder = function()
      return {
        cmd = { gradle_cmd() },
        args = { task },
        components = { "default" },
      }
    end,
  })
end

-- 任意の Gradle タスクを入力して実行
overseer.register_template({
  name = "gradle <custom>",
  builder = function()
    local task = vim.fn.input("Gradle task: ")
    return {
      cmd = { gradle_cmd() },
      args = { task },
      components = { "default" },
    }
  end,
})

local map = vim.keymap.set
map("n", "<leader>or", "<cmd>OverseerRun<CR>", { desc = "Gradle タスク実行" })
map("n", "<leader>ot", "<cmd>OverseerToggle<CR>", { desc = "タスクパネル(右)トグル" })
```

- [ ] **Step 2: init.lua から require する**

`init.lua` の require 群（前タスクで追加した `require("git")` の直後）に追加:

変更前:
```lua
require("git")
```
変更後:
```lua
require("git")
require("tasks")
```

- [ ] **Step 3: 起動エラーが無いことを確認**

Run:

```bash
nvim --headless "+qa" 2>&1 | head -40
```

Expected: エラー出力なし。

- [ ] **Step 4: overseer コマンドが存在することを確認**

Run:

```bash
nvim --headless "+lua print(vim.fn.exists(':OverseerRun'), vim.fn.exists(':OverseerToggle'))" "+qa" 2>&1 | head
```

Expected: `2 2`（両コマンドとも定義済み）。

- [ ] **Step 5: コミット**

```bash
git add lua/tasks.lua init.lua
git commit -m "feat: add Gradle task panel (overseer)"
```

---

## Task 5: Java LSP (jdtls) を設定する

**Files:**
- Create: `ftplugin/java.lua`
- Modify: `lua/lsp.lua`（mason に jdtls を追加、自動 enable から除外）

- [ ] **Step 1: mason に jdtls を追加し、自動 enable から除外する**

`lua/lsp.lua` の以下を変更:

変更前:
```lua
require("mason-lspconfig").setup({
  ensure_installed = { "lua_ls", "ts_ls", "pyright" },
  -- automatic_enable (default true) が ensure_installed を自動で vim.lsp.enable() する
})
```
変更後:
```lua
require("mason-lspconfig").setup({
  ensure_installed = { "lua_ls", "ts_ls", "pyright", "jdtls" },
  -- jdtls は nvim-jdtls 側で起動するため自動 enable から除外する
  automatic_enable = { exclude = { "jdtls" } },
})
```

- [ ] **Step 2: jdtls を mason 経由でインストールする**

Run:

```bash
nvim --headless "+MasonInstall jdtls" "+qa" 2>&1 | tail -10
```

Expected: jdtls のインストールが完了する（既にあれば「already installed」）。

- [ ] **Step 3: jdtls 起動設定を作成**

`ftplugin/java.lua`（java ファイルを開くと自動実行される）:

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

-- 補完用 capabilities（cmp-nvim-lsp があれば利用）
local capabilities = vim.lsp.protocol.make_client_capabilities()
local cmp_ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
if cmp_ok then
  capabilities = cmp_lsp.default_capabilities(capabilities)
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
    "--add-modules=ALL-SYSTEM",
    "--add-opens", "java.base/java.util=ALL-UNNAMED",
    "--add-opens", "java.base/java.lang=ALL-UNNAMED",
    "-jar", launcher_jar,
    "-configuration", mason_path .. "/config_mac",
    "-data", workspace_dir,
  },
  root_dir = root_dir,
  capabilities = capabilities,
  settings = { java = {} },
  init_options = { bundles = {} },
  on_attach = function(client, bufnr)
    local opts = { buffer = bufnr }
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
  end,
}

jdtls.start_or_attach(config)
```

- [ ] **Step 4: 起動エラーが無いことを確認（通常起動）**

Run:

```bash
nvim --headless "+qa" 2>&1 | head -40
```

Expected: エラー出力なし。

- [ ] **Step 5: java ファイルで jdtls 設定が読み込めることを確認（構文エラーが無いこと）**

Run:

```bash
nvim --headless "+lua loadfile(vim.fn.stdpath('config')..'/ftplugin/java.lua')" "+qa" 2>&1 | head
```

Expected: エラー出力なし（loadfile が構文エラーを出さない）。

> 注: 実際の jdtls 起動には JDK 17 以上が必要。未導入の場合は `brew install openjdk@17` を実行する。Java 補完の動作確認は Task 7 の手動検証で行う。

- [ ] **Step 6: コミット**

```bash
git add ftplugin/java.lua lua/lsp.lua
git commit -m "feat: add Java LSP via nvim-jdtls"
```

---

## Task 6: IDE レイアウト一括起動を追加する

**Files:**
- Create: `lua/ide.lua`
- Modify: `init.lua`（require 追加）

- [ ] **Step 1: IDE レイアウト起動関数とキーマップを作成**

`lua/ide.lua`:

```lua
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
```

- [ ] **Step 2: init.lua から require する**

`init.lua` の require 群（前タスクの `require("tasks")` の直後）に追加:

変更前:
```lua
require("tasks")
```
変更後:
```lua
require("tasks")
require("ide")
```

- [ ] **Step 3: 起動エラーが無いことを確認**

Run:

```bash
nvim --headless "+qa" 2>&1 | head -40
```

Expected: エラー出力なし。

- [ ] **Step 4: `<leader>ui` キーマップが登録されていることを確認**

Run:

```bash
nvim --headless "+lua print(vim.fn.maparg(',ui', 'n') ~= '')" "+qa" 2>&1 | head
```

Expected: `true`（leader=`,` なので `,ui` にマップ登録済み）。

- [ ] **Step 5: コミット**

```bash
git add lua/ide.lua init.lua
git commit -m "feat: add IDE layout launcher keymap"
```

---

## Task 7: 全体の手動検証

設定リポジトリのため、最終確認は実際の `nvim` 起動で行う。以下を順に確認する。

- [ ] **Step 1: クリーン起動**

`nvim` を起動し、`:messages` でエラーが無いこと、`:checkhealth` で致命的な問題が無いことを確認。

- [ ] **Step 2: 見た目（catppuccin）**

tree / bufferline / telescope（`<C-p>`）の配色が catppuccin で統一されていること。

- [ ] **Step 3: Git 差分**

変更のあるファイルを開き、行横に変更マーカー（+/~/_）が出ること。`<leader>gd` で diffview が開き、`<leader>gc` で閉じること。`<leader>gp` で hunk プレビューが出ること。

- [ ] **Step 4: Gradle（Gradle プロジェクトで）**

`<leader>or` で `gradle build` 等が選択でき、`<leader>ot` で右パネルに出力が表示されること。

- [ ] **Step 5: Java（JDK 17+ 導入済みの場合）**

java ファイルを開いて jdtls が起動し、`gd`（定義ジャンプ）・`K`（hover）・補完が効くこと。`:LspInfo` で jdtls が attach していること。

- [ ] **Step 6: IDE レイアウト**

`<leader>ui` で「左 tree ＋ 右 overseer ＋ 下 terminal」が一括で開くこと。

- [ ] **Step 7: 最終コミット（必要なら）**

手動検証で微修正が出た場合のみコミットする。

```bash
git add -A
git commit -m "fix: adjust IDE layout config after manual verification"
```
