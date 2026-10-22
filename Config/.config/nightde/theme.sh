#!/usr/bin/env bash
# NightDE theme switch (the left sidebar's toggles and thumbnails call this)
#   theme.sh NAME              switch theme: kanagawa | catppuccin-mocha | everforest | ember
#                              (also brings back the wallpaper you last used with that theme)
#   theme.sh wallpaper PATH    change only the wallpaper (remembered for the current theme)
#   theme.sh wallpaper next    next wallpaper of the current theme
#   theme.sh restore           re-apply the current theme's wallpaper (run at login)
#
# Wallpapers: put any number of images in ~/.config/nightde/themes/<theme>/wallpapers/
BASE="$HOME/.config/nightde"
ENGINE="$BASE/nightde-theme.py"
EWW="$HOME/.local/bin/eww"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/nightde"
mkdir -p "$STATE"

current_theme() { cat "$BASE/current" 2>/dev/null || echo kanagawa; }

walls_of() {   # all wallpapers of a theme, sorted
    find "$BASE/themes/$1/wallpapers" "$BASE/themes/$1" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' \) \
        \( -path "*/wallpapers/*" -o -name 'wallpaper.*' \) 2>/dev/null | sort
}

wall_for() {   # the wallpaper last used with a theme, else its first one
    local last; last=$(cat "$STATE/wall-$1" 2>/dev/null)
    if [ -n "$last" ] && [ -f "$last" ]; then echo "$last"; else walls_of "$1" | head -1; fi
}

set_wall() {   # $1 = image, $2 = theme it belongs to
    [ -f "$1" ] || return 0
    echo "$1" > "$STATE/wall-$2"
    command -v awww >/dev/null &&
        awww img "$1" --transition-type fade --transition-duration 0.8 >/dev/null 2>&1 &
    "$EWW" update wall_current="$1" >/dev/null 2>&1
}

case "$1" in
    ""|-h|--help)
        sed -n '2,9p' "$0"; exit 1 ;;
    restore)
        t=$(current_theme); set_wall "$(wall_for "$t")" "$t"; wait; exit 0 ;;
    wallpaper)
        t=$(current_theme)
        if [ "$2" = next ]; then
            mapfile -t all < <(walls_of "$t")
            (( ${#all[@]} )) || exit 0
            cur=$(wall_for "$t"); next="${all[0]}"
            for i in "${!all[@]}"; do
                [ "${all[$i]}" = "$cur" ] && next="${all[$(( (i + 1) % ${#all[@]} ))]}"
            done
            set_wall "$next" "$t"
        else
            set_wall "$2" "$t"
        fi
        wait; exit 0 ;;
esac

name="$1"
[ "$name" = "$(current_theme)" ] && exit 0                    # already active: nothing to do

# One switch at a time (double clicks are ignored)
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/nightde-theme.lock"
flock -n 9 || exit 0

python3 "$ENGINE" apply "$name" >/dev/null || { notify-send -a NightDE "Theme" "Could not switch to $name"; exit 1; }

# Everything below reloads in parallel
set_wall "$(wall_for "$name")" "$name" &                      # this theme's wallpaper
pkill -SIGUSR2 -x waybar &                                    # Waybar: new style + icon colours
pkill -SIGUSR1 -x kitty &                                     # every kitty window
{ dunstctl reload >/dev/null 2>&1 || { pkill -x dunst; setsid -f dunst >/dev/null 2>&1; }; } &
hyprctl reload >/dev/null 2>&1 &                              # window borders
{ gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'           # nudge open GTK apps
  sleep 0.15                                                               # to reload their colours
  gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'; } >/dev/null 2>&1 &
for sock in "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"/nvim.*; do   # every open Neovim
    [ -S "$sock" ] && nvim --server "$sock" --remote-expr "v:lua.NightdeTheme()" >/dev/null 2>&1 &
done
{ "$EWW" update theme="$name"; "$EWW" reload; } >/dev/null 2>&1 &   # panels pick up the new colours
wait
