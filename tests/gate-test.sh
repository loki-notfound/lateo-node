#!/bin/sh
# Checks deploy/ha/gate/gate.sh against a stub origin and a stub connector:
# the connector runs only while the origin looks like a healthy, synchronized
# zephyrd. Needs python3 and curl; uses 127.0.0.1:18999. Run from the
# repository root.
set -eu

gate=deploy/ha/gate/gate.sh
dir=$(mktemp -d)
srv=''; gp=''
cleanup() { [ -z "$gp" ] || kill "$gp" 2>/dev/null || true; [ -z "$srv" ] || kill "$srv" 2>/dev/null || true; rm -rf "$dir"; }
trap cleanup EXIT
fail() { echo "FAIL: $*" >&2; cat "$dir/gate.log" >&2 2>/dev/null || true; exit 1; }
pass() { echo "ok: $*"; }

info() { printf '{\n  "height": %s,\n  "status": "%s",\n  "synchronized": %s,\n  "target_height": %s\n}\n' "$@" > "$dir/info.json"; }

cat > "$dir/srv.py" <<'PY'
import http.server, sys
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        try:
            body = open(sys.argv[1], "rb").read()
        except OSError:
            self.send_error(503)
            return
        self.send_response(200)
        self.end_headers()
        self.wfile.write(body)
    def log_message(self, *args):
        pass
http.server.HTTPServer(("127.0.0.1", 18999), H).serve_forever()
PY
python3 "$dir/srv.py" "$dir/info.json" &
srv=$!

running() { [ -e "$dir/started" ] && kill -0 "$(cat "$dir/started")" 2>/dev/null; }
expect() { # expect up|down <what>
  i=0
  while :; do
    if running; then s=up; else s=down; fi
    [ "$s" = "$1" ] && break
    i=$((i + 1)); [ $i -le 20 ] || fail "$2: connector is not $1"
    sleep 1
  done
  pass "$2: connector $1"
}

info 100 OK false 0
GATE_URL=http://127.0.0.1:18999/ GATE_INTERVAL=1 sh "$gate" \
  sh -c 'echo $$ > "$0/started"; exec sleep 1000' "$dir" 2> "$dir/gate.log" &
gp=$!
sleep 4; running && fail "started while not synchronized"
pass "not synchronized: connector down"
info 100 OK true 0;     expect up   "synchronized"
info 100 OK true 200;   expect down "behind its peers"
info 100 OK true 103;   expect up   "within the allowed lag"
info 100 BUSY true 0;   expect down "status not OK"
info 100 OK true 0;     expect up   "recovered"
rm "$dir/info.json";    expect down "no answer"
info 100 OK true 0;     expect up   "recovered again"

kill -TERM "$gp"; rc=0; wait "$gp" || rc=$?; gp=''
[ "$rc" = 0 ] || fail "stop exit $rc"
running && fail "connector survived the stop"
pass "stop ends the connector, exit 0"

rc=0
GATE_URL=http://127.0.0.1:18999/ GATE_INTERVAL=1 sh "$gate" sh -c 'sleep 2; exit 7' 2>> "$dir/gate.log" || rc=$?
[ "$rc" = 7 ] || fail "connector exit status not passed on: $rc"
pass "a connector that exits ends the gate with its status"

rc=0; GATE_INTERVAL=x sh "$gate" true 2>/dev/null || rc=$?
[ "$rc" = 64 ] || fail "invalid value exit $rc"
pass "invalid value exits 64"
echo "all gate checks passed"
