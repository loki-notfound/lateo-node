#!/bin/sh
# Offline checks of a built zephyrd image. No network access is needed or used.
#
#   tests/image-test.sh <image> <expected version, e.g. v2.3.0-3adbb517a>
#
# ENGINE selects the container engine (default docker; podman works too).
# PLATFORM, if set, is passed as --platform.
set -eu

image=$1
version=$2
engine=${ENGINE:-docker}
name="image-test-$$"

fail() { echo "FAIL: $*" >&2; $engine rm -f "$name" >/dev/null 2>&1 || true; exit 1; }
pass() { echo "ok: $*"; }

run_sh() { $engine run --rm ${PLATFORM:+"--platform=$PLATFORM"} --network none --entrypoint sh "$image" -c "$1"; }

# Binary, user, PID 1.
out=$(run_sh 'zephyrd --version')
case "$out" in *"($version)"*) pass "version $version" ;; *) fail "version: $out" ;; esac
[ "$(run_sh 'id -u')" = 10001 ] || fail "uid"
pass "runs as uid 10001"

# Entrypoint: environment to flags, without starting zephyrd.
argv=$($engine run --rm ${PLATFORM:+"--platform=$PLATFORM"} --network none --entrypoint sh \
  -e ADD_PEERS='a.example:17766, b.example:17766' -e DISABLE_RPC_BAN=1 -e OUT_PEERS=16 \
  "$image" -c 'sed "s#^exec /usr/local/bin/zephyrd#printf \"%s\\\\n\"#" /usr/local/bin/entrypoint.sh > /tmp/e.sh; sh /tmp/e.sh --db-sync-mode=safe 2>/dev/null')
for want in --restricted-rpc --disable-rpc-ban --no-zmq --out-peers=16 \
            --add-peer=a.example:17766 --add-peer=b.example:17766 --db-sync-mode=safe; do
  printf '%s\n' "$argv" | grep -qx -- "$want" || fail "entrypoint argv lacks $want"
done
[ "$(printf '%s\n' "$argv" | tail -1)" = --db-sync-mode=safe ] || fail "container arguments are not last"
pass "entrypoint argv"

set +e
$engine run --rm ${PLATFORM:+"--platform=$PLATFORM"} --network none -e OUT_PEERS=abc "$image" >/dev/null 2>&1
rc=$?
set -e
[ "$rc" = 64 ] || fail "invalid value exit $rc"
pass "invalid value exits 64"

# Offline start: healthy, restricted, PID 1 is tini, clean stop.
$engine run -d --name "$name" ${PLATFORM:+"--platform=$PLATFORM"} --network none "$image" --offline >/dev/null
i=0
until $engine exec "$name" /usr/local/bin/healthcheck.sh >/dev/null 2>&1; do
  i=$((i + 1)); [ $i -le 90 ] || fail "not healthy after 180 s"; sleep 2
done
pass "healthy after about $((i * 2)) s"
[ "$($engine exec "$name" cat /proc/1/comm)" = tini ] || fail "PID 1"
pass "PID 1 is tini"
info=$($engine exec "$name" curl -s http://127.0.0.1:17767/get_info)
printf '%s' "$info" | grep -q '"restricted": *true' || fail "not restricted"
pass "restricted RPC"
denied=$($engine exec "$name" curl -s -X POST http://127.0.0.1:17767/json_rpc \
  -d '{"jsonrpc":"2.0","id":0,"method":"get_connections"}')
printf '%s' "$denied" | grep -q 'Method not found' || fail "admin method answered"
pass "admin method refused"
$engine stop -t 120 "$name" >/dev/null
rc=$($engine inspect -f '{{.State.ExitCode}}' "$name")
$engine rm "$name" >/dev/null
[ "$rc" = 0 ] || fail "stop exit $rc"
pass "clean stop, exit 0"

# A stop right after start ends at once instead of waiting for SIGKILL.
$engine run -d --name "$name" ${PLATFORM:+"--platform=$PLATFORM"} --network none "$image" --offline >/dev/null
sleep 1
start=$(date +%s)
$engine stop -t 60 "$name" >/dev/null
took=$(( $(date +%s) - start ))
rc=$($engine inspect -f '{{.State.ExitCode}}' "$name")
$engine rm "$name" >/dev/null
[ "$took" -lt 30 ] || fail "early stop took ${took} s"
pass "early stop in ${took} s (exit $rc)"

echo "all checks passed: $image"
