local wezterm = require("wezterm")
local act = wezterm.action

return {
	-- { key = "C", mods = "CTRL|SHIFT", action = act.CopyTo("ClipboardAndPrimarySelection") },

	{ key = "-", mods = "CTRL", action = "DecreaseFontSize" },
	{ key = "=", mods = "CTRL", action = "IncreaseFontSize" },

	-- { key = "Space", mods = "CTRL|SHIFT", action = "QuickSelect" },
	{ key = "Space", mods = "CTRL|SHIFT", action = "ActivateCopyMode" },
}
