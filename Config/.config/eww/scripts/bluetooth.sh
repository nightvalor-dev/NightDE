#!/usr/bin/env bash
# bluetooth.sh status -> true/false     bluetooth.sh toggle
EWW="$HOME/.local/bin/eww"
on() { bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; }
case "$1" in
    status) on && echo true || echo false ;;
    toggle)
        if on; then bluetoothctl power off >/dev/null; "$EWW" update bt_on=false
        else        bluetoothctl power on  >/dev/null; "$EWW" update bt_on=true
        fi ;;
esac
