#!/bin/sh
# Runs the given command (the tunnel connector) only while the local zephyrd is
# healthy: its RPC answers get_info with status OK, it reports itself
# synchronized, and it is not behind the height its peers announce.
#
#   gate.sh cloudflared tunnel --no-autoupdate run
#
# The connector is started after GATE_UP_AFTER good checks in a row and stopped
# after GATE_DOWN_AFTER bad ones, so Cloudflare sends requests to the other
# replicas instead. If the connector exits on its own, this script exits with
# its status and the container's restart policy takes over.
#
#   GATE_URL         http://zephyrd:17767/get_info
#   GATE_INTERVAL    seconds between checks (10)
#   GATE_UP_AFTER    good checks before the connector starts (2)
#   GATE_DOWN_AFTER  bad checks before the connector stops (3)
#   GATE_MAX_LAG     blocks zephyrd may be behind target_height (5)
set -eu

url=${GATE_URL:-http://zephyrd:17767/get_info}
interval=${GATE_INTERVAL:-10}
up_after=${GATE_UP_AFTER:-2}
down_after=${GATE_DOWN_AFTER:-3}
max_lag=${GATE_MAX_LAG:-5}

for v in "$interval" "$up_after" "$down_after" "$max_lag"; do
  case "$v" in ''|*[!0-9]*) echo "gate: not a non-negative integer: $v" >&2; exit 64 ;; esac
done
[ $# -gt 0 ] || { echo "gate: no command given" >&2; exit 64; }

log() { echo "gate: $*" >&2; }

field() { printf '%s\n' "$info" | sed -n "s/.*\"$1\": *\([0-9][0-9]*\).*/\1/p" | head -n 1; }

# Sets $reason when unhealthy.
healthy() {
  info=$(curl -fsS --max-time 5 "$url" 2>/dev/null) || { reason="no answer from zephyrd"; return 1; }
  printf '%s' "$info" | grep -q '"status": *"OK"' || { reason="status is not OK"; return 1; }
  printf '%s' "$info" | grep -q '"synchronized": *true' || { reason="not synchronized"; return 1; }
  height=$(field height); target=$(field target_height)
  if [ -n "$height" ] && [ -n "$target" ] && [ "$target" -gt $((height + max_lag)) ]; then
    reason="behind: height $height, target $target"; return 1
  fi
  return 0
}

child=''
stop_child() {
  [ -n "$child" ] || return 0
  kill -TERM "$child" 2>/dev/null || true
  wait "$child" 2>/dev/null || true
  child=''
}
trap 'log "stopping"; stop_child; exit 0' TERM INT

good=0; bad=0; reason=''
log "waiting for a healthy zephyrd at $url"
while :; do
  if healthy; then good=$((good + 1)); bad=0; else bad=$((bad + 1)); good=0; fi

  if [ -n "$child" ]; then
    if ! kill -0 "$child" 2>/dev/null; then
      rc=0; wait "$child" || rc=$?
      log "connector exited on its own with status $rc"
      exit "$rc"
    fi
    if [ "$bad" -ge "$down_after" ]; then
      log "zephyrd unhealthy ($reason); stopping the connector"
      stop_child
    fi
  elif [ "$good" -ge "$up_after" ]; then
    log "zephyrd healthy; starting the connector"
    "$@" &
    child=$!
  fi

  sleep "$interval" &
  wait $! || true
done
