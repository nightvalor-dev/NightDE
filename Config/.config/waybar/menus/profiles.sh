#!/usr/bin/env bash
# Power-mode overlay: Performance / Balanced / Power Saver.
# The active mode is shown as brighter glass.
DIR="$HOME/.config/waybar/menus"

pkill -x wlogout && exit 0

current=$(busctl get-property net.hadess.PowerProfiles /net/hadess/PowerProfiles \
    net.hadess.PowerProfiles ActiveProfile 2>/dev/null | awk -F'"' '{print $2}')

# Temp copy of the stylesheet (icon paths made absolute) plus a highlight for the active mode
css=$(mktemp --suffix=.css)
trap 'rm -f "$css"' EXIT
sed "s|url(\"icons/|url(\"file://$DIR/icons/|g" "$DIR/wlogout.css" > "$css"
if [ -n "$current" ]; then
    printf '\n#%s { background-color: rgba(255, 255, 255, 0.18); }\n' "$current" >> "$css"
    printf '#%s:hover, #%s:focus { background-color: rgba(255, 255, 255, 0.28); }\n' "$current" "$current" >> "$css"
fi

wlogout \
    --layout "$DIR/profiles.layout" \
    --css "$css" \
    --buttons-per-row 3 \
    --column-spacing 0 --row-spacing 0 \
    --margin-top 355 --margin-bottom 355 \
    --margin-left 570 --margin-right 570 \
    --protocol layer-shell
