local import_if_exe = require("util").import_if_exe
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    -- add LazyVim and import its plugins
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    -- import/override with your plugins
    -- { import = "lazyvim.plugins.extras.lang.docker" },
    -- { import = "plugins" },
    { import = "plugins.builtins" },
    { import = "plugins.disabled" },
    { import = "plugins.host" },
    { import = "plugins.ui" },
    -- { import = "plugins.misc" },

    { import = "plugins.language.misc" },
    { import = "plugins.language.lua" },
    { import = "plugins.language.markdown" },
    { import = "plugins.language.shell" },
    { import = "plugins.language.python" },
    { import = "plugins.language.tex" },

    import_if_exe("go", "plugins.language.go" ),
    import_if_exe("nim", "plugins.language.nim"),
    import_if_exe("nix" , "plugins.language.nix" ),
    -- import_if_exe("nu", "plugins.language.nu" ),
    import_if_exe("rust", "plugins.language.rust" ),
    import_if_exe("typst", "plugins.language.typst" ),
    import_if_exe("roc", "plugins.language.roc" ),
    -- import_if_exe("zig", "plugins.language.zig" ),
    --
  },
  rocks = {
    enabled = false,
  },
  defaults = {
    -- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
    -- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
    lazy = false,
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = false, -- always use the latest git commit
    -- version = "*", -- try installing the latest stable version for plugins that support semver
  },
  -- install = { colorscheme = { "tokyonight", "habamax" } },
  checker = {
    enabled = true, -- check for plugin updates periodically
    notify = false, -- notify on update
  }, -- automatically check for plugin updates
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "gzip",
        -- "matchit",
        -- "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
