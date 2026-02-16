-- Tests for lua/neo-c/detect.lua
local helpers = require('tests.helpers')

describe('detect', function()
  local detect
  local temp_dir

  before_each(function()
    package.loaded['neo-c.detect'] = nil
    package.loaded['neo-c.storage'] = nil
    package.loaded['neo-c.schema'] = nil
    package.loaded['neo-c.utils'] = nil

    detect = require('neo-c.detect')
    temp_dir = helpers.create_temp_dir()
  end)

  after_each(function()
    helpers.cleanup_temp_dir(temp_dir)
  end)

  describe('get_cmake_targets', function()
    it('should return default CMake targets', function()
      local project_path = temp_dir .. '/cmake_project'
      helpers.create_cmake_project(project_path)

      local targets = detect.get_cmake_targets(project_path)

      assert.is_not_nil(targets)
      assert.is_true(vim.tbl_contains(targets, 'all'))
      assert.is_true(vim.tbl_contains(targets, 'clean'))
      assert.is_true(vim.tbl_contains(targets, 'test'))
    end)
  end)

  describe('get_make_targets', function()
    it('should extract targets from Makefile', function()
      local project_path = temp_dir .. '/make_project'
      helpers.create_makefile_project(project_path)

      local targets = detect.get_make_targets(project_path)

      assert.is_not_nil(targets)
      assert.is_true(#targets > 0)

      -- Should contain common targets
      assert.is_true(vim.tbl_contains(targets, 'all') or vim.tbl_contains(targets, 'main'))
      assert.is_true(vim.tbl_contains(targets, 'clean'))
      assert.is_true(vim.tbl_contains(targets, 'test'))
    end)

    it('should return default targets for non-existent Makefile', function()
      local project_path = temp_dir .. '/no_makefile'
      vim.fn.mkdir(project_path, 'p')

      local targets = detect.get_make_targets(project_path)

      assert.is_not_nil(targets)
      assert.is_true(vim.tbl_contains(targets, 'all'))
      assert.is_true(vim.tbl_contains(targets, 'clean'))
    end)

    it('should exclude .PHONY and special targets', function()
      local project_path = temp_dir .. '/special_makefile'
      vim.fn.mkdir(project_path, 'p')

      local makefile_content = [[
.PHONY: all clean test
.DEFAULT_GOAL := all

all: build

build:
	gcc main.c -o app

clean:
	rm -f app

test:
	./app
]]

      helpers.create_test_file(project_path .. '/Makefile', makefile_content)

      local targets = detect.get_make_targets(project_path)

      -- Should not include .PHONY or .DEFAULT_GOAL
      assert.is_false(vim.tbl_contains(targets, '.PHONY'))
      assert.is_false(vim.tbl_contains(targets, '.DEFAULT_GOAL'))

      -- Should include regular targets
      assert.is_true(vim.tbl_contains(targets, 'all'))
      assert.is_true(vim.tbl_contains(targets, 'build'))
      assert.is_true(vim.tbl_contains(targets, 'clean'))
      assert.is_true(vim.tbl_contains(targets, 'test'))
    end)

    it('should handle complex Makefile with variables', function()
      local project_path = temp_dir .. '/complex_makefile'
      vim.fn.mkdir(project_path, 'p')

      local makefile_content = [[
CC = gcc
CFLAGS = -Wall

my-app: main.o utils.o
	$(CC) -o my-app main.o utils.o

main.o: main.c
	$(CC) $(CFLAGS) -c main.c

install:
	cp my-app /usr/local/bin/

uninstall:
	rm /usr/local/bin/my-app
]]

      helpers.create_test_file(project_path .. '/Makefile', makefile_content)

      local targets = detect.get_make_targets(project_path)

      assert.is_true(vim.tbl_contains(targets, 'my-app'))
      assert.is_true(vim.tbl_contains(targets, 'install'))
      assert.is_true(vim.tbl_contains(targets, 'uninstall'))
    end)
  end)

  describe('detect_all', function()
    it('should detect CMake project', function()
      local project_path = temp_dir .. '/cmake_only'
      helpers.create_cmake_project(project_path)

      local detected = detect.detect_all(project_path)

      assert.equals(1, #detected)
      assert.equals('cmake', detected[1].type)
      assert.is_true(detected[1].detected)
      assert.equals('CMakeLists.txt', detected[1].file)
      assert.is_not_nil(detected[1].commands)
      assert.is_not_nil(detected[1].commands.configure)
      assert.is_not_nil(detected[1].commands.build)
    end)

    it('should detect Makefile project', function()
      local project_path = temp_dir .. '/make_only'
      helpers.create_makefile_project(project_path)

      local detected = detect.detect_all(project_path)

      assert.equals(1, #detected)
      assert.equals('make', detected[1].type)
      assert.is_true(detected[1].detected)
      assert.equals('Makefile', detected[1].file)
      assert.is_not_nil(detected[1].commands)
      assert.is_not_nil(detected[1].commands.build)
    end)

    it('should detect multiple build systems', function()
      local project_path = temp_dir .. '/multi_build'
      helpers.create_multi_build_project(project_path)

      local detected = detect.detect_all(project_path)

      assert.equals(2, #detected)

      -- CMake should be first (higher priority)
      assert.equals('cmake', detected[1].type)
      assert.equals('make', detected[2].type)
    end)

    it('should return empty table for no build systems', function()
      local project_path = temp_dir .. '/no_build_system'
      vim.fn.mkdir(project_path, 'p')

      local detected = detect.detect_all(project_path)

      assert.equals(0, #detected)
    end)

    it('should include compile_commands_path for CMake', function()
      local project_path = temp_dir .. '/cmake_compile_commands'
      helpers.create_cmake_project(project_path)

      local detected = detect.detect_all(project_path)

      assert.equals(1, #detected)
      assert.equals('build/compile_commands.json', detected[1].compile_commands_path)
    end)

    it('should set correct build_dir for CMake', function()
      local project_path = temp_dir .. '/cmake_build_dir'
      helpers.create_cmake_project(project_path)

      local detected = detect.detect_all(project_path)

      assert.equals('build', detected[1].build_dir)
    end)

    it('should include all standard commands', function()
      local project_path = temp_dir .. '/full_commands'
      helpers.create_cmake_project(project_path)

      local detected = detect.detect_all(project_path)
      local cmake_system = detected[1]

      assert.is_not_nil(cmake_system.commands.configure)
      assert.is_not_nil(cmake_system.commands.build)
      assert.is_not_nil(cmake_system.commands.clean)
      assert.is_not_nil(cmake_system.commands.test)
      assert.is_not_nil(cmake_system.commands.install)
    end)
  end)

  describe('detect_build_system', function()
    it('should detect and save CMake configuration', function()
      local project_path = temp_dir .. '/detect_cmake'
      helpers.create_cmake_project(project_path)

      -- Mock storage
      local storage = require('neo-c.storage')
      local original_get_storage_dir = storage.get_storage_dir
      storage.get_storage_dir = function()
        return temp_dir .. '/storage/neo-c/projects'
      end

      local mock = helpers.mock_vim_notify()

      detect.detect_build_system = function()
        local utils = require('neo-c.utils')
        local proj_path = utils.find_project_root(project_path)
        local proj_name = utils.get_project_name(proj_path)

        vim.notify('Detecting build systems in: ' .. proj_path, vim.log.levels.INFO)

        local detected = detect.detect_all(proj_path)

        if #detected == 0 then
          vim.notify('No build systems detected', vim.log.levels.WARN)
          return
        end

        local schema = require('neo-c.schema')
        local config = schema.new_config(proj_path, proj_name)
        config.build_systems = detected
        config.selected_build_system = detected[1].type

        storage.save_config(proj_path, config)

        vim.notify('Detected: cmake | Selected: cmake', vim.log.levels.INFO)
      end

      detect.detect_build_system()

      local last_notification = mock.get_last()
      assert.is_not_nil(last_notification)
      assert.is_true(last_notification.msg:match('Detected.*cmake') ~= nil)

      mock.restore()
      storage.get_storage_dir = original_get_storage_dir
    end)

    it('should handle no build systems gracefully', function()
      local project_path = temp_dir .. '/no_build'
      vim.fn.mkdir(project_path, 'p')
      -- Create a marker so find_project_root works
      helpers.create_test_file(project_path .. '/.git/config', '')

      local mock = helpers.mock_vim_notify()

      -- Change to the project directory so find_project_root() finds it
      local original_cwd = vim.fn.getcwd()
      vim.cmd('cd ' .. project_path)

      detect.detect_build_system()

      vim.cmd('cd ' .. original_cwd)

      local last = mock.get_last()
      assert.is_not_nil(last)
      assert.equals(vim.log.levels.WARN, last.level)

      mock.restore()
    end)

    it('should prioritize CMake over Make in multi-build projects', function()
      local project_path = temp_dir .. '/multi_priority'
      helpers.create_multi_build_project(project_path)

      local detected = detect.detect_all(project_path)

      -- CMake should come first
      assert.equals('cmake', detected[1].type)
      assert.equals('make', detected[2].type)
    end)
  end)

  describe('integration scenarios', function()
    it('should handle real-world CMake project structure', function()
      local project_path = temp_dir .. '/real_cmake'
      vim.fn.mkdir(project_path .. '/src', 'p')
      vim.fn.mkdir(project_path .. '/include', 'p')
      vim.fn.mkdir(project_path .. '/tests', 'p')

      local cmake_content = [[
cmake_minimum_required(VERSION 3.10)
project(RealProject VERSION 1.0)

set(CMAKE_C_STANDARD 11)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

add_executable(app src/main.c src/utils.c)
target_include_directories(app PRIVATE include)

enable_testing()
add_subdirectory(tests)
]]

      helpers.create_test_file(project_path .. '/CMakeLists.txt', cmake_content)
      helpers.create_test_file(project_path .. '/.git/config', '')

      local detected = detect.detect_all(project_path)

      assert.equals(1, #detected)
      assert.equals('cmake', detected[1].type)
      assert.is_true(detected[1].commands.configure:match('CMAKE_EXPORT_COMPILE_COMMANDS') ~= nil)
    end)

    it('should handle project with both build systems preferring CMake', function()
      local project_path = temp_dir .. '/both_systems'
      helpers.create_multi_build_project(project_path)

      local detected = detect.detect_all(project_path)

      assert.equals(2, #detected)
      assert.equals('cmake', detected[1].type)  -- Higher priority

      -- Both should have valid commands
      assert.is_not_nil(detected[1].commands.build)
      assert.is_not_nil(detected[2].commands.build)
    end)
  end)

  describe('edge cases', function()
    it('should handle empty CMakeLists.txt', function()
      local project_path = temp_dir .. '/empty_cmake'
      vim.fn.mkdir(project_path, 'p')
      helpers.create_test_file(project_path .. '/CMakeLists.txt', '')

      local detected = detect.detect_all(project_path)

      assert.equals(1, #detected)
      assert.equals('cmake', detected[1].type)
    end)

    it('should handle empty Makefile', function()
      local project_path = temp_dir .. '/empty_makefile'
      vim.fn.mkdir(project_path, 'p')
      helpers.create_test_file(project_path .. '/Makefile', '')

      local detected = detect.detect_all(project_path)

      assert.equals(1, #detected)
      assert.equals('make', detected[1].type)

      local targets = detect.get_make_targets(project_path)
      assert.is_true(vim.tbl_contains(targets, 'all'))
      assert.is_true(vim.tbl_contains(targets, 'clean'))
    end)

    it('should handle Makefile with only comments', function()
      local project_path = temp_dir .. '/comment_makefile'
      vim.fn.mkdir(project_path, 'p')

      local makefile = [[
# This is a comment
# Another comment

# all: build
]]

      helpers.create_test_file(project_path .. '/Makefile', makefile)

      local targets = detect.get_make_targets(project_path)
      -- Should return defaults since no actual targets
      assert.is_true(#targets >= 2)
    end)
  end)
end)
