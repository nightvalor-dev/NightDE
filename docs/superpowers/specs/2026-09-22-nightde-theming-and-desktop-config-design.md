# NightDE Theming & Desktop Config Design

Date: 2026-09-22
Status: Approved, pre-implementation

## Purpose

Build out NightDE's actual desktop-environment config layer — Hyprland,
Waybar, Rofi, Dunst, Kitty, Hyprlock, Hypridle — with a theming
architecture modeled on HyDE's real structure: fixed base configs per
app, plus a small per-theme overlay file each base config includes.
Not wallbash — no wallpaper-driven color extraction, no dynamic
generation. Themes are hand-authored, checked into this repo.

This phase ships one theme ("obsidian": dark, muted/minimal) and proves
the base+overlay architecture end to end. Additional themes, a
theme-switch script, and GTK/icon/cursor/font fetching are explicitly
future work.

## Relationship to the 2026-09-20 MVP spec

This spec **supersedes** `2026-09-20-nightde-mvp-design.md`'s distro
priority. That spec named Arch as primary/fully-tested and Fedora as a
designed-for-but-unverified fast-follow. This spec reverses that:
**Fedora is the only distro built and verified for this phase**; Arch
and any other distro become the future fast-follow, once a distro
abstraction is needed again.

The existing `Scripts/lib/detect.sh` (`detect_distro`/`detect_gpu`) and
the `arch:`/`fedora:`-tagged package-list format from the MVP spec are
already distro-neutral and require no changes — this spec doesn't touch
them. `install.sh`/`deploy.sh` wiring for the new `Themes/` directory is
explicitly deferred (see Non-goals).

## Non-goals (this phase)

- `install.sh` / `Scripts/lib/deploy.sh` changes — deploying the
  `Themes/` tree and wiring the active-theme pointer into the install
  flow is a later phase. This phase is config content and directory
  architecture only.
- A theme-switch script/CLI (`theme.select.sh`/`theme.switch.sh`
  equivalents).
- More than one theme. "obsidian" is the only theme built now; the
  architecture is proven by building it well, not by building several.
- Any other distro besides Fedora.
- Fetching or installing GTK/icon/cursor themes, cursor packages, or
  fonts. A theme's `theme.env` *declares* intended values (see below)
  but nothing installs them yet.
- HyDE-parity utilities beyond the original 7 components (wlogout,
  cliphist, screenshot tooling, swaync, etc.) — already decided out of
  scope for this pass.
- Separate per-theme git repos (HyDE's `hyde-themes` pattern). Themes
  live inside this repo under `Themes/` for now; an external-repo
  convention is a possible future direction, not built here.
- `starship` — not one of the 7 desktop components, left untouched
  outside `Themes/`.

## Distro & hardware scope

- **Distro:** Fedora only, verified on the owner's real Fedora machine.
- **GPU:** out of scope for this phase — no package installation or
  driver work happens here, only static config files.

## Component scope

Hyprland, Waybar, Rofi, Dunst, Kitty, Hyprlock, Hypridle — unchanged
from the MVP spec's list. Hypridle has no visual/color surface (idle
timings only) and gets no theme file.

## Repo layout

```
Config/.config/<app>/            # base, structural, fixed across themes
├── hypr/hyprland.conf
├── waybar/style.css
├── rofi/config.rasi
├── dunst/                       # exception — see "Per-app overlay mechanism"
├── kitty/kitty.conf
├── hyprlock/hyprlock.conf
└── hypridle/hypridle.conf       # no theme file — nothing visual to theme

Themes/
├── active -> obsidian/          # symlink; a future switch script updates this
└── obsidian/
    ├── theme.env                 # GTK_THEME/ICON_THEME/CURSOR_THEME/fonts — declared, not fetched
    ├── hypr/colors.conf
    ├── waybar/colors.css
    ├── rofi/theme.rasi           # migrated from Config/.config/rofi/themes/theme.rasi
    ├── dunst/dunstrc             # full file — dunst has no include syntax, see below
    ├── hyprlock/colors.conf
    └── kitty/theme.conf          # migrated from Config/.config/kitty/theme.conf
```

`Config/.config/kitty` and `Config/.config/rofi`'s existing theme files
(`theme.conf`, `themes/theme.rasi`) are `git mv`'d into
`Themes/obsidian/` and restyled to the obsidian palette. Their base
files (`kitty.conf`, `config.rasi`) stay in `Config/.config/` — both
already `include`/`@theme` a theme file today, so no structural change
is needed there, only a content/path update.

## Per-app overlay mechanism

| App | Base file | Include mechanism | Overlay file |
|---|---|---|---|
| Hyprland | `hyprland.conf` | `source = ~/.config/hypr/colors.conf` (native hyprlang `source`) | `Themes/obsidian/hypr/colors.conf` |
| Waybar | `style.css` | `@import "colors.css";` (GTK CSS import) | `Themes/obsidian/waybar/colors.css` |
| Rofi | `config.rasi` | `@theme "~/.config/rofi/themes/theme.rasi"` (already the existing pattern) | `Themes/obsidian/rofi/theme.rasi` |
| Kitty | `kitty.conf` | `include theme.conf` (already the existing pattern) | `Themes/obsidian/kitty/theme.conf` |
| Hyprlock | `hyprlock.conf` | `source = ~/.config/hyprlock/colors.conf` (hyprlang, same family as Hyprland) | `Themes/obsidian/hyprlock/colors.conf` |
| Dunst | `dunstrc` | **No base+overlay split** — dunst's INI-style config has no native include/import directive. The theme directory holds the complete `dunstrc`. | `Themes/obsidian/dunst/dunstrc` (whole file) |
| Hypridle | `hypridle.conf` | N/A — no theme file; nothing visual to theme | — |

Dunst is a deliberate exception to the base+overlay rule, not an
oversight: splitting a format that can't include files would just mean
hand-concatenating two files at deploy time, which is exactly the
merge-logic complexity this design otherwise avoids (see the rejected
"Approach B" discussion below). Since Dunst only has one theme's worth
of content this phase, shipping it whole is simpler and gets revisited
if/when a second theme exists and the duplication actually hurts.

## theme.env

Declares intent for system-level theming that isn't implemented yet —
data only, nothing reads or acts on it this phase:

```
GTK_THEME="obsidian-gtk"
ICON_THEME="Tela-circle-dark"
CURSOR_THEME="Bibata-Modern-Classic"
CURSOR_SIZE=24
FONT="CaskaydiaCove Nerd Font"
FONT_SIZE=10
```

A future phase that adds GTK/icon/cursor/font installation reads this
file; nothing in this phase requires the named packages to exist.

## The "obsidian" palette

| Role | Value | Used by |
|---|---|---|
| Background | `#121214` | Kitty bg, Rofi window bg, Waybar bg, Hyprlock bg |
| Background alt | `#1c1c20` | Rofi inputbar, Waybar module bg, Dunst bg |
| Foreground | `#E4E4E7` | Primary text, all apps |
| Foreground muted | `#8B8B93` | Placeholders, inactive text, Waybar secondary text |
| Accent (single) | `#6E8CAE` (muted desaturated blue) | Active window border, Rofi selection, Waybar active workspace, cursor, URLs |
| Border / inactive | `#ffffff1A` (10% white) | Window borders, dividers |
| Urgent / error | `#B57575` (muted red) | Dunst critical, low-battery indicator |

Kitty's terminal ANSI 16-colors move from the current Catppuccin Mocha
(pastel, multi-hue) to a desaturated palette in the same neutral-plus-
one-accent family — hues stay distinguishable for terminal use, just
muted rather than vivid. Rofi's current palette is already close to
this and is mostly reused as-is.

## Migration plan

1. `git mv Config/.config/kitty/theme.conf Themes/obsidian/kitty/theme.conf`,
   restyle to the obsidian palette.
2. `git mv Config/.config/rofi/themes/theme.rasi Themes/obsidian/rofi/theme.rasi`,
   restyle; update `config.rasi`'s `@theme` path if the target location
   changes (it doesn't — stays `~/.config/rofi/themes/theme.rasi` at
   deploy time, only the *repo source* path moves to `Themes/`).
3. Author new base configs for Hyprland, Waybar, Dunst, Hyprlock,
   Hypridle from scratch (none exist yet).
4. Author `Themes/obsidian/{hypr,waybar,hyprlock}/colors.*` and
   `Themes/obsidian/dunst/dunstrc` against the palette table above.
5. Write `Themes/obsidian/theme.env`.
6. Create the `Themes/active -> obsidian/` symlink.

`Config/.config/starship/` is untouched throughout.

## Testing approach

This phase produces static declarative config files, not shell
functions — there's no logic to unit test the way `detect.sh`/
`deploy.sh` had. Verification is manual, dogfooded on the owner's real
Fedora + Hyprland machine (same precedent as the MVP spec: no VM
infrastructure).

Because `install.sh`/`deploy.sh` aren't wired to the new `Themes/`
directory yet, base configs' include paths (e.g.
`~/.config/hypr/colors.conf`) won't resolve automatically from a plain
symlink deploy. For manual verification this phase, temporarily symlink
each overlay file from `Themes/active/<app>/...` to its include path by
hand — this is a documented, throwaway step, not a permanent mechanism;
real deploy wiring is the next phase's job.

**Manual verification checklist:**

- [ ] `hyprctl reload` (or a fresh Hyprland session start) completes
      with no config parse errors
- [ ] Waybar renders with the obsidian palette, no CSS parse warnings
      in its log output
- [ ] Rofi (`drun` mode) launches, themed correctly, selection uses the
      accent color
- [ ] A test notification (`notify-send`) appears styled per
      `Themes/obsidian/dunst/dunstrc`
- [ ] Hyprlock locks and renders with the obsidian palette
- [ ] Hypridle triggers lock/DPMS on schedule (unthemed, behavior-only
      check)
- [ ] Kitty opens with the desaturated obsidian ANSI palette

## Key decisions & rationale (for future reference)

- **Fedora-first now, supersedes the MVP spec's Arch-first priority** —
  the owner's current focus shifted; `detect.sh`/package-list format
  needed no changes since they were already distro-neutral.
- **Base+overlay, not full parallel theme trees.** Initially proposed
  full self-contained `Themes/<name>/.config/<app>/` trees per theme
  (simpler, fully independent themes). Rejected in favor of matching
  HyDE's actual model (fixed base config + small per-theme overlay
  file) once the real HyDE source was inspected — kitty and rofi
  already followed this pattern before this spec existed, which was
  the tell.
- **No wallbash, no external theme repos, no GTK/icon/cursor
  fetching.** HyDE's full model also includes wallpaper-driven dynamic
  color extraction, one-repo-per-theme distribution, and system-wide
  GTK/icon/cursor/font installation via a patch/downloader script.
  All three are real infrastructure the owner explicitly did not ask
  for; `theme.env` captures the *data shape* HyDE uses for the last one
  so a future phase can add the installer without redesigning the file
  format.
- **Dunst ships as a complete per-theme file, not base+overlay** —
  dunstrc has no native include directive; splitting it would require
  merge logic at deploy time, which contradicts the "no wallbash-style
  machinery" preference. Revisit only if a second theme makes the
  duplication costly.
- **One theme this phase, not several** — proves the architecture
  works end-to-end before spending effort on theme variety.
