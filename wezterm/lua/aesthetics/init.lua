-- ~/config/wezterm/helpers.lua
local wezterm = require 'wezterm'
local nix_info = require 'nix-info'

local module = {}

function module.apply_to_config(config)
    -- Example: Set a custom color scheme
    config.color_scheme = nix_info('Tokyo Night', 'theme')
    
    -- Example: Set a custom font

    config.font_size = nix_info(8, 'font_size')
    wezterm.font_with_fallback(nix_info({}, 'fonts'))
end

return module
