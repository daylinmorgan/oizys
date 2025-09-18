local function setDefault(t, d)
  local mt = {
    __index = function()
      return d
    end,
  }
  setmetatable(t, mt)
end

-- local function setup_lsp(name)
--   return {
--     "neovim/nvim-lspconfig",
--     opts = {
--       servers = {
--         [name] = { mason = false },
--       },
--     },
--   }
-- end


-- local function setup_lang(defs)
--   setDefault(defs, {})
--   return {
--     {
--       "nvim-treesitter/nvim-treesitter",
--       opts = function(_, opts)
--         opts.ensure_installed = vim.list_extend(opts.ensure_installed or {}, defs.treesitter)
--       end,
--     },
--     {
--       "williamboman/mason.nvim",
--       opts = function(_, opts)
--         opts.ensure_installed = vim.list_extend(opts.ensure_installed or {}, defs.mason)
--       end,
--     },
--   }
-- end


local function lsp_no_mason(server_name)
  return {
    [server_name] = {
      mason = false,
    },
  }
end

--- generated with the help of claude
local function setup_lang(defs)
  setDefault(defs, {})

  local result = {
    {
      "nvim-treesitter/nvim-treesitter",
      opts = function(_, opts)
        opts.ensure_installed = vim.list_extend(opts.ensure_installed or {}, defs.treesitter or {})
      end,
    },
    {
      "mason-org/mason.nvim",
      opts = function(_, opts)
        opts.ensure_installed = vim.list_extend(opts.ensure_installed or {}, defs.mason or {})
      end,
    },
  }

  -- Handle LSP configuration
  if defs.lsp then
    table.insert(result, {
      "neovim/nvim-lspconfig",
      opts = {
        servers = {},
      },
    })

    -- i think the result[#result] syntax is taking the "last" index of result
    for _, lsp in ipairs(defs.lsp) do
      if type(lsp) == "string" then
        -- Regular LSP server
        result[#result].opts.servers[lsp] = {mason = false}
      elseif type(lsp) == "table" and lsp[1] then
        -- LSP server with no Mason
        result[#result].opts.servers = vim.tbl_deep_extend("force", result[#result].opts.servers, lsp_no_mason(lsp[1]))
      end
    end
  end

  return result
end


local function if_exe(exe, deps)
  if vim.fn.executable(exe) == 0 then
    return {}
  end
  return deps
end

local function import_if_exe(exe, mod)
  return if_exe(exe, { { import = mod } })
end

return {
  setup_lang = setup_lang,
  if_exe = if_exe,
  import_if_exe = import_if_exe,
}
