-- MasonでLSPサーバーを管理
require("mason").setup()

require("mason-lspconfig").setup({
  ensure_installed = { "lua_ls", "ts_ls", "pyright" }
})

-- LSPサーバーの設定
local lspconfig = require("lspconfig")

-- Lua
lspconfig.lua_ls.setup({})

-- TypeScript / JavaScript
lspconfig.ts_ls.setup({  -- ✅ ts_ls → tsserver に修正
  on_attach = function(client, bufnr)
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = bufnr,
      callback = function()
        vim.lsp.buf.format({ async = false })
      end,
    })

    local opts = { buffer = bufnr }
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
  end,
})

-- Python
lspconfig.pyright.setup({})
