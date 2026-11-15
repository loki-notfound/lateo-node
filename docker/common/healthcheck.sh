#!/bin/sh
# Healthy when the local RPC answers get_info with status OK. With
# HEALTH_REQUIRE_SYNC=true the node must also report itself synchronized.
# RPC_LOGIN goes to curl on stdin, so it does not show up in the process list.
set -eu
info=$(
  {
    if [ -n "${RPC_LOGIN:-}" ]; then
      printf 'digest\nuser = "%s"\n' "$RPC_LOGIN"
    fi
  } | curl -fsS --max-time 8 -K - http://127.0.0.1:17767/get_info
)
printf '%s' "$info" | grep -q '"status": *"OK"'
case "$(printf '%s' "${HEALTH_REQUIRE_SYNC:-false}" | tr '[:upper:]' '[:lower:]')" in
  1|true|yes|on) printf '%s' "$info" | grep -q '"synchronized": *true' ;;
esac
