-- JSON Configuration Schema for Build Systems
--
-- Example configuration:
-- {
--   "version": "1.0",
--   "project_path": "/home/user/my-project",
--   "project_name": "my-project",
--   "detected_at": "2026-02-15T10:30:00Z",
--   "build_systems": [
--     {
--       "type": "cmake",
--       "detected": true,
--       "file": "CMakeLists.txt",
--       "build_dir": "build",
--       "commands": {
--         "configure": "cmake -B build -S .",
--         "build": "cmake --build build",
--         "clean": "cmake --build build --target clean",
--         "test": "ctest --test-dir build",
--         "install": "cmake --install build"
--       },
--       "targets": ["all", "clean", "test"],
--       "compile_commands_path": "build/compile_commands.json"
--     },
--     {
--       "type": "make",
--       "detected": true,
--       "file": "Makefile",
--       "commands": {
--         "build": "make",
--         "clean": "make clean",
--         "test": "make test"
--       },
--       "targets": ["all", "clean", "test", "install"]
--     }
--   ],
--   "selected_build_system": "cmake",
--   "custom_commands": {
--     "run": "./build/my-project",
--     "debug": "gdb ./build/my-project"
--   },
--   "compiler": {
--     "cc": "gcc",
--     "cxx": "g++",
--     "cflags": ["-Wall", "-Wextra", "-std=c11"],
--     "cxxflags": ["-Wall", "-Wextra", "-std=c++17"]
--   },
--   "test_framework": {
--     "type": "ctest",
--     "command": "ctest --test-dir build --output-on-failure"
--   },
--   "debug_config": {
--     "adapter": "gdb",
--     "program": "./build/my-project",
--     "args": [],
--     "cwd": "${workspaceFolder}"
--   }
-- }

local M = {}

---Create a new empty configuration with default values
---@param project_path string # Absolute path to project root
---@param project_name string # Name of the project
---@return NeoCConfig # New configuration table with defaults
function M.new_config(project_path, project_name)
  return {
    version = "1.0",
    project_path = project_path,
    project_name = project_name,
    detected_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    build_systems = {},
    selected_build_system = nil,
    custom_commands = {},
    compiler = {
      cc = "gcc",
      cxx = "g++",
      cflags = {"-Wall", "-Wextra", "-std=c11"},
      cxxflags = {"-Wall", "-Wextra", "-std=c++17"}
    },
    test_framework = nil,
    debug_config = nil
  }
end

return M
