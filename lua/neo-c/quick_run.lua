local executor = require('neo-c.executor')

local M = {}

-- Quick compile and run current buffer
function M.run_current_buffer()
  local current_file = vim.fn.expand('%:p')

  -- Check if current file is a C file
  if not current_file:match('%.c$') then
    vim.notify('Current file is not a C file', vim.log.levels.ERROR)
    return
  end

  -- Check if file exists
  if vim.fn.filereadable(current_file) == 0 then
    vim.notify('Current file does not exist', vim.log.levels.ERROR)
    return
  end

  local output_dir = '/tmp/makec'
  local output_file = output_dir .. '/a.out'

  -- Ensure output directory exists
  vim.fn.mkdir(output_dir, 'p')

  vim.notify('Compiling ' .. vim.fn.expand('%:t') .. '...', vim.log.levels.INFO)

  -- Compile the file
  local compile_cmd = {
    command = 'gcc',
    args = {'-Wall', '-Wextra', '-std=c11', current_file, '-o', output_file},
  }

  executor.execute_async(compile_cmd, {
    on_stdout = function(data) print(data) end,
    on_stderr = function(data) print(data) end
  }, function(result)
    if result.code ~= 0 then
      vim.notify('Compilation failed', vim.log.levels.ERROR)
      -- Populate quickfix with errors
      vim.fn.setqflist({}, 'r', {
        title = 'Compilation Errors',
        lines = vim.split(result.stderr, '\n')
      })
      vim.cmd('copen')
      return
    end

    vim.notify('Compilation succeeded! Running...', vim.log.levels.INFO)

    -- Run the compiled program in a terminal
    vim.cmd('split | terminal ' .. output_file)
    vim.cmd('startinsert')
  end)
end

return M
