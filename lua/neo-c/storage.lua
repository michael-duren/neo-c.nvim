local M = {}

-- Get storage directory path
function M.get_storage_dir()
  local data_path = vim.fn.stdpath('data')
  return data_path .. '/neo-c/projects'
end

-- Generate unique project ID from path
function M.get_project_id(project_path)
  return vim.fn.sha256(project_path)
end

-- Get config file path for a project
function M.get_config_path(project_path)
  local storage_dir = M.get_storage_dir()
  local project_id = M.get_project_id(project_path)
  return storage_dir .. '/' .. project_id .. '.json'
end

-- Ensure storage directory exists
function M.ensure_storage_dir()
  local dir = M.get_storage_dir()
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, 'p')
  end
end

-- Load project configuration
function M.load_config(project_path)
  local config_path = M.get_config_path(project_path)

  if vim.fn.filereadable(config_path) == 0 then
    return nil
  end

  local file = io.open(config_path, 'r')
  if not file then return nil end

  local content = file:read('*all')
  file:close()

  local ok, config = pcall(vim.json.decode, content)
  if not ok then
    vim.notify('Failed to parse config: ' .. config_path, vim.log.levels.ERROR)
    return nil
  end

  return config
end

-- Save project configuration
function M.save_config(project_path, config)
  M.ensure_storage_dir()

  local config_path = M.get_config_path(project_path)
  local ok, json_str = pcall(vim.json.encode, config)

  if not ok then
    vim.notify('Failed to encode config', vim.log.levels.ERROR)
    return false
  end

  local file = io.open(config_path, 'w')
  if not file then
    vim.notify('Failed to write config: ' .. config_path, vim.log.levels.ERROR)
    return false
  end

  file:write(json_str)
  file:close()

  return true
end

-- Delete project configuration
function M.delete_config(project_path)
  local config_path = M.get_config_path(project_path)
  if vim.fn.filereadable(config_path) == 1 then
    vim.fn.delete(config_path)
  end
end

return M
