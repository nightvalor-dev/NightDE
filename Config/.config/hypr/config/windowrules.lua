--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Example window rules that are useful
local suppressMaximizeRule = hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",        -- suppressMaximizeRule:set_enabled(false)
})

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

hl.window_rule({
    name  = "float-utilities",
    match = { class = "^(org.pulseaudio.pavucontrol|nm-connection-editor|blueman-manager)$" },

    float = true,
})

-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})

-- Settings-type apps open floating, centered, at a sensible size
hl.window_rule({
    name   = "float-settings-apps",
    match  = { class = "^(org.pulseaudio.pavucontrol|pavucontrol|nwg-look|qt6ct|code|brave)$" },
    float  = true,
    center = true,
    size   = "900 600",
})

-- Nautilus: full when alone, floating when the workspace already has a window
hl.window_rule({
    name   = "nautilus-float-when-busy",
    match  = { class = "^(org.gnome.Nautilus)$", workspace = "w[1-99]" },
    float  = true,
    center = true,
    size   = "1100 700",
})