#!/usr/bin/env bash
# Esc handling for the eww panels (sidebar, clipboard dropdown).
#   panels.sh enter   switch Hyprland into the "eww-panel" key mode (Esc = close)
#   panels.sh close   close every panel and leave that key mode
EWW="$HOME/.local/bin/eww"
case "$1" in
    enter)
        hyprctl dispatch 'hl.dsp.submap("eww-panel")' >/dev/null 2>&1 ;;
    close)
        "$EWW" close sidebar sidebar-closer clipboard clip-closer leftbar left-closer >/dev/null 2>&1
        hyprctl dispatch 'hl.dsp.submap("reset")' >/dev/null 2>&1 ;;
    *)
        echo "usage: panels.sh enter|close"; exit 1 ;;
esac
