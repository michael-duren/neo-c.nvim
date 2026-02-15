-- Filetype plugin for C files
-- This file is automatically loaded when opening C files

-- Check if user wants to disable default keymaps
if vim.g.neo_c_disable_keymaps then
  return
end

local opts = { noremap = true, silent = true, buffer = true }

-- Quick compile and run current buffer
vim.keymap.set('n', '<leader>cr', ':CRun<CR>', vim.tbl_extend('force', opts, { desc = 'CRun: Compile and run current buffer' }))

-- Project-level commands
vim.keymap.set('n', '<leader>cd', ':CDetect<CR>', vim.tbl_extend('force', opts, { desc = 'CDetect: Detect build systems' }))
vim.keymap.set('n', '<leader>cb', ':CRunProject<CR>', vim.tbl_extend('force', opts, { desc = 'CRunProject: Build project' }))
vim.keymap.set('n', '<leader>cR', ':CRunProjectRun<CR>', vim.tbl_extend('force', opts, { desc = 'CRunProjectRun: Build and run project' }))

-- Testing and debugging
vim.keymap.set('n', '<leader>ct', ':CTest<CR>', vim.tbl_extend('force', opts, { desc = 'CTest: Run tests' }))
vim.keymap.set('n', '<leader>cD', ':CDebug<CR>', vim.tbl_extend('force', opts, { desc = 'CDebug: Start debugging' }))

-- LSP and configuration
vim.keymap.set('n', '<leader>cl', ':CGenerateCompileCommands<CR>', vim.tbl_extend('force', opts, { desc = 'CGenerateCompileCommands: Generate compile_commands.json' }))
vim.keymap.set('n', '<leader>cc', ':CConfig<CR>', vim.tbl_extend('force', opts, { desc = 'CConfig: Open configuration menu' }))
