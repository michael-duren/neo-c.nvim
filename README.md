# neo-c.nvim

A comprehensive Neovim plugin for C project management with build system detection, execution, testing, and debugging capabilities.

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Commands](#commands)
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
- [Storage](#storage)
- [Examples](#examples)
- [JSON Configuration Schema](#json-configuration-schema)
- [Dependencies](#dependencies)
- [Architecture](#architecture)
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
  dependencies = {
    'MunifTanjim/nui.nvim',  -- Optional: for better UI
    'mfussenegger/nvim-dap',  -- Optional: for debugging support
  },
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'michael-duren/neo-c.nvim',
  requires = {
    'MunifTanjim/nui.nvim',  -- Optional: for better UI
    'mfussenegger/nvim-dap',  -- Optional: for debugging support
  }
}
```

## Commands

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

The plugin works out-of-the-box with sensible defaults. No Lua configuration is required.

For projects with custom requirements, use `:CConfig` to adjust settings interactively.

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
