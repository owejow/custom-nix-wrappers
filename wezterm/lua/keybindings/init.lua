-- keybindings for weztermc
-- many of bindings and overall structure taken from https://github.com/sei40kr/wez-tmux/blob/main/plugin/init.lua

local M = {}

local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux
local cmdpicker = require("cmdpicker")

-- increment to resize a window by in resize mode
local window_resize_increment = 10

local search_direction = {
    BACKWARD = 0,
    FORWARD = 1,
}

wezterm.GLOBAL.tmux_search_directions = {}

M.action = {
    ClearPattern = wezterm.action_callback(function(window, pane)
        wezterm.GLOBAL.tmux_search_directions[tostring(pane)] = nil
        window:perform_action(act.Multiple({
            act.CopyMode("ClearPattern"),
            act.CopyMode("AcceptPattern"),
        }), pane)
    end),

    ClearSelectionOrClearPatternOrClose = wezterm.action_callback(function(window, pane)
        local action

        if window:get_selection_text_for_pane(pane) ~= "" then
            action = act.Multiple({
                act.ClearSelection,
                act.CopyMode("ClearSelectionMode"),
            })
        elseif wezterm.GLOBAL.tmux_search_directions[tostring(pane)] then
            action = M.action.ClearPattern
        else
            action = act.CopyMode("Close")
        end

        window:perform_action(action, pane)
    end),

    NextMatch = wezterm.action_callback(function(window, pane)
        local direction = wezterm.GLOBAL.tmux_search_directions[tostring(pane)]
        local action

        if not direction then
            return
        end

        if direction == search_direction.BACKWARD then
            action = act.Multiple({
                act.CopyMode("PriorMatch"),
                act.ClearSelection,
                act.CopyMode("ClearSelectionMode"),
            })
        elseif direction == search_direction.FORWARD then
            action = act.Multiple({
                act.CopyMode("NextMatch"),
                act.ClearSelection,
                act.CopyMode("ClearSelectionMode"),
            })
        end

        window:perform_action(action, pane)
    end),

    PriorMatch = wezterm.action_callback(function(window, pane)
        local direction = wezterm.GLOBAL.tmux_search_directions[tostring(pane)]
        local action

        if not direction then
            return
        end

        if direction == search_direction.BACKWARD then
            action = act.Multiple({
                act.CopyMode("NextMatch"),
                act.ClearSelection,
                act.CopyMode("ClearSelectionMode"),
            })
        elseif direction == search_direction.FORWARD then
            action = act.Multiple({
                act.CopyMode("PriorMatch"),
                act.ClearSelection,
                act.CopyMode("ClearSelectionMode"),
            })
        end

        window:perform_action(action, pane)
    end),

    MovePaneToNewTab = wezterm.action_callback(function(_, pane)
        local tab, _ = pane:move_to_new_tab()
        tab:activate()
    end),

    RenameWorkspace = wezterm.action_callback(function(window, pane)
        window:perform_action(act.PromptInputLine({
            description = "Rename workspace: ",
            action = wezterm.action_callback(function(_, _, line)
                if not line or line == "" then
                    return
                end

                mux.rename_workspace(mux.get_active_workspace(), line)
            end),
        }), pane)
    end),

    SearchBackward = wezterm.action_callback(function(window, pane)
        wezterm.GLOBAL.tmux_search_directions[tostring(pane)] = search_direction.BACKWARD

        window:perform_action(act.Multiple({
            act.CopyMode("ClearPattern"),
            act.CopyMode("EditPattern"),
        }), pane)
    end),

    SearchForward = wezterm.action_callback(function(window, pane)
        wezterm.GLOBAL.tmux_search_directions[tostring(pane)] = search_direction.FORWARD

        window:perform_action(act.Multiple({
            act.CopyMode("ClearPattern"),
            act.CopyMode("EditPattern"),
        }), pane)
    end),

    WorkspaceSelect = wezterm.action_callback(function(window, pane)
        local active_workspace = mux.get_active_workspace()
        local workspaces = mux.get_workspace_names()
        local num_tabs_by_workspace = {}

        for _, mux_window in ipairs(mux.all_windows()) do
            local workspace = mux_window:get_workspace()
            local num_tabs = #mux_window:tabs()

            if num_tabs_by_workspace[workspace] then
                num_tabs_by_workspace[workspace] = num_tabs_by_workspace[workspace] + num_tabs
            else
                num_tabs_by_workspace[workspace] = num_tabs
            end
        end

        local choices = {
            {
                id = active_workspace,
                label = active_workspace .. ": " .. num_tabs_by_workspace[active_workspace] .. " tabs (active)",
            },
        }

        for _, workspace in ipairs(workspaces) do
            if workspace ~= active_workspace then
                table.insert(choices, {
                    id = workspace,
                    label = workspace .. ": " .. num_tabs_by_workspace[workspace] .. " tabs",
                })
            end
        end

        window:perform_action(act.InputSelector({
            title = "Select Workspace",
            choices = choices,
            action = wezterm.action_callback(function(_, _, id, _)
                if not id then
                    return
                end

                mux.set_active_workspace(id)
            end),
        }), pane)
    end),

    CreateWorkspace = wezterm.action_callback(function(window, pane)
        window:perform_action(
            act.PromptInputLine {
                description = wezterm.format {
                    { Attribute = { Intensity = 'Bold' } },
                    { Foreground = { AnsiColor = 'Fuchsia' } },
                    { Text = 'Enter name for new workspace: ' },
                },
                action = wezterm.action_callback(function(win, p, line)
                    if line and line ~= "" then
                        win:perform_action(
                            act.SwitchToWorkspace {
                                name = line,
                            },
                            p
                        )
                    end
                end),
            },
            pane
        )
    end),


    RenameCurrentTab = wezterm.action_callback(function(win, pane)
        win:perform_action(act.PromptInputLine({
            description = 'Enter new name for tab',
            action = wezterm.action_callback(function(_, _, line)
                if not line or line == "" then return end
                win:active_tab():set_title(line)
            end),
        }), pane)
    end),
}

---@param config unknown
function M.apply_to_config(config, opts)
    if not config.leader then
        config.leader = { key = "b", mods = "CTRL" }
        wezterm.log_warn("No leader key set, using default: Ctrl-b")
    end

    local keys = {
        {
            key = config.leader.key,
            mods = "LEADER|" .. config.leader.mods,
            action = act.SendKey({ key = config.leader.key, mods = config.leader.mods })
        },

        -- Workspaces
        { key = "$", mods = "LEADER|SHIFT", action = M.action.RenameWorkspace,                desc = "rename workspace" },
        { key = "w", mods = "LEADER",       action = M.action.CreateWorkspace,                desc = "create workspace" },
        { key = "s", mods = "LEADER",       action = M.action.WorkspaceSelect,                desc = "select workspace" },
        { key = "(", mods = "LEADER|SHIFT", action = act.SwitchWorkspaceRelative(-1),         desc = "go to previous workspace" },
        { key = ")", mods = "LEADER|SHIFT", action = act.SwitchWorkspaceRelative(1),          desc = "go to next workspace" },

        -- Tabs
        { key = "c", mods = "LEADER",       action = act.SpawnTab("CurrentPaneDomain"),       desc = "create new tab" },
        { key = "&", mods = "LEADER|SHIFT", action = act.CloseCurrentTab({ confirm = true }), desc = "close current tab" },
        { key = "p", mods = "LEADER",       action = act.ActivateTabRelative(-1),             desc = "go to previous tab" },
        { key = "n", mods = "LEADER",       action = act.ActivateTabRelative(1),              desc = "go to next tab" },

        -- Panes
        {
            key = "|",
            mods = "LEADER|SHIFT",
            action = act.SplitHorizontal({
                domain = "CurrentPaneDomain" }),
            desc = "split pane horizontally"
        },
        {
            key = "-",
            mods = "LEADER",
            action = act.SplitVertical({
                domain = "CurrentPaneDomain" }),
            desc = "split pane vertically"
        },
        { key = "<", mods = "LEADER|SHIFT", action = act.RotatePanes("CounterClockwise"),                                    desc = "rotate panes counter clockwise" },
        { key = ">", mods = "LEADER|SHIFT", action = act.RotatePanes("Clockwise"),                                           desc = "rotate pantes clockwise" },
        { key = "h", mods = "LEADER",       action = act.ActivatePaneDirection("Left"),                                      desc = "activate left pane" },
        { key = "j", mods = "LEADER",       action = act.ActivatePaneDirection("Down"),                                      desc = "activate below pane" },
        { key = "k", mods = "LEADER",       action = act.ActivatePaneDirection("Up"),                                        desc = "activate above pane" },
        { key = "l", mods = "LEADER",       action = act.ActivatePaneDirection("Right"),                                     desc = "activate right pane" },
        { key = "q", mods = "LEADER",       action = act.PaneSelect({ mode = "Activate" }),                                  desc = "activate pane selector" },
        { key = "z", mods = "LEADER",       action = act.TogglePaneZoomState,                                                desc = "zoom pane" },
        { key = "!", mods = "LEADER",       action = M.action.MovePaneToNewTab,                                              desc = "move pane to new tab" },
        { key = "x", mods = "LEADER",       action = act.CloseCurrentPane({ confirm = true }),                               desc = "close current pane with confirmation" },

        { key = "/", mods = "LEADER",       action = act.QuickSelect,                                                        desc = "activate quick select" },


        -- Copy Mode
        { key = "[", mods = "LEADER",       action = act.ActivateCopyMode,                                                   desc = "activate copy mode" },

        -- Resize modes
        { key = "r", mods = "LEADER",       action = act.ActivateKeyTable { name = 'resize_pane_mode', one_shot = false },   desc = "activate resize pane mode" },
        { key = "R", mods = "LEADER",       action = act.ActivateKeyTable { name = 'window_resize_mode', one_shot = false }, desc = "activate resize window mode" },

        -- Move tab mode
        {
            key = 'T',
            mods = 'LEADER|SHIFT',
            action = act.ActivateKeyTable {
                name = 'move_tab_mode',
                one_shot = false, -- Keeps the mode active for consecutive shifts
            },
            desc = "activate move tab mode"
        },

        -- Session mode
        {
            key = "s",
            mods = "LEADER|CTRL",
            action = act.EmitEvent("save_session"),
            desc = "save session"
        },
        {
            key = "l",
            mods = "LEADER|CTRL",
            action = act.EmitEvent("load_session"),
            desc = "load session"
        },
        {
            key = "r",
            mods = "LEADER|CTRL",
            action = act.EmitEvent("restore_session"),
            desc = "restore session"
        },
        {
            key = "d",
            mods = "LEADER|CTRL",
            action = act.EmitEvent("delete_session"),
            desc = "delete session"
        },
        {
            key = "e",
            mods = "LEADER|CTRL",
            action = act.EmitEvent("edit_session"),
            desc = "edit session"
        },
        {
            key = "t",
            mods = "LEADER|CTRL",
            action = act.EmitEvent("toggle_autosave"),
            desc = "toggle session"
        },
        {
            key = "f",
            mods = "LEADER|CTRL",
            action = act.EmitEvent("fork_session"),
            desc = "fork session"
        },


        -- define leader
        { key = ",", mods = "LEADER", action = M.action.RenameCurrentTab, desc = "rename current tab" },
    }

    local index_offset = 1
    for i = index_offset, 9 do
        table.insert(keys,
            { key = tostring(i), mods = "LEADER", action = act.ActivateTab(i - index_offset), desc = "Go to tab" })
    end

    local resize_pane_mode = {
        -- Resize using Vim keys (h, j, k, l)
        { key = 'h',      action = act.AdjustPaneSize { 'Left', 1 } },
        { key = 'l',      action = act.AdjustPaneSize { 'Right', 1 } },
        { key = 'k',      action = act.AdjustPaneSize { 'Up', 1 } },
        { key = 'j',      action = act.AdjustPaneSize { 'Down', 1 } },

        -- Press Enter or Escape to exit resize mode
        { key = 'Enter',  action = act.PopKeyTable },
        { key = 'Escape', action = act.PopKeyTable },
    }


    local window_resize_mode = {
        -- Increase Width
        {
            key = 'l',
            action = wezterm.action_callback(function(window)
                local d = window:get_dimensions()
                window:set_inner_size(d.pixel_width + window_resize_increment, d.pixel_height)
            end)
        },
        -- Decrease Width
        {
            key = 'h',
            action = wezterm.action_callback(function(window)
                local d = window:get_dimensions()
                window:set_inner_size(d.pixel_width - window_resize_increment, d.pixel_height)
            end)
        },
        -- Increase Height
        {
            key = 'j',
            action = wezterm.action_callback(function(window)
                local d = window:get_dimensions()
                window:set_inner_size(d.pixel_width, d.pixel_height + window_resize_increment)
            end)
        },
        -- Decrease Height
        {
            key = 'k',
            action = wezterm.action_callback(function(window)
                local d = window:get_dimensions()
                window:set_inner_size(d.pixel_width, d.pixel_height - window_resize_increment)
            end)
        },
        -- Exit Mode
        { key = 'Escape', action = act.PopKeyTable },
    }

    local copy_mode = {
        {
            key = "y",
            mods = "NONE",
            action = act.Multiple({
                act.CopyTo("Clipboard"),
                act.ClearSelection,
                act.CopyMode("ClearSelectionMode"),
            }),
            desc = "copy to clipboard in copy mode"
        },
        { key = "Escape", mods = "NONE", action = M.action.ClearSelectionOrClearPatternOrClose, desc = "escape copy mode" },
        { key = "v",      mods = "NONE", action = act.CopyMode { SetSelectionMode = "Cell" },   desc = "set cell selection copy mode" },
        { key = "V",      mods = "NONE", action = act.CopyMode { SetSelectionMode = "Line" },   desc = "set line selection copy mode" },
        { key = "v",      mods = "CTRL", action = act.CopyMode { SetSelectionMode = "Block" },  desc = "set block selection copy mode" },
        { key = "h",      mods = "NONE", action = act.CopyMode("MoveLeft"),                     desc = "move left in copy mode" },
        { key = "j",      mods = "NONE", action = act.CopyMode("MoveDown"),                     desc = "move down in copy mode" },
        { key = "k",      mods = "NONE", action = act.CopyMode("MoveUp"),                       desc = "move up in copy mode" },
        { key = "l",      mods = "NONE", action = act.CopyMode("MoveRight"),                    desc = "move right in copy mode" },
        { key = "w",      mods = "NONE", action = act.CopyMode("MoveForwardWord"),              desc = "move forward word in copy mode" },
        { key = "b",      mods = "NONE", action = act.CopyMode("MoveBackwardWord"),             desc = "move backward word in copy mode" },
        { key = "e",      mods = "NONE", action = act.CopyMode("MoveForwardWordEnd"),           desc = "move forward word end in copy mode" },
        { key = "0",      mods = "NONE", action = act.CopyMode("MoveToStartOfLine"),            desc = "move start of line in copy mode" },
        { key = "$",      mods = "NONE", action = act.CopyMode("MoveToEndOfLineContent"),       desc = "move to end of line in copy mode" },
        { key = "^",      mods = "NONE", action = act.CopyMode("MoveToStartOfLineContent"),     desc = "move to start of line in copy mode" },
        { key = "G",      mods = "NONE", action = act.CopyMode("MoveToScrollbackBottom"),       desc = "move to scrollback bottom in copy mode" },
        { key = "g",      mods = "NONE", action = act.CopyMode("MoveToScrollbackTop"),          desc = "move to scroll back top in copy mode" },
        { key = "H",      mods = "NONE", action = act.CopyMode("MoveToViewportTop"),            desc = "move to viewport top in copy mode" },
        { key = "M",      mods = "NONE", action = act.CopyMode("MoveToViewportMiddle"),         desc = "move to viewport bottom in copy mode" },
        { key = "L",      mods = "NONE", action = act.CopyMode("MoveToViewportBottom"),         desc = "move to viewport bottom in copy mode" },
        { key = "b",      mods = "CTRL", action = act.CopyMode("PageUp"),                       desc = "move page up in copy mode" },
        { key = "u",      mods = "CTRL", action = act.CopyMode { MoveByPage = -0.5 },           desc = "move by 1/2 page up in copy mode" },
        { key = "f",      mods = "CTRL", action = act.CopyMode("PageDown"),                     desc = "move page down in copy mode" },
        { key = "d",      mods = "CTRL", action = act.CopyMode { MoveByPage = 0.5 },            desc = "move by 1/2 page down in copy mode" },

        { key = "/",      mods = "NONE", action = M.action.SearchForward,                       desc = "search forward in copy mode" },
        { key = "?",      mods = "NONE", action = M.action.SearchBackward,                      desc = "search backward in copy mode" },
        { key = "n",      mods = "NONE", action = M.action.NextMatch,                           desc = "find next match in copy mode" },
        { key = "N",      mods = "NONE", action = M.action.PriorMatch,                          desc = "find previous match in copy mode" },
    }

    local search_mode = {
        {
            key = "Enter",
            action = act.Multiple({
                act.CopyMode("AcceptPattern"),
                act.ClearSelection,
                act.CopyMode("ClearSelectionMode"),
            }),
        },
        { key = "Escape", action = M.action.ClearPattern },
    }

    local move_tab_mode = {
        -- Move tab left with 'h'
        { key = 'h',      action = act.MoveTabRelative(-1) },
        -- Move tab right with 'l'
        { key = 'l',      action = act.MoveTabRelative(1) },

        -- Exit the mode safely
        { key = 'Escape', action = act.PopKeyTable },
        { key = 'Enter',  action = act.PopKeyTable },
    }



    -- Apply to your config
    config.key_tables = config.key_tables or {}

    -- overrites all that are defined here
    config.key_tables.copy_mode = copy_mode
    config.key_tables.search_mode = search_mode
    config.key_tables.resize_pane_mode = resize_pane_mode
    config.key_tables.window_resize_mode = window_resize_mode
    config.key_tables.move_tab_mode = move_tab_mode

    cmdpicker.add_keys(config, keys)
    cmdpicker.apply_to_config(config, opts)
end

return M
