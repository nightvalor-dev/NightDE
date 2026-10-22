#!/usr/bin/env bash
# Open/close the sidebar together with its invisible click-away layer.
#   toggle.sh         -> open if closed, close if open
#   toggle.sh close   -> close
EWW="$HOME/.local/bin/eww"
is_open() { "$EWW" active-windows 2>/dev/null | grep -q "^sidebar:"; }

if [ "$1" = close ] || is_open; then
    "$HOME/.config/eww/scripts/panels.sh" close          # also leaves the Esc key mode
else
    # Reset the calendar to the current month every time the sidebar opens
    "$HOME/.config/eww/scripts/calendar.sh" today >/dev/null 2>&1
    "$EWW" close leftbar left-closer >/dev/null 2>&1        # one panel at a time
    # Open the click-away layer first so the sidebar sits on top of it
    "$EWW" open sidebar-closer >/dev/null 2>&1
    "$EWW" open sidebar >/dev/null 2>&1
    "$HOME/.config/eww/scripts/panels.sh" enter          # Esc now closes the sidebar
fi
