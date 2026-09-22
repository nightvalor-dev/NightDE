# NightDE

A portable, themeable dotfiles framework for Hyprland on Fedora Linux — inspired by [HyDE](https://github.com/HyDE-Project/HyDE).

NightDE bundles curated Wayland-stack configs and a hand-authored, multi-theme system into one opinionated but swappable setup for Hyprland. Unlike HyDE's wallpaper-driven color extraction, NightDE's themes are checked-in, hand-designed palettes — pick a look, not a wallpaper.

## Features

- 🧩 **Modular configs** — drop any component without breaking the rest
- 🎨 **Multi-theme system** — each theme is a self-contained set of colors and layout applied across the bar, launcher, terminal, lock screen, and notifications
- 📦 **Layered package lists** — base install plus optional extras *(planned)*
- 🔧 **CLI wrapper** — switch themes, change wallpapers, and reload configs from one command *(planned)*
- 🖥️ **One-command install** — detects your system and sets up the full stack *(planned)*

## Components

| Component | Role | Status |
|---|---|---|
| Hyprland | Wayland compositor | ✅ |
| Waybar | Status bar | ✅ |
| Rofi | App launcher / menu | ✅ |
| Dunst | Notifications | ✅ |
| Kitty | Terminal emulator | ✅ |
| Hyprlock / Hypridle | Lock screen / idle handling | ✅ |
| SDDM | Login manager | Planned |

## Themes

Themes live under `Themes/<name>/`, each a self-contained set of per-app color/layout overlays that the base config in `Config/.config/<app>/` includes. `Themes/active` is a symlink to the currently selected theme.

| Theme | Look |
|---|---|
| **obsidian** | Dark, muted/minimal — the only theme shipped so far |

## Distro support

Fedora is the only distro currently built and verified. The install/deploy layer isn't built yet; when it lands, it's designed to support additional distros as fast-follows.

## Status

Early WIP — no installer and no theme-switch CLI yet. Config content and the theme architecture are hand-verified on real Fedora + Hyprland hardware; see `docs/superpowers/specs/` and `docs/superpowers/plans/` for the design specs and implementation plans driving this project.
