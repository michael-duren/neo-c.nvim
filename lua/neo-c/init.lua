local M = {}

-- Default configuration
M.config = {
  -- Default keybindings (set to false to disable all keybindings)
  keybindings = {
    enabled = true,
    -- Quick compile and run
    run = '<leader>cr',
    -- Project-level commands
    detect = '<leader>cd',
    build = '<leader>cb',
    build_and_run = '<leader>cR',
    -- Testing and debugging
    test = '<leader>ct',
    debug = '<leader>cD',
    -- LSP and configuration
    generate_compile_commands = '<leader>cl',
    config = '<leader>cc',
  },
  -- Compiler options for CRun
  compiler = {
    executable = 'gcc',
    flags = {'-Wall', '-Wextra', '-std=c11'},
    output_dir = '/tmp/makec',
  },
}

-- Setup function to configure the plugin
function M.setup(user_config)
  -- Mark that setup has been called
  M._setup_called = true

  -- Merge user config with defaults
  if user_config then
    M.config = vim.tbl_deep_extend('force', M.config, user_config)
  end

  -- Set up keybindings if enabled
  if M.config.keybindings.enabled then
    M.setup_keybindings()
  end
end

-- Setup keybindings
function M.setup_keybindings()
  local augroup = vim.api.nvim_create_augroup('NeoCKeybindings', { clear = true })

  vim.api.nvim_create_autocmd('FileType', {
    group = augroup,
    pattern = 'c',
    callback = function()
      local opts = { noremap = true, silent = true, buffer = true }
      local kb = M.config.keybindings

      if kb.run then
        vim.keymap.set('n', kb.run, ':CRun<CR>',
          vim.tbl_extend('force', opts, { desc = 'CRun: Compile and run current buffer' }))
      end

      if kb.detect then
        vim.keymap.set('n', kb.detect, ':CDetect<CR>',
          vim.tbl_extend('force', opts, { desc = 'CDetect: Detect build systems' }))
      end

      if kb.build then
        vim.keymap.set('n', kb.build, ':CRunProject<CR>',
          vim.tbl_extend('force', opts, { desc = 'CRunProject: Build project' }))
      end

      if kb.build_and_run then
        vim.keymap.set('n', kb.build_and_run, ':CRunProjectRun<CR>',
          vim.tbl_extend('force', opts, { desc = 'CRunProjectRun: Build and run project' }))
      end

      if kb.test then
        vim.keymap.set('n', kb.test, ':CTest<CR>',
          vim.tbl_extend('force', opts, { desc = 'CTest: Run tests' }))
      end

      if kb.debug then
        vim.keymap.set('n', kb.debug, ':CDebug<CR>',
          vim.tbl_extend('force', opts, { desc = 'CDebug: Start debugging' }))
      end

      if kb.generate_compile_commands then
        vim.keymap.set('n', kb.generate_compile_commands, ':CGenerateCompileCommands<CR>',
          vim.tbl_extend('force', opts, { desc = 'CGenerateCompileCommands: Generate compile_commands.json' }))
      end

      if kb.config then
        vim.keymap.set('n', kb.config, ':CConfig<CR>',
          vim.tbl_extend('force', opts, { desc = 'CConfig: Open configuration menu' }))
      end
    end,
  })
end

-- Auto-setup with defaults if user doesn't call setup()
vim.api.nvim_create_autocmd('VimEnter', {
  once = true,
  callback = function()
    -- Only auto-setup if user hasn't called setup() yet
    if not M._setup_called then
      M.setup()
    end
  end,
})

return M
