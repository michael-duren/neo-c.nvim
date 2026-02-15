# neo-c.nvim

A comprehensive Neovim plugin for C project management with build system detection, execution, testing, and debugging capabilities.

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Commands](#commands)
  - [:NewCProject](#newcproject)
  - [:CRun](#crun)
  - [:CDetect](#cdetect)
  - [:CRunProject](#crunproject)
  - [:CRunProjectRun](#crunprojectrun)
  - [:CTest](#ctest)
  - [:CDebug](#cdebug)
  - [:CGenerateCompileCommands](#cgeneratecompilecommands)
  - [:CConfig](#cconfig)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
  - [Setup Function](#setup-function)
  - [Default Keybindings](#default-keybindings)
  - [Customization Examples](#customization-examples)
- [Storage](#storage)
- [Examples](#examples)
- [JSON Configuration Schema](#json-configuration-schema)
- [Dependencies](#dependencies)
- [Architecture](#architecture)
- [Testing](#testing)
- [Related Projects](#related-projects)
- [License](#license)
- [Contributing](#contributing)
- [Roadmap](#roadmap)

## Features

- **Build System Detection**: Automatically detects CMake and Makefile-based projects
- **Project Execution**: Build and run entire projects with async execution
- **Test Runner**: Execute tests with results in quickfix list
- **Debug Integration**: Auto-configure nvim-dap for GDB and CodeLLDB
- **LSP Helper**: Generate compile_commands.json for clangd and other LSP servers
- **Interactive Configuration**: Customize build, run, test, and debug settings via UI
- **Persistent Storage**: JSON-based configuration stored per-project
- **Multi-Build Support**: Handle projects with multiple build systems with preference storage

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'michael-duren/neo-c.nvim',
  ft = 'c',  -- Lazy load on C files
  dependencies = {
    'MunifTanjim/nui.nvim',  -- Optional: for better UI
    'mfussenegger/nvim-dap',  -- Optional: for debugging support
  },
  config = function()
    require('neo-c').setup({
      -- Your custom configuration here (optional)
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'michael-duren/neo-c.nvim',
  ft = 'c',  -- Lazy load on C files
  requires = {
    'MunifTanjim/nui.nvim',  -- Optional: for better UI
    'mfussenegger/nvim-dap',  -- Optional: for debugging support
  },
  config = function()
    require('neo-c').setup({
      -- Your custom configuration here (optional)
    })
  end,
}
```

## Commands

### `:NewCProject`

Create a new C project from interactive templates. **Available globally** in Neovim.

```vim
:NewCProject
```

Features:

- Interactive project name and location selection
- Three project templates:
  - **Simple**: Single `main.c` file for quick prototyping
  - **CMake**: Modern CMake-based project with src/, include/, and tests/ directories
  - **Makefile**: Traditional Makefile-based project with organized directory structure
- Automatically creates README.md with build instructions
- Option to immediately open the newly created project

Templates include:

**Simple Template:**
- `main.c` - Single source file
- `README.md` - Basic documentation

**CMake Template:**
- `CMakeLists.txt` - CMake configuration with compile_commands.json generation
- `src/main.c` - Main source file
- `include/` - Header files directory
- `tests/CMakeLists.txt` - Test configuration
- `tests/test_main.c` - Basic test file
- `README.md` - Build and test instructions

**Makefile Template:**
- `Makefile` - Complete Makefile with build, run, clean targets
- `src/` - Source files directory
- `include/` - Header files directory
- `obj/` - Object files directory (created during build)
- `bin/` - Binary output directory
- `README.md` - Build instructions

**Use case**: Quickly scaffold new C projects with proper structure and build configuration.

### `:CRun`

Quick compile and run the current buffer without needing project detection.

```vim
:CRun
```

Features:
- Compiles current C file with `gcc -Wall -Wextra -std=c11`
- Outputs to `/tmp/makec/a.out`
- Runs immediately after successful compilation
- Opens in a split terminal
- Compilation errors populate quickfix list
- Perfect for quick testing and single-file programs

**Use case**: When you want to quickly test a single C file without setting up a full project.

### `:CDetect`

Detect all build systems in the current project and store configuration.

```vim
:CDetect
```

Detects:

- CMake projects (CMakeLists.txt)
- Makefile projects (Makefile)

Stores configuration in `~/.local/share/nvim/neo-c/projects/<sha256>.json`

### `:CRunProject`

Build the entire project using the detected build system.

```vim
:CRunProject
```

Features:

- Async execution with vim.loop
- CMake configure step handled automatically
- Build errors populate quickfix list
- Handles multi-build-system projects with selection prompt

### `:CRunProjectRun`

Build and run the entire project.

```vim
:CRunProjectRun
```

Runs the custom run command configured via `:CConfig` after successful build.

### `:CTest`

Run project tests.

```vim
:CTest
```

Supports:

- CTest for CMake projects
- `make test` for Makefile projects
- Custom test commands via `:CConfig`

### `:CDebug`

Start a debugging session with auto-configured nvim-dap.

```vim
:CDebug
```

Features:

- Auto-detects program path from run command
- Supports GDB and CodeLLDB adapters
- Saves debug configuration for reuse

Requirements: [nvim-dap](https://github.com/mfussenegger/nvim-dap)

### `:CGenerateCompileCommands`

Generate compile_commands.json for LSP servers.

```vim
:CGenerateCompileCommands
```

- **CMake**: Symlinks from `build/compile_commands.json` to project root
- **Make**: Uses [Bear](https://github.com/rizsotto/Bear) to generate

### `:CConfig`

Interactive configuration menu.

```vim
:CConfig
```

Options:

1. Set build system (for multi-build projects)
2. Set run command
3. Set test command
4. Set debug program path
5. Set debug adapter (gdb/codelldb)
6. Set compiler flags

## Quick Start

### For Single Files
1. Open a C file in Neovim
2. Run `:CRun` to compile and execute immediately

### For Projects
1. Navigate to a C project with CMake or Makefile
2. Run `:CDetect` to detect the build system
3. Run `:CConfig` to set a run command (e.g., `./build/my-project`)
4. Run `:CRunProjectRun` to build and execute your project

## Configuration

The plugin works out-of-the-box with sensible defaults. No configuration is required.

### Setup Function

To customize the plugin, call `setup()` in your Neovim config:

```lua
require('neo-c').setup({
  -- Keybindings configuration
  keybindings = {
    enabled = true,  -- Set to false to disable all keybindings
    run = '<leader>cr',              -- Compile and run current buffer
    detect = '<leader>cd',           -- Detect build systems
    build = '<leader>cb',            -- Build project
    build_and_run = '<leader>cR',   -- Build and run project
    test = '<leader>ct',             -- Run tests
    debug = '<leader>cD',            -- Start debugging
    generate_compile_commands = '<leader>cl',  -- Generate compile_commands.json
    config = '<leader>cc',           -- Open configuration menu
    -- Global keybindings (available everywhere, not just in C buffers)
    global = {
      new_project = '<leader>cn',   -- Create a new C project
    },
  },
  -- Compiler options for CRun command
  compiler = {
    executable = 'gcc',
    flags = {'-Wall', '-Wextra', '-std=c11'},
    output_dir = '/tmp/makec',
  },
})
```

### Default Keybindings

#### Global Keybindings (Available Everywhere)

| Keybinding | Command | Description |
|------------|---------|-------------|
| `<leader>cn` | `:NewCProject` | Create a new C project |

#### C Buffer Keybindings (Available in C Files)

The following keybindings are automatically set when opening C files (`.c` extension):

| Keybinding | Command | Description |
|------------|---------|-------------|
| `<leader>cr` | `:CRun` | Compile and run current buffer |
| `<leader>cd` | `:CDetect` | Detect build systems |
| `<leader>cb` | `:CRunProject` | Build project |
| `<leader>cR` | `:CRunProjectRun` | Build and run project |
| `<leader>ct` | `:CTest` | Run tests |
| `<leader>cD` | `:CDebug` | Start debugging |
| `<leader>cl` | `:CGenerateCompileCommands` | Generate compile_commands.json |
| `<leader>cc` | `:CConfig` | Open configuration menu |

**Note**: These keybindings use `<leader>c` as the prefix (e.g., if your leader is `<Space>`, press `<Space>cn` to create a new project or `<Space>cr` to run current buffer).

### Customization Examples

**Disable all keybindings:**

```lua
require('neo-c').setup({
  keybindings = {
    enabled = false,
  },
})
```

**Use custom keybindings:**

```lua
require('neo-c').setup({
  keybindings = {
    run = '<F5>',              -- Press F5 to compile and run
    build = '<F7>',            -- Press F7 to build project
    debug = '<F9>',            -- Press F9 to debug
    test = '<leader>tt',       -- Custom prefix
    -- Set any binding to false to disable it
    config = false,            -- Disable :CConfig keybinding
    -- Customize global keybindings
    global = {
      new_project = '<leader>np',  -- Custom keybinding for new project
    },
  },
})
```

**Customize compiler settings:**

```lua
require('neo-c').setup({
  compiler = {
    executable = 'clang',      -- Use clang instead of gcc
    flags = {'-Wall', '-Wextra', '-std=c17', '-O2'},  -- Custom flags
    output_dir = '/tmp/my-c-builds',  -- Custom output directory
  },
})

## Storage

Project configurations are stored in:

- Linux/macOS: `~/.local/share/nvim/neo-c/projects/<sha256>.json`
- Windows: `%LOCALAPPDATA%\nvim-data\neo-c\projects\<sha256>.json`

Each project is identified by SHA256 hash of its path.

## Examples

### Example: Single C File

```bash
# Open a simple C file
nvim hello.c
```

```vim
:CRun                             " Compile and run immediately
```

**hello.c:**
```c
#include <stdio.h>

int main(void) {
    printf("Hello, World!\n");
    return 0;
}
```

After `:CRun`, the program compiles to `/tmp/makec/a.out` and runs in a split terminal.

### Example: CMake Project

```bash
# In a CMake project directory
nvim
```

```vim
:CDetect                          " Detect CMake
:CConfig                          " Set run command: ./build/my-app
:CRunProjectRun                   " Build and run
:CTest                            " Run tests
:CGenerateCompileCommands         " Generate for clangd
:CDebug                           " Start debugging
```

### Example: Makefile Project

```bash
# In a Makefile project directory
nvim
```

```vim
:CDetect                          " Detect Makefile
:CConfig                          " Set run command: ./bin/program
:CRunProject                      " Build only
:CTest                            " Run make test
```

### Example: Multi-Build Project

```bash
# Project with both CMakeLists.txt and Makefile
nvim
```

```vim
:CDetect                          " Detects both
:CRunProject                      " Prompts for selection
                                  " Select [1] CMake
                                  " Choice is remembered
:CRunProject                      " Uses CMake (no prompt)
```

## JSON Configuration Schema

```json
{
  "version": "1.0",
  "project_path": "/path/to/project",
  "project_name": "my-project",
  "detected_at": "2026-02-15T10:30:00Z",
  "build_systems": [
    {
      "type": "cmake",
      "detected": true,
      "file": "CMakeLists.txt",
      "build_dir": "build",
      "commands": {
        "configure": "cmake -B build -S . -DCMAKE_EXPORT_COMPILE_COMMANDS=1",
        "build": "cmake --build build",
        "clean": "cmake --build build --target clean",
        "test": "ctest --test-dir build --output-on-failure"
      },
      "targets": ["all", "clean", "test"],
      "compile_commands_path": "build/compile_commands.json"
    }
  ],
  "selected_build_system": "cmake",
  "custom_commands": {
    "run": "./build/my-project"
  },
  "compiler": {
    "cc": "gcc",
    "cxx": "g++",
    "cflags": ["-Wall", "-Wextra", "-std=c11"]
  },
  "debug_config": {
    "adapter": "gdb",
    "program": "./build/my-project",
    "args": []
  }
}
```

## Dependencies

### Required

- Neovim 0.8+ (for vim.json and vim.loop)

### Optional

- [nui.nvim](https://github.com/MunifTanjim/nui.nvim) - For better UI (falls back to vim.fn.input)
- [nvim-dap](https://github.com/mfussenegger/nvim-dap) - For debugging support
- [Bear](https://github.com/rizsotto/Bear) - For compile_commands.json generation with Make

## Architecture

- **Storage Layer**: JSON persistence using `vim.json` and `stdpath('data')`
- **Detection Layer**: File-based build system detection with priority ordering
- **Execution Layer**: Async job execution using `vim.loop` (libuv)
- **UI Layer**: Interactive configuration using nui.nvim with fallback
- **Integration Layer**: LSP, DAP, and quickfix integration

## Testing

neo-c.nvim includes a comprehensive test suite using [plenary.nvim](https://github.com/nvim-lua/plenary.nvim).

### Running Tests

```bash
# Run all tests
make test

# Or directly
./tests/run_tests.sh

# Run specific test suites
make test-storage
make test-utils
make test-detect
make test-executor
```

### Test Coverage

- **storage_spec.lua** (20 tests): Config persistence, JSON serialization, project ID generation
- **utils_spec.lua** (25 tests): Project root detection, path utilities
- **detect_spec.lua** (30 tests): Build system detection, target parsing
- **executor_spec.lua** (28 tests): Async/sync execution, command handling

Total: **103 test cases** covering all core functionality.

See [tests/README.md](tests/README.md) for detailed documentation on writing and running tests.

### CI/CD

Tests run automatically on every push via GitHub Actions across multiple platforms (Ubuntu, macOS) and Neovim versions (stable, nightly).

## Related Projects

- [build.nvim](https://github.com/cyuria/build.nvim) - Build system detection
- [compiler.nvim](https://github.com/Zeioth/compiler.nvim) - Multi-language compilation
- [cmake-tools.nvim](https://github.com/Shatur/neovim-cmake) - CMake-specific tools

## License

MIT License - See LICENSE file for details

## Contributing

Contributions are welcome! Please open an issue or pull request.

## Roadmap

- [ ] Support for additional build systems (Meson, Ninja, Autotools)
- [ ] Enhanced Makefile target parsing
- [ ] CMake target extraction from CMakeLists.txt
- [ ] Build output parsing and error highlighting
- [ ] C extension for performance-critical parsing
- [ ] Project templates (like CStart from original research)
- [ ] Integration with telescope.nvim for target selection
