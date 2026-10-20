---------------------
---- MY PROGRAMS ----
---------------------

-- Set programs that you use
local terminal = "kitty"
local fileManager = "nautilus"
local menu = "rofi -show drun"
local editor = "code"
local browser = "flatpak run com.brave.Browser --password-store=basic"
local postman = "flatpak run com.getpostman.Postman"
local pgadmin = "flatpak run org.pgadmin.pgadmin4"

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER" -- Sets "Windows" key as main modifier
local closeWindowBind = hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + G", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("pidof hyprlock || hyprlock -c ~/.config/hypr/hyprlock/hyprlock.conf"))

hl.define_submap("eww-panel", function()
	hl.bind("Escape", hl.dsp.exec_cmd("~/.config/eww/scripts/panels.sh close"))
end)

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
hl.bind(mainMod .. " + K", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(editor))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(postman))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(pgadmin))

-- closeWindowBind:set_enabled(false)
-- hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
-- hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
-- hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
-- hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))    -- dwindle only

-- maximize and maximize windows
hl.bind(mainMod .. " + up", function()
	local win = hl.get_active_window()
	if not win then
		return
	end

	-- leave real fullscreen/maximized if the app was in it
	if win.fullscreen ~= 0 then
		hl.dispatch(hl.dsp.window.fullscreen({ action = "unset" }))
	end

	-- tiled + alone on the workspace = fills the screen with your gaps
	if win.floating then
		hl.dispatch(hl.dsp.window.float({ action = "unset" }))
	end
end)

hl.bind(mainMod .. " + down", function()
	local win = hl.get_active_window()
	if not win then
		return
	end

	-- leave maximized/fullscreen first
	if win.fullscreen ~= 0 then
		hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "unset" }))
	end

	-- make it float
	if not win.floating then
		hl.dispatch(hl.dsp.window.float({ action = "set" }))
	end

	-- set the size and center it
	hl.dispatch(hl.dsp.window.resize({ x = 900, y = 600, exact = true }))
	hl.dispatch(hl.dsp.window.center({}))
end)

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ locked = true, repeating = true }
)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- Screenshots (saved to ~/Pictures/Screenshots + copied to clipboard)
hl.bind("Print",         hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh area"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh full"))
hl.bind("ALT + Print",   hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh window"))