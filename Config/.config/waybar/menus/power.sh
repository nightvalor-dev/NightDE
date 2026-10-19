#!/usr/bin/env bash
# Power overlay: Lock / Logout / Suspend / Shutdown / Hibernate / Reboot.
# Esc or clicking the bar button again closes it.
DIR="$HOME/.config/waybar/menus"

pkill -x wlogout && exit 0

# Temp copy of the stylesheet with absolute icon paths (wlogout doesn't resolve relative ones)
css=$(mktemp --suffix=.css)
trap 'rm -f "$css"' EXIT
sed "s|url(\"icons/|url(\"file://$DIR/icons/|g" "$DIR/wlogout.css" > "$css"

wlogout \
    --layout "$DIR/power.layout" \
    --css "$css" \
    --buttons-per-row 6 \
    --column-spacing 0 --row-spacing 0 \
    --margin-top 355 --margin-bottom 355 \
    --margin-left 210 --margin-right 210 \
    --protocol layer-shell
