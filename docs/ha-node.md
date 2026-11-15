# Run a highly available public node behind Cloudflare

This is the shape of node.lateo.dev: one public hostname, several hosts, each
running zephyrd next to a cloudflared connector of the same Cloudflare Tunnel.
Cloudflare sends each request to a connected replica; when a host goes down, the
others keep serving. No inbound RPC port is opened anywhere.

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
    docker compose up -d zephyrd

Wait until the node is synchronized:

    docker compose exec zephyrd healthcheck.sh && echo synchronized

Then start the connector:

    docker compose up -d

cloudflared starts only after zephyrd reports itself healthy and synchronized,
so a fresh replica does not serve an empty chain. Copying a synchronized data
volume from another replica (with both daemons stopped) saves the initial sync.

## 4. Check
    curl -s https://node.example.com/get_info | grep -E '"(height|synchronized)"'

The tunnel's page in the dashboard lists one connector per replica.

## Notes
- Requests are spread over the replicas without session affinity, so two
  consecutive requests can reach daemons that briefly differ by a block.
- The wait for synchronization applies to `docker compose up` only. After a
  reboot or a daemon restart, Docker's restart policy starts both containers at
  once, and a replica that falls behind keeps serving until it catches up. Watch
  `docker compose ps` for an unhealthy zephyrd.
- `DISABLE_RPC_BAN` is set because every client reaches zephyrd from the
  cloudflared container's address; a ban would lock out everyone at once. Use
  Cloudflare's rate limiting rules on the hostname for abuse instead.
- zephyrd matches RPC paths including the query string, so a request such as
  `/json_rpc?x=1` returns 404. Do not add query-string rewriting in front of it.
- A Worker on the same hostname must use exact routes only. A `/*` route would
  take over `/json_rpc` and the other RPC paths.
