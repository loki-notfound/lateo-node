# Run a highly available public node behind Cloudflare

This is the shape of node.lateo.dev: one public hostname, several hosts, each
running zephyrd next to a cloudflared connector of the same Cloudflare Tunnel.
Cloudflare sends each request to a connected replica; when a host goes down, the
others keep serving. The tunnel needs no inbound port on any host.

    wallet ──https──> Cloudflare ──tunnel──> cloudflared ─> zephyrd   (host A)
                                    └──────> cloudflared ─> zephyrd   (host B)
                                    └──────> cloudflared ─> zephyrd   (host C)

## What it needs
- A domain on a Cloudflare account (the free plan is enough for the tunnel).
- Two or more hosts, each meeting [the requirements of a standalone node](standalone-node.md#what-it-needs).
- Docker with Compose on every host.

## 1. Create the tunnel
In the Cloudflare dashboard, under Zero Trust, create a Cloudflare Tunnel of the
cloudflared type. Copy the token from the install instructions. It is a secret:
anyone holding it can attach a connector to your hostname.

## 2. Route the hostname
Add a public hostname to the tunnel, for example `node.example.com`, with service
type HTTP and URL `zephyrd:17767`. That is the Compose service name; every
replica resolves it to its own local daemon.

## 3. Start each replica
Either image works; `ZEPHYR_IMAGE` in `.env` selects the official release instead
of myzephyr ([docker/README.md](../docker/README.md) compares them). Use the same
image on every replica. On every host:

    cd deploy/ha
    cp example.env .env          # put the token in TUNNEL_TOKEN
    docker compose up -d --build

The connector container starts at once, but it attaches to the tunnel only while
its zephyrd is healthy: the RPC answers, the node reports itself synchronized and
it is not behind its peers. A fresh replica therefore takes no requests during
its first sync, and a replica whose daemon stops, restarts or falls behind drops
out of the tunnel until it has recovered. Follow it with:

    docker compose logs -f cloudflared
    docker compose exec zephyrd healthcheck.sh && echo synchronized

Copying a synchronized data volume from another replica (with both daemons
stopped) saves the initial sync. The daemon runs as uid and gid 10001; if you
copy the files by hand or mount a directory instead of the volume, make them
its own: `chown -R 10001:10001 <directory>`.

The connector is Cloudflare's own `cloudflared` binary, copied unchanged from the
official `cloudflare/cloudflared` image into a small image that Compose builds on
the host ([deploy/ha/gate](../deploy/ha/gate)); `gate.sh` there starts and stops it.

## 4. Check
    curl -s https://node.example.com/get_info | grep -E '"(height|synchronized)"'

The tunnel's page in the dashboard lists one connector per replica.

## Who can reach RPC on the host
The tunnel reaches zephyrd over the Compose network and needs no published port.
Beside it, the Compose file publishes the restricted RPC on the host, so the node
is also usable directly. Choose per host:

| Setting | RPC on the host | Use it when |
|---|---|---|
| default (`RPC_BIND` unset) | every address of the host, port 17767 | wallets or tools on the host's network should reach this replica directly |
| `RPC_BIND=127.0.0.1` in `.env` | the host itself only | you want local checks (`curl http://127.0.0.1:17767/get_info`) and nothing else |
| delete the `17767` line under `ports` in `compose.yaml` | none | the tunnel must be the only way in |

Apply a change with `docker compose up -d`. With the default, on a host with a
public address anyone can reach port 17767: those requests pass around
Cloudflare, so its rate limiting and its hiding of the host's address do not
apply to them, and the daemon's own RPC ban is off in this setup. Docker
publishes ports past `ufw` and `firewalld`; a host firewall rule does not close
it. For a public node whose hosts should stay unknown, delete the line.

The Compose file also publishes the P2P port 17766, so other Zephyr nodes can
connect in. That is optional: delete its line under `ports` for a host with no
open port at all; the node then makes outgoing connections only.

Without a published port, check a replica from inside its container:

    docker compose exec zephyrd curl -s http://127.0.0.1:17767/get_info

## Update
One replica at a time, so the others keep serving.

- zephyrd: change `ZEPHYR_IMAGE` in `.env` (or pull the new default), then
  `docker compose pull zephyrd && docker compose up -d zephyrd`. The connector
  leaves the tunnel while the daemon restarts and returns by itself.
- cloudflared: change `CLOUDFLARED_IMAGE` in `compose.yaml`, then
  `docker compose up -d --build cloudflared`.

## Notes
- Requests are spread over the replicas without session affinity, so two
  consecutive requests can reach daemons that briefly differ by a block.
- The gate checks every 10 seconds and stops the connector after three failed
  checks, so a daemon that goes down can still receive requests for up to a
  minute; those fail. A daemon that has lost all its peers
  cannot tell that it is behind and keeps serving. `GATE_*` variables on the
  `cloudflared` service tune the checks (`gate/gate.sh`).
- `DISABLE_RPC_BAN` is set because every client reaches zephyrd from the
  cloudflared container's address; a ban would lock out everyone at once. Use
  Cloudflare's rate limiting rules on the hostname for abuse instead.
- zephyrd matches RPC paths including the query string, so a request such as
  `/json_rpc?x=1` returns 404. Do not add query-string rewriting in front of it.
- A Worker on the same hostname must use exact routes only. A `/*` route would
  take over `/json_rpc` and the other RPC paths.
