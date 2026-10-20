#!/usr/bin/env bash
# Print dunst's notification history as a JSON list for the sidebar:
# [{"id": 12, "app": "Firefox", "summary": "...", "body": "..."}, ...]
dunstctl history 2>/dev/null | python3 -c '
import json, re, sys
try:
    items = json.load(sys.stdin)["data"][0]
except Exception:
    print("[]"); sys.exit()
def val(n, key):
    return re.sub(r"<[^>]+>", "", str(n.get(key, {}).get("data", ""))).strip()
print(json.dumps([
    {"id": n["id"]["data"], "app": val(n, "appname"),
     "summary": val(n, "summary"), "body": val(n, "body")}
    for n in items
]))'
