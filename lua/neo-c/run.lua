local storage = require('neo-c.storage')
local utils = require('neo-c.utils')
local executor = require('neo-c.executor')

local M = {}

---@class NeoCRunOptions
---@field run? boolean # Whether to run the program after building

---Parse command string into command + args
---@param cmd_str string # Command string to parse
---@return NeoCCommand # Parsed command with args
local function parse_command(cmd_str)
  local parts = vim.split(cmd_str, '%s+')
  return {
    command = parts[1],
    args = vim.list_slice(parts, 2)
  }
end

---Get selected build system config from configuration
---@param config NeoCConfig # Project configuration
---@return NeoCBuildSystem|nil # Selected build system or nil if not found
local function get_selected_build_system(config)
  if not config.selected_build_system then
    return nil
  end

  for _, system in ipairs(config.build_systems) do
    if system.type == config.selected_build_system then
      return system
    end
  end

  return nil
end

---Run build command for the project
---@param project_path string # Absolute path to project root
---@param config NeoCConfig # Project configuration
---@param on_complete? fun(result: NeoCExecutionResult) # Callback when build completes
---@return nil
function M.build_project(project_path, config, on_complete)
  local system = get_selected_build_system(config)

  if not system then
    vim.notify('No build system selected', vim.log.levels.ERROR)
    return
  end

  vim.notify('Building with ' .. system.type .. '...', vim.log.levels.INFO)

  -- Handle CMake configure step first
  if system.type == 'cmake' then
    local configure_cmd = parse_command(system.commands.configure)
    configure_cmd.cwd = project_path

    executor.execute_async(configure_cmd, {
      on_stdout = function(data) print(data) end,
      on_stderr = function(data) print(data) end
    }, function(result)
      if result.code ~= 0 then
        vim.notify('CMake configure failed', vim.log.levels.ERROR)
        vim.cmd('copen')  -- Open quickfix with errors
        return
      end

      -- Now run build
      local build_cmd = parse_command(system.commands.build)
      build_cmd.cwd = project_path

      executor.execute_async(build_cmd, {
        on_stdout = function(data) print(data) end,
        on_stderr = function(data) print(data) end
      }, on_complete)
    end)
  else
    -- Make or other build systems
    local build_cmd = parse_command(system.commands.build)
    build_cmd.cwd = project_path

    executor.execute_async(build_cmd, {
      on_stdout = function(data) print(data) end,
      on_stderr = function(data) print(data) end
    }, on_complete)
  end
end

---Run the built program in a terminal split
---@param project_path string # Absolute path to project root
---@param config NeoCConfig # Project configuration with run command
---@return nil
function M.run_program(project_path, config)
  local run_cmd = config.custom_commands.run

  if not run_cmd then
    vim.notify('No run command configured. Use :CConfig to set one.', vim.log.levels.WARN)
    return
  end

  -- Execute in terminal
  local cmd = string.format('cd %s && %s', project_path, run_cmd)
  vim.cmd('split | terminal ' .. cmd)
  vim.cmd('startinsert')
end

---Main CRunProject implementation - builds and optionally runs the project
---@param opts? NeoCRunOptions # Run options (e.g., whether to run after building)
---@return nil
function M.run_project(opts)
  opts = opts or {}
  local project_path = utils.find_project_root()

  -- Load config
  local config = storage.load_config(project_path)
  if not config then
    vim.notify('No configuration found. Run :CDetect first.', vim.log.levels.ERROR)
    return
  end

  -- Check if multiple build systems and no selection
  if #config.build_systems > 1 and not config.selected_build_system then
    M.prompt_build_system_selection(config, project_path, opts)
    return
  end

  -- Build the project
  M.build_project(project_path, config, function(result)
    if result.code ~= 0 then
      vim.notify('Build failed with exit code ' .. result.code, vim.log.levels.ERROR)
      -- Populate quickfix with errors
      vim.fn.setqflist({}, 'r', {
        title = 'Build Errors',
        lines = vim.split(result.stderr, '\n')
      })
      vim.cmd('copen')
      return
    end

    vim.notify('Build succeeded!', vim.log.levels.INFO)

    -- Run if requested
    if opts.run then
      M.run_program(project_path, config)
    end
  end)
end

---Prompt user to select build system (for multi-build projects)
---@param config NeoCConfig # Project configuration
---@param project_path string # Absolute path to project root
---@param opts? NeoCRunOptions # Run options to pass through after selection
---@return nil
function M.prompt_build_system_selection(config, project_path, opts)
  -- Check if nui.nvim is available
  local has_nui, _ = pcall(require, 'nui.input')
  if not has_nui then
    -- Fallback to simple vim.fn.input
    vim.notify('Multiple build systems detected. Please select one:', vim.log.levels.INFO)
    for i, system in ipairs(config.build_systems) do
      print(string.format('[%d] %s', i, system.type))
    end
    local choice = tonumber(vim.fn.input('Enter number: '))

    if choice and choice >= 1 and choice <= #config.build_systems then
      config.selected_build_system = config.build_systems[choice].type
      storage.save_config(project_path, config)
      vim.notify('Selected: ' .. config.selected_build_system, vim.log.levels.INFO)
      M.run_project(opts)
    else
      vim.notify('Invalid selection', vim.log.levels.ERROR)
    end
    return
  end

  local Input = require('nui.input')
  local Popup = require('nui.popup')

  -- Build options string
  local options_str = ''
  for i, system in ipairs(config.build_systems) do
    options_str = options_str .. string.format('[%d] %s\n', i, system.type)
  end

  local popup = Popup({
    position = '50%',
    size = {
      width = 40,
      height = #config.build_systems + 4,
    },
    enter = true,
    border = {
      style = 'rounded',
      text = {
        top = ' Select Build System ',
        top_align = 'center',
      },
    },
  })

  popup:mount()

  -- Set content
  vim.api.nvim_buf_set_lines(popup.bufnr, 0, -1, false,
    vim.split(options_str .. '\nEnter number:', '\n'))

  local input = Input({
    position = {
      row = #config.build_systems + 2,
      col = 0,
    },
    size = { width = 5 },
    border = { style = 'none' },
  }, {
    prompt = '> ',
    on_submit = function(value)
      popup:unmount()

      local choice = tonumber(value)
      if not choice or choice < 1 or choice > #config.build_systems then
        vim.notify('Invalid selection', vim.log.levels.ERROR)
        return
      end

      -- Remember choice
      config.selected_build_system = config.build_systems[choice].type
      storage.save_config(project_path, config)

      vim.notify('Selected: ' .. config.selected_build_system, vim.log.levels.INFO)

      -- Retry run with selection
      M.run_project(opts)
    end,
  })

  input:mount()
end

return M
