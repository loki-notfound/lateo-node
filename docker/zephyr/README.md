# zephyr image

`ghcr.io/loki-notfound/zephyr`: zephyrd from the official
[ZephyrProtocol](https://github.com/ZephyrProtocol/zephyr/releases) release
`v2.3.0`, unchanged. The binary reports `v2.3.0-67c5f53b8`.

## Limitations

- **No upstream verification.** ZephyrProtocol publishes no hashes or signatures.
  The Dockerfile pins the hashes of the two release archives as downloaded on
  2026-11-15; they match the sha256 digests GitHub keeps for those assets. That
  proves the archive has not changed since, not who built it.
- **No security backports.** It is `v2.3.0` as released. The 30 Monero fixes that
  zephyr-backports `v2.3.0-sec.2` adds are not in it; the `myzephyr` image has them.
- **Dead built-in seeds.** The two seed addresses compiled into `v2.3.0` no longer
  answer, so a fresh node may not find the network on its own. The image sets
  `SEED_NODES=24.199.101.125:17766,85.215.93.176:17766`, the extra seeds of the
  myzephyr build; override it with your own list.
- **Licence texts.** The release archive carries none. The image adds the source
  tree's `LICENSE` from the release commit, pinned by hash, in
  `/usr/share/doc/zephyrd/`; the texts of the linked third-party libraries are not
  included.

Build arguments: `ZEPHYR_TAG`, `ZEPHYR_COMMIT`, `ZEPHYR_ZIP_SHA256_AMD64`,
`ZEPHYR_ZIP_SHA256_ARM64`, `ZEPHYR_LICENSE_SHA256`, `DEBIAN_IMAGE`.

Configuration, running and the comparison with the `myzephyr` image:
[../README.md](../README.md).
