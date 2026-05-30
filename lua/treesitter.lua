-- ~/.config/nvim/lua/treesitter.lua
--
-- nvim-treesitter は main ブランチ（Neovim 0.12+ 対応）を使用。
-- main では旧 `require("nvim-treesitter.configs").setup{}` API は廃止され、
-- パーサのインストールは install()、ハイライトは vim.treesitter.start() で行う。

-- インストールするパーサ（ファイルタイプ名ではなくパーサ名で指定）
local parsers = {
  "lua",
  "vim",
  "vimdoc",
  "typescript",
  "tsx",
  "javascript",
  "python",
  "json",
  "html",
  "css",
}

-- main API が利用可能か確認する。別マシンなどで lazy.nvim がまだ旧 master ブランチを
-- チェックアウトしたままだと install() が存在せず、起動時に落ちてしまう。その場合は
-- 静かに諦め、ユーザーに :Lazy sync を促す（main へ切替＆再起動すれば有効になる）。
local ok, nvim_treesitter = pcall(require, "nvim-treesitter")
if not ok or type(nvim_treesitter.install) ~= "function" then
  vim.schedule(function()
    vim.notify(
      "nvim-treesitter: main ブランチが未適用です。`:Lazy sync` 実行後に Neovim を再起動してください。",
      vim.log.levels.WARN
    )
  end)
  return
end

-- 未インストールのパーサだけ非同期で取得する（:TSUpdate / :TSInstall でも可）
nvim_treesitter.install(parsers)

-- ファイルを開くたびに、パーサが利用可能ならハイライト＆インデントを有効化。
-- パーサが無いファイルタイプでは pcall でそっと失敗させる（旧 highlight.enable=true 相当）。
vim.api.nvim_create_autocmd("FileType", {
  callback = function(ev)
    if pcall(vim.treesitter.start, ev.buf) then
      -- 旧 indent.enable=true 相当（main の indentexpr は experimental）
      vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})
