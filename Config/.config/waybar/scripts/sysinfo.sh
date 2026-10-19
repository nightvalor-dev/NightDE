#!/usr/bin/env bash
# Waybar: three ring gauges (CPU, RAM, temperature) on the bar; full details in the tooltip.
# Prints one JSON line every few seconds.

INTERVAL=2

# Ring glyphs: empty circle + 8 slices (Nerd Font, Material Design)
RINGS=('󰝦' '󰪞' '󰪟' '󰪠' '󰪡' '󰪢' '󰪣' '󰪤' '󰪥')
ring() {  # percent -> glyph
    local p=$1; (( p < 0 )) && p=0; (( p > 100 )) && p=100
    echo "${RINGS[$(( (p * 8 + 50) / 100 ))]}"
}
span() { printf "<span color='%s'>%s</span>" "$1" "$2"; }

gib() { awk -v k="$1" 'BEGIN { printf "%.1f GiB", k / 1048576 }'; }

cpu_model=$(awk -F': ' '/^model name/ { print $2; exit }' /proc/cpuinfo)
cpu_model=${cpu_model//\"/}
threads=$(nproc)

# Pick a CPU temperature sensor (package temp if available, else the hottest zone)
temp_file=""
for z in /sys/class/thermal/thermal_zone*; do
    [ "$(cat "$z/type" 2>/dev/null)" = "x86_pkg_temp" ] && temp_file="$z/temp" && break
done
read_temp() {
    if [ -n "$temp_file" ]; then
        echo $(( $(cat "$temp_file") / 1000 ))
    else
        cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -n | tail -1 | awk '{ print int($1/1000) }'
    fi
}

read_cpu() {
    read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
    cpu_total=$((user + nice + system + idle + iowait + irq + softirq + steal))
    cpu_idle=$((idle + iowait))
}

read_cpu
prev_total=$cpu_total
prev_idle=$cpu_idle

while true; do
    sleep "$INTERVAL"

    # CPU
    read_cpu
    d_total=$((cpu_total - prev_total)); d_idle=$((cpu_idle - prev_idle))
    prev_total=$cpu_total; prev_idle=$cpu_idle
    usage=0; (( d_total > 0 )) && usage=$(( 100 * (d_total - d_idle) / d_total ))

    # Memory (kB)
    while read -r key value _; do
        case "$key" in
            MemTotal:) mem_total=$value ;; MemFree:) mem_free=$value ;;
            MemAvailable:) mem_avail=$value ;; Buffers:) buffers=$value ;;
            Cached:) cached=$value ;; SwapTotal:) swap_total=$value ;; SwapFree:) swap_free=$value ;;
        esac
    done < /proc/meminfo
    mem_used=$((mem_total - mem_avail)); mem_pct=$((100 * mem_used / mem_total))
    cache=$((buffers + cached)); swap_used=$((swap_total - swap_free))

    # Temperature
    temp=$(read_temp); temp=${temp:-0}
    tcol='#FFA066'; (( temp >= 80 )) && tcol='#E82424'

    text="$(span '#98BB6C' "$(ring "$usage")") ${usage}%   "
    text+="$(span '#7E9CD8' "$(ring "$mem_pct")") ${mem_pct}%   "
    text+="$(span "$tcol" "$(ring "$temp")") ${temp}°C"

    t="<b>CPU</b>\n"
    t+=$(printf '%-12s %s' "Model" "$cpu_model")"\n"
    t+=$(printf '%-12s %s' "Threads" "$threads")"\n"
    t+=$(printf '%-12s %s%%' "Usage" "$usage")"\n"
    t+=$(printf '%-12s %s°C' "Temperature" "$temp")"\n\n"
    t+="<b>Memory</b>\n"
    t+=$(printf '%-12s %s' "Installed" "$(gib "$mem_total")")"\n"
    t+=$(printf '%-12s %s (%s%%)' "In use" "$(gib "$mem_used")" "$mem_pct")"\n"
    t+=$(printf '%-12s %s' "Available" "$(gib "$mem_avail")")"\n"
    t+=$(printf '%-12s %s' "Unallocated" "$(gib "$mem_free")")"\n"
    t+=$(printf '%-12s %s' "Cache" "$(gib "$cache")")"\n\n"
    t+="<b>Swap</b>\n"
    t+=$(printf '%-12s %s / %s' "Used" "$(gib "$swap_used")" "$(gib "$swap_total")")

    printf '{"text": "%s", "tooltip": "%s"}\n' "$text" "$t"
done
