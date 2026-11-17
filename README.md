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

Point a Zephyr wallet at `node.lateo.dev:443`; it detects SSL by itself. Where a
full address is asked for, use `https://node.lateo.dev:443`, with the port.
With the command-line wallet, leave out `--daemon-ssl enabled` (it then asks for
a pinned certificate) and set `SSL_CERT_FILE` to the system's certificate list
to have the node's certificate checked, for example
`SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt zephyr-wallet-cli --daemon-address node.lateo.dev:443`. The RPC is restricted: view-only
methods and transaction submission.

## Contributing

Issues and pull requests are welcome. Every commit on `main` is signed by the
maintainer, so an accepted pull request is not merged with GitHub's button: the
maintainer applies the change as a signed commit that credits you, and closes
the pull request with a reference to it. Contributions are accepted under the
repository's licence. For security problems, see [SECURITY.md](SECURITY.md).

## Not affiliated

This project is not part of ZephyrProtocol or zephyr-backports. The daemon in the
image is a personal build; its release notes say what it changes.

## License

BSD-3-Clause, see [LICENSE](LICENSE). The lateo name and the mark files of the
site (its favicons and logo) are not covered by that licence; see
[TRADEMARKS.md](TRADEMARKS.md).
