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
