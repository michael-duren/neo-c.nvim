local M = {}

-- Markers that indicate project root
local root_markers = {
  '.git',
  'CMakeLists.txt',
  'Makefile',
  'configure',
  '.hg',
  '.svn',
  'meson.build'
}

---Find project root by walking up directory tree looking for markers
---@param start_path? string # Starting directory path (defaults to current buffer's directory)
---@return string # Absolute path to project root (falls back to cwd)
function M.find_project_root(start_path)
  local path = start_path or vim.fn.expand('%:p:h')

  while path ~= '/' do
    for _, marker in ipairs(root_markers) do
      local marker_path = path .. '/' .. marker
      if vim.fn.isdirectory(marker_path) == 1 or
         vim.fn.filereadable(marker_path) == 1 then
        return path
      end
    end
    path = vim.fn.fnamemodify(path, ':h')
  end

  -- Fallback to cwd
  return vim.fn.getcwd()
end

---Get project name from path (extracts directory name)
---@param project_path string # Absolute path to project directory
---@return string # Name of the project (last component of path)
function M.get_project_name(project_path)
  return vim.fn.fnamemodify(project_path, ':t')
end

return M
