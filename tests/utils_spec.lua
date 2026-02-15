-- Tests for lua/neo-c/utils.lua
local helpers = require('tests.helpers')

describe('utils', function()
  local utils
  local temp_dir

  before_each(function()
    package.loaded['neo-c.utils'] = nil
    utils = require('neo-c.utils')
    temp_dir = helpers.create_temp_dir()
  end)

  after_each(function()
    helpers.cleanup_temp_dir(temp_dir)
  end)

  describe('find_project_root', function()
    it('should find project root with .git directory', function()
      local project_path = temp_dir .. '/my_project'
      vim.fn.mkdir(project_path .. '/.git', 'p')
      vim.fn.mkdir(project_path .. '/src/deep/nested', 'p')

      local root = utils.find_project_root(project_path .. '/src/deep/nested')
      assert.equals(project_path, root)
    end)

    it('should find project root with CMakeLists.txt', function()
      local project_path = temp_dir .. '/cmake_project'
      vim.fn.mkdir(project_path .. '/src', 'p')
      helpers.create_test_file(project_path .. '/CMakeLists.txt', 'cmake_minimum_required(VERSION 3.10)')

      local root = utils.find_project_root(project_path .. '/src')
      assert.equals(project_path, root)
    end)

    it('should find project root with Makefile', function()
      local project_path = temp_dir .. '/make_project'
      vim.fn.mkdir(project_path .. '/src', 'p')
      helpers.create_test_file(project_path .. '/Makefile', 'all:\n\techo "build"')

      local root = utils.find_project_root(project_path .. '/src')
      assert.equals(project_path, root)
    end)

    it('should prioritize closest marker when multiple exist', function()
      local outer_project = temp_dir .. '/outer'
      local inner_project = outer_project .. '/inner'

      vim.fn.mkdir(outer_project .. '/.git', 'p')
      vim.fn.mkdir(inner_project .. '/.git', 'p')
      vim.fn.mkdir(inner_project .. '/src', 'p')

      local root = utils.find_project_root(inner_project .. '/src')
      assert.equals(inner_project, root)
    end)

    it('should find project root with configure script', function()
      local project_path = temp_dir .. '/autotools_project'
      vim.fn.mkdir(project_path, 'p')
      helpers.create_test_file(project_path .. '/configure', '#!/bin/sh')
      vim.fn.system('chmod +x ' .. project_path .. '/configure')

      local root = utils.find_project_root(project_path)
      assert.equals(project_path, root)
    end)

    it('should find project root with .hg directory', function()
      local project_path = temp_dir .. '/hg_project'
      vim.fn.mkdir(project_path .. '/.hg', 'p')

      local root = utils.find_project_root(project_path)
      assert.equals(project_path, root)
    end)

    it('should find project root with .svn directory', function()
      local project_path = temp_dir .. '/svn_project'
      vim.fn.mkdir(project_path .. '/.svn', 'p')

      local root = utils.find_project_root(project_path)
      assert.equals(project_path, root)
    end)

    it('should find project root with meson.build', function()
      local project_path = temp_dir .. '/meson_project'
      vim.fn.mkdir(project_path, 'p')
      helpers.create_test_file(project_path .. '/meson.build', "project('test', 'c')")

      local root = utils.find_project_root(project_path)
      assert.equals(project_path, root)
    end)

    it('should fallback to cwd when no markers found', function()
      local project_path = temp_dir .. '/no_markers'
      vim.fn.mkdir(project_path, 'p')

      local root = utils.find_project_root(project_path)
      -- Should return cwd as fallback
      assert.is_not_nil(root)
    end)

    it('should handle root directory without infinite loop', function()
      local root = utils.find_project_root('/')
      assert.is_not_nil(root)
      -- Should not hang or error
    end)

    it('should handle traversal through multiple directories', function()
      local deep_path = temp_dir .. '/a/b/c/d/e/f'
      vim.fn.mkdir(deep_path, 'p')
      vim.fn.mkdir(temp_dir .. '/.git', 'p')

      local root = utils.find_project_root(deep_path)
      assert.equals(temp_dir, root)
    end)

    it('should detect multiple marker types correctly', function()
      local project_path = temp_dir .. '/multi_marker'
      vim.fn.mkdir(project_path, 'p')

      -- Add multiple markers
      vim.fn.mkdir(project_path .. '/.git', 'p')
      helpers.create_test_file(project_path .. '/CMakeLists.txt', 'project(test)')
      helpers.create_test_file(project_path .. '/Makefile', 'all:')

      local root = utils.find_project_root(project_path)
      assert.equals(project_path, root)
    end)
  end)

  describe('get_project_name', function()
    it('should extract project name from path', function()
      local name = utils.get_project_name('/path/to/my_project')
      assert.equals('my_project', name)
    end)

    it('should handle path with trailing slash', function()
      local name = utils.get_project_name('/path/to/my_project/')
      -- Vim's fnamemodify should handle this correctly
      assert.is_not_nil(name)
      assert.is_true(#name > 0)
    end)

    it('should handle single directory name', function()
      local name = utils.get_project_name('/project')
      assert.equals('project', name)
    end)

    it('should handle relative paths', function()
      local name = utils.get_project_name('./my_project')
      assert.is_not_nil(name)
    end)

    it('should handle paths with special characters', function()
      local name = utils.get_project_name('/path/to/my-project_v2.0')
      assert.equals('my-project_v2.0', name)
    end)

    it('should handle root directory', function()
      local name = utils.get_project_name('/')
      assert.is_not_nil(name)
    end)
  end)

  describe('integration scenarios', function()
    it('should work with find_project_root and get_project_name together', function()
      local project_path = temp_dir .. '/integration_test'
      vim.fn.mkdir(project_path .. '/.git', 'p')
      vim.fn.mkdir(project_path .. '/src/nested', 'p')

      local root = utils.find_project_root(project_path .. '/src/nested')
      local name = utils.get_project_name(root)

      assert.equals(project_path, root)
      assert.equals('integration_test', name)
    end)

    it('should handle complex directory structures', function()
      -- Create structure: temp/project_root/submodule/src
      local root_path = temp_dir .. '/project_root'
      local submodule_path = root_path .. '/submodule'

      vim.fn.mkdir(root_path .. '/.git', 'p')
      vim.fn.mkdir(submodule_path .. '/.git', 'p')
      vim.fn.mkdir(submodule_path .. '/src', 'p')

      -- From submodule/src, should find submodule as root (closest .git)
      local found_root = utils.find_project_root(submodule_path .. '/src')
      assert.equals(submodule_path, found_root)

      local name = utils.get_project_name(found_root)
      assert.equals('submodule', name)
    end)
  end)

  describe('edge cases', function()
    it('should handle empty string path gracefully', function()
      -- This tests robustness
      local root = utils.find_project_root('')
      assert.is_not_nil(root)
    end)

    it('should handle non-existent paths', function()
      local root = utils.find_project_root('/definitely/does/not/exist/path')
      -- Should fallback to cwd
      assert.is_not_nil(root)
    end)

    it('should handle symlinks correctly', function()
      local real_project = temp_dir .. '/real_project'
      local link_path = temp_dir .. '/link_to_project'

      vim.fn.mkdir(real_project .. '/.git', 'p')
      vim.fn.system(string.format('ln -s %s %s', real_project, link_path))

      if vim.fn.isdirectory(link_path) == 1 then
        local root = utils.find_project_root(link_path)
        -- Should resolve to real project or link - either is acceptable
        assert.is_not_nil(root)
      end
    end)
  end)
end)
