if vim.g.loaded_neo_c then return end
vim.g.loaded_neo_c = true

vim.api.nvim_create_user_command('CRun', function()
  require('neo-c.quick_run').run_current_buffer()
end, { desc = 'Compile and run current buffer to /tmp/makec/a.out' })

vim.api.nvim_create_user_command('CDetect', function()
  require('neo-c.detect').detect_build_system()
end, { desc = 'Detect all build systems in project' })

vim.api.nvim_create_user_command('CRunProject', function()
  require('neo-c.run').run_project({ run = false })
end, { desc = 'Build the entire project' })

vim.api.nvim_create_user_command('CRunProjectRun', function()
  require('neo-c.run').run_project({ run = true })
end, { desc = 'Build and run the entire project' })

vim.api.nvim_create_user_command('CTest', function()
  require('neo-c.test').run_tests()
end, { desc = 'Run project tests' })

vim.api.nvim_create_user_command('CDebug', function()
  require('neo-c.debug').setup_debug()
end, { desc = 'Start debugging session with auto-configured settings' })

vim.api.nvim_create_user_command('CGenerateCompileCommands', function()
  require('neo-c.lsp_helper').generate_compile_commands()
end, { desc = 'Generate compile_commands.json for LSP' })

vim.api.nvim_create_user_command('CConfig', function()
  require('neo-c.config_ui').show_config_form()
end, { desc = 'Configure project build and run settings interactively' })
