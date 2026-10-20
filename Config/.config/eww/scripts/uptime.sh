#!/usr/bin/env bash
# Uptime as "3d 4h 12m" / "2h 5m" / "9m"
secs=$(cut -d. -f1 /proc/uptime)
d=$((secs / 86400)); h=$(((secs % 86400) / 3600)); m=$(((secs % 3600) / 60))
out=""
(( d > 0 )) && out+="${d}d "
(( d > 0 || h > 0 )) && out+="${h}h "
out+="${m}m"
echo "$out"
