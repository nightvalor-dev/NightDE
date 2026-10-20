#!/usr/bin/env bash
# NightDE — install: copy the configs in Config/ into the current user's home folder.
# Anything that would be replaced is first backed up to ~/.nightde-backup-<date>/.
#
# Usage (run as the user who should get the configs):
#   Scripts/install-configs.sh

set -euo pipefail

PROJECT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$PROJECT/Config"
MANIFEST="$SRC/.nightde-manifest"
BACKUP="$HOME/.nightde-backup-$(date +%Y%m%d-%H%M%S)"

if [ ! -s "$MANIFEST" ]; then
    echo "No manifest found — run Scripts/export-configs.sh first."
    exit 1
fi

echo "Installing into $HOME:"
while IFS= read -r item; do
    [ -z "$item" ] && continue
    [ -e "$SRC/$item" ] || { echo "  skip    $item (missing in project)"; continue; }
    target="$HOME/$item"
    if [ -e "$target" ] || [ -L "$target" ]; then
        mkdir -p "$BACKUP/$(dirname "$item")"
        mv "$target" "$BACKUP/$item"
    fi
    mkdir -p "$(dirname "$target")"
    cp -a "$SRC/$item" "$target"
    echo "  install $item"
done < "$MANIFEST"

# Rewrite absolute paths from the exporting user's home to this user's home
OLD_HOME=$(cat "$SRC/.nightde-home" 2>/dev/null || true)
if [ -n "$OLD_HOME" ] && [ "$OLD_HOME" != "$HOME" ]; then
    while IFS= read -r item; do
        [ -e "$HOME/$item" ] || continue
        grep -rIl -- "$OLD_HOME/" "$HOME/$item" 2>/dev/null | while IFS= read -r f; do
            sed -i "s|$OLD_HOME/|$HOME/|g" "$f" && echo "  fixed   ${f#$HOME/} (paths -> $HOME)"
        done
    done < "$MANIFEST"
fi

# Scripts must stay executable
for d in .config/waybar .config/eww .config/hypr; do
    find "$HOME/$d" -name '*.sh' -exec chmod +x {} + 2>/dev/null || true
done
chmod +x "$HOME/.local/bin/eww" 2>/dev/null || true

# Desktop portal target (file pickers, screen sharing, GTK settings)
systemctl --user daemon-reload 2>/dev/null || true

echo
[ -d "$BACKUP" ] && echo "Previous files backed up to: $BACKUP"
echo "See PACKAGES.md for the programs to install, then log out and back in."
