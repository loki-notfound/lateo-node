# Run a standalone Zephyr node

A full node of your own: your wallet talks to it instead of to someone else's,
and it adds a peer to the network.

## What it needs
- Disk: the database was about 25 GiB in November 2026 and grows with the chain.
  An SSD helps the initial sync a lot. `PRUNE=true` keeps roughly a third.
- Time: a sync from an empty data directory took about 11.5 hours on one test
  machine in November 2026. Expect anything from hours to days.
- Network: outbound P2P on 17766, outbound HTTPS to the Zephyr oracle hosts.
  Inbound 17766 is optional; forwarding it helps the network.
- Docker with Compose, on `linux/amd64` or `linux/arm64`.

## Start

    cd deploy/standalone
    docker compose up -d
    docker compose logs -f zephyrd

Progress shows in the log as `Synced <height>/<target>`. Ask the node itself:

    curl -s http://127.0.0.1:17767/get_info | grep -E '"(height|target_height|synchronized)"'

Point a wallet at `127.0.0.1:17767` (or the host's address on your network).

## Finding peers
The node finds peers on its own, which can take a few minutes. To speed it up,
name known nodes:

    environment:
      ADD_PEERS: "node-a.example:17766,node-b.example:17766"

## Opening RPC to others
The Compose file publishes RPC on localhost only. To run a public remote node,
keep `RESTRICTED_RPC: "true"`, publish `17767:17767` and consider
`PUBLIC_NODE: "true"` so wallets can find it. Never publish RPC with
`RESTRICTED_RPC: "false"`. To put the node behind Cloudflare instead of opening
a port, see [ha-node.md](ha-node.md).

## Update
Pull the new image and recreate the container; the data volume stays:

    docker compose pull && docker compose up -d

## Other ways to run zephyrd
- [myzephyr releases](https://github.com/loki-notfound/myzephyr/releases): the
  binaries this image is built from, with signed `SHA256SUMS`.
- [ZephyrProtocol releases](https://github.com/ZephyrProtocol/zephyr/releases): the
  official binaries, published without hashes or signatures. The seed nodes built
  into v2.3.0 no longer answer; use `--add-peer` to find the network.
- [`jnitecki/zephyr`](https://hub.docker.com/r/jnitecki/zephyr): a third-party image of
  v2.3.0 for amd64 and arm64. Its source and binary origin are not published.
