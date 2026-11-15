# lateo-node

Source of [node.lateo.dev](https://node.lateo.dev), a public Zephyr RPC node, and
everything needed to run one of your own.

- [`docker/myzephyr`](docker/myzephyr): the `myzephyr` image, zephyrd built from the signed
  [myzephyr](https://github.com/loki-notfound/myzephyr) releases, configured by
  environment variables.
- [`deploy/standalone`](deploy/standalone): a single node with Docker Compose.
  Guide: [docs/standalone-node.md](docs/standalone-node.md).
- [`deploy/ha`](deploy/ha): one replica of a highly available public node behind
  Cloudflare Tunnel. Guide: [docs/ha-node.md](docs/ha-node.md).

## Using node.lateo.dev

Point a Zephyr wallet at `node.lateo.dev:443` with SSL, or use
`https://node.lateo.dev` as the daemon address. The RPC is restricted: view-only
methods and transaction submission.

## Not affiliated

This project is not part of ZephyrProtocol or zephyr-backports. The daemon in the
image is a personal build; its release notes say what it changes.

## License

BSD-3-Clause, see [LICENSE](LICENSE).
