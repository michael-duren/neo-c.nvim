-- Minimal init file for running tests
-- This sets up the minimal environment needed for testing

-- Add project root to runtime path
local project_root = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h')
vim.opt.rtp:append(project_root)

-- Add plenary to runtime path (adjust path as needed for your system)
local plenary_paths = {
  vim.fn.expand('~/.local/share/nvim/site/pack/packer/start/plenary.nvim'),
  vim.fn.expand('~/.local/share/nvim/lazy/plenary.nvim'),
  vim.fn.expand('~/.config/nvim/pack/vendor/start/plenary.nvim'),
}

for _, path in ipairs(plenary_paths) do
  if vim.fn.isdirectory(path) == 1 then
    vim.opt.rtp:append(path)
    break
  end
end

-- Ensure test helpers are available
vim.opt.rtp:append(project_root .. '/tests')

-- Set up basic vim options for testing
vim.opt.swapfile = false
vim.opt.hidden = true

-- Load plenary
vim.cmd('runtime! plugin/plenary.vim')
