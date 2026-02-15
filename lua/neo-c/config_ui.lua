local storage = require('neo-c.storage')
local utils = require('neo-c.utils')

local M = {}

-- Check if nui.nvim is available
local has_nui = pcall(require, 'nui.input')

-- Show configuration form
function M.show_config_form()
  local project_path = utils.find_project_root()

  local config = storage.load_config(project_path)
  if not config then
    vim.notify('No configuration found. Run :CDetect first.', vim.log.levels.ERROR)
    return
  end

  if has_nui then
    M.show_nui_config_form(config, project_path)
  else
    M.show_simple_config_form(config, project_path)
  end
end

-- Simple fallback config form without nui.nvim
function M.show_simple_config_form(config, project_path)
  print('Neo-C Configuration')
  print('─────────────────────')
  print('')
  print('[1] Set build system')
  print('[2] Set run command')
  print('[3] Set test command')
  print('[4] Set debug program')
  print('[5] Set debug adapter (gdb/codelldb)')
  print('[6] Set compiler flags')
  print('')
  print('[q] Quit')

  local choice = vim.fn.input('Enter choice: ')

  if choice == '1' then
    M.set_build_system_simple(config, project_path)
  elseif choice == '2' then
    M.set_run_command_simple(config, project_path)
  elseif choice == '3' then
    M.set_test_command_simple(config, project_path)
  elseif choice == '4' then
    M.set_debug_program_simple(config, project_path)
  elseif choice == '5' then
    M.set_debug_adapter_simple(config, project_path)
  elseif choice == '6' then
    M.set_compiler_flags_simple(config, project_path)
  end
end

-- NUI-based config form
function M.show_nui_config_form(config, project_path)
  local Popup = require('nui.popup')

  local menu_lines = {
    'Neo-C Configuration',
    '─────────────────────',
    '',
    '[1] Set build system',
    '[2] Set run command',
    '[3] Set test command',
    '[4] Set debug program',
    '[5] Set debug adapter (gdb/codelldb)',
    '[6] Set compiler flags',
    '',
    '[q] Quit',
  }

  local popup = Popup({
    position = '50%',
    size = {
      width = 50,
      height = #menu_lines + 2,
    },
    enter = true,
    focusable = true,
    border = {
      style = 'rounded',
      text = {
        top = ' CConfig ',
        top_align = 'center',
      },
    },
  })

  popup:mount()

  vim.api.nvim_buf_set_lines(popup.bufnr, 0, -1, false, menu_lines)
  vim.api.nvim_buf_set_option(popup.bufnr, 'modifiable', false)

  -- Handle selection
  popup:map('n', '1', function() popup:unmount(); M.set_build_system(config, project_path) end)
  popup:map('n', '2', function() popup:unmount(); M.set_run_command(config, project_path) end)
  popup:map('n', '3', function() popup:unmount(); M.set_test_command(config, project_path) end)
  popup:map('n', '4', function() popup:unmount(); M.set_debug_program(config, project_path) end)
  popup:map('n', '5', function() popup:unmount(); M.set_debug_adapter(config, project_path) end)
  popup:map('n', '6', function() popup:unmount(); M.set_compiler_flags(config, project_path) end)
  popup:map('n', 'q', function() popup:unmount() end)
  popup:map('n', '<Esc>', function() popup:unmount() end)
end

-- Simple fallback functions
function M.set_build_system_simple(config, project_path)
  if #config.build_systems == 0 then
    vim.notify('No build systems detected', vim.log.levels.WARN)
    return
  end

  for i, system in ipairs(config.build_systems) do
    print(string.format('[%d] %s', i, system.type))
  end

  local choice = tonumber(vim.fn.input('Select build system: '))
  if choice and choice >= 1 and choice <= #config.build_systems then
    config.selected_build_system = config.build_systems[choice].type
    storage.save_config(project_path, config)
    vim.notify('Build system set to: ' .. config.selected_build_system, vim.log.levels.INFO)
  else
    vim.notify('Invalid selection', vim.log.levels.ERROR)
  end
end

function M.set_run_command_simple(config, project_path)
  local current = config.custom_commands.run or ''
  local value = vim.fn.input('Run command: ', current)
  config.custom_commands.run = value
  storage.save_config(project_path, config)
  vim.notify('Run command updated', vim.log.levels.INFO)
end

function M.set_test_command_simple(config, project_path)
  local current = config.custom_commands.test or ''
  local value = vim.fn.input('Test command: ', current)
  config.custom_commands.test = value
  storage.save_config(project_path, config)
  vim.notify('Test command updated', vim.log.levels.INFO)
end

function M.set_debug_program_simple(config, project_path)
  config.debug_config = config.debug_config or {}
  local current = config.debug_config.program or ''
  local value = vim.fn.input('Debug program path: ', current, 'file')
  config.debug_config.program = value
  storage.save_config(project_path, config)
  vim.notify('Debug program updated', vim.log.levels.INFO)
end

function M.set_debug_adapter_simple(config, project_path)
  config.debug_config = config.debug_config or {}
  local current = config.debug_config.adapter or 'gdb'
  local value = vim.fn.input('Debug adapter (gdb/codelldb): ', current)
  if value == 'gdb' or value == 'codelldb' then
    config.debug_config.adapter = value
    storage.save_config(project_path, config)
    vim.notify('Debug adapter set to: ' .. value, vim.log.levels.INFO)
  else
    vim.notify('Invalid adapter. Use "gdb" or "codelldb"', vim.log.levels.ERROR)
  end
end

function M.set_compiler_flags_simple(config, project_path)
  local current = table.concat(config.compiler.cflags or {}, ' ')
  local value = vim.fn.input('Compiler flags (space-separated): ', current)
  config.compiler.cflags = vim.split(value, '%s+')
  storage.save_config(project_path, config)
  vim.notify('Compiler flags updated', vim.log.levels.INFO)
end

-- NUI-based functions
function M.set_build_system(config, project_path)
  if #config.build_systems == 0 then
    vim.notify('No build systems detected', vim.log.levels.WARN)
    return
  end

  local Input = require('nui.input')

  local options = {}
  for i, system in ipairs(config.build_systems) do
    table.insert(options, string.format('[%d] %s', i, system.type))
  end

  local current = config.selected_build_system or 'none'

  local input = Input({
    position = '50%',
    size = { width = 40 },
    border = {
      style = 'rounded',
      text = {
        top = string.format(' Select Build System (current: %s) ', current),
        top_align = 'center',
      },
    },
  }, {
    prompt = '> ',
    on_submit = function(value)
      local choice = tonumber(value)
      if choice and choice >= 1 and choice <= #config.build_systems then
        config.selected_build_system = config.build_systems[choice].type
        storage.save_config(project_path, config)
        vim.notify('Build system set to: ' .. config.selected_build_system, vim.log.levels.INFO)
      else
        vim.notify('Invalid selection', vim.log.levels.ERROR)
      end
    end,
  })

  input:mount()

  -- Show options in buffer
  local lines = table.concat(options, '\n')
  vim.api.nvim_buf_set_lines(input.bufnr, -2, -2, false, vim.split(lines, '\n'))
end

function M.set_run_command(config, project_path)
  local Input = require('nui.input')
  local current = config.custom_commands.run or ''

  local input = Input({
    position = '50%',
    size = { width = 60 },
    border = {
      style = 'rounded',
      text = {
        top = ' Run Command ',
        top_align = 'center',
      },
    },
  }, {
    prompt = '> ',
    default_value = current,
    on_submit = function(value)
      config.custom_commands.run = value
      storage.save_config(project_path, config)
      vim.notify('Run command updated', vim.log.levels.INFO)
    end,
  })

  input:mount()
end

function M.set_test_command(config, project_path)
  local Input = require('nui.input')
  local current = config.custom_commands.test or ''

  local input = Input({
    position = '50%',
    size = { width = 60 },
    border = {
      style = 'rounded',
      text = {
        top = ' Test Command ',
        top_align = 'center',
      },
    },
  }, {
    prompt = '> ',
    default_value = current,
    on_submit = function(value)
      config.custom_commands.test = value
      storage.save_config(project_path, config)
      vim.notify('Test command updated', vim.log.levels.INFO)
    end,
  })

  input:mount()
end

function M.set_debug_program(config, project_path)
  local Input = require('nui.input')
  config.debug_config = config.debug_config or {}
  local current = config.debug_config.program or ''

  local input = Input({
    position = '50%',
    size = { width = 60 },
    border = {
      style = 'rounded',
      text = {
        top = ' Debug Program Path ',
        top_align = 'center',
      },
    },
  }, {
    prompt = '> ',
    default_value = current,
    on_submit = function(value)
      config.debug_config.program = value
      storage.save_config(project_path, config)
      vim.notify('Debug program updated', vim.log.levels.INFO)
    end,
  })

  input:mount()
end

function M.set_debug_adapter(config, project_path)
  local Input = require('nui.input')
  config.debug_config = config.debug_config or {}
  local current = config.debug_config.adapter or 'gdb'

  local input = Input({
    position = '50%',
    size = { width = 40 },
    border = {
      style = 'rounded',
      text = {
        top = string.format(' Debug Adapter (current: %s) ', current),
        top_align = 'center',
      },
    },
  }, {
    prompt = '> ',
    default_value = current,
    on_submit = function(value)
      if value == 'gdb' or value == 'codelldb' then
        config.debug_config.adapter = value
        storage.save_config(project_path, config)
        vim.notify('Debug adapter set to: ' .. value, vim.log.levels.INFO)
      else
        vim.notify('Invalid adapter. Use "gdb" or "codelldb"', vim.log.levels.ERROR)
      end
    end,
  })

  input:mount()

  vim.api.nvim_buf_set_lines(input.bufnr, -2, -2, false, {
    'Options: gdb, codelldb'
  })
end

function M.set_compiler_flags(config, project_path)
  local Input = require('nui.input')
  local current = table.concat(config.compiler.cflags or {}, ' ')

  local input = Input({
    position = '50%',
    size = { width = 60 },
    border = {
      style = 'rounded',
      text = {
        top = ' Compiler Flags (space-separated) ',
        top_align = 'center',
      },
    },
  }, {
    prompt = '> ',
    default_value = current,
    on_submit = function(value)
      config.compiler.cflags = vim.split(value, '%s+')
      storage.save_config(project_path, config)
      vim.notify('Compiler flags updated', vim.log.levels.INFO)
    end,
  })

  input:mount()
end

return M
