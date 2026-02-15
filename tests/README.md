# neo-c.nvim Test Suite

Comprehensive unit tests for the neo-c.nvim plugin using [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)'s test harness.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Running Tests](#running-tests)
- [Test Structure](#test-structure)
- [Writing Tests](#writing-tests)
- [CI/CD Integration](#cicd-integration)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Required

- **Neovim 0.8+**: The plugin requires Neovim 0.8 or higher
- **plenary.nvim**: Testing framework for Neovim plugins

### Optional

- **gcc/clang**: For executor integration tests that compile C code
- **make**: For Makefile-related tests
- **cmake**: For CMake-related tests

## Installation

### Installing plenary.nvim

#### Using lazy.nvim

```lua
{
  'nvim-lua/plenary.nvim',
}
```

#### Using packer.nvim

```lua
use 'nvim-lua/plenary.nvim'
```

#### Manual Installation

```bash
git clone https://github.com/nvim-lua/plenary.nvim \
  ~/.local/share/nvim/site/pack/packer/start/plenary.nvim
```

## Running Tests

### Run All Tests

```bash
./tests/run_tests.sh
```

### Run Specific Test Suites

```bash
# Run storage tests only
./tests/run_tests.sh storage

# Run multiple specific test suites
./tests/run_tests.sh storage utils detect
```

### Run Tests from Neovim

```vim
:PlenaryBustedDirectory tests/
```

Or for a specific file:

```vim
:PlenaryBustedFile tests/storage_spec.lua
```

### Run Tests with Make (Optional)

You can add a Makefile target for convenience:

```makefile
.PHONY: test
test:
	@./tests/run_tests.sh

.PHONY: test-storage
test-storage:
	@./tests/run_tests.sh storage
```

Then run:

```bash
make test
```

## Test Structure

```
tests/
├── README.md              # This file
├── run_tests.sh          # Main test runner script
├── minimal_init.lua      # Minimal init for test environment
├── helpers.lua           # Shared test utilities and fixtures
├── storage_spec.lua      # Tests for lua/neo-c/storage.lua
├── utils_spec.lua        # Tests for lua/neo-c/utils.lua
├── detect_spec.lua       # Tests for lua/neo-c/detect.lua
├── executor_spec.lua     # Tests for lua/neo-c/executor.lua
└── fixtures/             # Test fixtures and sample projects
    └── projects/
        ├── cmake_project/
        ├── make_project/
        └── multi_build_project/
```

## Test Coverage

### storage_spec.lua

Tests for configuration persistence and project identification:

- ✓ SHA256 project ID generation
- ✓ Config file path resolution
- ✓ Storage directory creation
- ✓ Config save/load operations
- ✓ JSON serialization/deserialization
- ✓ Invalid JSON handling
- ✓ Config deletion
- ✓ Edge cases (empty configs, special characters)

**Lines of test code**: ~250
**Test cases**: ~20

### utils_spec.lua

Tests for project root detection and utilities:

- ✓ Finding project root with various markers (.git, CMakeLists.txt, Makefile, etc.)
- ✓ Prioritizing closest marker in nested projects
- ✓ Handling multiple marker types
- ✓ Fallback to cwd when no markers found
- ✓ Project name extraction
- ✓ Edge cases (root directory, symlinks, non-existent paths)

**Lines of test code**: ~280
**Test cases**: ~25

### detect_spec.lua

Tests for build system detection:

- ✓ CMake project detection
- ✓ Makefile project detection
- ✓ Multi-build system detection
- ✓ CMake target extraction
- ✓ Makefile target parsing (excluding .PHONY)
- ✓ Priority ordering (CMake > Make)
- ✓ compile_commands.json path detection
- ✓ Edge cases (empty files, comments-only)

**Lines of test code**: ~420
**Test cases**: ~30

### executor_spec.lua

Tests for async/sync command execution:

- ✓ Synchronous command execution
- ✓ Asynchronous command execution
- ✓ stdout/stderr separation and streaming
- ✓ Exit code handling
- ✓ Working directory (cwd) support
- ✓ Command failure handling
- ✓ Integration tests (compiling/running C programs)
- ✓ Long-running commands
- ✓ Edge cases (empty args, nil options, many arguments)

**Lines of test code**: ~380
**Test cases**: ~28

## Writing Tests

### Basic Test Structure

```lua
-- tests/mymodule_spec.lua
local helpers = require('tests.helpers')

describe('mymodule', function()
  local mymodule

  before_each(function()
    -- Reload module for fresh state
    package.loaded['neo-c.mymodule'] = nil
    mymodule = require('neo-c.mymodule')
  end)

  describe('my_function', function()
    it('should do something', function()
      local result = mymodule.my_function('input')
      assert.equals('expected', result)
    end)
  end)
end)
```

### Using Test Helpers

The `helpers.lua` module provides useful utilities:

```lua
local helpers = require('tests.helpers')

-- Create temporary directory
local temp_dir = helpers.create_temp_dir()

-- Create test file
helpers.create_test_file(temp_dir .. '/test.txt', 'content')

-- Create mock project structures
local cmake_project = helpers.create_cmake_project(temp_dir .. '/cmake')
local make_project = helpers.create_makefile_project(temp_dir .. '/make')
local multi_build = helpers.create_multi_build_project(temp_dir .. '/both')

-- Mock vim.notify
local mock = helpers.mock_vim_notify()
-- ... code that calls vim.notify ...
local last_notification = mock.get_last()
assert.is_not_nil(last_notification)
mock.restore()

-- Cleanup
helpers.cleanup_temp_dir(temp_dir)
```

### Assertions

plenary.nvim uses busted-style assertions:

```lua
-- Equality
assert.equals(expected, actual)
assert.same({table1}, {table2})  -- Deep equality

-- Truthiness
assert.is_true(value)
assert.is_false(value)
assert.is_nil(value)
assert.is_not_nil(value)

-- Type checking
assert.equals('string', type(value))

-- String matching
assert.is_true(str:match('pattern') ~= nil)

-- Table membership
assert.is_true(vim.tbl_contains(tbl, value))
```

### Async Tests

For testing async functions:

```lua
it('should execute async operation', function(done)
  some_async_function(function(result)
    assert.equals(expected, result)
    done()  -- Signal test completion
  end)

  -- Wait for completion (with timeout)
  vim.wait(1000, function() return false end)
end)
```

### Mocking

```lua
-- Save original function
local original_func = module.some_function

-- Mock it
module.some_function = function(...)
  return 'mocked result'
end

-- ... run tests ...

-- Restore
module.some_function = original_func
```

## CI/CD Integration

### GitHub Actions

Create `.github/workflows/test.yml`:

```yaml
name: Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install Neovim
        uses: rhysd/action-setup-vim@v1
        with:
          neovim: true
          version: stable

      - name: Install plenary.nvim
        run: |
          git clone https://github.com/nvim-lua/plenary.nvim \
            ~/.local/share/nvim/site/pack/packer/start/plenary.nvim

      - name: Run tests
        run: ./tests/run_tests.sh

      - name: Upload test results
        if: failure()
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: /tmp/neo-c-test-output.txt
```

### GitLab CI

Create `.gitlab-ci.yml`:

```yaml
test:
  image: alpine:latest
  before_script:
    - apk add --no-cache neovim git gcc make
    - git clone https://github.com/nvim-lua/plenary.nvim \
        ~/.local/share/nvim/site/pack/packer/start/plenary.nvim
  script:
    - ./tests/run_tests.sh
  artifacts:
    when: on_failure
    paths:
      - /tmp/neo-c-test-output.txt
```

## Troubleshooting

### plenary.nvim Not Found

**Error**: `Warning: plenary.nvim not found in standard locations`

**Solution**: Ensure plenary.nvim is installed in one of:
- `~/.local/share/nvim/site/pack/packer/start/plenary.nvim`
- `~/.local/share/nvim/lazy/plenary.nvim`

Or update `minimal_init.lua` with your custom path.

### Tests Hang or Timeout

**Issue**: Async tests don't complete

**Solution**:
- Ensure you call `done()` in async test callbacks
- Increase timeout in `vim.wait()` calls
- Check if the command being tested actually completes

### Module Not Found

**Error**: `module 'neo-c.mymodule' not found`

**Solution**:
- Verify the module path is correct
- Ensure the project root is in the runtime path
- Check `minimal_init.lua` configuration

### Test Failures in CI but Pass Locally

**Common causes**:
- Missing system dependencies (gcc, make, cmake)
- Different Neovim version
- Timing issues in async tests
- File system differences

**Solution**:
- Add required packages to CI setup
- Pin Neovim version in CI
- Increase timeouts for CI environment
- Use temporary directories instead of hardcoded paths

### Cleaning Up Test Artifacts

Tests create temporary files. If tests crash, cleanup may not happen:

```bash
# Clean up temp test directories
rm -rf /tmp/tmp.*

# Clean up test storage
rm -rf /tmp/neo-c-test-output.txt
```

## Best Practices

1. **Isolation**: Each test should be independent and not rely on others
2. **Cleanup**: Always clean up temporary files and directories
3. **Mocking**: Mock external dependencies (file system, vim functions) when possible
4. **Descriptive Names**: Use clear, descriptive test names
5. **Edge Cases**: Test boundary conditions and error cases
6. **Fast Tests**: Keep tests fast by avoiding unnecessary waits
7. **DRY**: Use helpers for common operations

## Contributing

When adding new features:

1. Write tests first (TDD approach recommended)
2. Ensure all existing tests pass
3. Add tests for edge cases
4. Update this README if adding new test utilities
5. Aim for >80% code coverage

## License

Same as neo-c.nvim - MIT License
