-- Test helper utilities
local M = {}

-- Create a temporary directory for testing
function M.create_temp_dir()
  local temp_dir = vim.fn.tempname()
  vim.fn.mkdir(temp_dir, 'p')
  return temp_dir
end

-- Clean up temporary directory
function M.cleanup_temp_dir(dir)
  if dir and vim.fn.isdirectory(dir) == 1 then
    vim.fn.delete(dir, 'rf')
  end
end

-- Create a test file with content
function M.create_test_file(path, content)
  local dir = vim.fn.fnamemodify(path, ':h')
  vim.fn.mkdir(dir, 'p')

  local file = io.open(path, 'w')
  if file then
    file:write(content)
    file:close()
    return true
  end
  return false
end

-- Read file content
function M.read_file(path)
  local file = io.open(path, 'r')
  if not file then return nil end

  local content = file:read('*all')
  file:close()
  return content
end

-- Create a mock CMake project structure
function M.create_cmake_project(root_path)
  vim.fn.mkdir(root_path, 'p')

  local cmake_content = [[
cmake_minimum_required(VERSION 3.10)
project(TestProject)

add_executable(main src/main.c)

enable_testing()
add_test(NAME test_main COMMAND main)
]]

  M.create_test_file(root_path .. '/CMakeLists.txt', cmake_content)
  M.create_test_file(root_path .. '/src/main.c', '#include <stdio.h>\nint main() { return 0; }\n')
  M.create_test_file(root_path .. '/.git/config', '') -- Make it a git repo

  return root_path
end

-- Create a mock Makefile project structure
function M.create_makefile_project(root_path)
  vim.fn.mkdir(root_path, 'p')

  local makefile_content = [[
CC = gcc
CFLAGS = -Wall -Wextra

all: main

main: src/main.o
	$(CC) -o bin/main src/main.o

clean:
	rm -f src/*.o bin/main

test:
	./bin/main

install:
	cp bin/main /usr/local/bin/
]]

  M.create_test_file(root_path .. '/Makefile', makefile_content)
  M.create_test_file(root_path .. '/src/main.c', '#include <stdio.h>\nint main() { return 0; }\n')
  M.create_test_file(root_path .. '/.git/config', '')

  return root_path
end

-- Create a project with both CMake and Makefile
function M.create_multi_build_project(root_path)
  M.create_cmake_project(root_path)

  local makefile_content = [[
all: build
	@echo "Building with make"

build:
	gcc src/main.c -o bin/main

clean:
	rm -f bin/main
]]

  M.create_test_file(root_path .. '/Makefile', makefile_content)

  return root_path
end

-- Assert table equality (deep comparison)
function M.assert_table_eq(actual, expected, path)
  path = path or 'root'

  if type(actual) ~= type(expected) then
    error(string.format('%s: type mismatch - expected %s, got %s',
      path, type(expected), type(actual)))
  end

  if type(actual) ~= 'table' then
    if actual ~= expected then
      error(string.format('%s: value mismatch - expected %s, got %s',
        path, tostring(expected), tostring(actual)))
    end
    return
  end

  -- Check all keys in expected exist in actual
  for k, v in pairs(expected) do
    if actual[k] == nil then
      error(string.format('%s.%s: missing key', path, tostring(k)))
    end
    M.assert_table_eq(actual[k], v, path .. '.' .. tostring(k))
  end
end

-- Mock vim.notify for testing
function M.mock_vim_notify()
  local notifications = {}
  local original_notify = vim.notify

  vim.notify = function(msg, level)
    table.insert(notifications, {
      msg = msg,
      level = level or vim.log.levels.INFO
    })
  end

  return {
    notifications = notifications,
    restore = function()
      vim.notify = original_notify
    end,
    get_last = function()
      return notifications[#notifications]
    end,
    clear = function()
      notifications = {}
    end
  }
end

return M
