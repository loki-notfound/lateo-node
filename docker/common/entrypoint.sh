#!/bin/sh
# Builds the zephyrd command line from environment variables, then replaces this
# shell with zephyrd so it receives stop signals directly.
#
# Arguments given to the container are appended last. zephyrd rejects an option
# that appears twice, so do not pass an option that is fixed below or that an
# environment variable already sets.
set -eu

die() { echo "entrypoint: $*" >&2; exit 64; }

is_true() {
  case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
    1|true|yes|on) return 0 ;;
    0|false|no|off|'') return 1 ;;
    *) die "not a boolean: $1" ;;
  esac
}

is_uint() {
  case "$1" in ''|*[!0-9]*) return 1 ;; *) return 0 ;; esac
}

user_args=$(for a in "$@"; do printf '%s\n' "$a"; done)

# Fixed: data location, binds inside the container, no prompts, no UPnP.
set -- --non-interactive \
  --data-dir=/data \
  --log-file=/data/zephyrd.log \
  --max-log-files=5 \
  --p2p-bind-ip=0.0.0.0 \
  --p2p-bind-port=17766 \
  --rpc-bind-ip=0.0.0.0 \
  --rpc-bind-port=17767 \
  --confirm-external-bind \
  --no-igd

if is_true "${RESTRICTED_RPC:-true}"; then
  set -- "$@" --restricted-rpc
elif [ -z "${RPC_LOGIN:-}" ]; then
  echo "entrypoint: warning: full RPC without RPC_LOGIN; never publish port 17767" >&2
fi

[ -z "${RPC_LOGIN:-}" ] || set -- "$@" --rpc-login="$RPC_LOGIN"
if is_true "${DISABLE_RPC_BAN:-false}"; then set -- "$@" --disable-rpc-ban; fi
if is_true "${PUBLIC_NODE:-false}"; then set -- "$@" --public-node; fi
if is_true "${PRUNE:-false}"; then set -- "$@" --prune-blockchain; fi
if is_true "${HIDE_MY_PORT:-false}"; then set -- "$@" --hide-my-port; fi
if ! is_true "${ZMQ:-false}"; then set -- "$@" --no-zmq; fi

for spec in LOG_LEVEL:--log-level OUT_PEERS:--out-peers IN_PEERS:--in-peers \
            MAX_CONNECTIONS_PER_IP:--max-connections-per-ip \
            LIMIT_RATE_UP:--limit-rate-up LIMIT_RATE_DOWN:--limit-rate-down; do
  var=${spec%%:*}; flag=${spec#*:}
  eval "val=\${$var:-}"
  [ -z "$val" ] && continue
  is_uint "$val" || die "$var must be a non-negative integer: $val"
  set -- "$@" "$flag=$val"
done

# Comma-separated host:port lists; each item becomes one repeated option.
for spec in ADD_PEERS:--add-peer PRIORITY_NODES:--add-priority-node \
            EXCLUSIVE_NODES:--add-exclusive-node SEED_NODES:--seed-node; do
  var=${spec%%:*}; flag=${spec#*:}
  eval "list=\${$var:-}"
  [ -z "$list" ] && continue
  old_ifs=$IFS; IFS=,
  for item in $list; do
    item=$(printf '%s' "$item" | tr -d '[:space:]')
    [ -n "$item" ] && set -- "$@" "$flag=$item"
  done
  IFS=$old_ifs
done

if [ -n "$user_args" ]; then
  old_ifs=$IFS; IFS='
'
  for a in $user_args; do set -- "$@" "$a"; done
  IFS=$old_ifs
fi

if [ -n "${RPC_LOGIN:-}" ]; then login=set; else login=unset; fi
echo "entrypoint: starting zephyrd (restricted RPC: ${RESTRICTED_RPC:-true}, RPC login: $login)" >&2
exec /usr/local/bin/zephyrd "$@"
