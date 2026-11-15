# myzephyr image

`ghcr.io/loki-notfound/myzephyr`: the Zephyr daemon from the signed [myzephyr](https://github.com/loki-notfound/myzephyr)
release archives, on Debian 13 slim, for `linux/amd64` and `linux/arm64`.

The build downloads the release's `SHA256SUMS.asc`, checks that it is signed by
`31DA39AB43E0CA67F1F3A661BA2AFF22DF8A4A13` (the key is in `keys/`), and accepts the
archive only if its hash is in that signed list. A different key or hash stops
the build.

## Build

From the repository root:

    docker build -f docker/myzephyr/Dockerfile -t myzephyr .

Build arguments: `MYZEPHYR_TAG` (release tag), `MYZEPHYR_KEY_FPR` (signing key),
`DEBIAN_IMAGE` (base image, pinned by tag and index digest).

## Run

    docker run -d --name zephyrd --restart unless-stopped \
      -p 17766:17766 -p 127.0.0.1:17767:17767 \
      -v zephyrd-data:/data myzephyr

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
| `ADD_PEERS` | unset | Comma-separated `host:port` list, one `--add-peer` each. |
| `PRIORITY_NODES` | unset | Same, `--add-priority-node`. |
| `EXCLUSIVE_NODES` | unset | Same, `--add-exclusive-node`. |
| `SEED_NODES` | unset | Same, `--seed-node`. |
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
