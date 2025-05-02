-- ~/.config/nvim/lua/lsp.lua

-- MasonでLSPサーバーを管理
require("mason").setup()

require("mason-lspconfig").setup({
  ensure_installed = { "lua_ls", "ts_ls", "pyright" } -- ts_lsではなく正しくは tsserver！
})

-- LSPサーバーの設定
local lspconfig = require("lspconfig")

-- Lua言語サーバー
lspconfig.lua_ls.setup({})

-- TypeScript言語サーバー
lspconfig.ts_ls.setup({
  on_attach = function(client, bufnr)
    -- 保存時に自動フォーマットする設定
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = bufnr,
      callback = function()
        vim.lsp.buf.format({ async = false })
      end,
    })

    -- 追加で基本的なLSPキーマップ（必要なら）
    local opts = { buffer = bufnr }
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
  end,
})

-- Python言語サーバー
lspconfig.pyright.setup({})

-- typescript-toolsを使う場合（別途）
-- ※普通はtsserverと被るので、どっちかにするのがオススメ
-- require("typescript-tools").setup({
--   on_attach = function(_, bufnr)
--     local opts = { buffer = bufnr }
--     vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
--     vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
--   end,
-- })
