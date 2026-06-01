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
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "定義へジャンプ" }))
    vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "ホバー情報を表示" }))
  end,
})

-- lua_ls / pyright は nvim-lspconfig が lsp/<name>.lua で提供するデフォルト設定を使用
