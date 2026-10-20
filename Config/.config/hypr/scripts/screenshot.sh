#!/usr/bin/env bash
# Screenshot: saves to ~/Pictures/Screenshots and copies to the clipboard
#   screenshot.sh full     whole screen
#   screenshot.sh area     drag to select an area
#   screenshot.sh window   the focused window
dir="$HOME/Pictures/Screenshots"; mkdir -p "$dir"
file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"

case "$1" in
    area)   geom=$(slurp) || exit 0 ;;
    window) geom=$(hyprctl activewindow -j | python3 -c 'import json,sys
w=json.load(sys.stdin); print(f"{w[\"at\"][0]},{w[\"at\"][1]} {w[\"size\"][0]}x{w[\"size\"][1]}")') ;;
    *)      geom="" ;;
esac

if [ -n "$geom" ]; then grim -g "$geom" "$file"; else grim "$file"; fi &&
    wl-copy < "$file" &&
    notify-send -a "Screenshot" -i "$file" "Screenshot saved" "Copied to clipboard"
