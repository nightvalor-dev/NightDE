#!/usr/bin/env bash
# NightDE theme switch (the sidebar's theme dots call this)
#   theme.sh NAME      switch to a theme: kanagawa | catppuccin-mocha | everforest | ember
#   theme.sh restore   re-apply the current theme's wallpaper (run at login)
BASE="$HOME/.config/nightde"
ENGINE="$BASE/nightde-theme.py"
EWW="$HOME/.local/bin/eww"

wallpaper() {
    local wp
    wp=$(ls "$BASE/themes/$1"/wallpaper.* 2>/dev/null | head -1)
    [ -n "$wp" ] && command -v awww >/dev/null &&
        awww img "$wp" --transition-type fade --transition-duration 0.8 >/dev/null 2>&1
}

case "$1" in
    ""|-h|--help)
        echo "usage: theme.sh $(python3 "$ENGINE" names | tr ' ' '|') | restore"; exit 1 ;;
    restore)
        wallpaper "$(python3 "$ENGINE" current)"; exit 0 ;;
esac

name="$1"
[ "$name" = "$(python3 "$ENGINE" current)" ] && exit 0      # already active: nothing to do

# One switch at a time (double clicks are ignored)
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/nightde-theme.lock"
flock -n 9 || exit 0

python3 "$ENGINE" apply "$name" >/dev/null || { notify-send -a NightDE "Theme" "Could not switch to $name"; exit 1; }

# Everything below reloads in parallel
wallpaper "$name" &
pkill -SIGUSR2 -x waybar &                                    # Waybar: new style + icon colours
pkill -SIGUSR1 -x kitty &                                     # every kitty window
{ dunstctl reload >/dev/null 2>&1 || { pkill -x dunst; setsid -f dunst >/dev/null 2>&1; }; } &
hyprctl reload >/dev/null 2>&1 &                              # window borders
for sock in "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"/nvim.*; do   # every open Neovim
    [ -S "$sock" ] && nvim --server "$sock" --remote-expr "v:lua.NightdeTheme()" >/dev/null 2>&1 &
done
{ "$EWW" update theme="$name"; "$EWW" reload; } >/dev/null 2>&1 &   # sidebar + clipboard dropdown
wait
