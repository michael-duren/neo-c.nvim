local storage = require('neo-c.storage')
local utils = require('neo-c.utils')
local executor = require('neo-c.executor')

local M = {}

-- Parse command string
local function parse_command(cmd_str)
  local parts = vim.split(cmd_str, '%s+')
  return {
    command = parts[1],
    args = vim.list_slice(parts, 2)
  }
end

-- Get selected build system
local function get_selected_build_system(config)
  for _, system in ipairs(config.build_systems) do
    if system.type == config.selected_build_system then
      return system
    end
  end
  return nil
end

-- Run tests
function M.run_tests()
  local project_path = utils.find_project_root()

  local config = storage.load_config(project_path)
  if not config then
    vim.notify('No configuration found. Run :CDetect first.', vim.log.levels.ERROR)
    return
  end

  local system = get_selected_build_system(config)
  if not system then
    vim.notify('No build system selected', vim.log.levels.ERROR)
    return
  end

  -- Get test command
  local test_cmd_str = config.custom_commands.test or system.commands.test

  if not test_cmd_str then
    vim.notify('No test command available for ' .. system.type, vim.log.levels.WARN)
    return
  end

  vim.notify('Running tests with ' .. system.type .. '...', vim.log.levels.INFO)

  local test_cmd = parse_command(test_cmd_str)
  test_cmd.cwd = project_path

  executor.execute_async(test_cmd, {
    on_stdout = function(data) print(data) end,
    on_stderr = function(data) print(data) end
  }, function(result)
    if result.code == 0 then
      vim.notify('All tests passed!', vim.log.levels.INFO)
    else
      vim.notify('Tests failed with exit code ' .. result.code, vim.log.levels.ERROR)

      -- Populate quickfix
      local output = result.stdout .. result.stderr
      vim.fn.setqflist({}, 'r', {
        title = 'Test Results',
        lines = vim.split(output, '\n')
      })
      vim.cmd('copen')
    end
  end)
end

return M
