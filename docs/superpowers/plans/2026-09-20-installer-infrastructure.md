# Installer Infrastructure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the shell installer substrate — distro/GPU detection, package-manager abstraction, the symlink deploy engine, and NVIDIA/bootloader handling — that `install.sh` orchestrates to turn `Config/.config/*` into a running desktop.

**Architecture:** Four small, single-responsibility bash libraries under `Scripts/lib/` (`detect.sh`, `pkg.sh`, `deploy.sh`, `gpu.sh`), each with pure/injectable functions so behavior is unit-testable without root or real hardware. `install.sh` sources all four and wires them together behind a `main()` function guarded so it only auto-runs when executed directly (not when sourced by tests).

**Tech Stack:** POSIX-ish bash (associative arrays require bash 4+, present on both Arch and Fedora), no external test framework — plain bash scripts with a small custom assert helper (`tests/lib/assert.sh`), no bats/shunit2 dependency.

**Spec:** `docs/superpowers/specs/2026-09-20-nightde-mvp-design.md`

## Global Constraints

- Distros in scope: Arch (`pacman`) and Fedora (`dnf`) — `detect_distro` must return exactly `arch`, `fedora`, or `unsupported`.
- GPU branches: `nvidia` and `other` (AMD/Intel) — `detect_gpu` must return exactly `nvidia` or `other`.
- NVIDIA bootloader patching must never run silently, must always back up the target config before first modification, must never re-create a backup that already exists, and must be skippable via a `--no-nvidia` flag.
- Deploy mechanism is plain bash with per-app `.preserve` files — no TOML, no external manifest parser.
- `Config/.config/<app>/` mirrors `$HOME/.config/<app>/` directly (already established by the existing `Config/.config/kitty/` directory).
- Every file that touches the real filesystem, `sudo`, or hardware state must take its target paths / privileged-command runner as parameters (or env-var overrides) so tests can redirect them to scratch fixtures — nothing in this plan is tested against the developer's real `$HOME`, `/etc`, or `/boot`.

---

### Task 1: Test helper + distro/GPU detection (`Scripts/lib/detect.sh`)

**Files:**
- Create: `tests/lib/assert.sh`
- Create: `Scripts/lib/detect.sh`
- Test: `tests/test_detect.sh`

**Interfaces:**
- Produces: `assert_eq(expected, actual, msg)` — prints `PASS: msg` and returns 0 on match, prints `FAIL: msg (expected 'X', got 'Y')` to stderr and exits 1 on mismatch. Used by every later test file.
- Produces: `detect_distro()` — echoes `arch`, `fedora`, or `unsupported` based on `command -v pacman`/`command -v dnf`.
- Produces: `detect_gpu()` — echoes `nvidia` or `other` based on `lspci | grep -qi nvidia`.

- [ ] **Step 1: Write the assert helper**

```bash
# tests/lib/assert.sh
assert_eq() {
  local expected="$1" actual="$2" msg="${3:-assert_eq}"
  if [[ "$expected" != "$actual" ]]; then
    echo "FAIL: $msg (expected '$expected', got '$actual')" >&2
    return 1
  fi
  echo "PASS: $msg"
}
```

- [ ] **Step 2: Write the failing test for detect.sh**

```bash
# tests/test_detect.sh
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/../Scripts/lib/detect.sh"

test_detect_distro_arch() {
  local stub_dir
  stub_dir="$(mktemp -d)"
  trap 'rm -rf "$stub_dir"' RETURN
  printf '#!/bin/sh\n' > "$stub_dir/pacman"
  chmod +x "$stub_dir/pacman"
  PATH="$stub_dir:$PATH" assert_eq "arch" "$(PATH="$stub_dir:$PATH" detect_distro)" "detect_distro finds pacman -> arch"
}

test_detect_distro_fedora() {
  local stub_dir
  stub_dir="$(mktemp -d)"
  trap 'rm -rf "$stub_dir"' RETURN
  printf '#!/bin/sh\n' > "$stub_dir/dnf"
  chmod +x "$stub_dir/dnf"
  assert_eq "fedora" "$(PATH="$stub_dir" detect_distro)" "detect_distro finds dnf -> fedora"
}

test_detect_distro_unsupported() {
  local stub_dir
  stub_dir="$(mktemp -d)"
  trap 'rm -rf "$stub_dir"' RETURN
  assert_eq "unsupported" "$(PATH="$stub_dir" detect_distro)" "detect_distro finds neither -> unsupported"
}

test_detect_gpu_nvidia() {
  local stub_dir
  stub_dir="$(mktemp -d)"
  trap 'rm -rf "$stub_dir"' RETURN
  printf '#!/bin/sh\necho "01:00.0 VGA compatible controller: NVIDIA Corporation TU117"\n' > "$stub_dir/lspci"
  chmod +x "$stub_dir/lspci"
  assert_eq "nvidia" "$(PATH="$stub_dir" detect_gpu)" "detect_gpu finds NVIDIA in lspci -> nvidia"
}

test_detect_gpu_other() {
  local stub_dir
  stub_dir="$(mktemp -d)"
  trap 'rm -rf "$stub_dir"' RETURN
  printf '#!/bin/sh\necho "01:00.0 VGA compatible controller: Advanced Micro Devices"\n' > "$stub_dir/lspci"
  chmod +x "$stub_dir/lspci"
  assert_eq "other" "$(PATH="$stub_dir" detect_gpu)" "detect_gpu finds no NVIDIA in lspci -> other"
}

test_detect_distro_arch
test_detect_distro_fedora
test_detect_distro_unsupported
test_detect_gpu_nvidia
test_detect_gpu_other
echo "All detect.sh tests passed."
```

- [ ] **Step 3: Run test to verify it fails**

Run: `bash tests/test_detect.sh`
Expected: FAIL — `Scripts/lib/detect.sh: No such file or directory` (file doesn't exist yet).

- [ ] **Step 4: Implement detect.sh**

```bash
# Scripts/lib/detect.sh
detect_distro() {
  if command -v pacman >/dev/null 2>&1; then
    echo "arch"
  elif command -v dnf >/dev/null 2>&1; then
    echo "fedora"
  else
    echo "unsupported"
  fi
}

detect_gpu() {
  if lspci 2>/dev/null | grep -qi nvidia; then
    echo "nvidia"
  else
    echo "other"
  fi
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `bash tests/test_detect.sh`
Expected: 5x `PASS` lines, then `All detect.sh tests passed.`

- [ ] **Step 6: Commit**

```bash
git add tests/lib/assert.sh tests/test_detect.sh Scripts/lib/detect.sh
git commit -m "feat: add distro/GPU detection with tests"
```

---

### Task 2: Package list parsing & install (`Scripts/lib/pkg.sh`)

**Files:**
- Create: `Scripts/lib/pkg.sh`
- Test: `tests/test_pkg.sh`
- Test fixture: `tests/fixtures/pkg_sample.lst`

**Interfaces:**
- Consumes: nothing from Task 1 directly (distro strings are just passed in as plain arguments by the caller).
- Produces: `parse_pkg_list(list_file, distro)` — pure function, echoes one package name per line for the given distro column.
- Produces: `PKG_INSTALL` — associative array, `PKG_INSTALL[arch]` / `PKG_INSTALL[fedora]`, each a full install command prefix string.
- Produces: `install_pkg_list(list_file, distro)` — parses the list, then runs `${PKG_INSTALL[$distro]} <packages>`. Used by `install.sh` in Task 5.

- [ ] **Step 1: Write the fixture package list**

```
# tests/fixtures/pkg_sample.lst
# <logical-name>  arch:<pkg>  fedora:<pkg>
hyprland          arch:hyprland          fedora:hyprland
waybar            arch:waybar            fedora:waybar
rofi              arch:rofi-wayland      fedora:rofi-wayland
```

- [ ] **Step 2: Write the failing test**

```bash
# tests/test_pkg.sh
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/../Scripts/lib/pkg.sh"

test_parse_pkg_list_arch() {
  local expected="hyprland
waybar
rofi-wayland"
  local actual
  actual="$(parse_pkg_list "$SCRIPT_DIR/fixtures/pkg_sample.lst" "arch")"
  assert_eq "$expected" "$actual" "parse_pkg_list extracts arch column"
}

test_parse_pkg_list_fedora() {
  local expected="hyprland
waybar
rofi-wayland"
  local actual
  actual="$(parse_pkg_list "$SCRIPT_DIR/fixtures/pkg_sample.lst" "fedora")"
  assert_eq "$expected" "$actual" "parse_pkg_list extracts fedora column"
}

test_install_pkg_list_invokes_installer() {
  local log_file
  log_file="$(mktemp)"
  trap 'rm -f "$log_file"' RETURN
  record_install() { printf '%s\n' "$@" >> "$log_file"; }
  PKG_INSTALL[arch]="record_install"
  install_pkg_list "$SCRIPT_DIR/fixtures/pkg_sample.lst" "arch"
  local expected="hyprland
waybar
rofi-wayland"
  assert_eq "$expected" "$(cat "$log_file")" "install_pkg_list passes parsed packages to installer"
}

test_parse_pkg_list_arch
test_parse_pkg_list_fedora
test_install_pkg_list_invokes_installer
echo "All pkg.sh tests passed."
```

- [ ] **Step 3: Run test to verify it fails**

Run: `bash tests/test_pkg.sh`
Expected: FAIL — `Scripts/lib/pkg.sh: No such file or directory`.

- [ ] **Step 4: Implement pkg.sh**

```bash
# Scripts/lib/pkg.sh
parse_pkg_list() {
  local list_file="$1" distro="$2"
  awk -v d="$distro" '
    !/^#/ && NF > 0 {
      for (i = 1; i <= NF; i++) {
        if ($i ~ "^" d ":") {
          print substr($i, length(d) + 2)
        }
      }
    }
  ' "$list_file"
}

declare -A PKG_INSTALL=(
  [arch]="sudo pacman -S --needed --noconfirm"
  [fedora]="sudo dnf install -y"
)

install_pkg_list() {
  local list_file="$1" distro="$2"
  local packages
  packages="$(parse_pkg_list "$list_file" "$distro")"
  [[ -z "$packages" ]] && return 0
  # shellcheck disable=SC2086
  xargs ${PKG_INSTALL[$distro]} <<< "$packages"
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `bash tests/test_pkg.sh`
Expected: 3x `PASS`, then `All pkg.sh tests passed.`

- [ ] **Step 6: Commit**

```bash
git add Scripts/lib/pkg.sh tests/test_pkg.sh tests/fixtures/pkg_sample.lst
git commit -m "feat: add package list parsing and install with tests"
```

---

### Task 3: Symlink deploy engine (`Scripts/lib/deploy.sh`)

**Files:**
- Create: `Scripts/lib/deploy.sh`
- Test: `tests/test_deploy.sh`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: `is_preserved(rel_path, preserve_list_path)` — return code 0 if `rel_path` is listed in `preserve_list_path`, 1 otherwise (or if the file doesn't exist).
- Produces: `deploy_app(app_dir, target_root)` — symlinks every file under `app_dir` into `target_root/$(basename app_dir)/`, honoring `.preserve` and backing up pre-existing real files to `<file>.nightde.bkp`. Used by `install.sh` in Task 5 as `deploy_app "$app_config_dir" "$HOME/.config"`.

- [ ] **Step 1: Write the failing test**

```bash
# tests/test_deploy.sh
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/../Scripts/lib/deploy.sh"

setup_fixture() {
  local base
  base="$(mktemp -d)"
  mkdir -p "$base/src/testapp"
  echo "config content" > "$base/src/testapp/app.conf"
  mkdir -p "$base/target"
  echo "$base"
}

test_fresh_deploy_creates_symlink() {
  local base src target
  base="$(setup_fixture)"; trap 'rm -rf "$base"' RETURN
  src="$base/src/testapp"; target="$base/target"

  deploy_app "$src" "$target"

  [[ -L "$target/testapp/app.conf" ]] && assert_eq "0" "0" "app.conf is a symlink after fresh deploy" \
    || { echo "FAIL: app.conf is not a symlink" >&2; return 1; }
  assert_eq "config content" "$(cat "$target/testapp/app.conf")" "symlinked file reads through to source content"
}

test_idempotent_rerun_no_duplicate_backup() {
  local base src target
  base="$(setup_fixture)"; trap 'rm -rf "$base"' RETURN
  src="$base/src/testapp"; target="$base/target"

  deploy_app "$src" "$target"
  deploy_app "$src" "$target"

  [[ ! -e "$target/testapp/app.conf.nightde.bkp" ]] && assert_eq "0" "0" "no backup created on idempotent re-run" \
    || { echo "FAIL: unexpected backup file on re-run" >&2; return 1; }
}

test_backs_up_preexisting_real_file() {
  local base src target
  base="$(setup_fixture)"; trap 'rm -rf "$base"' RETURN
  src="$base/src/testapp"; target="$base/target"
  mkdir -p "$target/testapp"
  echo "user's real file" > "$target/testapp/app.conf"

  deploy_app "$src" "$target"

  assert_eq "user's real file" "$(cat "$target/testapp/app.conf.nightde.bkp")" "pre-existing real file backed up before overwrite"
  [[ -L "$target/testapp/app.conf" ]] && assert_eq "0" "0" "app.conf replaced with symlink after backup" \
    || { echo "FAIL: app.conf not replaced with symlink" >&2; return 1; }
}

test_preserve_leaves_existing_file_alone() {
  local base src target
  base="$(setup_fixture)"; trap 'rm -rf "$base"' RETURN
  src="$base/src/testapp"; target="$base/target"
  echo "app.conf" > "$src/.preserve"
  mkdir -p "$target/testapp"
  echo "user's customized content" > "$target/testapp/app.conf"

  deploy_app "$src" "$target"

  assert_eq "user's customized content" "$(cat "$target/testapp/app.conf")" "preserved file left untouched when already present"
  [[ ! -L "$target/testapp/app.conf" ]] && assert_eq "0" "0" "preserved existing file is not converted to a symlink" \
    || { echo "FAIL: preserved file was symlinked" >&2; return 1; }
}

test_preserve_still_deploys_on_first_install() {
  local base src target
  base="$(setup_fixture)"; trap 'rm -rf "$base"' RETURN
  src="$base/src/testapp"; target="$base/target"
  echo "app.conf" > "$src/.preserve"

  deploy_app "$src" "$target"

  [[ -L "$target/testapp/app.conf" ]] && assert_eq "0" "0" "preserved file still symlinked on first install (nothing to preserve yet)" \
    || { echo "FAIL: preserved file not deployed on first install" >&2; return 1; }
}

test_fresh_deploy_creates_symlink
test_idempotent_rerun_no_duplicate_backup
test_backs_up_preexisting_real_file
test_preserve_leaves_existing_file_alone
test_preserve_still_deploys_on_first_install
echo "All deploy.sh tests passed."
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_deploy.sh`
Expected: FAIL — `Scripts/lib/deploy.sh: No such file or directory`.

- [ ] **Step 3: Implement deploy.sh**

```bash
# Scripts/lib/deploy.sh
is_preserved() {
  local rel="$1" preserve_list="$2"
  [[ -f "$preserve_list" ]] || return 1
  grep -qxF "$rel" "$preserve_list"
}

deploy_app() {
  local app_dir="$1" target_root="$2"
  local app target_dir preserve_list
  app="$(basename "$app_dir")"
  target_dir="$target_root/$app"
  preserve_list="$app_dir/.preserve"

  mkdir -p "$target_dir"
  find "$app_dir" -type f ! -name '.preserve' | while read -r src; do
    rel="${src#"$app_dir"/}"
    dest="$target_dir/$rel"

    if is_preserved "$rel" "$preserve_list" && [[ -e "$dest" ]]; then
      continue
    fi
    mkdir -p "$(dirname "$dest")"
    if [[ -e "$dest" && ! -L "$dest" ]]; then
      mv "$dest" "$dest.nightde.bkp"
    fi
    ln -sf "$src" "$dest"
  done
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/test_deploy.sh`
Expected: multiple `PASS` lines, then `All deploy.sh tests passed.`

- [ ] **Step 5: Commit**

```bash
git add Scripts/lib/deploy.sh tests/test_deploy.sh
git commit -m "feat: add symlink deploy engine with preserve/backup tests"
```

---

### Task 4: GPU driver install & NVIDIA bootloader patch (`Scripts/lib/gpu.sh`)

**Files:**
- Create: `Scripts/lib/gpu.sh`
- Test: `tests/test_gpu.sh`

**Interfaces:**
- Consumes: distro string (`arch`/`fedora`) and gpu string (`nvidia`/`other`) as produced by Task 1's `detect_distro`/`detect_gpu`.
- Produces: `run_privileged(cmd...)` — thin wrapper around `sudo "$@"`; tests override this function to log calls instead of executing.
- Produces: `install_nvidia_driver(distro)`, `install_mesa_packages(distro)`.
- Produces: `patch_bootloader_nvidia()` — reads `GRUB_CONFIG_PATH` (default `/etc/default/grub`), `GRUB_OUTPUT_PATH` (default `/boot/grub/grub.cfg`), `SYSTEMD_BOOT_ENTRIES_DIR` (default `/boot/loader/entries`) from env, so tests can redirect to scratch fixtures.
- Produces: `configure_gpu(distro, gpu, no_nvidia)` — top-level entry point used by `install.sh` in Task 5.

- [ ] **Step 1: Write the failing test**

```bash
# tests/test_gpu.sh
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/../Scripts/lib/gpu.sh"

test_install_nvidia_driver_arch() {
  local log_file; log_file="$(mktemp)"; trap 'rm -f "$log_file"' RETURN
  run_privileged() { printf '%s\n' "$@" >> "$log_file"; }
  install_nvidia_driver "arch"
  assert_eq "pacman
-S
--needed
--noconfirm
nvidia-dkms" "$(cat "$log_file")" "install_nvidia_driver runs pacman with nvidia-dkms on arch"
}

test_install_nvidia_driver_fedora() {
  local log_file; log_file="$(mktemp)"; trap 'rm -f "$log_file"' RETURN
  run_privileged() { printf '%s\n' "$@" >> "$log_file"; }
  install_nvidia_driver "fedora"
  assert_eq "dnf
install
-y
akmod-nvidia" "$(cat "$log_file")" "install_nvidia_driver runs dnf with akmod-nvidia on fedora"
}

test_install_mesa_packages_arch() {
  local log_file; log_file="$(mktemp)"; trap 'rm -f "$log_file"' RETURN
  run_privileged() { printf '%s\n' "$@" >> "$log_file"; }
  install_mesa_packages "arch"
  assert_eq "pacman
-S
--needed
--noconfirm
mesa
vulkan-radeon
vulkan-intel" "$(cat "$log_file")" "install_mesa_packages runs pacman with mesa+vulkan on arch"
}

test_patch_grub_nvidia_fresh() {
  local base; base="$(mktemp -d)"; trap 'rm -rf "$base"' RETURN
  echo 'GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"' > "$base/grub"
  local log_file; log_file="$(mktemp)"; trap 'rm -f "$log_file"' RETURN
  run_privileged() { printf '%s\n' "$@" >> "$log_file"; }
  GRUB_CONFIG_PATH="$base/grub" GRUB_OUTPUT_PATH="$base/grub.cfg" patch_grub_nvidia
  grep -q 'nvidia_drm.modeset=1' "$base/grub" && assert_eq "0" "0" "grub cmdline patched with nvidia_drm.modeset=1" \
    || { echo "FAIL: grub cmdline not patched" >&2; return 1; }
  assert_eq 'GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"' "$(cat "$base/grub.nightde.bkp")" "original grub config backed up before patch"
}

test_patch_grub_nvidia_idempotent() {
  local base; base="$(mktemp -d)"; trap 'rm -rf "$base"' RETURN
  echo 'GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"' > "$base/grub"
  run_privileged() { :; }
  GRUB_CONFIG_PATH="$base/grub" patch_grub_nvidia
  local first_backup_content; first_backup_content="$(cat "$base/grub.nightde.bkp")"
  GRUB_CONFIG_PATH="$base/grub" patch_grub_nvidia
  local occurrences
  occurrences="$(grep -o 'nvidia_drm.modeset=1' "$base/grub" | wc -l)"
  assert_eq "1" "$occurrences" "second patch run does not duplicate the modeset flag"
  assert_eq "$first_backup_content" "$(cat "$base/grub.nightde.bkp")" "second patch run does not overwrite existing backup"
}

test_configure_gpu_skips_nvidia_when_flagged() {
  local log_file; log_file="$(mktemp)"; trap 'rm -f "$log_file"' RETURN
  install_nvidia_driver() { echo "SHOULD_NOT_RUN" >> "$log_file"; }
  patch_bootloader_nvidia() { echo "SHOULD_NOT_RUN" >> "$log_file"; }
  configure_gpu "arch" "nvidia" "true"
  assert_eq "" "$(cat "$log_file")" "configure_gpu skips driver+bootloader when no_nvidia=true"
}

test_install_nvidia_driver_arch
test_install_nvidia_driver_fedora
test_install_mesa_packages_arch
test_patch_grub_nvidia_fresh
test_patch_grub_nvidia_idempotent
test_configure_gpu_skips_nvidia_when_flagged
echo "All gpu.sh tests passed."
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_gpu.sh`
Expected: FAIL — `Scripts/lib/gpu.sh: No such file or directory`.

- [ ] **Step 3: Implement gpu.sh**

```bash
# Scripts/lib/gpu.sh
run_privileged() {
  sudo "$@"
}

install_nvidia_driver() {
  local distro="$1"
  case "$distro" in
    arch)   run_privileged pacman -S --needed --noconfirm nvidia-dkms ;;
    fedora) run_privileged dnf install -y akmod-nvidia ;;
  esac
}

install_mesa_packages() {
  local distro="$1"
  case "$distro" in
    arch)   run_privileged pacman -S --needed --noconfirm mesa vulkan-radeon vulkan-intel ;;
    fedora) run_privileged dnf install -y mesa-dri-drivers mesa-vulkan-drivers ;;
  esac
}

patch_grub_nvidia() {
  local cfg="${GRUB_CONFIG_PATH:-/etc/default/grub}"
  local out="${GRUB_OUTPUT_PATH:-/boot/grub/grub.cfg}"
  local bkp="${cfg}.nightde.bkp"

  [[ -f "$bkp" ]] || cp "$cfg" "$bkp"

  if ! grep -q 'nvidia_drm.modeset=1' "$cfg"; then
    sed -i -E 's/^(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*)"/\1 nvidia_drm.modeset=1"/' "$cfg"
    echo "Patched $cfg (backup at $bkp)"
  else
    echo "$cfg already has nvidia_drm.modeset=1, skipping"
  fi
  run_privileged grub-mkconfig -o "$out"
}

patch_systemd_boot_nvidia() {
  local entries_dir="${SYSTEMD_BOOT_ENTRIES_DIR:-/boot/loader/entries}"
  local entry
  entry="$(find "$entries_dir" -name '*.conf' | head -n1)"
  if [[ -z "$entry" ]]; then
    echo "WARNING: no systemd-boot entry found in $entries_dir" >&2
    return 1
  fi
  local bkp="${entry}.nightde.bkp"
  [[ -f "$bkp" ]] || cp "$entry" "$bkp"

  if ! grep -q 'nvidia_drm.modeset=1' "$entry"; then
    sed -i -E 's/^(options .*)$/\1 nvidia_drm.modeset=1/' "$entry"
    echo "Patched $entry (backup at $bkp)"
  else
    echo "$entry already has nvidia_drm.modeset=1, skipping"
  fi
  run_privileged bootctl update
}

patch_bootloader_nvidia() {
  local cfg="${GRUB_CONFIG_PATH:-/etc/default/grub}"
  local entries_dir="${SYSTEMD_BOOT_ENTRIES_DIR:-/boot/loader/entries}"
  if [[ -f "$cfg" ]]; then
    patch_grub_nvidia
  elif [[ -d "$entries_dir" ]]; then
    patch_systemd_boot_nvidia
  else
    echo "WARNING: could not detect grub or systemd-boot; add nvidia_drm.modeset=1 to your kernel cmdline manually." >&2
  fi
}

configure_gpu() {
  local distro="$1" gpu="$2" no_nvidia="$3"
  case "$gpu" in
    nvidia)
      if [[ "$no_nvidia" == "true" ]]; then
        echo "NVIDIA detected but --no-nvidia passed; skipping driver and bootloader changes."
        return 0
      fi
      install_nvidia_driver "$distro"
      patch_bootloader_nvidia
      ;;
    other)
      install_mesa_packages "$distro"
      ;;
  esac
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/test_gpu.sh`
Expected: 6x `PASS`-bearing test functions complete, then `All gpu.sh tests passed.`

- [ ] **Step 5: Commit**

```bash
git add Scripts/lib/gpu.sh tests/test_gpu.sh
git commit -m "feat: add GPU driver install and NVIDIA bootloader patch with tests"
```

---

### Task 5: `install.sh` orchestrator + `Scripts/pkg_core.lst`

**Files:**
- Create: `Scripts/pkg_core.lst`
- Create: `install.sh`
- Test: `tests/test_install.sh`

**Interfaces:**
- Consumes: `detect_distro`, `detect_gpu` (Task 1); `install_pkg_list` (Task 2); `deploy_app` (Task 3); `configure_gpu` (Task 4).
- Produces: `main()` in `install.sh`, guarded to only auto-run when the script is executed directly; honors `NIGHTDE_ROOT` (default: script's own directory) and `NIGHTDE_TARGET` (default: `$HOME/.config`) env overrides so tests can redirect both the source tree and the deploy target to scratch fixtures.

- [ ] **Step 1: Write the initial package list**

```
# Scripts/pkg_core.lst
# <logical-name>  arch:<pkg>          fedora:<pkg>
hyprland          arch:hyprland       fedora:hyprland
waybar            arch:waybar         fedora:waybar
rofi              arch:rofi-wayland   fedora:rofi-wayland
dunst             arch:dunst          fedora:dunst
kitty             arch:kitty          fedora:kitty
hyprlock          arch:hyprlock       fedora:hyprlock
hypridle          arch:hypridle       fedora:hypridle
```

- [ ] **Step 2: Write the failing test**

```bash
# tests/test_install.sh
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/assert.sh"

setup_fixture_root() {
  local base; base="$(mktemp -d)"
  mkdir -p "$base/Config/.config/app-one" "$base/Config/.config/app-two"
  echo "one" > "$base/Config/.config/app-one/one.conf"
  echo "two" > "$base/Config/.config/app-two/two.conf"
  echo "$base"
}

test_main_wires_everything_in_order() {
  local root target log_file
  root="$(setup_fixture_root)"; trap 'rm -rf "$root"' RETURN
  target="$(mktemp -d)"; trap 'rm -rf "$target"' RETURN
  log_file="$(mktemp)"; trap 'rm -f "$log_file"' RETURN

  source "$SCRIPT_DIR/../install.sh"

  detect_distro() { echo "arch"; }
  detect_gpu() { echo "nvidia"; }
  install_pkg_list() { printf 'install_pkg_list %s %s\n' "$1" "$2" >> "$log_file"; }
  configure_gpu() { printf 'configure_gpu %s %s %s\n' "$1" "$2" "$3" >> "$log_file"; }
  deploy_app() { printf 'deploy_app %s %s\n' "$(basename "$1")" "$2" >> "$log_file"; }

  NIGHTDE_ROOT="$root" NIGHTDE_TARGET="$target" main --no-nvidia

  local expected
  expected="install_pkg_list $root/Scripts/pkg_core.lst arch
configure_gpu arch nvidia true
deploy_app app-one $target
deploy_app app-two $target"
  assert_eq "$expected" "$(cat "$log_file")" "main calls pkg install, gpu config, and deploy_app per app in expected shape"
}

test_main_errors_on_unsupported_distro() {
  local root target
  root="$(setup_fixture_root)"; trap 'rm -rf "$root"' RETURN
  target="$(mktemp -d)"; trap 'rm -rf "$target"' RETURN

  source "$SCRIPT_DIR/../install.sh"
  detect_distro() { echo "unsupported"; }

  local output status
  set +e
  output="$(NIGHTDE_ROOT="$root" NIGHTDE_TARGET="$target" main 2>&1)"
  status=$?
  set -e
  [[ $status -ne 0 ]] && assert_eq "0" "0" "main exits non-zero on unsupported distro" \
    || { echo "FAIL: main did not exit non-zero on unsupported distro" >&2; return 1; }
  [[ "$output" == *"unsupported distro"* ]] && assert_eq "0" "0" "main prints a clear error for unsupported distro" \
    || { echo "FAIL: error message missing expected text" >&2; return 1; }
}

test_main_wires_everything_in_order
test_main_errors_on_unsupported_distro
echo "All install.sh tests passed."
```

- [ ] **Step 3: Run test to verify it fails**

Run: `bash tests/test_install.sh`
Expected: FAIL — `install.sh: No such file or directory`.

- [ ] **Step 4: Implement install.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/Scripts/lib/detect.sh"
source "$SCRIPT_DIR/Scripts/lib/pkg.sh"
source "$SCRIPT_DIR/Scripts/lib/deploy.sh"
source "$SCRIPT_DIR/Scripts/lib/gpu.sh"

main() {
  local no_nvidia="false"
  for arg in "$@"; do
    [[ "$arg" == "--no-nvidia" ]] && no_nvidia="true"
  done

  local root_dir="${NIGHTDE_ROOT:-$SCRIPT_DIR}"
  local target_root="${NIGHTDE_TARGET:-$HOME/.config}"

  local distro gpu
  distro="$(detect_distro)"
  if [[ "$distro" == "unsupported" ]]; then
    echo "ERROR: unsupported distro (need pacman or dnf)" >&2
    exit 1
  fi
  gpu="$(detect_gpu)"

  install_pkg_list "$root_dir/Scripts/pkg_core.lst" "$distro"
  configure_gpu "$distro" "$gpu" "$no_nvidia"

  local app_dir
  for app_dir in "$root_dir"/Config/.config/*/; do
    deploy_app "${app_dir%/}" "$target_root"
  done

  echo "NightDE install complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
```

- [ ] **Step 5: Run test to verify it passes**

Run: `bash tests/test_install.sh`
Expected: `PASS` lines, then `All install.sh tests passed.`

- [ ] **Step 6: Commit**

```bash
git add Scripts/pkg_core.lst install.sh tests/test_install.sh
git commit -m "feat: add install.sh orchestrator wiring detect/pkg/deploy/gpu"
```

---

### Task 6: Test runner + README install instructions

**Files:**
- Create: `tests/run_all.sh`
- Modify: `README.md`

**Interfaces:**
- Consumes: nothing new — wires the test files from Tasks 1-5 together.
- Produces: `tests/run_all.sh`, a single command to run the whole suite.

- [ ] **Step 1: Write the test runner**

```bash
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for test_file in "$SCRIPT_DIR"/test_*.sh; do
  echo "=== Running $test_file ==="
  bash "$test_file"
done
echo "=== All test suites passed ==="
```

- [ ] **Step 2: Run it to verify the whole suite passes**

Run: `chmod +x tests/run_all.sh && bash tests/run_all.sh`
Expected: all five `test_*.sh` suites run and pass in sequence, ending with `=== All test suites passed ===`.

- [ ] **Step 3: Update README with install instructions and manual verification checklist**

Add to `README.md` (after the existing Features/Components sections):

```markdown
## Installing

```shell
git clone <repo-url> ~/NightDE
cd ~/NightDE
./install.sh            # pass --no-nvidia to skip NVIDIA driver/bootloader changes
```

Safe to re-run: `install.sh` is idempotent — re-running it won't duplicate
package installs, won't re-patch an already-patched bootloader config, and
won't clobber files listed in an app's `.preserve` list.

**Tested:** Arch Linux (primary target).
**Designed for, not yet verified:** Fedora — the package-manager and driver
paths exist and are unit-tested, but the end-to-end install hasn't been run
on real Fedora hardware yet. The NVIDIA+Fedora combination additionally
requires RPM Fusion to be enabled before `akmod-nvidia` will install; this
isn't automated.

### Manual verification checklist (run before trusting a change to `install.sh`, `Scripts/lib/gpu.sh`, or the package lists)

- [ ] `bash tests/run_all.sh` passes
- [ ] Fresh Arch VM/box: `./install.sh` completes without error, reboots into
      a working Hyprland session (bar, launcher, notifications, terminal,
      lock/idle all present)
- [ ] Re-running `./install.sh` on the same box exits cleanly with no
      duplicate work or errors
- [ ] On NVIDIA hardware: confirm `/etc/default/grub` (or the systemd-boot
      entry) was backed up to `*.nightde.bkp` before any modification, and
      that `nvidia_drm.modeset=1` appears exactly once in the kernel
      cmdline after a reboot
```

- [ ] **Step 4: Commit**

```bash
git add tests/run_all.sh README.md
git commit -m "docs: add install instructions, test runner, and manual verification checklist"
```
