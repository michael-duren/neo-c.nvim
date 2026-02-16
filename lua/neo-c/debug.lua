local storage = require('neo-c.storage')
local utils = require('neo-c.utils')

local M = {}

---Configure nvim-dap for C debugging and start a debug session
---@return nil
function M.setup_debug()
  local project_path = utils.find_project_root()

  local config = storage.load_config(project_path)
  if not config then
    vim.notify('No configuration found. Run :CDetect first.', vim.log.levels.ERROR)
    return
  end

  -- Get debug config or create default
  local debug_config = config.debug_config or {}

  -- Determine program path
  local program = debug_config.program
  if not program then
    -- Try to infer from custom_commands.run
    if config.custom_commands.run then
      program = config.custom_commands.run:match('^%.?/?(.-)[%s$]') or config.custom_commands.run
    else
      -- Prompt user
      program = vim.fn.input('Path to executable: ', project_path .. '/', 'file')
    end
  end

  -- Load dap
  local ok, dap = pcall(require, 'dap')
  if not ok then
    vim.notify('nvim-dap not installed. Install it first.', vim.log.levels.ERROR)
    return
  end

  -- Configure GDB adapter (default)
  local adapter = debug_config.adapter or 'gdb'

  if adapter == 'gdb' then
    dap.adapters.gdb = {
      id = 'gdb',
      type = 'executable',
      command = 'gdb',
      args = { '--quiet', '--interpreter=dap' }
    }
  elseif adapter == 'codelldb' then
    dap.adapters.codelldb = {
      type = 'server',
      port = '${port}',
      executable = {
        command = 'codelldb',
        args = { '--port', '${port}' }
      }
    }
  end

  -- Configure C debug configuration
  dap.configurations.c = {
    {
      name = 'Launch',
      type = adapter,
      request = 'launch',
      program = program,
      cwd = debug_config.cwd or project_path,
      args = debug_config.args or {},
      stopAtBeginningOfMainSubprogram = false,
    }
  }

  -- Save debug config
  config.debug_config = {
    adapter = adapter,
    program = program,
    args = debug_config.args or {},
    cwd = debug_config.cwd or project_path
  }
  storage.save_config(project_path, config)

  -- Start debugging
  dap.continue()
end

return M
