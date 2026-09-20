# NightDE MVP Design

Date: 2026-09-20
Status: Approved, pre-implementation

## Purpose

NightDE is a portable, themeable Hyprland desktop-environment framework,
inspired by [HyDE](https://github.com/HyDE-Project/HyDE) but deliberately
smaller in scope. It bundles a shell installer, curated Wayland-stack
configs, and (post-MVP) a wallpaper-to-palette theming pipeline.

Primary audience: personal daily-driver use across the owner's own Arch
and (later) Fedora machines, built cleanly enough to reinstall on new
hardware or hand to a friend — not a public project optimized for
strangers on the internet. No contributor docs, i18n, or broad
third-party hardware compatibility testing are in scope.

## Non-goals (MVP)

- SDDM theming
- Wallpaper-to-palette theming pipeline
- `nightde-cli` day-to-day wrapper (theme switch, wallpaper change, reload)
- Verified Fedora install (code exists and is designed-for, but untested
  end to end for MVP)
- Automated test suite / CI matrix for the shell scripts
- Public-project concerns: contributor docs, issue templates, i18n

## Distro & hardware scope

- **Distros:** Arch Linux (primary, fully tested for MVP) and Fedora
  (designed for now, verified as a fast-follow — see "Design for it now,
  build Fedora later" decision below).
- **GPU vendors:** NVIDIA and AMD/Intel, both branched and documented.
  The NVIDIA+Fedora combination (RPM Fusion + akmod-nvidia) is
  implemented but unverified on real hardware for MVP; flag it as such
  rather than claiming it works.

## Repo layout

```
NightDE/
├── install.sh                  # entry point, orchestrates everything below
├── Scripts/
│   ├── lib/
│   │   ├── detect.sh           # distro family + GPU vendor detection
│   │   ├── pkg.sh              # package-manager abstraction (install/query per distro)
│   │   └── deploy.sh           # symlink engine (walks Config/.config/*)
│   ├── pkg_core.lst            # base packages, distro-tagged
│   └── pkg_extra.lst           # optional packages, same format
├── Config/
│   └── .config/
│       ├── hypr/
│       ├── waybar/
│       ├── rofi/
│       ├── dunst/
│       ├── kitty/              # already exists
│       ├── hyprlock/
│       └── hypridle/
└── README.md
```

`install.sh` sources `Scripts/lib/*.sh` as function libraries rather than
shelling out to a dozen loosely-coupled scripts (contrast with HyDE's
`install_pre.sh`/`install_pkg.sh`/`install_pst.sh`/`global_fn.sh` split).
Each lib file has one job: `detect.sh` answers "what am I running on,"
`pkg.sh` turns a package list into the right install command, `deploy.sh`
turns `Config/.config/` into real symlinks in `$HOME/.config/`.

`Config/.config/<app>/` mirrors the real `$HOME/.config/<app>/` tree
directly (the convention already established by the existing
`Config/.config/kitty/` directory) rather than a flatter
`Config/<app>/` layout.

## Deploy engine (`Scripts/lib/deploy.sh`)

For each directory under `Config/.config/<app>/`, symlink its files into
`$HOME/.config/<app>/`, preserving anything the user has locally
customized.

```bash
deploy_app() {
  local app_dir="$1"                      # e.g. Config/.config/hypr
  local app="$(basename "$app_dir")"
  local target_dir="$HOME/.config/$app"
  local preserve_list="$app_dir/.preserve" # optional, one filename per line

  mkdir -p "$target_dir"
  find "$app_dir" -type f ! -name '.preserve' | while read -r src; do
    rel="${src#"$app_dir"/}"
    dest="$target_dir/$rel"

    if is_preserved "$rel" "$preserve_list" && [[ -e "$dest" ]]; then
      continue   # user already has it deployed and it's marked hands-off
    fi
    mkdir -p "$(dirname "$dest")"
    [[ -e "$dest" && ! -L "$dest" ]] && mv "$dest" "$dest.nightde.bkp"  # back up real (non-symlink) files once
    ln -sf "$src" "$dest"
  done
}
```

Rules that make this idempotent and safe to re-run:

- Only individual files are symlinked, never whole directories — a user
  can drop a private extra file into `~/.config/hypr/` without it
  vanishing on the next install.
- A pre-existing **real** file (not already a symlink from a prior run)
  is backed up once with a `.nightde.bkp` suffix before being replaced —
  mirrors HyDE's "always back up before clobbering" pattern.
- `.preserve` lists filenames (e.g. `userprefs.conf`) that are symlinked
  on first install only; if the target already exists on a later run,
  it's left alone so local edits to that specific file survive
  `install.sh` re-runs. Kitty's existing config already anticipates this
  (`#include userprefs.conf`, marked "to be configured by user and
  remains static") — `userprefs.conf` goes in kitty's `.preserve` list
  once added.

## Package installation & distro detection (`detect.sh` + `pkg.sh`)

Distro family detection is a one-time check, not per-package:

```bash
detect_distro() {
  if command -v pacman >/dev/null; then echo "arch"
  elif command -v dnf >/dev/null; then echo "fedora"
  else echo "unsupported"; fi
}
```

Package lists carry per-distro names as data, not logic — a flat,
greppable format rather than TOML, since there's no manifest parser to
write:

```
# Scripts/pkg_core.lst
# <logical-name>  arch:<pkg>  fedora:<pkg>
hyprland          arch:hyprland          fedora:hyprland
waybar            arch:waybar            fedora:waybar
kitty             arch:kitty             fedora:kitty
rofi              arch:rofi-wayland      fedora:rofi-wayland
```

`pkg.sh` picks the right column for the detected distro and the right
install command:

```bash
PKG_INSTALL[arch]="sudo pacman -S --needed --noconfirm"
PKG_INSTALL[fedora]="sudo dnf install -y"

install_pkg_list() {
  local list_file="$1" distro="$2"
  awk -v d="$distro" '!/^#/ && $0 !~ /^$/ { for(i=1;i<=NF;i++) if ($i ~ "^"d":") print substr($i, length(d)+2) }' "$list_file" \
    | xargs ${PKG_INSTALL[$distro]}
}
```

This is the "design for Fedora now, build it later" decision: the
format and code already branch cleanly on distro, but only the `arch:`
column needs to be fully correct and tested for MVP. Any package
missing a `fedora:` entry when running on Fedora is a loud error, not a
silent skip.

## GPU / NVIDIA handling

Same `detect.sh`, a separate function, run once during install:

```bash
detect_gpu() {
  lspci | grep -qi nvidia && echo "nvidia" || echo "other"
}
```

- **`other` (AMD/Intel):** install `mesa` + the relevant Vulkan package
  from the distro's package list. No bootloader changes.
- **`nvidia`:** install the DKMS driver (`nvidia-dkms` on Arch,
  `akmod-nvidia` from RPM Fusion on Fedora — Fedora's path needs RPM
  Fusion enabled first, documented as its own pre-step), then patch the
  bootloader:
  1. Detect grub vs systemd-boot.
  2. Back up the relevant config to `*.nightde.bkp` if a backup doesn't
     already exist.
  3. `sed`-inject `nvidia_drm.modeset=1` into the kernel cmdline
     (grub's `GRUB_CMDLINE_LINUX_DEFAULT` or the systemd-boot entry's
     `options` line).
  4. Regenerate the bootloader config (`grub-mkconfig` / `bootctl
     update` as applicable).
  5. Print exactly what was changed and where the backup lives. This
     step never runs silently and is skippable via a `--no-nvidia`
     flag, per CLAUDE.md's instruction to document hardware-specific
     branches explicitly rather than assume.

The Fedora+NVIDIA combination (RPM Fusion enablement, akmod build
timing) is implemented but not verified end to end for MVP — call this
out explicitly in the README/acceptance checklist rather than claiming
it works.

## MVP scope & acceptance criteria

| In MVP | Out of MVP (next phase) |
|---|---|
| Configs: hypr, waybar, rofi, dunst, kitty, hyprlock, hypridle | SDDM theming |
| `install.sh`: distro detect, GPU branch, package install, deploy | Wallpaper-to-palette pipeline |
| Idempotent re-run (`./install.sh` twice = no errors, no duplicate work) | `nightde-cli` wrapper |
| Arch fully tested on real hardware | Fedora verified end-to-end (code exists, untested) |
| README with real install steps | — |

**Done** means: fresh Arch box → `./install.sh` → reboot → Hyprland
session with the bar, launcher, notifications, terminal, and lock/idle
all working, using the actual configs (not placeholders) — and running
`install.sh` again afterward doesn't break or duplicate anything.

## Testing approach

No VM infrastructure for MVP — this is dogfooded manually:

- `deploy.sh` gets a quick local check (run against a scratch `$HOME`
  override, confirm symlink / `.preserve` / backup behavior) since that
  logic is easy to get subtly wrong and cheap to verify without
  touching real hardware.
- `install.sh` end-to-end is verified by actually running it on the
  owner's real Arch machine (and later Fedora, post-MVP) — matches
  "personal use, built to be portable," not a CI matrix.
- No automated test suite for the shell scripts beyond that; would be
  scope creep for this phase.

## Key decisions & rationale (for future reference)

- **Configs-first, installer-later** build order: get a working desktop
  before automating deployment.
- **Fedora: design now, verify later.** Package-manager abstraction is
  built from day one so retrofitting isn't needed, but only Arch is
  required to be correct for MVP.
- **Theming pipeline (post-MVP):** plain shell/awk + ImageMagick-style
  dominant-color extraction with HyDE-style template substitution, no
  external binary dependency (matugen/pywal) — deferred decision to
  revisit when that phase starts, but the approach is already chosen.
- **NVIDIA + AMD/Intel both in scope**, since both are present across
  the owner's machines; bootloader patching always backs up first and
  is never silent.
- **Deploy mechanism: plain bash with `.preserve` flag files**, not a
  TOML manifest — no parser to write or maintain, ~50 lines total,
  matches HyDE's `sync`/`preserve` idea without HyDE's Python
  deez-dots engine.
