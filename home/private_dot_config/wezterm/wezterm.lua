local wezterm = require("wezterm")

local padding = 10

local config = wezterm.config_builder()

config.check_for_updates = false
config.window_padding = {
	left = padding,
	right = padding,
	top = padding,
	bottom = padding,
}

-- https://github.com/NixOS/nixpkgs/issues/336069
-- https://github.com/wez/wezterm/issues/5990
-- why though front_end ?
-- OpenGL on nix?
config.front_end = "WebGpu"

config.color_scheme = "Catppuccin Mocha"
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = true
config.font = wezterm.font("MonoLisa Nerd Font")
-- config.disable_default_key_bindings = true
-- config.bold_brightens_ansi_colors = true
-- config.window_background_opacity = .9
-- config.text_background_opacity = .9

config.hyperlink_rules = wezterm.default_hyperlink_rules()
config.hide_mouse_cursor_when_typing = false
config.adjust_window_size_when_changing_font_size = false
config.initial_cols = 80
config.enable_wayland = false
config.keys = require("keys")
config.default_gui_startup_args = { "start", "--always-new-process" }
config.warn_about_missing_glyphs = false

return config
