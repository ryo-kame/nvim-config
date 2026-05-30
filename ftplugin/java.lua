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
