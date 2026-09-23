# Project: NightDE — Hyprland Desktop Environment Framework

## Overview
A portable, themeable dotfiles/config framework for Hyprland on Fedora Linux (inspired by HyDE).
Ships curated configs for the Wayland stack and a hand-authored, checked-in multi-theme system —
not a wallpaper-derived palette pipeline. An installer is planned but not yet built.

## Scope (what this project owns)
- Installer script(s) that detect the system, install packages, and symlink/copy configs *(planned, not built)*
- Config files for: Hyprland (compositor), Waybar (bar), Rofi (launcher), Dunst (notifications),
  Kitty (terminal), SDDM (login manager, planned), Hyprlock/Hypridle (lock/idle)
- A hand-authored multi-theme system: fixed base configs per app, each including a small per-theme
  overlay file (colors + some layout) — see "Directory structure" below
- A CLI wrapper for day-to-day tasks (theme switch, wallpaper change, config reload) *(planned)*
- Optional: a package list system (base vs. extra/user packages) *(planned)*

## Non-goals
- Not a general Linux distro or package manager
- Not targeting X11/other WMs — Wayland/Hyprland only
- No GUI settings app (config-file-first, like the original)
- No wallpaper-driven/dynamic color extraction (no wallbash-style pipeline, no pywal/matugen).
  Themes are hand-authored and checked into the repo, not generated.
- No separate per-theme git repos (HyDE's `hyde-themes` pattern) — themes live in this repo under
  `Themes/`.

## Tech stack
- Shell (bash) for install + CLI scripts
- Static declarative config files for theming — no generation engine: Hyprland's hyprlang DSL,
  GTK CSS (Waybar), rasi (Rofi), dunstrc INI, kitty.conf
- systemd user services if any daemons are involved (e.g. wallpaper daemon) *(not yet needed)*

## Directory structure
- `Scripts/` — install/setup scripts (`lib/detect.sh` exists; `install.sh` not yet built) and dev
  helpers (e.g. `dev-symlink-theme.sh`, a throwaway manual test helper — not the real installer)
- `Config/.config/<app>/` — base, structural configs, fixed across themes, mirroring
  `$HOME/.config/<app>/` directly
- `Themes/<name>/` — one directory per theme, holding small per-app overlay files (colors + some
  layout) that the matching base config includes/imports; also `theme.env`, which *declares*
  intended GTK/icon/cursor/font theming as data (nothing fetches or installs them yet).
  `Themes/active` is a symlink to the currently selected theme. One theme exists so far: `obsidian`
  (dark, muted/minimal). Dunst is the one exception — its dunstrc has no include syntax, so its
  complete config lives directly in the theme directory rather than being split base+overlay.
- `Scripts/pkg_*.lst` — package lists (base, extra, user) *(planned)*

## Conventions
- Config files should be idempotent to re-apply (install script safe to re-run)
- Prefer XDG-compliant paths (`$XDG_CONFIG_HOME`, `$XDG_DATA_HOME`)
- Keep app configs decoupled — a user should be able to drop one component without breaking others
- Document any hardware-specific branch (NVIDIA vs AMD/Intel) explicitly in the script, don't silently assume

## Commands
- `./Scripts/dev-symlink-theme.sh` — throwaway dev helper: symlinks `Config/.config/<app>/` base
  configs and the active theme's overlay files into `~/.config` for manual testing. Not the real
  installer/deploy engine.
- `./Scripts/install.sh` — full install *(planned, not yet built)*
- `./Scripts/install.sh pkg_user.lst` — install with extra user packages *(planned)*
- (add your CLI commands here once built, e.g. `nightde-cli theme set <name>`)

## Current focus / known constraints
- Target distro: Fedora (primary, verified). Arch/other distros are a planned fast-follow once a
  distro abstraction is needed again — this reverses an earlier Arch-first decision.
- NVIDIA support requires DRM modeset flags in bootloader config — flag this clearly in any script
  that touches grub/systemd-boot (not yet implemented for Fedora)
- Early WIP — no installer, no theme-switch CLI, no stable theme API yet
