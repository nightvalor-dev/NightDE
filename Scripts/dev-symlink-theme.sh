#!/usr/bin/env bash
# Manual dev/test helper — NOT the real installer.
#
# Symlinks the base configs (Config/.config/<app>/) and the active theme's
# overlay files (Themes/active/<app>/) into ~/.config so the desktop can be
# dogfooded on real hardware/a VM. This is throwaway scaffolding for Task 8
# of docs/superpowers/plans/2026-09-22-nightde-theming-and-desktop-config.md
# — it will be replaced once install.sh/deploy.sh wiring is built.
#
# Usage: run after cloning the repo, from anywhere:
#   ./Scripts/dev-symlink-theme.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

mkdir -p ~/.config/{hypr,hyprlock,waybar,kitty,rofi/themes,dunst,hypridle}

# Active theme overlay files
ln -sf "$REPO_ROOT/Themes/active/hypr/colors.conf"        ~/.config/hypr/colors.conf
ln -sf "$REPO_ROOT/Themes/active/hyprlock/colors.conf"    ~/.config/hyprlock/colors.conf
ln -sf "$REPO_ROOT/Themes/active/waybar/colors.css"       ~/.config/waybar/colors.css
ln -sf "$REPO_ROOT/Themes/active/kitty/theme.conf"        ~/.config/kitty/theme.conf
ln -sf "$REPO_ROOT/Themes/active/rofi/theme.rasi"         ~/.config/rofi/themes/theme.rasi
ln -sf "$REPO_ROOT/Themes/active/dunst/dunstrc"           ~/.config/dunst/dunstrc

# Base configs
ln -sf "$REPO_ROOT/Config/.config/hypr/hyprland.conf"     ~/.config/hypr/hyprland.conf
ln -sf "$REPO_ROOT/Config/.config/hyprlock/hyprlock.conf" ~/.config/hyprlock/hyprlock.conf
ln -sf "$REPO_ROOT/Config/.config/hypridle/hypridle.conf" ~/.config/hypridle/hypridle.conf
ln -sf "$REPO_ROOT/Config/.config/waybar/config.jsonc"    ~/.config/waybar/config.jsonc
ln -sf "$REPO_ROOT/Config/.config/waybar/style.css"       ~/.config/waybar/style.css
ln -sf "$REPO_ROOT/Config/.config/kitty/kitty.conf"       ~/.config/kitty/kitty.conf
ln -sf "$REPO_ROOT/Config/.config/rofi/config.rasi"       ~/.config/rofi/config.rasi

echo "Symlinked NightDE (theme: $(basename "$(readlink "$REPO_ROOT/Themes/active")")) configs into ~/.config"
echo "Reload Hyprland (hyprctl reload) or start a fresh session to pick them up."
