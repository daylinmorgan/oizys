-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
  pattern = { "Knitfile" },
  command = "set syntax=lua",
})

vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
  pattern = { "*.md" },
  command = "set conceallevel=0",
})

-- make .roc files have the correct filetype
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
  pattern = { "*.roc" },
  command = "set filetype=roc",
})

-- if cspell config found then disable buitlin spell check
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile", }, {
  pattern = "*",
  callback = function()
    -- this isn't exhuastive and won't work if config is contained in a package.json
    local cspell_files = {
      "cspell.json",
      ".cspell.json",
      "cSpell.json",
      ".cSpell.json",
      ".cspell.config.json",
      "cspell.config.yaml",
      ".cspell.config.yaml",
    }
    for _, file in ipairs(cspell_files) do
      if vim.fn.findfile(file, ".;") ~= "" then
        vim.opt_local.spell = false
        break
      end
    end
  end,
})

-- Define the group for our autocmds set the filetype to 'systemd'
-- for common Quadlet file extensions
vim.api.nvim_create_augroup("FileTypeQuadlet", { clear = true })
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  pattern = {
    "*.container",
    "*.pod",
    "*.volume",
    "*.network",
    "*.build",
    "*.kube"
  },
  command = "set filetype=systemd",
  group = "FileTypeQuadlet",
})
