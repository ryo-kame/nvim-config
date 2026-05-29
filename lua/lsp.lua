-- MasonでLSPサーバーを管理
require("mason").setup()

require("mason-lspconfig").setup({
  ensure_installed = { "lua_ls", "ts_ls", "pyright", "jdtls" },
  -- jdtls は nvim-jdtls 側で起動するため自動 enable から除外する
  automatic_enable = { exclude = { "jdtls" } },
})

-- TypeScript / JavaScript のカスタム on_attach
vim.lsp.config("ts_ls", {
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

-- lua_ls / pyright は nvim-lspconfig が lsp/<name>.lua で提供するデフォルト設定を使用
