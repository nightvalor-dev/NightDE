#!/usr/bin/env bash
# NightDE clipboard dropdown (eww + cliphist)
#   clipboard.sh toggle      open / close the dropdown (Waybar button)
#   clipboard.sh close
#   clipboard.sh next|prev   change page
#   clipboard.sh paste ID    copy entry ID back to the clipboard and paste it
#   clipboard.sh wipe        clear the history
EWW="$HOME/.local/bin/eww"
PER_PAGE=15
STATE="${XDG_RUNTIME_DIR:-/tmp}/eww-clip-page"

page_json() {   # $1 = page index (0-based) -> JSON for the dropdown
    cliphist list 2>/dev/null | python3 -c '
import json, sys
per, page = int(sys.argv[1]), int(sys.argv[2])
items = []
for line in sys.stdin.read().splitlines():
    if "\t" not in line:
        continue
    cid, text = line.split("\t", 1)
    image = text.startswith("[[ binary data")
    text = " ".join(text.split())[:200] or "(blank)"
    items.append({"id": cid, "text": text, "image": image})
pages = max(1, -(-len(items) // per))
page = min(max(page, 0), pages - 1)
print(json.dumps({
    "items": items[page * per:(page + 1) * per],
    "page": page + 1, "pages": pages, "total": len(items),
    "has_prev": page > 0, "has_next": page < pages - 1,
}))
print(page, file=sys.stderr)
' "$PER_PAGE" "$1" 2>"$STATE.tmp"
    mv -f "$STATE.tmp" "$STATE" 2>/dev/null
}

refresh() { "$EWW" update clip="$(page_json "$1")"; }

is_open() { "$EWW" active-windows 2>/dev/null | grep -q "^clipboard:"; }

close() { "$HOME/.config/eww/scripts/panels.sh" close; }   # also leaves the Esc key mode

case "$1" in
    toggle)
        if is_open; then close; exit 0; fi
        # Only one top-right panel at a time
        "$EWW" close sidebar sidebar-closer >/dev/null 2>&1
        refresh 0
        "$EWW" open clip-closer >/dev/null 2>&1
        # Open directly under the mouse (i.e. under the Waybar icon you clicked)
        read -r x mon_x mon_w < <(python3 -c '
import json, subprocess
cur = json.loads(subprocess.run(["hyprctl", "cursorpos", "-j"], capture_output=True, text=True).stdout or "{}")
mons = json.loads(subprocess.run(["hyprctl", "monitors", "-j"], capture_output=True, text=True).stdout or "[]")
m = next((m for m in mons if m.get("focused")), mons[0] if mons else {"x": 0, "width": 1920, "scale": 1})
print(int(cur.get("x", 0)), int(m.get("x", 0)), int(m["width"] / m.get("scale", 1)))
' 2>/dev/null || echo "0 0 1920")
        WIDTH=400
        left=$(( x - mon_x - WIDTH / 2 ))
        (( left < 6 )) && left=6
        (( left > mon_w - WIDTH - 6 )) && left=$(( mon_w - WIDTH - 6 ))
        "$EWW" open clipboard --anchor "top left" --pos "${left}x6" >/dev/null 2>&1
        "$HOME/.config/eww/scripts/panels.sh" enter          # Esc now closes the dropdown
        ;;
    close)
        close
        ;;
    next|prev)
        p=$(cat "$STATE" 2>/dev/null || echo 0)
        [ "$1" = next ] && p=$((p + 1)) || p=$((p - 1))
        refresh "$p"
        ;;
    paste)
        [ -n "$2" ] || exit 1
        close
        cliphist list | grep -m1 "^$2	" | cliphist decode | wl-copy
        sleep 0.2                        # let focus settle back on your window
        # Terminals paste with Ctrl+Shift+V, everything else with Ctrl+V
        class=$(hyprctl activewindow -j 2>/dev/null | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("class",""))
except Exception: print("")')
        case "$class" in
            kitty|nmtui|*terminal*|*Terminal*|foot|Alacritty|org.wezfurlong.wezterm)
                wtype -M ctrl -M shift v -m shift -m ctrl ;;
            *)
                wtype -M ctrl v -m ctrl ;;
        esac
        ;;
    wipe)
        cliphist wipe
        refresh 0
        ;;
    *)
        echo "usage: clipboard.sh toggle|close|next|prev|paste ID|wipe"; exit 1 ;;
esac
