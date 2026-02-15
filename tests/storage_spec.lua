-- Tests for lua/neo-c/storage.lua
local helpers = require('tests.helpers')

describe('storage', function()
  local storage
  local temp_dir
  local test_project_path

  before_each(function()
    -- Reload module to get fresh state
    package.loaded['neo-c.storage'] = nil
    storage = require('neo-c.storage')

    -- Create temp directory for testing
    temp_dir = helpers.create_temp_dir()
    test_project_path = temp_dir .. '/test_project'
    vim.fn.mkdir(test_project_path, 'p')
  end)

  after_each(function()
    helpers.cleanup_temp_dir(temp_dir)
  end)

  describe('get_storage_dir', function()
    it('should return a valid storage directory path', function()
      local dir = storage.get_storage_dir()
      assert.is_not_nil(dir)
      assert.is_true(dir:match('/neo%-c/projects$') ~= nil)
    end)
  end)

  describe('get_project_id', function()
    it('should generate consistent SHA256 hash for same path', function()
      local id1 = storage.get_project_id(test_project_path)
      local id2 = storage.get_project_id(test_project_path)

      assert.equals(id1, id2)
      assert.equals(64, #id1) -- SHA256 produces 64 hex characters
    end)

    it('should generate different hashes for different paths', function()
      local id1 = storage.get_project_id('/path/to/project1')
      local id2 = storage.get_project_id('/path/to/project2')

      assert.is_not.equals(id1, id2)
    end)

    it('should be case-sensitive', function()
      local id1 = storage.get_project_id('/Path/To/Project')
      local id2 = storage.get_project_id('/path/to/project')

      assert.is_not.equals(id1, id2)
    end)
  end)

  describe('get_config_path', function()
    it('should return correct config file path', function()
      local path = storage.get_config_path(test_project_path)
      local project_id = storage.get_project_id(test_project_path)

      assert.is_not_nil(path)
      assert.is_true(path:match('/' .. project_id .. '%.json$') ~= nil)
    end)
  end)

  describe('ensure_storage_dir', function()
    it('should create storage directory if it does not exist', function()
      -- Mock the storage dir to point to our temp directory
      local original_get_storage_dir = storage.get_storage_dir
      storage.get_storage_dir = function()
        return temp_dir .. '/neo-c/projects'
      end

      storage.ensure_storage_dir()

      local dir = storage.get_storage_dir()
      assert.equals(1, vim.fn.isdirectory(dir))

      -- Restore original function
      storage.get_storage_dir = original_get_storage_dir
    end)
  end)

  describe('save_config and load_config', function()
    it('should save and load config correctly', function()
      -- Mock storage dir
      local original_get_storage_dir = storage.get_storage_dir
      storage.get_storage_dir = function()
        return temp_dir .. '/neo-c/projects'
      end

      local config = {
        version = '1.0',
        project_path = test_project_path,
        project_name = 'test_project',
        build_systems = {
          {
            type = 'cmake',
            detected = true,
            file = 'CMakeLists.txt'
          }
        },
        selected_build_system = 'cmake'
      }

      -- Save config
      local save_result = storage.save_config(test_project_path, config)
      assert.is_true(save_result)

      -- Load config
      local loaded_config = storage.load_config(test_project_path)
      assert.is_not_nil(loaded_config)
      assert.equals(config.version, loaded_config.version)
      assert.equals(config.project_path, loaded_config.project_path)
      assert.equals(config.project_name, loaded_config.project_name)
      assert.equals(config.selected_build_system, loaded_config.selected_build_system)

      -- Restore
      storage.get_storage_dir = original_get_storage_dir
    end)

    it('should return nil when loading non-existent config', function()
      local config = storage.load_config('/non/existent/path')
      assert.is_nil(config)
    end)

    it('should handle complex nested structures', function()
      local original_get_storage_dir = storage.get_storage_dir
      storage.get_storage_dir = function()
        return temp_dir .. '/neo-c/projects'
      end

      local config = {
        version = '1.0',
        project_path = test_project_path,
        build_systems = {
          {
            type = 'cmake',
            commands = {
              configure = 'cmake -B build',
              build = 'cmake --build build',
              test = 'ctest --test-dir build'
            },
            targets = {'all', 'clean', 'test'}
          }
        },
        custom_commands = {
          run = './build/app'
        },
        debug_config = {
          adapter = 'gdb',
          program = './build/app',
          args = {'--verbose'}
        }
      }

      storage.save_config(test_project_path, config)
      local loaded = storage.load_config(test_project_path)

      assert.equals(config.debug_config.adapter, loaded.debug_config.adapter)
      assert.equals(#config.debug_config.args, #loaded.debug_config.args)
      assert.equals(config.build_systems[1].commands.build, loaded.build_systems[1].commands.build)

      storage.get_storage_dir = original_get_storage_dir
    end)

    it('should handle invalid JSON gracefully', function()
      local original_get_storage_dir = storage.get_storage_dir
      storage.get_storage_dir = function()
        return temp_dir .. '/neo-c/projects'
      end

      storage.ensure_storage_dir()
      local config_path = storage.get_config_path(test_project_path)

      -- Write invalid JSON
      helpers.create_test_file(config_path, '{ invalid json }')

      local mock = helpers.mock_vim_notify()
      local config = storage.load_config(test_project_path)

      assert.is_nil(config)
      assert.is_not_nil(mock.get_last())
      assert.is_true(mock.get_last().msg:match('Failed to parse config') ~= nil)

      mock.restore()
      storage.get_storage_dir = original_get_storage_dir
    end)
  end)

  describe('delete_config', function()
    it('should delete existing config file', function()
      local original_get_storage_dir = storage.get_storage_dir
      storage.get_storage_dir = function()
        return temp_dir .. '/neo-c/projects'
      end

      local config = {
        version = '1.0',
        project_path = test_project_path
      }

      storage.save_config(test_project_path, config)

      local config_path = storage.get_config_path(test_project_path)
      assert.equals(1, vim.fn.filereadable(config_path))

      storage.delete_config(test_project_path)
      assert.equals(0, vim.fn.filereadable(config_path))

      storage.get_storage_dir = original_get_storage_dir
    end)

    it('should not error when deleting non-existent config', function()
      storage.delete_config('/non/existent/path')
      -- Should complete without error
      assert.is_true(true)
    end)
  end)

  describe('edge cases', function()
    it('should handle empty config objects', function()
      local original_get_storage_dir = storage.get_storage_dir
      storage.get_storage_dir = function()
        return temp_dir .. '/neo-c/projects'
      end

      local config = {}
      storage.save_config(test_project_path, config)
      local loaded = storage.load_config(test_project_path)

      assert.is_not_nil(loaded)
      assert.same({}, loaded)

      storage.get_storage_dir = original_get_storage_dir
    end)

    it('should handle special characters in project paths', function()
      local special_path = temp_dir .. '/project-with-special_chars.test'
      vim.fn.mkdir(special_path, 'p')

      local id = storage.get_project_id(special_path)
      assert.equals(64, #id)
      assert.is_true(id:match('^%x+$') ~= nil) -- All hex characters
    end)
  end)
end)
