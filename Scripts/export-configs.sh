#!/usr/bin/env bash
# NightDE — export: copy this user's desktop configs into the project folder,
# keeping the same layout as the home folder (e.g. ~/.config/hypr -> NightDE/.config/hypr).
#
# Usage:  ./export-configs.sh [destination] [--with-themes]
#   destination    defaults to ~/Desktop/Projects/NightDE
#   --with-themes  also copy GTK themes, icon themes and fonts (can be large)

set -euo pipefail

DEST="$HOME/Desktop/Projects/NightDE"
WITH_THEMES=0
for arg in "$@"; do
    case "$arg" in
        --with-themes) WITH_THEMES=1 ;;
        -h|--help) sed -n '2,8p' "$0"; exit 0 ;;
        *) DEST="$arg" ;;
    esac
done

# Everything is listed relative to $HOME
CONFIGS=(
    .config/hypr            # Hyprland, hyprlock, decorations, rules, keybinds
    .config/waybar          # bar, gauges script, wlogout menus + icons
    .config/swaync          # sidebar / notifications
    .config/kitty           # terminal + Kanagawa theme
    .config/rofi            # app launcher
    .config/qt6ct           # Qt theme + Kanagawa color scheme
    .config/gtk-3.0         # GTK3 settings (written by nwg-look)
    .config/gtk-4.0         # GTK4 / libadwaita theme
    .config/starship.toml   # shell prompt
    .config/Code/User/settings.json      # VS Code settings
    .config/Code/User/keybindings.json   # VS Code keybindings
    .local/share/nwg-look   # nwg-look's saved choices
    .dircolors              # ls colors
    .face                   # profile picture (lock screen)
)
THEMES=(
    .themes                 # GTK themes (Kanagawa)
    .local/share/icons      # icon themes
    .local/share/fonts      # Nerd Fonts
)
(( WITH_THEMES )) && CONFIGS+=("${THEMES[@]}")

mkdir -p "$DEST"
cd "$HOME"

MANIFEST="$DEST/.nightde-manifest"
: > "$MANIFEST"
copied=0; skipped=0
for item in "${CONFIGS[@]}"; do
    if [ ! -e "$item" ]; then
        echo "  skip   $item (not found)"
        skipped=$((skipped + 1))
        continue
    fi
    mkdir -p "$DEST/$(dirname "$item")"
    if [ -d "$item" ]; then
        # Mirror the folder exactly: remove the old copy first so deleted files don't linger.
        # -L follows symlinks so the project gets real files, not links into this home folder.
        rm -rf "${DEST:?}/$item"
        cp -aL "$item" "$DEST/$item"
    else
        cp -aL "$item" "$DEST/$item"
    fi
    echo "$item" >> "$MANIFEST"
    echo "  copy   $item"
    copied=$((copied + 1))
done

echo
echo "Done: $copied copied, $skipped skipped -> $DEST"

# Warn about hard-coded paths to this home folder (they won't work for another user)
hits=$(grep -rIl -- "$HOME/" "$DEST" --exclude-dir=.git --exclude='*.sh' 2>/dev/null | head -20 || true)
if [ -n "$hits" ]; then
    echo
    echo "Note: these files contain $HOME and may need \$HOME or ~ instead:"
    echo "$hits" | sed "s|$DEST/|  |"
fi
