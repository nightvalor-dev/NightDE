# Project: DarkDE — Hyprland Desktop Environment Framework

## Overview
A portable, themeable dotfiles/config framework for Hyprland on Arch Linux (inspired by HyDE).
Ships an installer, a set of curated configs for the Wayland stack, and a theming system that
derives a color palette from the user's wallpaper and propagates it across apps.

## Scope (what this project owns)
- Installer script(s) that detect the system, install packages, and symlink/copy configs
- Config files for: Hyprland (compositor), Waybar (bar), Rofi (launcher), Dunst/mako (notifications),
  Kitty/Alacritty (terminal), SDDM (login manager), Hyprlock/Hypridle (lock/idle)
- A theming/wallpaper-to-palette pipeline (e.g. pywal-style color extraction)
- A CLI wrapper for day-to-day tasks (theme switch, wallpaper change, config reload)
- Optional: a package list system (base vs. extra/user packages)

## Non-goals
- Not a general Linux distro or package manager
- Not targeting X11/other WMs — Wayland/Hyprland only
- No GUI settings app (config-file-first, like the original)

## Tech stack
- Shell (bash/zsh) for install + CLI scripts
- Hyprland's config DSL (`.conf` files) for compositor rules
- Whatever the theming engine is (e.g. Python for palette generation, or Rust/Go if you're rewriting it)
- systemd user services if any daemons are involved (e.g. wallpaper daemon)

## Directory structure
- `Scripts/` — install.sh and setup scripts
- `Configs/` — dotfiles, one directory per app, symlinked into `$HOME/.config`
- `Themes/` — theme definitions consumed by the palette engine
- `Scripts/pkg_*.lst` — package lists (base, extra, user)

## Conventions
- Config files should be idempotent to re-apply (install script safe to re-run)
- Prefer XDG-compliant paths (`$XDG_CONFIG_HOME`, `$XDG_DATA_HOME`)
- Keep app configs decoupled — a user should be able to drop one component without breaking others
- Document any hardware-specific branch (NVIDIA vs AMD/Intel) explicitly in the script, don't silently assume

## Commands
- `./Scripts/install.sh` — full install
- `./Scripts/install.sh pkg_user.lst` — install with extra user packages
- (add your CLI commands here once built, e.g. `hyde-cli theme set <name>`)

## Current focus / known constraints
- Target distro: Arch Linux (and Arch-based)
- NVIDIA support requires DRM modeset flags in bootloader config — flag this clearly in any script that touches grub/systemd-boot
- Early WIP — no stable theme API yet