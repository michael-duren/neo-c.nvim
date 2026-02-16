---@class NeoCBuildSystemCommands
---@field configure? string # Command to configure build system
---@field build string # Command to build project
---@field clean string # Command to clean build artifacts
---@field test string # Command to run tests
---@field install string # Command to install built artifacts

---@class NeoCBuildSystem
---@field type "cmake"|"make" # Type of build system
---@field detected boolean # Whether this build system was auto-detected
---@field file string # Path to build system file (CMakeLists.txt, Makefile, etc.)
---@field build_dir? string # Build directory path (typically for CMake)
---@field commands NeoCBuildSystemCommands # Commands for this build system
---@field targets string[] # Available build targets
---@field compile_commands_path? string # Path to compile_commands.json

---@class NeoCCompilerConfig
---@field cc string # C compiler (e.g., "gcc", "clang")
---@field cxx string # C++ compiler (e.g., "g++", "clang++")
---@field cflags string[] # C compiler flags
---@field cxxflags string[] # C++ compiler flags

---@class NeoCTestFramework
---@field type string # Test framework type (e.g., "ctest", "custom")
---@field command string # Command to run tests

---@class NeoCDebugConfig
---@field adapter string # Debug adapter name (e.g., "gdb", "lldb", "codelldb")
---@field program string # Path to executable to debug
---@field args? string[] # Arguments to pass to program
---@field cwd? string # Working directory for debugging

---@class NeoCCustomCommands
---@field run? string # Custom run command
---@field test? string # Custom test command
---@field debug? string # Custom debug command

---@class NeoCConfig
---@field version string # Config schema version
---@field project_path string # Absolute path to project root
---@field project_name string # Name of the project
---@field detected_at string # ISO8601 timestamp of detection
---@field build_systems NeoCBuildSystem[] # Detected build systems
---@field selected_build_system? string # Currently selected build system type
---@field custom_commands NeoCCustomCommands # User-defined custom commands
---@field compiler NeoCCompilerConfig # Compiler configuration
---@field test_framework? NeoCTestFramework # Test framework configuration
---@field debug_config? NeoCDebugConfig # Debug configuration

local M = {}

---Get storage directory path
---@return string # Path to neo-c storage directory
function M.get_storage_dir()
  local data_path = vim.fn.stdpath('data')
  return data_path .. '/neo-c/projects'
end

---Generate unique project ID from path using SHA256
---@param project_path string # Absolute path to project directory
---@return string # SHA256 hash of the project path
function M.get_project_id(project_path)
  return vim.fn.sha256(project_path)
end

---Get config file path for a project
---@param project_path string # Absolute path to project directory
---@return string # Full path to JSON config file
function M.get_config_path(project_path)
  local storage_dir = M.get_storage_dir()
  local project_id = M.get_project_id(project_path)
  return storage_dir .. '/' .. project_id .. '.json'
end

---Ensure storage directory exists, creating it if necessary
---@return nil
function M.ensure_storage_dir()
  local dir = M.get_storage_dir()
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, 'p')
  end
end

---Load project configuration from storage
---@param project_path string # Absolute path to project directory
---@return NeoCConfig|nil # Parsed configuration table, or nil if not found/invalid
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

---Save project configuration to storage
---@param project_path string # Absolute path to project directory
---@param config NeoCConfig # Configuration table to save
---@return boolean # True if save succeeded, false otherwise
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

---Delete project configuration file
---@param project_path string # Absolute path to project directory
---@return nil
function M.delete_config(project_path)
  local config_path = M.get_config_path(project_path)
  if vim.fn.filereadable(config_path) == 1 then
    vim.fn.delete(config_path)
  end
end

return M
