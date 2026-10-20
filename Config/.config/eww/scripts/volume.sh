#!/usr/bin/env bash
# volume.sh get -> 0-100     volume.sh set <value>
case "$1" in
    get) wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{ printf "%d\n", $2 * 100 }' ;;
    set) wpctl set-volume @DEFAULT_AUDIO_SINK@ "$(printf '%.0f' "$2")%" ;;
esac
