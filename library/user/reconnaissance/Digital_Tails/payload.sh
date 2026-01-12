#!/bin/bash
# Title: Digital Tails (Persistent Devices)
# Passive-only. Tracks devices that persist nearby across scans (possible "tail").
# Uses Pager UI output methods (commands.sh) so it shows on the device screen.

set -u
export LC_ALL=C

DBG="/tmp/digital_tails.log"
: > "$DBG"

# ----------------------------
# Load Hak5 UI helpers FIRST
# ----------------------------
if [ -f /lib/hak5/commands.sh ]; then
  . /lib/hak5/commands.sh 2>>"$DBG" || true
fi

# ----------------------------
# UI Output (auto-detect)
# ----------------------------
ui_title() {
  # Prefer Hak5 TITLE if available
  if command -v TITLE >/dev/null 2>&1; then
    TITLE "$1"
    return
  fi
  echo "=== $1 ==="
}

ui_log() {
  # Prefer Hak5 LOG if available
  if command -v LOG >/dev/null 2>&1; then
    LOG "$1"
    return
  fi
  echo "[DT] $1"
}

ui_clear() {
  # Some firmwares support a clear/screen reset helper; if not, just print separator
  if command -v CLEAR >/dev/null 2>&1; then
    CLEAR
    return
  fi
  echo
}

# Always tee to debug log as well
tlog() { echo "$1" >>"$DBG"; }

trap 'command -v led_off >/dev/null 2>&1 && led_off 2>/dev/null || true' EXIT

# ----------------------------
# Config
# ----------------------------
SCAN_INTERVAL=5
WINDOW_SCANS=12
PERSIST_MIN=7
STRONG_RSSI=-55
MAX_SHOW=8
SAMPLE_ROWS=2500

DB="/mmc/root/recon/recon.db"
TABLE="wifi_device"

STATE_DIR="/tmp/digital_tails"
SEEN="$STATE_DIR/seen.psv"           # MAC|RSSI
STATE="$STATE_DIR/state.psv"         # MAC|BITS|RSSI
mkdir -p "$STATE_DIR"

# ----------------------------
# SQLite wrapper
# ----------------------------
sql() {
  sqlite3 "$DB" 2>>"$DBG" <<EOF
PRAGMA busy_timeout=2500;
.mode tabs
.headers off
$1
EOF
}

# ----------------------------
# Parse seen -> MAC|RSSI
# ----------------------------
parse_seen() {
  : > "$SEEN"
  sql "SELECT mac, signal FROM $TABLE ORDER BY rowid DESC LIMIT $SAMPLE_ROWS;" \
  | awk -F'\t' '
      function is_hex12(s){ return (s ~ /^[0-9A-Fa-f]{12}$/) }
      function is_colon(s){ return (s ~ /^[0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2}){5}$/) }
      function hex12_to_colon(h){
        h=toupper(h)
        return substr(h,1,2) ":" substr(h,3,2) ":" substr(h,5,2) ":" \
               substr(h,7,2) ":" substr(h,9,2) ":" substr(h,11,2)
      }
      NF>=2 {
        mac=$1; rssi=$2
        gsub(/[^0-9A-Fa-f:]/,"",mac)
        if (is_hex12(mac)) mac=hex12_to_colon(mac)
        if (!is_colon(mac)) next
        mac=toupper(mac)
        if (mac=="00:00:00:00:00:00") next
        if (rssi !~ /^-?[0-9]+$/) next
        print mac "|" rssi
      }
    ' | sort -u > "$SEEN"

  [ -s "$SEEN" ]
}

# ----------------------------
# Update state: MAC|BITS|RSSI
# ----------------------------
update_state() {
  [ -f "$STATE" ] || : > "$STATE"

  awk -F'|' -v W="$WINDOW_SCANS" '
    BEGIN{OFS="|"}
    FNR==NR { seen[$1]=$2; next }
    {
      mac=$1; bits=$2; last=$3

      gsub(/[^01]/,"",bits)
      if (length(bits) > W) bits = substr(bits, length(bits)-W+1)
      while (length(bits) < W) bits = "0" bits

      bits = substr(bits,2)
      if (mac in seen) { bits = bits "1"; last = seen[mac] }
      else            { bits = bits "0" }

      print mac, bits, last
      had[mac]=1
    }
    END{
      for (m in seen) if (!(m in had)) {
        bits=""
        for (i=1;i<=W-1;i++) bits=bits "0"
        bits=bits "1"
        print m, bits, seen[m]
      }
    }
  ' "$SEEN" "$STATE" > "$STATE.tmp" && mv -f "$STATE.tmp" "$STATE"
}

# ----------------------------
# ASCII bars
# ----------------------------
bars() {
  local r="$1" b=1
  if   [ "$r" -ge -35 ]; then b=10
  elif [ "$r" -ge -40 ]; then b=9
  elif [ "$r" -ge -45 ]; then b=8
  elif [ "$r" -ge -50 ]; then b=7
  elif [ "$r" -ge -55 ]; then b=6
  elif [ "$r" -ge -60 ]; then b=5
  elif [ "$r" -ge -65 ]; then b=4
  elif [ "$r" -ge -70 ]; then b=3
  elif [ "$r" -ge -80 ]; then b=2
  else b=1
  fi
  printf "%s" "$(printf '#%.0s' $(seq 1 "$b"))"
}

# ----------------------------
# Render to Pager UI
# ----------------------------
render() {
  ui_clear
  ui_title "DIGITAL TAILS"
  ui_log "Scan ${SCAN_INTERVAL}s | Window ${WINDOW_SCANS} | Persist>=${PERSIST_MIN} | Strong>=${STRONG_RSSI}"
  ui_log "Seen now: $(wc -l < "$SEEN" 2>/dev/null || echo 0)"
  echo

  # Build top list and print line-by-line
  awk -F'|' '
    function count1(s,   i,c){ c=0; for(i=1;i<=length(s);i++) if(substr(s,i,1)=="1") c++; return c }
    BEGIN{OFS="\t"}
    {
      mac=$1; bits=$2; rssi=$3
      gsub(/[^01]/,"",bits)
      c=count1(bits)
      if (rssi=="") rssi=-99
      print c, rssi, mac
    }
  ' "$STATE" | sort -k1,1nr -k2,2nr | head -n "$MAX_SHOW" \
    | while IFS=$'\t' read -r c rssi mac; do
        short="$(echo "$mac" | awk -F: '{print $(NF-3)":"$(NF-2)":"$(NF-1)":"$NF}')"

        flag="  "
        if [ "$c" -ge "$PERSIST_MIN" ] && [ "$rssi" -ge "$STRONG_RSSI" ]; then
          flag="!!"
        elif [ "$c" -ge "$PERSIST_MIN" ]; then
          flag="! "
        fi

        ui_log "$flag $short  seen:$c/$WINDOW_SCANS  rssi:$rssi  $(bars "$rssi")"
      done

  ui_log "!! persistent+strong | ! persistent"
}

# ----------------------------
# Start
# ----------------------------
ui_title "DIGITAL TAILS"
ui_log "Starting..."
ui_log "Debug: $DBG"
tlog "[BOOT] started"

while true; do
  if parse_seen; then
    update_state
    render
  else
    ui_clear
    ui_title "DIGITAL TAILS"
    ui_log "No devices parsed from DB."
    ui_log "Is Recon running?"
    ui_log "Debug: $DBG"
  fi
  sleep "$SCAN_INTERVAL"
done
