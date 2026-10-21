#!/usr/bin/env bash
# NightDE — export: copy this user's desktop configs into the project.
# Files are mirrored under Config/ with the same layout as the home folder:
#   ~/.config/hypr  ->  NightDE/Config/.config/hypr
#
# Usage:  Scripts/export-configs.sh [--with-themes]
#   --with-themes  also copy GTK themes, icon/cursor themes and fonts (large)

set -euo pipefail

PROJECT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$PROJECT/Config"
WITH_THEMES=0
for arg in "$@"; do
    case "$arg" in
        --with-themes) WITH_THEMES=1 ;;
        -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
        *) echo "Unknown option: $arg"; exit 1 ;;
    esac
done

# Everything is listed relative to $HOME
CONFIGS=(
    .config/hypr            # Hyprland: binds, rules, autostart, compact workspaces, hyprlock, screenshot script
    .config/waybar          # bar, gauges script, clipboard button, wlogout menus + icons
    .config/eww             # sidebar, clipboard dropdown, calendar, Esc handling + scripts
    .config/dunst           # notifications
    .config/kitty           # terminal + Kanagawa theme
    .config/rofi            # app launcher (NightDE theme)
    .config/nvim            # Neovim (lazy.nvim, Kanagawa, LSP, completion)
    .config/qt6ct           # Qt theme + Kanagawa colour scheme
    .config/gtk-3.0         # GTK3 settings + selection colour
    .config/gtk-4.0         # GTK4 / libadwaita theme
    .config/fontconfig      # Rubik as the system font
    .config/systemd/user/hyprland-session.target   # lets the desktop portal start under Hyprland
    .config/nightde         # theme switcher: engine, themes, per-theme wallpapers
    .config/starship.toml   # shell prompt
    .config/Code/User/settings.json      # VS Code settings
    .config/Code/User/keybindings.json   # VS Code keybindings
    .local/share/nwg-look   # nwg-look's saved choices
    .local/bin/eww          # eww binary (not packaged in Fedora)
    .dircolors              # ls colours
    .face                   # profile picture
)
THEMES=(
    .themes                 # GTK themes (Kanagawa)
    .local/share/icons      # WhiteSur icons, Bibata Modern Ice cursor
    .local/share/fonts      # Nerd Fonts
)
(( WITH_THEMES )) && CONFIGS+=("${THEMES[@]}")

# Configs NightDE no longer uses — removed from the project if present
OBSOLETE=(
    .config/swaync          # replaced by the eww sidebar + dunst
)

mkdir -p "$DEST"
cd "$HOME"

MANIFEST="$DEST/.nightde-manifest"
: > "$MANIFEST"
echo "$HOME" > "$DEST/.nightde-home"     # lets install-configs.sh fix absolute paths for another user
copied=0; skipped=0
for item in "${CONFIGS[@]}"; do
    if [ ! -e "$item" ]; then
        echo "  skip    $item (not found)"
        skipped=$((skipped + 1))
        continue
    fi
    mkdir -p "$DEST/$(dirname "$item")"
    # Mirror exactly: remove the old copy first so deleted files don't linger.
    # -L copies the real files behind symlinks.
    rm -rf "${DEST:?}/$item"
    cp -aL "$item" "$DEST/$item"
    echo "$item" >> "$MANIFEST"
    echo "  copy    $item"
    copied=$((copied + 1))
done

for item in "${OBSOLETE[@]}"; do
    if [ -e "$DEST/$item" ]; then
        rm -rf "${DEST:?}/$item"
        echo "  remove  $item (no longer used)"
    fi
done

# Save the project in Kanagawa whatever theme is active right now, so switching
# themes never shows up as changed files in git.
if [ -f "$DEST/.config/nightde/nightde-theme.py" ]; then
    HOME="$DEST" python3 "$DEST/.config/nightde/nightde-theme.py" apply kanagawa >/dev/null &&
        echo "  theme   saved as Kanagawa"
    # the engine wrote paths under the project; point them back at the home folder
    grep -rIl -- "$DEST/" "$DEST" 2>/dev/null | while IFS= read -r f; do
        sed -i "s|$DEST/|$HOME/|g" "$f"
    done
fi

# Leftover backups and generated junk don't belong in the project
find "$DEST" \( -name '*.bak*' -o -name '*.nightde-tmp' -o -name '__pycache__' \) -prune -exec rm -rf {} + 2>/dev/null || true

echo
echo "Done: $copied copied, $skipped skipped -> $DEST"

# Warn about hard-coded paths to this home folder (they won't work for another user)
hits=$(grep -rIl -- "$HOME/" "$DEST" --exclude='*.sh' 2>/dev/null | head -20 || true)
if [ -n "$hits" ]; then
    echo
    echo "These files contain $HOME — install-configs.sh rewrites it to the new user's home:"
    echo "$hits" | sed "s|$DEST/|  |"
fi
