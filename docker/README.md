# Images

Two images of the Zephyr daemon, built the same way and configured the same way.
They differ only in which `zephyrd` binary they carry.

| | `myzephyr` | `zephyr` |
|---|---|---|
| Image | `ghcr.io/loki-notfound/myzephyr` | `ghcr.io/loki-notfound/zephyr` |
| Binary | [myzephyr](https://github.com/loki-notfound/myzephyr/releases) `v2.3.0-sec.2-my.2`, a personal build | [ZephyrProtocol](https://github.com/ZephyrProtocol/zephyr/releases) `v2.3.0`, the official release, unchanged |
| Verified by | the release key's signature on `SHA256SUMS`, checked in the build | archive hashes recorded in the Dockerfile on 2026-11-15; upstream publishes no hashes or signatures |
| Security fixes | the 30 Monero fixes of zephyr-backports `v2.3.0-sec.2` | none beyond `v2.3.0` |
| Finding peers | built-in seeds that answer | the built-in seeds no longer answer; the image sets `SEED_NODES` to the ones myzephyr uses |
| Licence texts | source licence and all linked third-party licences | source licence only (the release archive carries none) |
| Platforms | `linux/amd64`, `linux/arm64` | `linux/amd64`, `linux/arm64` |

Both speak the same P2P protocol and RPC and use the same database format; a
data volume works with either. Neither is affiliated with ZephyrProtocol.

Pick `zephyr` to run exactly what ZephyrProtocol shipped. Pick `myzephyr` for the
security fixes and a signed chain from source to binary, from a single maintainer.

## Build

From the repository root:

    docker build -f docker/myzephyr/Dockerfile -t myzephyr .
    docker build -f docker/zephyr/Dockerfile -t zephyr .

## Run

    docker run -d --name zephyrd --restart unless-stopped \
      -p 17766:17766 -p 127.0.0.1:17767:17767 \
      -v zephyrd-data:/data ghcr.io/loki-notfound/myzephyr:v2.3.0-sec.2-my.2

The daemon runs as uid 10001 with its data, including `zephyrd.log`, in `/data`.
A bind mount must be writable by that uid.

## Environment

| Variable | Default | Effect |
|---|---|---|
| `RESTRICTED_RPC` | `true` | `--restricted-rpc`: view-only RPC, safe to expose. |
| `RPC_LOGIN` | unset | `--rpc-login=user:password`. It is visible in the host's process list. |
| `DISABLE_RPC_BAN` | `false` | `--disable-rpc-ban`. Set behind a proxy or tunnel, where every client shares one address. |
| `PUBLIC_NODE` | `false` | `--public-node`: advertise the RPC port to peers. Only if 17767 is reachable directly. |
| `PRUNE` | `false` | `--prune-blockchain`. |
| `HIDE_MY_PORT` | `false` | `--hide-my-port`: do not advertise the P2P port. |
| `ZMQ` | `false` | ZMQ RPC stays off (`--no-zmq`) unless true. |
| `LOG_LEVEL` | unset | `--log-level` (0 to 4). |
| `OUT_PEERS`, `IN_PEERS` | unset | `--out-peers`, `--in-peers`. |
| `MAX_CONNECTIONS_PER_IP` | unset | `--max-connections-per-ip` (P2P). |
| `LIMIT_RATE_UP`, `LIMIT_RATE_DOWN` | unset | `--limit-rate-up`, `--limit-rate-down` in kB/s. |
| `SEED_NODES` | unset; `zephyr`: two addresses | Comma-separated `ip:port` list, one `--seed-node` each: asked for peers, then dropped. Added to the built-in seeds. |
| `ADD_PEERS` | unset | Comma-separated `host:port` list, one `--add-peer` each: kept in the peer list. |
| `PRIORITY_NODES` | unset | Same, `--add-priority-node`: always kept connected. |
| `EXCLUSIVE_NODES` | unset | Same, `--add-exclusive-node`: connect to these only. |
| `HEALTH_REQUIRE_SYNC` | `false` | The health check also requires `synchronized: true`. |

Always set: `--non-interactive`, `--data-dir=/data`, `--log-file=/data/zephyrd.log`,
`--max-log-files=5`, P2P on `0.0.0.0:17766`, RPC on `0.0.0.0:17767` with
`--confirm-external-bind`, `--no-igd`.

Arguments after the image name are appended to the command line. zephyrd rejects
an option given twice, so do not repeat one that is always set or that a variable
above sets.

## Health check

`healthcheck.sh` asks the local RPC for `get_info` and expects `status: OK`; with
`HEALTH_REQUIRE_SYNC=true` also `synchronized: true`. It uses `RPC_LOGIN` when set.

## Stopping

tini runs as PID 1 and passes SIGTERM to zephyrd, which shuts down cleanly once
it is running (exit 0). A stop during the first seconds of start-up, before
zephyrd handles signals, ends it at once (exit 143). Give a running node time to
flush the database: `docker stop -t 300`, or `stop_grace_period` in Compose.
