#!/usr/bin/env bash
# Calendar data for the sidebar.
#   calendar.sh             -> print JSON for the shown month
#   calendar.sh prev|next   -> move one month and refresh the sidebar
#   calendar.sh today       -> back to the current month
STATE="${XDG_RUNTIME_DIR:-/tmp}/eww-calendar-offset"
EWW="$HOME/.local/bin/eww"
offset=$(cat "$STATE" 2>/dev/null || echo 0)

json() {
python3 - "$1" <<'PY'
import calendar, datetime, json, sys
offset = int(sys.argv[1])
today = datetime.date.today()
m = today.month - 1 + offset
year, month = today.year + m // 12, m % 12 + 1
weeks = []
dates = calendar.Calendar(firstweekday=0).monthdatescalendar(year, month)
# Always show 6 rows so the calendar never changes height between months
while len(dates) < 6:
    last = dates[-1][-1]
    dates.append([last + datetime.timedelta(days=i) for i in range(1, 8)])
for week in dates:
    row = []
    for d in week:
        c = "today" if d == today else ("other" if d.month != month else "day")
        row.append({"d": str(d.day), "c": c})
    weeks.append(row)
title = datetime.date(year, month, 1).strftime("%B %Y")
print(json.dumps({"title": title, "weeks": weeks}))
PY
}

case "$1" in
    prev)  offset=$((offset - 1)) ;;
    next)  offset=$((offset + 1)) ;;
    today) offset=0 ;;
    *)     json "$offset"; exit 0 ;;
esac
echo "$offset" > "$STATE"
"$EWW" update cal="$(json "$offset")"
