local storage = require("neo-c.storage")
local schema = require("neo-c.schema")
local utils = require("neo-c.utils")

local M = {}

---@class NeoCBuildSystemDetector
---@field type "cmake"|"make" # Type of build system
---@field file string # File to look for (CMakeLists.txt, Makefile, etc.)
---@field priority number # Detection priority (lower = higher priority)
---@field detect fun(project_path: string): NeoCBuildSystem|nil # Detection function

---Build system definitions with detection patterns
---@type NeoCBuildSystemDetector[]
local build_systems = {
	{
		type = "cmake",
		file = "CMakeLists.txt",
		priority = 1, -- Highest priority
		detect = function(project_path)
			local cmake_file = project_path .. "/CMakeLists.txt"
			if vim.fn.filereadable(cmake_file) == 0 then
				return nil
			end

			return {
				type = "cmake",
				detected = true,
				file = "CMakeLists.txt",
				build_dir = "build",
				commands = {
					configure = "cmake -B build -S . -DCMAKE_EXPORT_COMPILE_COMMANDS=1",
					build = "cmake --build build",
					clean = "cmake --build build --target clean",
					test = "ctest --test-dir build --output-on-failure",
					install = "cmake --install build",
				},
				targets = M.get_cmake_targets(project_path),
				compile_commands_path = "build/compile_commands.json",
			}
		end,
	},
	{
		type = "make",
		file = "Makefile",
		priority = 2,
		detect = function(project_path)
			local makefile = project_path .. "/Makefile"
			if vim.fn.filereadable(makefile) == 0 then
				return nil
			end

			return {
				type = "make",
				detected = true,
				file = "Makefile",
				commands = {
					build = "make",
					clean = "make clean",
					test = "make test",
					install = "make install",
				},
				targets = M.get_make_targets(project_path),
			}
		end,
	},
}

---Extract CMake targets (basic implementation)
---@param project_path string # Absolute path to project root
---@return string[] # List of available CMake targets
function M.get_cmake_targets(project_path)
	-- Default CMake targets
	-- TODO: Parse CMakeLists.txt or run cmake --build build --target help
	return { "all", "clean", "test", "install" }
end

---Extract Make targets from Makefile by parsing target definitions
---@param project_path string # Absolute path to project root
---@return string[] # List of available Make targets
function M.get_make_targets(project_path)
	local makefile_path = project_path .. "/Makefile"
	local targets = {}

	local file = io.open(makefile_path, "r")
	if not file then
		return { "all", "clean" }
	end

	for line in file:lines() do
		-- Match target definitions (simplified regex)
		local target = line:match("^([%w_-]+):%s")
		if target and not target:match("^%.") then -- Exclude .PHONY, etc.
			table.insert(targets, target)
		end
	end

	file:close()

	if #targets == 0 then
		return { "all", "clean" }
	end

	return targets
end

---Detect all build systems in project directory
---@param project_path string # Absolute path to project root
---@return NeoCBuildSystem[] # Array of detected build systems, sorted by priority
function M.detect_all(project_path)
	local detected = {}

	for _, system in ipairs(build_systems) do
		local result = system.detect(project_path)
		if result then
			table.insert(detected, result)
		end
	end

	-- Sort by priority
	table.sort(detected, function(a, b)
		local a_priority = 0
		local b_priority = 0

		for _, sys in ipairs(build_systems) do
			if sys.type == a.type then
				a_priority = sys.priority
			end
			if sys.type == b.type then
				b_priority = sys.priority
			end
		end

		return a_priority < b_priority
	end)

	return detected
end

---Main CDetect command implementation - detects build systems and saves configuration
---@return nil
function M.detect_build_system()
	local project_path = utils.find_project_root()
	local project_name = utils.get_project_name(project_path)

	vim.notify("Detecting build systems in: " .. project_path, vim.log.levels.INFO)

	-- Detect all build systems
	local detected = M.detect_all(project_path)

	if #detected == 0 then
		vim.notify("No build systems detected", vim.log.levels.WARN)
		return
	end

	-- Load or create config
	local config = storage.load_config(project_path)
	if not config then
		config = schema.new_config(project_path, project_name)
	end

	-- Update build systems
	config.build_systems = detected

	-- Select default build system if not already set
	if not config.selected_build_system and #detected > 0 then
		config.selected_build_system = detected[1].type
	end

	-- Update detection timestamp
	config.detected_at = os.date("!%Y-%m-%dT%H:%M:%SZ")

	-- Save config
	if storage.save_config(project_path, config) then
		local systems_str = table.concat(
			vim.tbl_map(function(s)
				return s.type
			end, detected),
			", "
		)
		vim.notify(
			string.format("Detected: %s | Selected: %s", systems_str, config.selected_build_system),
			vim.log.levels.INFO
		)
	else
		vim.notify("Failed to save configuration", vim.log.levels.ERROR)
	end
end

return M
