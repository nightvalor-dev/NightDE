#!/usr/bin/env bash
# brightness.sh get -> 0-100     brightness.sh set <value>
case "$1" in
    get) brightnessctl -m 2>/dev/null | awk -F, '{ gsub("%", "", $4); print $4 }' ;;
    set) brightnessctl -q set "$(printf '%.0f' "$2")%" ;;
esac
