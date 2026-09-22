# NightDE Theming & Desktop Config Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the 7-component Hyprland desktop config (Hyprland, Waybar, Rofi, Dunst, Kitty, Hyprlock, Hypridle) and the `Themes/` base+overlay architecture, shipping one complete theme ("obsidian").

**Architecture:** Fixed, structural base configs live in `Config/.config/<app>/`. Each app's colors live in a small overlay file under `Themes/obsidian/<app>/` that the base config includes via its native include mechanism (`source =` for Hyprland/Hyprlock, `@import` for Waybar CSS, `@theme` for Rofi, `include` for Kitty). Dunst is the one exception — its INI format has no include directive, so its complete themed config lives directly in `Themes/obsidian/dunst/dunstrc`. `Themes/active` is a symlink to `obsidian/`. No `install.sh`/`deploy.sh` wiring, no theme-switch script, no GTK/icon/cursor fetching — all explicitly deferred.

**Tech Stack:** Static config files only — Hyprland's hyprlang DSL, GTK CSS (Waybar), rasi (Rofi), dunstrc INI, kitty.conf. No new shell code in this plan.

**Spec:** `docs/superpowers/specs/2026-09-22-nightde-theming-and-desktop-config-design.md`

## Global Constraints

- Fedora only, this phase — no distro branching needed since nothing here touches package management.
- Base+overlay split per app, **except Dunst**, which ships as one complete file in `Themes/obsidian/dunst/dunstrc` (dunstrc has no native include syntax).
- Hypridle gets no theme file — nothing visual to theme.
- `Themes/active` → `obsidian/` via a plain relative symlink.
- Obsidian palette (all apps draw from this table):
  | Role | Value |
  |---|---|
  | Background | `#121214` |
  | Background alt | `#1c1c20` |
  | Foreground | `#E4E4E7` |
  | Foreground muted | `#8B8B93` |
  | Accent | `#6E8CAE` |
  | Border/inactive | `#ffffff1A` (10% white) / `rgba(255,255,255,0.10)` in CSS |
  | Urgent/error | `#B57575` |
- No `install.sh`/`deploy.sh` changes, no theme-switch script, no GTK/icon/cursor/font installation — `theme.env` only declares intent as data.
- `starship` is untouched throughout — not in scope.
- Existing `Config/.config/kitty/kitty.conf` and `Config/.config/rofi/config.rasi` already use the include mechanism this plan extends elsewhere (`include theme.conf`, `@theme "~/.config/rofi/themes/theme.rasi"`) — neither needs structural changes, only their theme files move and get restyled.

---

### Task 1: Scaffold `Themes/` directory, `theme.env`, and the active symlink

**Files:**
- Create: `Themes/obsidian/theme.env`
- Create: `Themes/active` (symlink → `obsidian`)

**Interfaces:**
- Produces: `Themes/obsidian/` as the directory every later task adds files under; `Themes/active` as the stable active-theme pointer later tasks and the spec's manual-verification step resolve against.

- [ ] **Step 1: Create the theme directory and `theme.env`**

```bash
mkdir -p Themes/obsidian
cat > Themes/obsidian/theme.env <<'EOF'
GTK_THEME="obsidian-gtk"
ICON_THEME="Tela-circle-dark"
CURSOR_THEME="Bibata-Modern-Classic"
CURSOR_SIZE=24
FONT="CaskaydiaCove Nerd Font"
FONT_SIZE=10
EOF
```

- [ ] **Step 2: Verify `theme.env` content**

Run: `grep -c '=' Themes/obsidian/theme.env`
Expected: `6`

- [ ] **Step 3: Create the active symlink**

```bash
cd Themes && ln -s obsidian active && cd ..
```

- [ ] **Step 4: Verify the symlink**

Run: `readlink Themes/active`
Expected: `obsidian`

- [ ] **Step 5: Commit**

```bash
git add -f Themes/obsidian/theme.env Themes/active
git commit -m "feat: scaffold Themes/ directory with obsidian theme.env and active symlink"
```

---

### Task 2: Migrate and restyle the Kitty theme

**Files:**
- Create: `Themes/obsidian/kitty/theme.conf`
- Delete: `Config/.config/kitty/theme.conf` (via `git mv`)
- Verify only: `Config/.config/kitty/kitty.conf` (no changes — already does `include theme.conf`)

**Interfaces:**
- Consumes: nothing from Task 1 directly — independent of `theme.env`/`active`.
- Produces: `Themes/obsidian/kitty/theme.conf`, the file a future deploy phase symlinks to `~/.config/kitty/theme.conf`.

- [ ] **Step 1: Move the file**

```bash
mkdir -p Themes/obsidian/kitty
git mv Config/.config/kitty/theme.conf Themes/obsidian/kitty/theme.conf
```

- [ ] **Step 2: Replace its content with the obsidian palette**

Overwrite `Themes/obsidian/kitty/theme.conf`:

```
## name:     Obsidian
## blurb:    Muted, neutral dark palette for NightDE

foreground              #E4E4E7
background              #121214
selection_foreground    #121214
selection_background    #6E8CAE

cursor                  #E4E4E7
cursor_text_color       #121214

url_color               #6E8CAE

active_border_color     #6E8CAE
inactive_border_color   #1c1c20
bell_border_color       #B57575

wayland_titlebar_color system
macos_titlebar_color system

active_tab_foreground   #121214
active_tab_background   #6E8CAE
inactive_tab_foreground #8B8B93
inactive_tab_background #1c1c20
tab_bar_background      #121214

mark1_foreground #121214
mark1_background #6E8CAE
mark2_foreground #121214
mark2_background #7FA8A3
mark3_foreground #121214
mark3_background #86A386

# black
color0 #1c1c20
color8 #3a3a40

# red
color1 #B57575
color9 #C98E8E

# green
color2  #86A386
color10 #9BB89B

# yellow
color3  #B8A97A
color11 #CDBE8F

# blue
color4  #6E8CAE
color12 #85A0C2

# magenta
color5  #A587A8
color13 #B99EBC

# cyan
color6  #7FA8A3
color14 #94BDB8

# white
color7  #E4E4E7
color15 #F2F2F4
```

- [ ] **Step 3: Verify migration and content**

Run:
```bash
test ! -e Config/.config/kitty/theme.conf && echo "old path gone"
grep -q 'include theme.conf' Config/.config/kitty/kitty.conf && echo "base still includes theme.conf"
grep -q 'background.*#121214' Themes/obsidian/kitty/theme.conf && echo "obsidian background present"
```
Expected: all three echo lines print.

- [ ] **Step 4: Commit**

```bash
git add Config/.config/kitty/theme.conf Themes/obsidian/kitty/theme.conf
git commit -m "feat: migrate kitty theme to Themes/obsidian, restyle to obsidian palette"
```

---

### Task 3: Migrate and restyle the Rofi theme

**Files:**
- Create: `Themes/obsidian/rofi/theme.rasi`
- Delete: `Config/.config/rofi/themes/theme.rasi` (via `git mv`)
- Verify only: `Config/.config/rofi/config.rasi` (no changes — already does `@theme "~/.config/rofi/themes/theme.rasi"`)

**Interfaces:**
- Consumes: nothing from Task 1 or Task 2 — independent.
- Produces: `Themes/obsidian/rofi/theme.rasi`, the file a future deploy phase symlinks to `~/.config/rofi/themes/theme.rasi`.

- [ ] **Step 1: Move the file**

```bash
mkdir -p Themes/obsidian/rofi
git mv Config/.config/rofi/themes/theme.rasi Themes/obsidian/rofi/theme.rasi
```

- [ ] **Step 2: Replace its content with the obsidian palette**

Overwrite `Themes/obsidian/rofi/theme.rasi`:

```
/* Themes/obsidian/rofi/theme.rasi — included via ~/.config/rofi/themes/theme.rasi */

* {
    bg:      #121214E6;   /* dark, semi-transparent for blur to show through */
    bg-alt:  #1c1c20CC;
    fg:      #E4E4E7;
    accent:  #6E8CAEF2;
    border:  #ffffff1A;

    background-color: transparent;
    text-color:        @fg;
}

window {
    width:              600px;
    height:             500px;
    background-color:   @bg;
    border:             1px;
    border-color:       @border;
    border-radius:      12px;
    padding:            12px;
}

inputbar {
    background-color:   @bg-alt;
    border-radius:       8px;
    padding:            10px 12px;
    children:            [ entry ];
}

entry {
    placeholder:        "Search…";
    placeholder-color:  #8B8B93;
}

listview {
    background-color:   transparent;
    margin:              10px 0 0;
    lines:               8;
    spacing:             4px;
}

element {
    padding:        8px 10px;
    border-radius:  8px;
}

element selected {
    background-color:  @accent;
    text-color:         @fg;
}
```

- [ ] **Step 3: Verify migration and content**

Run:
```bash
test ! -e Config/.config/rofi/themes/theme.rasi && echo "old path gone"
grep -q '@theme "~/.config/rofi/themes/theme.rasi"' Config/.config/rofi/config.rasi && echo "base still references theme"
grep -q '#121214E6' Themes/obsidian/rofi/theme.rasi && echo "obsidian background present"
```
Expected: all three echo lines print.

- [ ] **Step 4: Commit**

```bash
git add Config/.config/rofi/themes/theme.rasi Themes/obsidian/rofi/theme.rasi
git commit -m "feat: migrate rofi theme to Themes/obsidian, restyle to obsidian palette"
```

---

### Task 4: Hyprland base config + obsidian color overlay

**Files:**
- Create: `Config/.config/hypr/hyprland.conf`
- Create: `Themes/obsidian/hypr/colors.conf`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: `Config/.config/hypr/hyprland.conf` sourcing `$accent`/`$border` from `Themes/obsidian/hypr/colors.conf` — a future deploy phase symlinks the latter to `~/.config/hypr/colors.conf`.

- [ ] **Step 1: Write the color overlay**

Create `Themes/obsidian/hypr/colors.conf`:

```
$background = rgb(121214)
$backgroundAlt = rgb(1c1c20)
$foreground = rgb(E4E4E7)
$foregroundMuted = rgb(8B8B93)
$accent = rgb(6E8CAE)
$border = rgba(ffffff1A)
$urgent = rgb(B57575)
```

- [ ] **Step 2: Write the base Hyprland config**

Create `Config/.config/hypr/hyprland.conf`:

```
source = ~/.config/hypr/colors.conf

monitor=,preferred,auto,1

env = XCURSOR_SIZE,24

input {
    kb_layout = us
    follow_mouse = 1
    touchpad {
        natural_scroll = false
    }
}

general {
    gaps_in = 4
    gaps_out = 8
    border_size = 2
    col.active_border = $accent
    col.inactive_border = $border
    layout = dwindle
}

decoration {
    rounding = 8
    blur {
        enabled = true
        size = 4
        passes = 2
    }
    drop_shadow = true
    shadow_range = 12
    col.shadow = rgba(00000066)
}

animations {
    enabled = true
    bezier = smooth, 0.25, 0.1, 0.25, 1.0
    animation = windows, 1, 4, smooth
    animation = border, 1, 4, smooth
    animation = fade, 1, 4, smooth
    animation = workspaces, 1, 4, smooth
}

dwindle {
    pseudotile = true
    preserve_split = true
}

master {
    new_status = master
}

gestures {
    workspace_swipe = true
}

misc {
    disable_hyprland_logo = true
    disable_splash_rendering = true
}

$mod = SUPER
$terminal = kitty
$launcher = rofi -show drun

bind = $mod, Return, exec, $terminal
bind = $mod, D, exec, $launcher
bind = $mod, Q, killactive
bind = $mod SHIFT, E, exit
bind = $mod, V, togglefloating
bind = $mod, F, fullscreen
bind = $mod, L, exec, hyprlock

bind = $mod, 1, workspace, 1
bind = $mod, 2, workspace, 2
bind = $mod, 3, workspace, 3
bind = $mod, 4, workspace, 4
bind = $mod, 5, workspace, 5
bind = $mod SHIFT, 1, movetoworkspace, 1
bind = $mod SHIFT, 2, movetoworkspace, 2
bind = $mod SHIFT, 3, movetoworkspace, 3
bind = $mod SHIFT, 4, movetoworkspace, 4
bind = $mod SHIFT, 5, movetoworkspace, 5

bind = $mod, left, movefocus, l
bind = $mod, right, movefocus, r
bind = $mod, up, movefocus, u
bind = $mod, down, movefocus, d

bindm = $mod, mouse:272, movewindow
bindm = $mod, mouse:273, resizewindow

exec-once = waybar
exec-once = dunst
exec-once = hypridle
```

- [ ] **Step 3: Verify**

Run:
```bash
grep -q 'source = ~/.config/hypr/colors.conf' Config/.config/hypr/hyprland.conf && echo "source line present"
grep -q 'col.active_border = \$accent' Config/.config/hypr/hyprland.conf && echo "active border wired"
grep -q '\$accent = rgb(6E8CAE)' Themes/obsidian/hypr/colors.conf && echo "accent color present"
```
Expected: all three echo lines print.

- [ ] **Step 4: Commit**

```bash
git add Config/.config/hypr/hyprland.conf Themes/obsidian/hypr/colors.conf
git commit -m "feat: add Hyprland base config and obsidian color overlay"
```

---

### Task 5: Hypridle + Hyprlock base configs and obsidian overlay

**Files:**
- Create: `Config/.config/hypridle/hypridle.conf`
- Create: `Config/.config/hyprlock/hyprlock.conf`
- Create: `Themes/obsidian/hyprlock/colors.conf`

**Interfaces:**
- Consumes: `hyprlock` binary invoked by Task 4's `bind = $mod, L, exec, hyprlock` and by `hypridle.conf`'s `lock_cmd`.
- Produces: `Config/.config/hypridle/hypridle.conf` (no theme file — behavior only), `Config/.config/hyprlock/hyprlock.conf` sourcing `Themes/obsidian/hyprlock/colors.conf`.

- [ ] **Step 1: Write hypridle.conf**

Create `Config/.config/hypridle/hypridle.conf`:

```
general {
    lock_cmd = pidof hyprlock || hyprlock
    before_sleep_cmd = loginctl lock-session
    after_sleep_cmd = hyprctl dispatch dpms on
}

listener {
    timeout = 300
    on-timeout = loginctl lock-session
}

listener {
    timeout = 330
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on
}

listener {
    timeout = 600
    on-timeout = systemctl suspend
}
```

- [ ] **Step 2: Write the Hyprlock color overlay**

Create `Themes/obsidian/hyprlock/colors.conf`:

```
$background = rgb(121214)
$backgroundAlt = rgb(1c1c20)
$foreground = rgb(E4E4E7)
$accent = rgb(6E8CAE)
```

- [ ] **Step 3: Write the base Hyprlock config**

Create `Config/.config/hyprlock/hyprlock.conf`:

```
source = ~/.config/hyprlock/colors.conf

general {
    disable_loading_bar = true
    hide_cursor = true
}

background {
    monitor =
    color = $background
    blur_passes = 2
    blur_size = 4
}

input-field {
    monitor =
    size = 250, 50
    outline_thickness = 2
    dots_center = true
    outer_color = $accent
    inner_color = $backgroundAlt
    font_color = $foreground
    placeholder_text = <span foreground="##8B8B93">Password...</span>
    shadow_passes = 0
    position = 0, -20
    halign = center
    valign = center
}

label {
    monitor =
    text = cmd[update:1000] echo "$(date +"%H:%M")"
    color = $foreground
    font_size = 64
    position = 0, 150
    halign = center
    valign = center
}
```

- [ ] **Step 4: Verify**

Run:
```bash
grep -q 'lock_cmd = pidof hyprlock' Config/.config/hypridle/hypridle.conf && echo "hypridle lock_cmd present"
grep -q 'source = ~/.config/hyprlock/colors.conf' Config/.config/hyprlock/hyprlock.conf && echo "hyprlock source line present"
grep -q '\$accent = rgb(6E8CAE)' Themes/obsidian/hyprlock/colors.conf && echo "hyprlock accent present"
```
Expected: all three echo lines print.

- [ ] **Step 5: Commit**

```bash
git add Config/.config/hypridle/hypridle.conf Config/.config/hyprlock/hyprlock.conf Themes/obsidian/hyprlock/colors.conf
git commit -m "feat: add hypridle config and Hyprlock base config with obsidian overlay"
```

---

### Task 6: Waybar base config + obsidian color overlay

**Files:**
- Create: `Config/.config/waybar/config.jsonc`
- Create: `Config/.config/waybar/style.css`
- Create: `Themes/obsidian/waybar/colors.css`

**Interfaces:**
- Consumes: nothing from earlier tasks (Waybar is launched by Task 4's `exec-once = waybar`).
- Produces: `Config/.config/waybar/style.css` importing `Themes/obsidian/waybar/colors.css` — a future deploy phase symlinks the latter to `~/.config/waybar/colors.css`.

- [ ] **Step 1: Write the module/layout config**

Create `Config/.config/waybar/config.jsonc`:

```json
{
    "layer": "top",
    "position": "top",
    "height": 32,
    "spacing": 4,
    "modules-left": ["hyprland/workspaces"],
    "modules-center": ["clock"],
    "modules-right": ["pulseaudio", "network", "battery", "tray"],

    "hyprland/workspaces": {
        "format": "{icon}",
        "format-icons": {
            "active": "",
            "default": ""
        }
    },
    "clock": {
        "format": "{:%H:%M   %a %d %b}"
    },
    "pulseaudio": {
        "format": "{icon}  {volume}%",
        "format-muted": "  muted",
        "format-icons": {
            "default": ["", "", ""]
        },
        "on-click": "pavucontrol"
    },
    "network": {
        "format-wifi": "  {essid}",
        "format-ethernet": "  {ifname}",
        "format-disconnected": "  disconnected"
    },
    "battery": {
        "format": "{icon}  {capacity}%",
        "format-icons": ["", "", "", "", ""],
        "format-critical": "  {capacity}%",
        "states": {
            "critical": 15
        }
    },
    "tray": {
        "spacing": 8
    }
}
```

- [ ] **Step 2: Write the color overlay**

Create `Themes/obsidian/waybar/colors.css`:

```css
@define-color background #121214;
@define-color backgroundAlt #1c1c20;
@define-color foreground #E4E4E7;
@define-color foregroundMuted #8B8B93;
@define-color accent #6E8CAE;
@define-color border rgba(255, 255, 255, 0.10);
@define-color urgent #B57575;
```

- [ ] **Step 3: Write the base stylesheet**

Create `Config/.config/waybar/style.css`:

```css
@import "colors.css";

* {
    font-family: "CaskaydiaCove Nerd Font Mono";
    font-size: 13px;
    border: none;
    border-radius: 0;
    min-height: 0;
}

window#waybar {
    background-color: @background;
    color: @foreground;
    border-bottom: 1px solid @border;
}

#workspaces button {
    padding: 0 8px;
    color: @foregroundMuted;
}

#workspaces button.active {
    color: @accent;
}

#clock,
#pulseaudio,
#network,
#battery,
#tray {
    padding: 0 10px;
    margin: 4px 2px;
    background-color: @backgroundAlt;
    color: @foreground;
    border-radius: 6px;
}

#battery.critical {
    color: @urgent;
}
```

- [ ] **Step 4: Verify**

Run:
```bash
python3 -m json.tool Config/.config/waybar/config.jsonc > /dev/null && echo "config.jsonc is valid JSON"
grep -q '@import "colors.css";' Config/.config/waybar/style.css && echo "style.css imports colors.css"
grep -q '@define-color accent #6E8CAE;' Themes/obsidian/waybar/colors.css && echo "accent color defined"
```
Expected: all three echo lines print.

- [ ] **Step 5: Commit**

```bash
git add Config/.config/waybar/config.jsonc Config/.config/waybar/style.css Themes/obsidian/waybar/colors.css
git commit -m "feat: add Waybar base config and obsidian color overlay"
```

---

### Task 7: Dunst — complete themed config (no base/overlay split)

**Files:**
- Create: `Themes/obsidian/dunst/dunstrc`

**Interfaces:**
- Consumes: nothing from earlier tasks (Dunst is launched by Task 4's `exec-once = dunst`).
- Produces: `Themes/obsidian/dunst/dunstrc` — a future deploy phase symlinks it directly to `~/.config/dunst/dunstrc`. No `Config/.config/dunst/` file exists this phase (per the spec's stated exception — dunstrc has no include directive).

- [ ] **Step 1: Write the complete themed config**

Create `Themes/obsidian/dunst/dunstrc`:

```ini
[global]
    monitor = 0
    follow = mouse
    width = 300
    height = 300
    origin = top-right
    offset = 12x12
    scale = 0
    notification_limit = 5

    progress_bar = true
    progress_bar_height = 10
    progress_bar_frame_width = 1
    progress_bar_min_width = 150
    progress_bar_max_width = 300

    indicate_hidden = yes
    transparency = 10
    separator_height = 2
    padding = 10
    horizontal_padding = 10
    text_icon_padding = 0
    frame_width = 1
    frame_color = "#6E8CAE"
    separator_color = frame
    sort = yes
    idle_threshold = 120

    font = CaskaydiaCove Nerd Font Mono 10
    line_height = 0
    markup = full
    format = "<b>%s</b>\n%b"
    alignment = left
    vertical_alignment = center
    show_age_threshold = 60
    ellipsize = middle
    ignore_newline = no
    stack_duplicates = true
    hide_duplicate_count = false
    show_indicators = yes

    icon_position = left
    min_icon_size = 32
    max_icon_size = 64

    sticky_history = yes
    history_length = 20

    dmenu = /usr/bin/rofi -dmenu -p dunst
    browser = /usr/bin/xdg-open

    always_run_script = true
    title = Dunst
    class = Dunst

    corner_radius = 8
    ignore_dbusclose = false

    mouse_left_click = close_current
    mouse_middle_click = do_action, close_current
    mouse_right_click = close_all

[urgency_low]
    background = "#121214"
    foreground = "#E4E4E7"
    frame_color = "#1c1c20"
    timeout = 5

[urgency_normal]
    background = "#121214"
    foreground = "#E4E4E7"
    frame_color = "#6E8CAE"
    timeout = 8

[urgency_critical]
    background = "#121214"
    foreground = "#E4E4E7"
    frame_color = "#B57575"
    timeout = 0
```

- [ ] **Step 2: Verify**

Run:
```bash
test ! -e Config/.config/dunst && echo "no Config/.config/dunst base — matches the spec's stated exception"
grep -q 'frame_color = "#B57575"' Themes/obsidian/dunst/dunstrc && echo "critical urgency frame color present"
grep -c '^\[' Themes/obsidian/dunst/dunstrc
```
Expected: both echo lines print, and the section count is `4`.

- [ ] **Step 3: Commit**

```bash
git add Themes/obsidian/dunst/dunstrc
git commit -m "feat: add complete obsidian Dunst config"
```

---

### Task 8: Manual dogfood verification (human, on real Fedora + Hyprland hardware)

This task is **not** for a subagent to attempt — it requires a running Hyprland session on real hardware, which the implementation environment doesn't have. Run this yourself after Tasks 1–7 are committed.

**Files:** none (temporary local symlinks only, not committed).

- [ ] **Step 1: Temporarily wire the active theme's overlay files to their include paths**

`install.sh`/`deploy.sh` aren't wired to `Themes/` yet (deferred to a later phase), so the base configs' include paths won't resolve on their own. Symlink each by hand from the repo root:

```bash
mkdir -p ~/.config/{hypr,hyprlock,waybar,kitty,rofi/themes,dunst,hypridle}
ln -sf "$PWD/Themes/active/hypr/colors.conf"       ~/.config/hypr/colors.conf
ln -sf "$PWD/Themes/active/hyprlock/colors.conf"   ~/.config/hyprlock/colors.conf
ln -sf "$PWD/Themes/active/waybar/colors.css"      ~/.config/waybar/colors.css
ln -sf "$PWD/Themes/active/kitty/theme.conf"       ~/.config/kitty/theme.conf
ln -sf "$PWD/Themes/active/rofi/theme.rasi"        ~/.config/rofi/themes/theme.rasi
ln -sf "$PWD/Themes/active/dunst/dunstrc"          ~/.config/dunst/dunstrc
ln -sf "$PWD/Config/.config/hypr/hyprland.conf"    ~/.config/hypr/hyprland.conf
ln -sf "$PWD/Config/.config/hyprlock/hyprlock.conf" ~/.config/hyprlock/hyprlock.conf
ln -sf "$PWD/Config/.config/hypridle/hypridle.conf" ~/.config/hypridle/hypridle.conf
ln -sf "$PWD/Config/.config/waybar/config.jsonc"   ~/.config/waybar/config.jsonc
ln -sf "$PWD/Config/.config/waybar/style.css"      ~/.config/waybar/style.css
ln -sf "$PWD/Config/.config/kitty/kitty.conf"      ~/.config/kitty/kitty.conf
ln -sf "$PWD/Config/.config/rofi/config.rasi"      ~/.config/rofi/config.rasi
```

- [ ] **Step 2: Run through the spec's manual verification checklist**

- [ ] `hyprctl reload` (or a fresh Hyprland session start) completes with no config parse errors
- [ ] Waybar renders with the obsidian palette, no CSS parse warnings in its log output
- [ ] Rofi (`drun` mode) launches, themed correctly, selection uses the accent color
- [ ] A test notification (`notify-send "test" "obsidian dunst check"`) appears styled per `Themes/obsidian/dunst/dunstrc`
- [ ] Hyprlock (`hyprlock`) locks and renders with the obsidian palette
- [ ] Hypridle triggers lock/DPMS on schedule (unthemed, behavior-only check)
- [ ] Kitty opens with the desaturated obsidian ANSI palette

- [ ] **Step 3: Report back**

No commit for this task — it's manual verification of already-committed work. Report which checklist items passed and paste any error output for items that didn't, so the specific config file can be fixed in a follow-up commit.
