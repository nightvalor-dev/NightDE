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
]

GTK_BEGIN_OLD = "/* >>> NightDE theme colours (generated — edited on every theme switch) >>> */"
GTK_END_OLD = "/* <<< NightDE theme colours <<< */"


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

    style = {"lower": False}     # set per file in recolor()

    def keep_case(orig, new, context=""):
        """Write the new colour in the same letter case as the one it replaces.
        All-digit colours (e.g. 121212) carry no case, so use the alpha/prefix,
        then the file's usual style."""
        letters = [c for c in orig + context if c.isalpha() and c.lower() in "abcdef"]
        if letters:
            lower = all(c.islower() for c in letters)
        else:
            lower = style["lower"]
        return new.lower() if lower else new.upper()

    def hex_sub(m):
        body = m.group(2).upper()
        if body not in hex_map:
            return m.group(0)
        return m.group(1) + keep_case(m.group(2), hex_map[body], m.group(3) or "") + (m.group(3) or "")

    def rgb_sub(m):  # rgba(18, 18, 18, 0.7)  — keeps spacing style and alpha
        r, g, b = int(m.group(2)), int(m.group(4)), int(m.group(6))
        if (r, g, b) not in rgb_map:
            return m.group(0)
        nr, ng, nb = rgb_map[(r, g, b)]
        return f"{m.group(1)}{nr}{m.group(3)}{ng}{m.group(5)}{nb}"

    def argb_sub(m):  # 0xee1a1a1a (Hyprland shadow colours)
        body = m.group(2).upper()
        return m.group(1) + keep_case(m.group(2), hex_map[body], m.group(1)[2:]) if body in hex_map else m.group(0)

    hex_re = re.compile(r"(#|rgba?\()([0-9A-Fa-f]{6})([0-9A-Fa-f]{2})?(?![0-9A-Fa-f])")
    rgb_re = re.compile(r"(rgba?\(\s*)(\d{1,3})(\s*,\s*)(\d{1,3})(\s*,\s*)(\d{1,3})(?=\s*[,)])")
    argb_re = re.compile(r"(0x[0-9A-Fa-f]{2})([0-9A-Fa-f]{6})(?![0-9A-Fa-f])")

    case_re = re.compile(r"(?:#|0x|rgba?\()([0-9A-Fa-f]{6,8})(?![0-9A-Fa-f])")

    def recolor(text):
        found = "".join(c for c in "".join(case_re.findall(text)) if c.isalpha())
        style["lower"] = sum(c.islower() for c in found) > sum(c.isupper() for c in found)
        text = hex_re.sub(hex_sub, text)
        text = rgb_re.sub(rgb_sub, text)
        text = argb_re.sub(argb_sub, text)
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


def _rgba(hexc, a):
    r, g, b = hexrgb(hexc)
    return f"rgba({r}, {g}, {b}, {a})"


def gtk_css(p, gtk4):
    """Complete colour sheet for adw-gtk3 (GTK3) and libadwaita (GTK4)."""
    r = p["roles"]
    named = {
        "accent_color": r["accent"], "accent_bg_color": r["accent"], "accent_fg_color": r["bg"],
        "destructive_color": r["red"], "destructive_bg_color": r["red"], "destructive_fg_color": r["bg"],
        "success_color": r["green"], "success_bg_color": r["green"], "success_fg_color": r["bg"],
        "warning_color": r["yellow"], "warning_bg_color": r["yellow"], "warning_fg_color": _rgba(r["bg"], 0.8),
        "error_color": r["red"], "error_bg_color": r["red"], "error_fg_color": r["bg"],
        "window_bg_color": r["bg"], "window_fg_color": r["fg"],
        "view_bg_color": r["bg"], "view_fg_color": r["fg"],
        "headerbar_bg_color": r["bg_dim"], "headerbar_fg_color": r["fg"],
        "headerbar_border_color": r["fg"], "headerbar_backdrop_color": r["bg_dim"],
        "headerbar_shade_color": _rgba("#000000", 0.36),
        "sidebar_bg_color": r["bg_dim"], "sidebar_fg_color": r["fg"],
        "sidebar_backdrop_color": r["bg_dim"], "sidebar_shade_color": _rgba("#000000", 0.25),
        "sidebar_border_color": _rgba("#000000", 0.36),
        "secondary_sidebar_bg_color": r["bg_dim"], "secondary_sidebar_fg_color": r["fg"],
        "secondary_sidebar_backdrop_color": r["bg_dim"],
        "card_bg_color": r["bg_alt"], "card_fg_color": r["fg"], "card_shade_color": _rgba("#000000", 0.36),
        "dialog_bg_color": r["bg_alt"], "dialog_fg_color": r["fg"],
        "popover_bg_color": r["bg_alt"], "popover_fg_color": r["fg"], "popover_shade_color": _rgba("#000000", 0.25),
        "thumbnail_bg_color": r["bg_alt"], "thumbnail_fg_color": r["fg"],
        "shade_color": _rgba("#000000", 0.25), "scrollbar_outline_color": _rgba("#000000", 0.5),
        # GTK3 theme names (adw-gtk3 and older apps)
        "theme_bg_color": r["bg"], "theme_fg_color": r["fg"],
        "theme_base_color": r["bg"], "theme_text_color": r["fg"],
        "theme_selected_bg_color": r["accent"], "theme_selected_fg_color": r["bg"],
        "insensitive_fg_color": r["muted"], "borders": _rgba(r["fg"], 0.15),
    }
    out = [f"/* NightDE — {p['display']}. Generated by the theme switcher; rewritten on every switch. */", ""]
    out += [f"@define-color {k} {v};" for k, v in named.items()]
    if gtk4:   # libadwaita 1.6+ reads CSS variables
        out += ["", ":root {"]
        out += [f"  --{k.replace('_', '-')}: {v};" for k, v in named.items() if not k.startswith(("theme_", "insensitive", "borders"))]
        out += [f"  --border-color: {_rgba(r['fg'], 0.15)};", "}"]
    out += ["",
            "/* Highlighted text: the theme's selection colour */",
            "selection, text selection, entry selection, textview text selection {",
            f"  background-color: {r['selection']};",
            f"  color: {r['fg']};",
            "}", ""]
    return "\n".join(out)


def write_gtk(p):
    for v, gtk4 in (("gtk-3.0", False), ("gtk-4.0", True)):
        d = os.path.join(HOME, ".config", v)
        if not os.path.isdir(d):
            continue
        path = os.path.join(d, "gtk.css")
        if os.path.islink(path):          # an old theme's symlink: replace it with our own file
            os.unlink(path)
        write_if_changed(path, gtk_css(p, gtk4))


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
