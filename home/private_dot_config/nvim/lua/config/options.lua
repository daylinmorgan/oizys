vim.opt.listchars = {
  tab = "│→",
  extends = "⟩",
  precedes = "⟨",
  -- trail = "·",
  trail = "␣",
  nbsp = "␣",
}
vim.opt.foldenable = false
vim.opt.timeoutlen = 200

vim.g.autoformat = false

-- https://github.com/ziglang/zig.vim/issues/51#issuecomment-1637180522
vim.g.zig_fmt_autosave = 0

vim.lsp.set_log_level("off")

vim.api.nvim_create_user_command("Shrug", function()
  vim.api.nvim_put({ "¯\\_(ツ)_/¯" }, "", false, true)
end, {})

vim.api.nvim_create_user_command("Bootstrap", function()
  vim.cmd [[:Lazy! sync]]
  vim.cmd [[:TSUpdateSync]]
  vim.cmd [[sleep 20]]
  vim.cmd [[q]]
end, {})
