# Neovim を IntelliJ 風 IDE レイアウトにする — 設計

- 日付: 2026-05-29
- 対象: `~/.config/nvim`（lazy.nvim ベースの設定）

## 目的

IntelliJ のような IDE 体験を Neovim 上で実現する。具体的な要件は以下の4つ。

1. 左側にファイルエクスプローラ
2. 下側にターミナルを表示できる
3. 右側に Gradle を表示する
4. 未コミットの差分を表示できる

## 現状

すでに導入済みで、要件①②は実質的に満たしている。

- `nvim-tree`（左側ファイルツリー、`<C-n>` トグル） … 要件①
- `toggleterm`（下側ターミナル、`Ctrl+\` トグル） … 要件②
- その他: bufferline / lualine / tokyonight・catppuccin / LSP(ts_ls, lua_ls, pyright) / telescope / treesitter / trouble / nvim-cmp / nvim-autopairs / typescript-tools

ユーザーの利用方針:
- Java を本格的に書く → jdtls（Java LSP）と Gradle 連携が必要
- 未コミット差分は「行マーカー」と「差分ビュー」の両方を使う
- テーマは catppuccin に統一する

## 追加するプラグイン

| プラグイン | 役割 | 対応要件 |
|-----------|------|---------|
| `catppuccin/nvim` | テーマ統一（mocha）。各プラグインの integration を有効化 | 全体（見た目） |
| `lewis6991/gitsigns.nvim` | 行横の変更マーカー(+/~/-)、hunk プレビュー/移動、blame | ④ |
| `sindrets/diffview.nvim` | IntelliJ 風の左右差分ビュー・変更ファイル一覧 | ④ |
| `mfussenegger/nvim-jdtls` | Java LSP(jdtls) をプロジェクト単位で起動 | ③(Java) |
| `stevearc/overseer.nvim` | Gradle タスクを右パネルで一覧・実行・出力表示 | ③(Gradle) |

既存の nvim-tree（左）・toggleterm（下）はそのまま活かす。

## ファイル構成（既存パターンに合わせる）

新規プラグインは `lua/plugins/` 配下に spec ファイルとして追加し、設定本体は `lua/` 配下に置いて `init.lua` から require する。

```
lua/plugins/git.lua    ← gitsigns, diffview の spec
lua/plugins/java.lua   ← nvim-jdtls の spec
lua/plugins/tasks.lua  ← overseer の spec
lua/plugins/ui.lua     ← catppuccin を追加（既存ファイルに追記）
lua/git.lua            ← gitsigns/diffview の設定＋キーマップ
lua/tasks.lua          ← overseer 設定＋Gradle タスク定義＋キーマップ
lua/ide.lua            ← IDE レイアウト一括起動キーマップ
ftplugin/java.lua      ← jdtls 起動設定（java ファイルを開くと自動起動）
init.lua               ← colorscheme→catppuccin、require 追加、jdtls を mason に追加
lua/plugins/lualine.lua← theme="catppuccin" に変更
```

## コンポーネント設計

### 1. テーマ統一（catppuccin）

- `catppuccin/nvim`（mocha）を `lazy=false, priority=1000` で導入。
- `integrations` で nvim-tree / bufferline / telescope / treesitter / gitsigns / native_lsp などを有効化。
- 既存の透過設定（transparent）は維持する（`transparent_background = true`）。
- `init.lua` の `colorscheme tokyonight` を `colorscheme catppuccin` に変更。tokyonight の setup 呼び出しは削除する（プラグイン自体は lazy-lock に残るが参照しない）。
- `lualine` の `theme` を `"catppuccin"` に変更。

### 2. Git 差分（gitsigns + diffview）

- `gitsigns.nvim`: 変更マーカー、hunk 移動/プレビュー、行 blame を設定。
- `diffview.nvim`: `:DiffviewOpen` で作業ツリーと HEAD の差分を左右比較。`:DiffviewClose` で閉じる。
- どちらも catppuccin integration に含める。

### 3. Java（nvim-jdtls）

- `nvim-jdtls` を導入し、`ftplugin/java.lua` で java バッファを開いたときに jdtls を起動。
- jdtls 本体は mason 経由で導入（`init.lua` の `mason-lspconfig` の `ensure_installed` に `jdtls` を追加。ただし jdtls の起動は nvim-jdtls 側で行うため、mason-lspconfig の自動 enable 対象からは外す方針＝起動の二重化を避ける）。
- ワークスペースはプロジェクトごとに `vim.fn.stdpath("cache") .. "/jdtls/" .. プロジェクト名` に分離。
- root 検出マーカー: `gradlew`, `mvnw`, `.git`, `settings.gradle`, `build.gradle` など。
- 前提: **JDK 17 以上**が必要。

### 4. Gradle タスク（overseer）

- `overseer.nvim` を導入。タスクリストパネルはデフォルトで右側に開く。
- Gradle 用のカスタムテンプレートを定義: `build`, `test`, `run`, `clean`, `bootRun`、および任意タスク入力。
  - 実行コマンドは `./gradlew <task>`（`gradlew` が無ければ `gradle`）。
  - cwd はプロジェクトルート。
- `<leader>or` でテンプレート選択実行、`<leader>ot` で右パネルのトグル。

### 5. IDE レイアウト一括起動（lua/ide.lua）

- `<leader>ui` で「左 nvim-tree ＋ 右 overseer ＋ 下 toggleterm」を一括で開くキーマップを定義。

## キーマップ一覧（leader = `,`）

| キー | 動作 |
|------|------|
| `<C-n>` | ファイルツリー（既存） |
| `Ctrl+\` | ターミナル（既存） |
| `<leader>ui` | IDE レイアウト一括起動 |
| `<leader>or` | Gradle タスク実行（テンプレート選択） |
| `<leader>ot` | Gradle タスクパネル（右）トグル |
| `<leader>gd` | diffview を開く |
| `<leader>gc` | diffview を閉じる |
| `<leader>gh` | 次の hunk へ移動（gitsigns） |
| `<leader>gH` | 前の hunk へ移動（gitsigns） |
| `<leader>gp` | hunk プレビュー（gitsigns） |
| `<leader>gb` | 行 blame 表示（gitsigns） |

## 完成レイアウト

```
┌──────────┬────────────────────────┬──────────┐
│ nvim-tree│   bufferline             │ overseer │
│ (左)      ├────────────────────────┤ Gradle   │
│ +gitsigns│   コード編集 +変更マーカー │ tasks(右)│
│          ├────────────────────────┴──────────┤
│          │   toggleterm (下)                   │
└──────────┴───────────────────────────────────┘
           lualine (catppuccin)
```

## 前提・注意点

- jdtls には **JDK 17 以上**が必要（例: `brew install openjdk@17`）。未インストールなら Java のみ動かない可能性がある。
- catppuccin 統一に伴い未使用の tokyonight 参照を整理する。透過設定は維持する。
- 既存の `lua/plugins/init.lua` と個別 spec ファイルに重複定義（nvim-tree 等）があるが、lazy がリポジトリ名で名寄せするため動作に影響しない。今回は大きなリファクタはせず、新規追加に留める。

## テスト/検証方針

設定変更のため自動テストは無い。以下を手動で検証する。

1. `nvim` 起動時にエラーが出ない（`:messages`, `:checkhealth`）。
2. lazy がプラグインを正しく取得する（`:Lazy`）。
3. catppuccin が適用され、tree/bufferline/telescope の見た目が統一される。
4. gitsigns の変更マーカーが表示され、`<leader>gd` で diffview が開く。
5. `<leader>or` で Gradle タスクが選べ、右パネルに出力が出る（Gradle プロジェクトで確認）。
6. java ファイルを開くと jdtls が起動し補完・定義ジャンプが効く（JDK 導入済みの場合）。
7. `<leader>ui` で IDE レイアウトが一括起動する。
```
