#!/usr/bin/env bash
# Open / close the NightDE left sidebar (Waybar's Fedora logo runs this).
EWW="$HOME/.local/bin/eww"
W="$HOME/.config/eww/scripts/wallpapers.sh"
if "$EWW" active-windows 2>/dev/null | grep -q "^leftbar:"; then
    "$HOME/.config/eww/scripts/panels.sh" close
else
    "$HOME/.config/eww/scripts/panels.sh" close            # one panel at a time
    "$EWW" update walls="$("$W" list)" wall_current="$("$W" current)" >/dev/null 2>&1
    "$EWW" open left-closer >/dev/null 2>&1
    "$EWW" open leftbar >/dev/null 2>&1
    "$HOME/.config/eww/scripts/panels.sh" enter            # Esc closes it
fi
