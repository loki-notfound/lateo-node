# Run a standalone Zephyr node

A full node of your own: your wallet talks to it instead of to someone else's,
and it adds a peer to the network. One host, Docker, no Cloudflare account.

## Choose an image
- `ghcr.io/loki-notfound/myzephyr` (the default): a personal build with the
  zephyr-backports security fixes and a signed release chain.
- `ghcr.io/loki-notfound/zephyr`: the official ZephyrProtocol release, unchanged,
  without upstream hashes or signatures.

[docker/README.md](../docker/README.md) compares them. To use the official one:

    ZEPHYR_IMAGE=ghcr.io/loki-notfound/zephyr:v2.3.0 docker compose up -d

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

Point a wallet at `127.0.0.1:17767`, or at the host's address on your network.

## Finding peers
The node finds peers on its own, which can take a few minutes. To speed it up,
name known nodes:

    environment:
      ADD_PEERS: "node-a.example:17766,node-b.example:17766"

## Who can reach RPC
The Compose file publishes RPC (17767) on every address of the host, restricted
to view-only methods and transaction submission. Wallets on your network can use
the node; on a host with a public address, so can anyone, which makes it a public
remote node. Docker publishes ports past `ufw` and `firewalld`, so a host
firewall does not close it.

- Only this host: `RPC_BIND=127.0.0.1 docker compose up -d` (or `RPC_BIND` in a
  `.env` file next to `compose.yaml`).
- A public node on purpose: consider `PUBLIC_NODE: "true"` so wallets can find it.
- Never publish RPC with `RESTRICTED_RPC: "false"`.
- Behind Cloudflare instead of an open port: [ha-node.md](ha-node.md).

## Update
Pull the new image and recreate the container; the data volume stays:

    docker compose pull && docker compose up -d

## Other ways to run zephyrd
- [myzephyr releases](https://github.com/loki-notfound/myzephyr/releases): the
  binaries of the `myzephyr` image, with signed `SHA256SUMS`.
- [ZephyrProtocol releases](https://github.com/ZephyrProtocol/zephyr/releases): the
  binaries of the `zephyr` image, published without hashes or signatures. The seed
  nodes built into v2.3.0 no longer answer; start it with `--seed-node` addresses
  (the `zephyr` image sets them).
