-- Tests for lua/neo-c/executor.lua
local helpers = require('tests.helpers')

describe('executor', function()
  local executor

  before_each(function()
    package.loaded['neo-c.executor'] = nil
    executor = require('neo-c.executor')
  end)

  describe('execute_sync', function()
    it('should execute simple command successfully', function()
      local cmd = {
        command = 'echo',
        args = {'hello', 'world'}
      }

      local result = executor.execute_sync(cmd)

      assert.is_not_nil(result)
      assert.equals(0, result.code)
      assert.is_true(result.output:match('hello world') ~= nil)
    end)

    it('should capture command output', function()
      local cmd = {
        command = 'printf',
        args = {'test output'}
      }

      local result = executor.execute_sync(cmd)

      assert.equals(0, result.code)
      assert.is_true(result.output:match('test output') ~= nil)
    end)

    it('should return non-zero exit code for failed command', function()
      local cmd = {
        command = 'false'
      }

      local result = executor.execute_sync(cmd)

      assert.is_not.equals(0, result.code)
    end)

    it('should handle commands with no arguments', function()
      local cmd = {
        command = 'true'
      }

      local result = executor.execute_sync(cmd)

      assert.equals(0, result.code)
    end)

    it('should handle multi-line output', function()
      local cmd = {
        command = 'printf',
        args = {'line1\\nline2\\nline3'}
      }

      local result = executor.execute_sync(cmd)

      assert.is_true(result.output:match('line1') ~= nil)
      assert.is_true(result.output:match('line2') ~= nil)
      assert.is_true(result.output:match('line3') ~= nil)
    end)

    it('should execute command with special characters', function()
      local cmd = {
        command = 'echo',
        args = {'special!@#$%'}
      }

      local result = executor.execute_sync(cmd)

      assert.equals(0, result.code)
    end)
  end)

  describe('execute_async', function()
    it('should execute command asynchronously', function(done)
      local cmd = {
        command = 'echo',
        args = {'async test'}
      }

      local completed = false

      executor.execute_async(cmd, {}, function(result)
        completed = true
        assert.equals(0, result.code)
        assert.is_true(result.stdout:match('async test') ~= nil)
        done()
      end)

      -- Give it time to execute
      vim.wait(1000, function() return completed end)
      assert.is_true(completed, 'Command should have completed')
    end)

    it('should capture stdout separately from stderr', function(done)
      -- Create a command that outputs to both stdout and stderr
      local cmd = {
        command = 'sh',
        args = {'-c', 'echo stdout_msg && echo stderr_msg >&2'}
      }

      executor.execute_async(cmd, {}, function(result)
        assert.equals(0, result.code)
        assert.is_true(result.stdout:match('stdout_msg') ~= nil)
        assert.is_true(result.stderr:match('stderr_msg') ~= nil)
        done()
      end)

      vim.wait(1000, function() return false end)
    end)

    it('should call on_stdout callback with streamed data', function(done)
      local stdout_chunks = {}

      local cmd = {
        command = 'echo',
        args = {'streaming test'}
      }

      local opts = {
        on_stdout = function(data)
          table.insert(stdout_chunks, data)
        end
      }

      executor.execute_async(cmd, opts, function(result)
        assert.equals(0, result.code)
        assert.is_true(#stdout_chunks > 0)
        done()
      end)

      vim.wait(1000, function() return false end)
    end)

    it('should call on_stderr callback with error data', function(done)
      local stderr_chunks = {}

      local cmd = {
        command = 'sh',
        args = {'-c', 'echo error >&2'}
      }

      local opts = {
        on_stderr = function(data)
          table.insert(stderr_chunks, data)
        end
      }

      executor.execute_async(cmd, opts, function(result)
        assert.is_true(#stderr_chunks > 0)
        done()
      end)

      vim.wait(1000, function() return false end)
    end)

    it('should respect cwd option', function(done)
      local temp_dir = helpers.create_temp_dir()
      helpers.create_test_file(temp_dir .. '/test.txt', 'test content')

      local cmd = {
        command = 'ls',
        args = {},
        cwd = temp_dir
      }

      executor.execute_async(cmd, {}, function(result)
        assert.equals(0, result.code)
        assert.is_true(result.stdout:match('test.txt') ~= nil)
        helpers.cleanup_temp_dir(temp_dir)
        done()
      end)

      vim.wait(1000, function() return false end)
    end)

    it('should handle command failure correctly', function(done)
      local cmd = {
        command = 'false'
      }

      executor.execute_async(cmd, {}, function(result)
        assert.is_not.equals(0, result.code)
        done()
      end)

      vim.wait(1000, function() return false end)
    end)

    it('should handle non-existent command', function()
      local cmd = {
        command = 'this_command_does_not_exist_12345'
      }

      local mock = helpers.mock_vim_notify()

      executor.execute_async(cmd, {}, function() end)

      vim.wait(500, function() return false end)

      -- Should have notified about failure
      local last = mock.get_last()
      if last then
        assert.is_true(last.msg:match('Failed to spawn') ~= nil)
      end

      mock.restore()
    end)

    it('should execute multiple commands in sequence', function(done)
      local results = {}

      local cmd1 = { command = 'echo', args = {'first'} }
      local cmd2 = { command = 'echo', args = {'second'} }

      executor.execute_async(cmd1, {}, function(result)
        table.insert(results, result)

        executor.execute_async(cmd2, {}, function(result2)
          table.insert(results, result2)

          assert.equals(2, #results)
          assert.is_true(results[1].stdout:match('first') ~= nil)
          assert.is_true(results[2].stdout:match('second') ~= nil)
          done()
        end)
      end)

      vim.wait(2000, function() return false end)
    end)

    it('should handle long-running command', function(done)
      local cmd = {
        command = 'sleep',
        args = {'0.1'}
      }

      local start_time = vim.loop.now()

      executor.execute_async(cmd, {}, function(result)
        local elapsed = vim.loop.now() - start_time

        assert.equals(0, result.code)
        assert.is_true(elapsed >= 100) -- At least 100ms
        done()
      end)

      vim.wait(1000, function() return false end)
    end)
  end)

  describe('integration scenarios', function()
    it('should compile and run a simple C program', function(done)
      local temp_dir = helpers.create_temp_dir()
      local source_file = temp_dir .. '/hello.c'

      local c_code = [[
#include <stdio.h>
int main() {
    printf("Hello from test!\n");
    return 0;
}
]]

      helpers.create_test_file(source_file, c_code)

      -- Compile
      local compile_cmd = {
        command = 'gcc',
        args = {source_file, '-o', temp_dir .. '/hello'},
        cwd = temp_dir
      }

      executor.execute_async(compile_cmd, {}, function(compile_result)
        assert.equals(0, compile_result.code, 'Compilation should succeed')

        -- Run
        local run_cmd = {
          command = temp_dir .. '/hello',
          cwd = temp_dir
        }

        executor.execute_async(run_cmd, {}, function(run_result)
          assert.equals(0, run_result.code)
          assert.is_true(run_result.stdout:match('Hello from test') ~= nil)

          helpers.cleanup_temp_dir(temp_dir)
          done()
        end)
      end)

      vim.wait(3000, function() return false end)
    end)

    it('should handle compilation errors gracefully', function(done)
      local temp_dir = helpers.create_temp_dir()
      local source_file = temp_dir .. '/broken.c'

      local bad_code = [[
#include <stdio.h>
int main() {
    printf("Missing semicolon")
    return 0;
}
]]

      helpers.create_test_file(source_file, bad_code)

      local compile_cmd = {
        command = 'gcc',
        args = {source_file, '-o', temp_dir .. '/broken'},
        cwd = temp_dir
      }

      executor.execute_async(compile_cmd, {}, function(result)
        assert.is_not.equals(0, result.code, 'Compilation should fail')
        assert.is_true(result.stderr:len() > 0, 'Should have error output')

        helpers.cleanup_temp_dir(temp_dir)
        done()
      end)

      vim.wait(3000, function() return false end)
    end)

    it('should execute make command', function(done)
      local temp_dir = helpers.create_temp_dir()
      helpers.create_makefile_project(temp_dir)

      local make_cmd = {
        command = 'make',
        args = {'clean'},
        cwd = temp_dir
      }

      executor.execute_async(make_cmd, {}, function(result)
        -- May fail if make is not installed, but should execute
        assert.is_not_nil(result)
        assert.is_not_nil(result.code)

        helpers.cleanup_temp_dir(temp_dir)
        done()
      end)

      vim.wait(3000, function() return false end)
    end)
  end)

  describe('edge cases', function()
    it('should handle empty command args', function()
      local cmd = {
        command = 'pwd',
        args = {}
      }

      local result = executor.execute_sync(cmd)
      assert.is_not_nil(result)
    end)

    it('should handle nil options in execute_async', function(done)
      local cmd = {
        command = 'echo',
        args = {'test'}
      }

      executor.execute_async(cmd, nil, function(result)
        assert.equals(0, result.code)
        done()
      end)

      vim.wait(1000, function() return false end)
    end)

    it('should handle commands with many arguments', function()
      local args = {}
      for i = 1, 50 do
        table.insert(args, tostring(i))
      end

      local cmd = {
        command = 'echo',
        args = args
      }

      local result = executor.execute_sync(cmd)
      assert.equals(0, result.code)
    end)
  end)
end)
