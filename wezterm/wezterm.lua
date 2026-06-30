--
local wezterm = require 'wezterm'
local config = wezterm.config_builder()
local nix_info = require("nix-info")

-- load path and nix-info
local default_save_state_dir = wezterm.home_dir ..
"/" .. ".local" .. "/" .. "share" .. "/" .. "wezterm" .. "/" .. "sessions"
local current_dir = nix_info("", "package_dir")
package.path = package.path .. ";" .. current_dir .. "/?.lua;" .. current_dir .. "/?/init.lua"


-- set leader
config.leader = { key = 'b', mods = 'CTRL', timeout_milliseconds = 1000 }

-- aesthetics
local aesthetics = require("aesthetics")
aesthetics.apply_to_config(config, { include_key_tables = true })

-- tabline
local tabline = require("tabline")
local sanitize_mode = require("tabline.components.window.mode").update

config.tab_and_split_indices_are_zero_based = false;
config.use_fancy_tab_bar = false -- need to not have fancy tab bar

tabline.setup({
    theme = config.color_scheme,
    options = {
        refresh_interval = 1000,
    },
    sections = {
        tabline_a = {
            function(window)
                if not window or not window.leader_is_active then
                    return " Default "
                end
                if window:leader_is_active() then
                    return " LDR "
                end
                return sanitize_mode(window)
            end },
        tab_active = {
            "zoomed", -- Places the zoom indicator on the far left
            "tab", -- The actual tab title/name
        },

        -- Target the inactive tab layouts
        tab_inactive = {
            "tab",
        },
    },
})

-- Plugin: keybindings
local keybindings = require("keybindings")
keybindings.apply_to_config(config, { title = "Command picker", include_key_tables = true })

-- Plugin: sessions
local sessions = require("sessions")
package.path = package.path .. ";" .. current_dir .. "/?.lua;" .. current_dir .. "/?/init.lua"
sessions.apply_to_config(config, {
    -- Set your custom session storage location here
    save_state_dir = nix_info(nil, "save_state_dir") or default_save_state_dir,

    -- Other optional settings
    auto_save_interval_s = 30,
    git_branch_warn = true,
})

return config
