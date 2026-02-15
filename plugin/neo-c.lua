if vim.g.loaded_neo_c then return end
vim.g.loaded_neo_c = true

vim.api.nvim_create_user_command('CDetect', function()
  require('neo-c.detect').detect_build_system()
end, { desc = 'Detect all build systems in project' })

vim.api.nvim_create_user_command('CRunProject', function()
  require('neo-c.run').run_project({ run = false })
end, { desc = 'Build the entire project' })

vim.api.nvim_create_user_command('CRunProjectRun', function()
  require('neo-c.run').run_project({ run = true })
end, { desc = 'Build and run the entire project' })

-- Additional commands will be added in later phases
