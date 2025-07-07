local function disable(plugins)
  local disabled = {}
  for _, plugin in ipairs(plugins) do
    table.insert(disabled, { plugin, enabled = false })
  end
  return disabled
end

return disable({
  -- "mfussenegger/nvim-lint",
  "folke/tokyonight.nvim",
  "MeanderingProgrammer/render-markdown.nvim",
  -- snippets are wildly really annoying
  "L3MON4D3/LuaSnip",
  "nvim-neo-tree/neo-tree.nvim",
})
