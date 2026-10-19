#!/usr/bin/env bash
# NightDE — install: copy the configs in this project into the current user's home folder.
# Anything that would be replaced is first backed up to ~/.nightde-backup-<date>/.
#
# Usage (run as the user who should get the configs):
#   ./install-configs.sh

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$SRC/.nightde-manifest"
BACKUP="$HOME/.nightde-backup-$(date +%Y%m%d-%H%M%S)"

if [ ! -s "$MANIFEST" ]; then
    echo "No manifest found — run export-configs.sh first."
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

# Scripts must stay executable
find "$HOME/.config/waybar" -name '*.sh' -exec chmod +x {} + 2>/dev/null || true

echo
[ -d "$BACKUP" ] && echo "Previous files backed up to: $BACKUP"
echo "Log out and back in (or run 'hyprctl reload') to apply."
