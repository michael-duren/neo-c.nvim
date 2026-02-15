if vim.g.loaded_neo_c then return end
vim.g.loaded_neo_c = true

vim.api.nvim_create_user_command('CDetect', function()
  require('neo-c.detect').detect_build_system()
end, { desc = 'Detect all build systems in project' })

-- Additional commands will be added in later phases
