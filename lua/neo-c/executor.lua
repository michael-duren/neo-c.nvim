local M = {}

-- Execute command asynchronously with output capture
function M.execute_async(cmd, opts, on_complete)
  opts = opts or {}
  local stdout_data = {}
  local stderr_data = {}

  local stdout = vim.loop.new_pipe(false)
  local stderr = vim.loop.new_pipe(false)

  local handle, pid
  handle, pid = vim.loop.spawn(cmd.command, {
    args = cmd.args,
    cwd = cmd.cwd or vim.fn.getcwd(),
    stdio = {nil, stdout, stderr}
  }, vim.schedule_wrap(function(code, signal)
    stdout:close()
    stderr:close()
    handle:close()

    if on_complete then
      on_complete({
        code = code,
        signal = signal,
        stdout = table.concat(stdout_data),
        stderr = table.concat(stderr_data)
      })
    end
  end))

  if not handle then
    vim.notify('Failed to spawn command: ' .. cmd.command, vim.log.levels.ERROR)
    return
  end

  stdout:read_start(function(err, data)
    if err then
      vim.notify('stdout error: ' .. err, vim.log.levels.ERROR)
    elseif data then
      table.insert(stdout_data, data)
      if opts.on_stdout then
        vim.schedule(function() opts.on_stdout(data) end)
      end
    end
  end)

  stderr:read_start(function(err, data)
    if err then
      vim.notify('stderr error: ' .. err, vim.log.levels.ERROR)
    elseif data then
      table.insert(stderr_data, data)
      if opts.on_stderr then
        vim.schedule(function() opts.on_stderr(data) end)
      end
    end
  end)
end

-- Execute command synchronously (for simple cases)
function M.execute_sync(cmd)
  local full_cmd = cmd.command
  if cmd.args and #cmd.args > 0 then
    full_cmd = full_cmd .. ' ' .. table.concat(cmd.args, ' ')
  end

  local output = vim.fn.system(full_cmd)
  local code = vim.v.shell_error

  return {
    code = code,
    output = output
  }
end

return M
