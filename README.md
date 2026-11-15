# lateo-node

Source of [node.lateo.dev](https://node.lateo.dev), a public Zephyr RPC node, and
everything needed to run one of your own.

- [`docker`](docker): two images of the Zephyr daemon, configured by environment
  variables: `myzephyr` (a signed personal build with security backports) and
  `zephyr` (the official release, unchanged). The README there compares them.
- [`site`](site): the static site of node.lateo.dev.
- [`deploy/standalone`](deploy/standalone): a single node with Docker Compose, no
  Cloudflare needed. Guide: [docs/standalone-node.md](docs/standalone-node.md).
- [`deploy/ha`](deploy/ha): one replica of a highly available public node behind
  a Cloudflare Tunnel on the free plan. Guide: [docs/ha-node.md](docs/ha-node.md).

## Using node.lateo.dev

Point a Zephyr wallet at `node.lateo.dev:443` with SSL, or use
`https://node.lateo.dev` as the daemon address. The RPC is restricted: view-only
methods and transaction submission.

## Not affiliated

This project is not part of ZephyrProtocol or zephyr-backports. The daemon in the
image is a personal build; its release notes say what it changes.

## License

BSD-3-Clause, see [LICENSE](LICENSE).
