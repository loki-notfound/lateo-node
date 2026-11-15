# myzephyr image

`ghcr.io/loki-notfound/myzephyr`: zephyrd from the signed
[myzephyr](https://github.com/loki-notfound/myzephyr) release archives, a personal
build of the zephyr-backports tag `v2.3.0-sec.2` with working seed nodes. The
binary reports `v2.3.0-3adbb517a`.

The build downloads the release's `SHA256SUMS.asc`, checks that it is signed by
`31DA39AB43E0CA67F1F3A661BA2AFF22DF8A4A13` (the key is in `keys/`), and accepts the
archive only if its hash is in that signed list. A different key or hash stops
the build. The image keeps `SHA256SUMS`, `SHA256SUMS.asc`, the licence texts and
the release README in `/usr/share/doc/zephyrd/`.

## Limitations

- **A personal build.** One maintainer builds and signs it; it is not part of
  zephyr-backports and not an official Zephyr release.
- **Its own seed list.** The extra seed addresses are the maintainer's choice; the
  release notes name them.

Build arguments: `MYZEPHYR_TAG`, `MYZEPHYR_KEY_FPR`, `DEBIAN_IMAGE`.

Configuration, running and the comparison with the `zephyr` image:
[../README.md](../README.md).
