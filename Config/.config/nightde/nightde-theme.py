#!/usr/bin/env python3
"""NightDE theme engine.

Every theme defines the same 20 colour roles (palette.json). Switching themes
rewrites each role's colour from the old theme to the new one in your existing
config files, so your layouts and tweaks are kept. It also writes a few small
generated files (kitty, GTK, Qt) and sets the VS Code / Neovim theme.

Usage:
    nightde-theme.py list              display names + names, in sidebar order
    nightde-theme.py current           current theme name
    nightde-theme.py apply NAME        recolour everything to NAME
"""
import glob
import json
import os
import re
import shutil
import sys

HOME = os.path.expanduser("~")
BASE = os.path.join(HOME, ".config", "nightde")
THEMES = os.path.join(BASE, "themes")
STATE = os.path.join(BASE, "current")
DEFAULT = "kanagawa"

# Config files whose colours are swapped role-by-role (globs under ~)
RECOLOR_GLOBS = [
    ".config/waybar/config.jsonc",
    ".config/waybar/style.css",
    ".config/waybar/scripts/*.sh",
    ".config/waybar/menus/*.css",
    ".config/rofi/*.rasi",
    ".config/eww/*.scss",
    ".config/dunst/dunstrc",
    ".config/hypr/*.lua",
    ".config/hypr/**/*.lua",
    ".config/hypr/**/*.conf",
    ".config/gtk-3.0/gtk.css",
    ".config/gtk-4.0/gtk.css",
    ".dircolors",
]

GTK_BEGIN = "/* >>> NightDE theme colours (generated — edited on every theme switch) >>> */"
GTK_END = "/* <<< NightDE theme colours <<< */"


# ---------------------------------------------------------------- helpers
def load(name):
    with open(os.path.join(THEMES, name, "palette.json")) as f:
        return json.load(f)


def themes():
    out = []
    for d in os.listdir(THEMES):
        if os.path.isfile(os.path.join(THEMES, d, "palette.json")):
            p = load(d)
            out.append((p.get("order", 99), d, p["display"]))
    return [(d, disp) for _, d, disp in sorted(out)]


def current():
    try:
        with open(STATE) as f:
            name = f.read().strip()
        if os.path.isfile(os.path.join(THEMES, name, "palette.json")):
            return name
    except OSError:
        pass
    return DEFAULT


def hexrgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def write_if_changed(path, text):
    real = os.path.realpath(path)
    try:
        with open(real, encoding="utf-8") as f:
            if f.read() == text:
                return False
    except OSError:
        pass
    if not os.access(os.path.dirname(real) or ".", os.W_OK):
        print(f"  skip (not writable): {path}")
        return False
    tmp = real + ".nightde-tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(text)
    if os.path.exists(real):
        shutil.copymode(real, tmp)
    os.replace(tmp, real)
    return True


# ---------------------------------------------------------------- recolouring
def make_recolor(old, new):
    """Return a function that swaps every old-palette colour for the new one."""
    hex_map, rgb_map = {}, {}
    for role, o in old["roles"].items():
        n = new["roles"][role]
        hex_map[o.lstrip("#").upper()] = n.lstrip("#").upper()
        rgb_map[hexrgb(o)] = hexrgb(n)

    def hex_sub(m):
        body = m.group(2).upper()
        if body not in hex_map:
            return m.group(0)
        return m.group(1) + hex_map[body] + (m.group(3) or "")

    def rgb_sub(m):  # rgba(18, 18, 18, 0.7)  — keeps spacing style and alpha
        r, g, b = int(m.group(2)), int(m.group(4)), int(m.group(6))
        if (r, g, b) not in rgb_map:
            return m.group(0)
        nr, ng, nb = rgb_map[(r, g, b)]
        return f"{m.group(1)}{nr}{m.group(3)}{ng}{m.group(5)}{nb}"

    def argb_sub(m):  # 0xee1a1a1a (Hyprland shadow colours)
        body = m.group(2).upper()
        return m.group(1) + hex_map[body] if body in hex_map else m.group(0)

    def ansi_sub(m):  # 38;2;R;G;B  (true-colour codes in .dircolors)
        r, g, b = int(m.group(2)), int(m.group(3)), int(m.group(4))
        if (r, g, b) not in rgb_map:
            return m.group(0)
        nr, ng, nb = rgb_map[(r, g, b)]
        return f"{m.group(1)}{nr};{ng};{nb}"

    ansi_re = re.compile(r"((?:38|48);2;)(\d{1,3});(\d{1,3});(\d{1,3})")
    hex_re = re.compile(r"(#|rgba?\()([0-9A-Fa-f]{6})([0-9A-Fa-f]{2})?(?![0-9A-Fa-f])")
    rgb_re = re.compile(r"(rgba?\(\s*)(\d{1,3})(\s*,\s*)(\d{1,3})(\s*,\s*)(\d{1,3})(?=\s*[,)])")
    argb_re = re.compile(r"(0x[0-9A-Fa-f]{2})([0-9A-Fa-f]{6})(?![0-9A-Fa-f])")

    def recolor(text):
        text = hex_re.sub(hex_sub, text)
        text = rgb_re.sub(rgb_sub, text)
        text = argb_re.sub(argb_sub, text)
        text = ansi_re.sub(ansi_sub, text)
        return text

    return recolor


def recolor_files(old, new):
    recolor = make_recolor(old, new)
    seen, changed = set(), []
    for pattern in RECOLOR_GLOBS:
        for path in glob.glob(os.path.join(HOME, pattern), recursive=True):
            real = os.path.realpath(path)
            if real in seen or not os.path.isfile(real) or ".bak" in os.path.basename(path):
                continue
            seen.add(real)
            try:
                with open(real, encoding="utf-8") as f:
                    text = f.read()
            except (OSError, UnicodeDecodeError):
                continue
            if "nightde: no-recolor" in text[:400]:     # e.g. the theme dots, which must keep fixed colours
                continue
            if write_if_changed(path, recolor(text)):
                changed.append(path.replace(HOME, "~"))
    return changed


# ---------------------------------------------------------------- generated files
def write_kitty(name):
    """Write the theme's kitty colours to the file kitty.conf includes."""
    src = os.path.join(THEMES, name, "kitty.conf")
    kdir = os.path.join(HOME, ".config/kitty")
    if not (os.path.isfile(src) and os.path.isdir(kdir)):
        return
    try:
        with open(os.path.join(kdir, "kitty.conf")) as f:
            conf = f.read()
    except OSError:
        conf = ""
    target = "theme.conf" if re.search(r"^\s*include\s+theme\.conf\s*$", conf, re.M) else "current-theme.conf"
    with open(src) as f:
        write_if_changed(os.path.join(kdir, target), f.read())


def gtk_block(p):
    r = p["roles"]
    return "\n".join([
        GTK_BEGIN,
        f"@define-color accent_color {r['accent']};",
        f"@define-color accent_bg_color {r['accent']};",
        f"@define-color accent_fg_color {r['bg']};",
        f"@define-color window_bg_color {r['bg']};",
        f"@define-color window_fg_color {r['fg']};",
        f"@define-color view_bg_color {r['bg']};",
        f"@define-color view_fg_color {r['fg']};",
        f"@define-color headerbar_bg_color {r['bg_dim']};",
        f"@define-color headerbar_fg_color {r['fg']};",
        f"@define-color sidebar_bg_color {r['bg_dim']};",
        f"@define-color sidebar_fg_color {r['fg']};",
        f"@define-color popover_bg_color {r['bg_alt']};",
        f"@define-color popover_fg_color {r['fg']};",
        f"@define-color dialog_bg_color {r['bg_alt']};",
        f"@define-color dialog_fg_color {r['fg']};",
        f"@define-color card_bg_color {r['bg_alt']};",
        f"@define-color card_fg_color {r['fg']};",
        f"@define-color theme_bg_color {r['bg']};",
        f"@define-color theme_fg_color {r['fg']};",
        f"@define-color theme_base_color {r['bg']};",
        f"@define-color theme_text_color {r['fg']};",
        f"@define-color theme_selected_bg_color {r['selection']};",
        f"@define-color theme_selected_fg_color {r['fg']};",
        f"selection, text selection, entry selection, textview text selection "
        f"{{ background-color: {r['selection']}; color: {r['fg']}; }}",
        GTK_END,
    ])


def write_gtk(p):
    for v in ("gtk-3.0", "gtk-4.0"):
        d = os.path.join(HOME, ".config", v)
        if not os.path.isdir(d):
            continue
        path = os.path.join(d, "gtk.css")
        try:
            with open(os.path.realpath(path), encoding="utf-8") as f:
                text = f.read()
        except OSError:
            text = ""
        text = re.sub(re.escape(GTK_BEGIN) + r".*?" + re.escape(GTK_END) + r"\n?", "", text, flags=re.S)
        text = text.rstrip("\n") + ("\n\n" if text.strip() else "") + gtk_block(p) + "\n"
        write_if_changed(path, text)


def write_qt(name, p):
    d = os.path.join(HOME, ".config/qt6ct")
    conf = os.path.join(d, "qt6ct.conf")
    if not os.path.isfile(conf):
        return
    r = {k: v.lstrip("#").lower() for k, v in p["roles"].items()}
    own = os.path.join(d, "colors", "Kanagawa.conf")
    if name == "kanagawa" and os.path.isfile(own):
        scheme = own                       # keep your hand-tuned Kanagawa scheme
    else:
        a = lambda c: "#ff" + c
        active = [r["fg"], r["bg_alt"], r["surface"], r["bg_alt"], r["bg_dim"], r["surface"],
                  r["fg"], "ffffff", r["fg"], r["bg"], r["bg"], "000000", r["selection"], r["fg"],
                  r["blue"], r["magenta"], r["bg_dim"], r["bg"], r["bg_alt"], r["fg"], r["muted"]]
        disabled = list(active)
        for i in (0, 6, 8, 13, 19):        # text roles greyed out
            disabled[i] = r["muted"]
        line = lambda cols: ", ".join(a(c) for c in cols)
        scheme = os.path.join(d, "colors", "NightDE.conf")
        os.makedirs(os.path.dirname(scheme), exist_ok=True)
        write_if_changed(scheme, "[ColorScheme]\n"
                         f"active_colors={line(active)}\n"
                         f"disabled_colors={line(disabled)}\n"
                         f"inactive_colors={line(active)}\n")
    with open(conf) as f:
        text = f.read()
    if re.search(r"^color_scheme_path=", text, re.M):
        text = re.sub(r"^color_scheme_path=.*$", f"color_scheme_path={scheme}", text, flags=re.M)
    else:
        text = re.sub(r"^\[Appearance\]\s*$", f"[Appearance]\ncolor_scheme_path={scheme}", text, count=1, flags=re.M)
    text = re.sub(r"^custom_palette=.*$", "custom_palette=true", text, flags=re.M)
    write_if_changed(conf, text)



def write_vscode(p):
    if not p.get("vscode"):          # theme has no VS Code equivalent: leave VS Code as it is
        return
    for app in ("Code", "Code - OSS", "VSCodium"):
        path = os.path.join(HOME, ".config", app, "User", "settings.json")
        if not os.path.isfile(path):
            continue
        with open(path, encoding="utf-8") as f:
            text = f.read()
        new = re.sub(r'("workbench\.colorTheme"\s*:\s*)"[^"]*"', lambda m: m.group(1) + json.dumps(p["vscode"]), text)
        write_if_changed(path, new)


# ---------------------------------------------------------------- main
def apply(name):
    if not os.path.isfile(os.path.join(THEMES, name, "palette.json")):
        sys.exit(f"Unknown theme: {name}")
    old_name = current()
    old, new = load(old_name), load(name)
    changed = recolor_files(old, new) if old_name != name else []
    write_kitty(name)
    write_gtk(new)
    write_qt(name, new)
    write_vscode(new)
    os.makedirs(BASE, exist_ok=True)
    write_if_changed(STATE, name + "\n")
    print(f"{old_name} -> {name}")
    for c in changed:
        print("  recoloured", c)


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "list":
        for n, d in themes():
            print(f"{d}\t{n}")
    elif cmd == "names":
        print(" ".join(n for n, _ in themes()))
    elif cmd == "current":
        print(current())
    elif cmd == "apply" and len(sys.argv) == 3:
        apply(sys.argv[2])
    else:
        print(__doc__)
        sys.exit(1)
