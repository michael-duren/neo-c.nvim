local storage = require('neo-c.storage')
local utils = require('neo-c.utils')
local executor = require('neo-c.executor')

local M = {}

-- Generate compile_commands.json
function M.generate_compile_commands()
  local project_path = utils.find_project_root()

  local config = storage.load_config(project_path)
  if not config then
    vim.notify('No configuration found. Run :CDetect first.', vim.log.levels.ERROR)
    return
  end

  local system = nil
  for _, s in ipairs(config.build_systems) do
    if s.type == config.selected_build_system then
      system = s
      break
    end
  end

  if not system then
    vim.notify('No build system selected', vim.log.levels.ERROR)
    return
  end

  if system.type == 'cmake' then
    M.generate_cmake_compile_commands(project_path, system)
  elseif system.type == 'make' then
    M.generate_make_compile_commands(project_path, system)
  else
    vim.notify('Compile commands generation not supported for ' .. system.type, vim.log.levels.WARN)
  end
end

-- CMake: Already includes -DCMAKE_EXPORT_COMPILE_COMMANDS=1 in configure
function M.generate_cmake_compile_commands(project_path, system)
  local compile_commands_src = project_path .. '/' .. (system.compile_commands_path or 'build/compile_commands.json')
  local compile_commands_dst = project_path .. '/compile_commands.json'

  -- Check if it exists
  if vim.fn.filereadable(compile_commands_src) == 0 then
    vim.notify('compile_commands.json not found. Run :CRunProject first to configure CMake.', vim.log.levels.WARN)
    return
  end

  -- Create symlink or copy
  local link_cmd = string.format('ln -sf %s %s', compile_commands_src, compile_commands_dst)
  vim.fn.system(link_cmd)

  if vim.v.shell_error == 0 then
    vim.notify('compile_commands.json linked successfully', vim.log.levels.INFO)
  else
    vim.notify('Failed to link compile_commands.json', vim.log.levels.ERROR)
  end
end

-- Make: Use Bear to generate compile_commands.json
function M.generate_make_compile_commands(project_path, system)
  -- Check if Bear is installed
  local bear_check = vim.fn.system('which bear')
  if vim.v.shell_error ~= 0 then
    vim.notify('Bear not installed. Install it to generate compile_commands.json for Make projects.', vim.log.levels.ERROR)
    return
  end

  vim.notify('Generating compile_commands.json with Bear...', vim.log.levels.INFO)

  -- Run bear -- make
  local bear_cmd = {
    command = 'bear',
    args = {'--', 'make'},
    cwd = project_path
  }

  executor.execute_async(bear_cmd, {
    on_stdout = function(data) print(data) end,
    on_stderr = function(data) print(data) end
  }, function(result)
    if result.code == 0 then
      vim.notify('compile_commands.json generated successfully', vim.log.levels.INFO)
    else
      vim.notify('Failed to generate compile_commands.json', vim.log.levels.ERROR)
    end
  end)
end

return M
