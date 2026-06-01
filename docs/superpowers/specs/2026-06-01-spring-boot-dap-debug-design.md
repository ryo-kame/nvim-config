# Spring Boot ブレークポイントデバッグ（nvim-dap + jdtls）設計

- 日付: 2026-06-01
- 対象リポジトリ: `~/.config/nvim`（Neovim 設定）
- 目的: IntelliJ のデバッガ相当の体験（ブレークポイント・ステップ実行・変数ウォッチ）を Spring Boot プロジェクトで使えるようにする。

## 決定事項（ブレインストーミングでの合意）

| 項目 | 決定 |
|---|---|
| デバッグ運用 | **Attach**（`--debug-jvm` で待機する JVM に nvim-dap から接続）を軸にする |
| UI | **フル構成**（nvim-dap-ui + nvim-dap-virtual-text） |
| テストデバッグ | **含める**（vscode-java-test バンドルを jdtls に読み込む） |
| JVM 起動 | **overseer に `bootRun (debug-jvm)` タスクを追加**し `<leader>or` から起動 |
| 実装構成 | **案A**: 言語非依存の DAP コア（`lua/dap-config.lua`）＋ Java 固有配線（`ftplugin/java.lua`）を分離 |

設計方針は既存の「`lua/plugins/X.lua`（プラグイン宣言）＋ `lua/X.lua`（設定本体）」の分離パターン（lsp / git / tasks が該当）に合わせる。

## アーキテクチャ / コンポーネント

```
init.lua
 └─ require("dap-config")            ← 言語非依存の DAP コアを初期化

lua/plugins/dap.lua   (新規・宣言)
 ├─ mfussenegger/nvim-dap            ← DAP クライアント本体
 ├─ rcarriga/nvim-dap-ui             ← UI（依存: nvim-neotest/nvim-nio）
 └─ theHamsta/nvim-dap-virtual-text  ← 行末に変数値をインライン表示

lua/dap-config.lua    (新規・コア設定)
 ├─ dapui.setup() / nvim-dap-virtual-text.setup()
 ├─ ブレークポイント sign（●）と色（DapBreakpoint 等）の定義
 ├─ dap-ui の自動開閉（attach/launch 開始で open / 終了で close）
 └─ 汎用キーマップ（<F5> 等・<leader>d 系）

ftplugin/java.lua     (既存に追記)
 ├─ java-debug-adapter / java-test の jar を init_options.bundles に読込
 ├─ on_attach 内で jdtls.setup_dap()（"java" アダプタ & テスト構成を登録）
 ├─ dap.configurations.java =「Attach to bootRun (5005)」
 └─ Java 固有キーマップ（テストのデバッグ実行）

lua/lsp.lua           (既存に追記)
 └─ mason-registry で java-debug-adapter / java-test を ensure install
    （LSP サーバーではないため mason-lspconfig ではなく registry を直接利用）

lua/tasks.lua         (既存に追記)
 └─ overseer Gradle テンプレートに「bootRun (debug-jvm)」を追加

lua/plugins/whichkey.lua (既存に追記)
 └─ <leader>d グループ名「debug (DAP)」
```

### 重要な設計判断

- **jdtls がデバッグアダプタをバンドルとして内包する**ため、Java では mason-nvim-dap 等の外部アダプタ起動は不要。`require("jdtls").setup_dap()` が `dap.adapters.java` を登録する。
- mason への ensure install は**新規プラグインを足さず** `mason-registry` の薄いヘルパーで行う（このリポジトリの「小さな自前コードを好む」方針に合わせる。overseer の Gradle テンプレートや term_panel も自前実装）。
- `java-debug-adapter` / `java-test` は LSP サーバーではないので `mason-lspconfig.nvim` の `ensure_installed` には載らない。`mason-registry` の `refresh` → `get_package(...):install()` で導入する。

## デバッグのデータフロー（Attach 運用）

1. `<leader>or`（`:OverseerRun`）→「bootRun (debug-jvm)」を選択 → `./gradlew bootRun --debug-jvm` が起動。Gradle の `--debug-jvm` はポート **5005**・`suspend=y`（デバッガ接続まで待機）。
2. Java バッファで `<F5>`（`dap.continue`）→ filetype=java の構成一覧から「Attach to bootRun (5005)」を選択 → 127.0.0.1:5005 にアタッチ。アプリが走り出す。
3. dap-ui が自動で開く（変数 / コールスタック / ブレークポイント一覧 / REPL）。
4. `<leader>db` でブレークポイント設置 → 該当エンドポイントを叩くと停止、`<F10>/<F11>/<F12>` でステップ実行。
5. セッション終了で dap-ui が自動で閉じる。

### テストデバッグのフロー

テストファイルで `<leader>dn`（カーソル位置のテストメソッド）/ `<leader>dT`（テストクラス）→ jdtls がそのテストをデバッグ起動し、同様に停止できる。これらは `require("jdtls").test_nearest_method()` / `require("jdtls").test_class()` を呼ぶ（`setup_dap()` 後に利用可能）。

## キーマップ

### 汎用（`lua/dap-config.lua` / 全 filetype）

| キー | 動作 | 実装 |
|---|---|---|
| `<F5>` | 開始 / 継続 | `dap.continue` |
| `<F10>` | ステップオーバー | `dap.step_over` |
| `<F11>` | ステップイン | `dap.step_into` |
| `<F12>` | ステップアウト | `dap.step_out` |
| `<leader>db` | ブレークポイント切替 | `dap.toggle_breakpoint` |
| `<leader>dB` | 条件付きブレークポイント | `dap.set_breakpoint(vim.fn.input(...))` |
| `<leader>dr` | REPL を開く | `dap.repl.open` |
| `<leader>du` | dap-ui 表示切替 | `dapui.toggle` |
| `<leader>dt` | セッション終了 | `dap.terminate` |

### Java 固有（`ftplugin/java.lua` / buffer-local）

| キー | 動作 | 実装 |
|---|---|---|
| `<leader>dn` | カーソル位置のテストメソッドをデバッグ | `jdtls.test_nearest_method()` |
| `<leader>dT` | テストクラスをデバッグ | `jdtls.test_class()` |

`<leader>d` は既存マップと衝突しない（buffer 系は `<leader>bd` / `<leader>bo`、find 系は `<leader>f`、AI 系は `<leader>a`）。which-key に `<leader>d` グループを追加する。

## 主要な実装スニペット（方針確認用）

### jdtls bundles（ftplugin/java.lua）

```lua
local mason_pkgs = vim.fn.stdpath("data") .. "/mason/packages"
local bundles = {}
local debug_jar = vim.fn.glob(
  mason_pkgs .. "/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar", true)
if debug_jar ~= "" then
  table.insert(bundles, debug_jar)
end
vim.list_extend(
  bundles,
  vim.split(vim.fn.glob(mason_pkgs .. "/java-test/extension/server/*.jar", true), "\n"))
-- config.init_options.bundles = bundles
```

### setup_dap と attach 構成（on_attach 内）

```lua
require("jdtls").setup_dap({ hotcodereplace = "auto" })
local dap = require("dap")
dap.configurations.java = {
  {
    type = "java",
    request = "attach",
    name = "Attach to bootRun (5005)",
    hostName = "127.0.0.1",
    port = 5005,
  },
}
```

### mason ensure install（lua/lsp.lua）

```lua
local registry = require("mason-registry")
local function ensure(pkg)
  local ok, p = pcall(registry.get_package, pkg)
  if ok and not p:is_installed() then
    p:install()
  end
end
registry.refresh(function()
  ensure("java-debug-adapter")
  ensure("java-test")
end)
```

### overseer タスク（lua/tasks.lua）

既存の Gradle テンプレートの返り値リストに、専用引数のエントリを追加する。

```lua
table.insert(ret, {
  name = "gradle bootRun (debug-jvm)",
  builder = function()
    return { cmd = { gradle_cmd() }, args = { "bootRun", "--debug-jvm" }, components = { "default" } }
  end,
})
```

## エラーハンドリング / 既存方針との整合

- `lua/dap-config.lua` / `ftplugin/java.lua` 内の `require` は既存 `ftplugin/java.lua` 同様 `pcall` で保護し、未導入時は静かに return する。
- mason パッケージ未インストール時は bundles の glob が空になるだけで **jdtls の LSP 機能は壊れない**（graceful degradation）。`<F5>` でのアタッチ時にアダプタが無ければエラーになるが、ensure install により `:Lazy sync` 後の再起動で揃うため実運用では発生しない。
- `lazy-lock.json` は `:Lazy sync` が自動更新するため手編集しない。

## 検証（このリポジトリにテスト基盤は無いため手動）

1. `:Lazy sync` → `:Mason` で `java-debug-adapter` / `java-test` が installed であることを確認。
2. Spring Boot プロジェクトの Java ファイルで `:lua print(vim.inspect(require'dap'.configurations.java))` に attach 構成が出る。
3. 上記データフロー 1〜5 を実機確認（コントローラのメソッドにブレークポイント → エンドポイントを叩いて停止 → ステップ実行）。
4. テストファイルで `<leader>dn` がテストをデバッグ起動して停止する。
5. which-key で `<leader>d` グループと配下のマップが表示される。

## スコープ外（YAGNI）

- Launch 構成（nvim-dap がアプリ JVM を起動する方式）は今回作らない。Attach + overseer 起動で十分。
- Java 以外の言語（Python 等）の DAP 構成。ただし `lua/dap-config.lua` を言語非依存に保つことで将来の追加を容易にする。
- リモート（コンテナ / 別ホスト）への attach。必要になればポート / hostName を構成に足すだけで対応可能。
