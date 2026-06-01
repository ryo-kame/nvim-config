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

-- npm / pnpm / yarn / cargo / make / just などは overseer 標準プロバイダが
-- ロックファイルから自動判定してタスク化するため、ここでは登録不要。
-- Gradle 用プロバイダだけ自前で登録する。

local gradle_tasks = { "build", "test", "run", "clean", "bootRun" }

-- generator 方式: build.gradle 等が見つかったときだけタスクを返す
-- （見つからなければメッセージ文字列を返し、テンプレート一覧から除外される）
overseer.register_template({
  name = "gradle",
  generator = function(opts, cb)
    local markers = { "build.gradle", "build.gradle.kts", "settings.gradle", "settings.gradle.kts", "gradlew" }
    local found = false
    for _, m in ipairs(markers) do
      if next(vim.fs.find(m, { upward = true, type = "file", path = opts.dir })) then
        found = true
        break
      end
    end
    if not found then
      cb("Not a Gradle project")
      return
    end

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
      name = "gradle <custom>",
      builder = function()
        local task = vim.fn.input("Gradle task: ")
        return { cmd = { gradle_cmd() }, args = { task }, components = { "default" } }
      end,
    })
    cb(ret)
  end,
})

local map = vim.keymap.set
map("n", "<leader>or", "<cmd>OverseerRun<CR>", { desc = "Gradle タスク実行" })
map("n", "<leader>ot", "<cmd>OverseerToggle<CR>", { desc = "タスクパネル(右)トグル" })
