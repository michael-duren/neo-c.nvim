local M = {}

local function get_project_templates()
  return {
    { name = 'simple', description = 'Simple C project with single main.c file' },
    { name = 'cmake', description = 'CMake-based project with modern structure' },
    { name = 'makefile', description = 'Makefile-based project with src/ and include/ directories' },
  }
end

local function create_simple_project(project_path, project_name)
  -- Create main.c
  local main_content = string.format([[#include <stdio.h>

int main(void) {
    printf("Hello from %s!\n");
    return 0;
}
]], project_name)

  local main_path = project_path .. '/main.c'
  local file = io.open(main_path, 'w')
  if not file then
    vim.notify('Failed to create main.c', vim.log.levels.ERROR)
    return false
  end
  file:write(main_content)
  file:close()

  -- Create README.md
  local readme_content = string.format([[# %s

A simple C project created with neo-c.nvim

## Building

```bash
gcc -Wall -Wextra -std=c11 main.c -o %s
```

## Running

```bash
./%s
```
]], project_name, project_name, project_name)

  local readme_path = project_path .. '/README.md'
  file = io.open(readme_path, 'w')
  if file then
    file:write(readme_content)
    file:close()
  end

  -- Create .gitignore
  local gitignore_content = string.format([[# Compiled executable
%s

# Object files
*.o
*.obj

# Editor files
*.swp
*.swo
*~
.DS_Store
]], project_name)

  local gitignore_path = project_path .. '/.gitignore'
  file = io.open(gitignore_path, 'w')
  if file then
    file:write(gitignore_content)
    file:close()
  end

  return true
end

local function create_cmake_project(project_path, project_name)
  -- Create directory structure
  vim.fn.mkdir(project_path .. '/src', 'p')
  vim.fn.mkdir(project_path .. '/include', 'p')

  -- Create CMakeLists.txt
  local cmake_content = string.format([[cmake_minimum_required(VERSION 3.10)
project(%s VERSION 1.0 LANGUAGES C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

include_directories(include)

add_executable(%s
    src/main.c
)

target_compile_options(%s PRIVATE
    -Wall
    -Wextra
    -Wpedantic
)

# Optional: Enable testing
enable_testing()
add_subdirectory(tests)
]], project_name, project_name, project_name)

  local cmake_path = project_path .. '/CMakeLists.txt'
  local file = io.open(cmake_path, 'w')
  if not file then
    vim.notify('Failed to create CMakeLists.txt', vim.log.levels.ERROR)
    return false
  end
  file:write(cmake_content)
  file:close()

  -- Create src/main.c
  local main_content = string.format([[#include <stdio.h>

int main(void) {
    printf("Hello from %s!\n");
    return 0;
}
]], project_name)

  local main_path = project_path .. '/src/main.c'
  file = io.open(main_path, 'w')
  if file then
    file:write(main_content)
    file:close()
  end

  -- Create tests directory
  vim.fn.mkdir(project_path .. '/tests', 'p')

  -- Create tests/CMakeLists.txt
  local test_cmake = [[add_executable(test_main test_main.c)
target_link_libraries(test_main)

add_test(NAME test_main COMMAND test_main)
]]

  local test_cmake_path = project_path .. '/tests/CMakeLists.txt'
  file = io.open(test_cmake_path, 'w')
  if file then
    file:write(test_cmake)
    file:close()
  end

  -- Create basic test file
  local test_content = [[#include <stdio.h>
#include <assert.h>

int main(void) {
    // Add your tests here
    printf("All tests passed!\n");
    return 0;
}
]]

  local test_path = project_path .. '/tests/test_main.c'
  file = io.open(test_path, 'w')
  if file then
    file:write(test_content)
    file:close()
  end

  -- Create README.md
  local readme_content = string.format([[# %s

A CMake-based C project created with neo-c.nvim

## Building

```bash
cmake -B build -S .
cmake --build build
```

## Running

```bash
./build/%s
```

## Testing

```bash
ctest --test-dir build
```
]], project_name, project_name)

  local readme_path = project_path .. '/README.md'
  file = io.open(readme_path, 'w')
  if file then
    file:write(readme_content)
    file:close()
  end

  -- Create .gitignore
  local gitignore_content = [[# Build directory
build/
CMakeFiles/
CMakeCache.txt
cmake_install.cmake
compile_commands.json

# Compiled executable (adjust based on project name)
*.out

# Object files
*.o
*.obj

# Editor files
*.swp
*.swo
*~
.DS_Store
]]

  local gitignore_path = project_path .. '/.gitignore'
  file = io.open(gitignore_path, 'w')
  if file then
    file:write(gitignore_content)
    file:close()
  end

  return true
end

local function create_makefile_project(project_path, project_name)
  -- Create directory structure
  vim.fn.mkdir(project_path .. '/src', 'p')
  vim.fn.mkdir(project_path .. '/include', 'p')
  vim.fn.mkdir(project_path .. '/obj', 'p')
  vim.fn.mkdir(project_path .. '/bin', 'p')

  -- Create Makefile
  local makefile_content = string.format([[CC = gcc
CFLAGS = -Wall -Wextra -Wpedantic -std=c11 -Iinclude
LDFLAGS =

SRC_DIR = src
OBJ_DIR = obj
BIN_DIR = bin
INC_DIR = include

TARGET = $(BIN_DIR)/%s

SRCS = $(wildcard $(SRC_DIR)/*.c)
OBJS = $(SRCS:$(SRC_DIR)/%%.c=$(OBJ_DIR)/%%.o)

.PHONY: all clean run test

all: $(TARGET)

$(TARGET): $(OBJS) | $(BIN_DIR)
	$(CC) $(LDFLAGS) $^ -o $@

$(OBJ_DIR)/%%.o: $(SRC_DIR)/%%.c | $(OBJ_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BIN_DIR) $(OBJ_DIR):
	mkdir -p $@

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)

run: $(TARGET)
	./$(TARGET)

test:
	@echo "No tests configured yet"
]], project_name)

  local makefile_path = project_path .. '/Makefile'
  local file = io.open(makefile_path, 'w')
  if not file then
    vim.notify('Failed to create Makefile', vim.log.levels.ERROR)
    return false
  end
  file:write(makefile_content)
  file:close()

  -- Create src/main.c
  local main_content = string.format([[#include <stdio.h>

int main(void) {
    printf("Hello from %s!\n");
    return 0;
}
]], project_name)

  local main_path = project_path .. '/src/main.c'
  file = io.open(main_path, 'w')
  if file then
    file:write(main_content)
    file:close()
  end

  -- Create README.md
  local readme_content = string.format([[# %s

A Makefile-based C project created with neo-c.nvim

## Building

```bash
make
```

## Running

```bash
make run
# or
./bin/%s
```

## Cleaning

```bash
make clean
```
]], project_name, project_name)

  local readme_path = project_path .. '/README.md'
  file = io.open(readme_path, 'w')
  if file then
    file:write(readme_content)
    file:close()
  end

  -- Create .gitignore
  local gitignore_content = [[# Build artifacts
bin/
obj/
*.o
*.obj

# Compiled executable
*.out

# Editor files
*.swp
*.swo
*~
.DS_Store
]]

  local gitignore_path = project_path .. '/.gitignore'
  file = io.open(gitignore_path, 'w')
  if file then
    file:write(gitignore_content)
    file:close()
  end

  return true
end

function M.create_new_project()
  -- Get project name
  vim.ui.input({ prompt = 'Project name: ' }, function(project_name)
    if not project_name or project_name == '' then
      vim.notify('Project creation cancelled', vim.log.levels.INFO)
      return
    end

    -- Get project location
    vim.ui.input({
      prompt = 'Project location (default: current directory): ',
      default = vim.fn.getcwd()
    }, function(base_path)
      if not base_path or base_path == '' then
        vim.notify('Project creation cancelled', vim.log.levels.INFO)
        return
      end

      local project_path = base_path .. '/' .. project_name

      -- Check if directory already exists
      if vim.fn.isdirectory(project_path) == 1 then
        vim.notify('Directory ' .. project_path .. ' already exists!', vim.log.levels.ERROR)
        return
      end

      -- Select template
      local templates = get_project_templates()
      local template_names = {}
      for i, template in ipairs(templates) do
        table.insert(template_names, string.format('[%d] %s - %s', i, template.name, template.description))
      end

      vim.ui.select(template_names, {
        prompt = 'Select project template:',
      }, function(_, idx)
        if not idx then
          vim.notify('Project creation cancelled', vim.log.levels.INFO)
          return
        end

        local selected_template = templates[idx].name

        -- Create project directory
        vim.fn.mkdir(project_path, 'p')

        local success = false
        if selected_template == 'simple' then
          success = create_simple_project(project_path, project_name)
        elseif selected_template == 'cmake' then
          success = create_cmake_project(project_path, project_name)
        elseif selected_template == 'makefile' then
          success = create_makefile_project(project_path, project_name)
        end

        if success then
          vim.notify(string.format('Created %s project at %s', selected_template, project_path), vim.log.levels.INFO)

          -- Ask if user wants to open the project
          vim.ui.select({ 'Yes', 'No' }, {
            prompt = 'Open project now?',
          }, function(choice)
            if choice == 'Yes' then
              vim.cmd('cd ' .. vim.fn.fnameescape(project_path))
              if selected_template == 'simple' then
                vim.cmd('edit main.c')
              else
                vim.cmd('edit src/main.c')
              end
            end
          end)
        else
          vim.notify('Failed to create project', vim.log.levels.ERROR)
        end
      end)
    end)
  end)
end

return M
