local executor = require("neo-c.executor")

local M = {}

---Quick compile and run current C file buffer
---@return nil
function M.run_current_buffer()
	local current_file = vim.fn.expand("%:p")

	-- Check if current file is a C file
	if not current_file:match("%.c$") then
		vim.notify("Current file is not a C file", vim.log.levels.ERROR)
		return
	end

	-- Check if file exists
	if vim.fn.filereadable(current_file) == 0 then
		vim.notify("Current file does not exist", vim.log.levels.ERROR)
		return
	end

	-- Get config from main module
	--- @type NeoCQuickCompilerConfig
	local config = require("neo-c").config.compiler
	local output_dir = config.output_dir
	local output_file = output_dir .. "/a.out"

	-- Ensure output directory exists
	vim.fn.mkdir(output_dir, "p")

	vim.notify("Compiling " .. vim.fn.expand("%:t") .. "...", vim.log.levels.INFO)

	-- Compile the file with configured compiler and flags
	local compile_args = vim.deepcopy(config.flags)
	table.insert(compile_args, current_file)
	table.insert(compile_args, "-o")
	table.insert(compile_args, output_file)

	local compile_cmd = {
		command = config.executable,
		args = compile_args,
	}

	executor.execute_async(compile_cmd, {}, function(result)
		if result.code ~= 0 then
			vim.notify("Compilation failed", vim.log.levels.ERROR)
			-- Populate quickfix with errors
			vim.fn.setqflist({}, "r", {
				title = "Compilation Errors",
				lines = vim.split(result.stderr, "\n"),
			})
			vim.cmd("copen")
			return
		end

		vim.notify("Compilation succeeded! Running...", vim.log.levels.INFO)

		-- Prompt for program arguments
		vim.ui.input({
			prompt = "Program arguments (leave empty for none): ",
			default = "",
		}, function(args)
			-- User cancelled
			if args == nil then
				return
			end

			-- Build command with arguments
			local run_command = output_file
			if args and args ~= "" then
				run_command = run_command .. " " .. args
			end

			-- Run the compiled program in a terminal
			vim.cmd("split | terminal " .. run_command)
			vim.cmd("startinsert")
		end)
	end)
end

return M
