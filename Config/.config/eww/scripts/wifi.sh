#!/usr/bin/env bash
# wifi.sh status -> true/false     wifi.sh toggle
EWW="$HOME/.local/bin/eww"
on() { [ "$(nmcli radio wifi)" = enabled ]; }
case "$1" in
    status) on && echo true || echo false ;;
    toggle)
        if on; then nmcli radio wifi off; "$EWW" update wifi_on=false
        else        nmcli radio wifi on;  "$EWW" update wifi_on=true
        fi ;;
esac
