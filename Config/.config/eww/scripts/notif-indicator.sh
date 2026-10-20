#!/usr/bin/env bash
# For the Waybar bell: {"text": count, "alt": notification|none|dnd}
count=$(dunstctl count history 2>/dev/null || echo 0)
if [ "$(dunstctl is-paused 2>/dev/null)" = true ]; then alt=dnd
elif [ "${count:-0}" -gt 0 ]; then alt=notification
else alt=none
fi
printf '{"text": "%s", "alt": "%s", "class": "%s"}\n' "${count:-0}" "$alt" "$alt"
