#!/usr/bin/env bash
# Wallpaper list for the NightDE left sidebar.
#   wallpapers.sh list      JSON rows of two {path, thumb, name} for the current theme
#   wallpapers.sh current   the wallpaper currently set for the current theme
# Thumbnails are made once with ImageMagick and cached in ~/.cache/nightde/thumbs.
BASE="$HOME/.config/nightde"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/nightde"
theme=$(cat "$BASE/current" 2>/dev/null || echo kanagawa)

case "$1" in
    current)
        cat "$STATE/wall-$theme" 2>/dev/null || true ;;
    list)
        python3 - "$BASE/themes/$theme" "$HOME/.cache/nightde/thumbs" <<'PY'
import hashlib, json, os, shutil, subprocess, sys
folder, cache = sys.argv[1], sys.argv[2]
exts = (".jpg", ".jpeg", ".png", ".webp", ".gif")
paths = []
wdir = os.path.join(folder, "wallpapers")
if os.path.isdir(wdir):
    paths += sorted(os.path.join(wdir, f) for f in os.listdir(wdir) if f.lower().endswith(exts))
# an older single wallpaper.* next to palette.json also counts
paths += sorted(os.path.join(folder, f) for f in os.listdir(folder)
                if f.startswith("wallpaper.") and f.lower().endswith(exts)) if os.path.isdir(folder) else []
os.makedirs(cache, exist_ok=True)
magick = shutil.which("magick") or shutil.which("convert")
items = []
for p in paths:
    st = os.stat(p)
    key = hashlib.md5(f"{p}:{st.st_mtime_ns}:{st.st_size}".encode()).hexdigest()
    thumb = os.path.join(cache, key + ".jpg")
    if not os.path.exists(thumb) and magick:
        subprocess.run([magick, p + "[0]", "-thumbnail", "256x144^", "-gravity", "center",
                        "-extent", "256x144", "-quality", "85", thumb],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    items.append({"path": p, "thumb": thumb if os.path.exists(thumb) else p,
                  "name": os.path.splitext(os.path.basename(p))[0]})
print(json.dumps([items[i:i + 2] for i in range(0, len(items), 2)]))
PY
        ;;
    *)
        echo "usage: wallpapers.sh list|current"; exit 1 ;;
esac
