# The zephyr image: zephyrd from the official ZephyrProtocol release, unchanged.
#
# Build from the repository root:
#   docker build -f docker/zephyr/Dockerfile -t zephyr .
#
# ZephyrProtocol publishes no hashes or signatures. The archive hashes below were
# recorded from the release assets on 2026-11-15 and match the sha256 digests
# GitHub keeps for those assets; a changed asset stops the build.

# Tag and multi-platform index digest; each platform resolves its own image.
ARG DEBIAN_IMAGE=debian:trixie-20261104-slim@sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2

FROM ${DEBIAN_IMAGE} AS fetch
ARG ZEPHYR_TAG=v2.3.0
ARG ZEPHYR_COMMIT=67c5f53b878fef41fb5e74c4382d5b7a2f37fd8a
ARG ZEPHYR_ZIP_SHA256_AMD64=d60a94d187e288de0ea76d26ecba26c850cdec0500bba84699c7abe85d1a6f91
ARG ZEPHYR_ZIP_SHA256_ARM64=2f9f786af49c1ba1dc463d42f2881e1cf95c7bdb66849b577ca6dedda569829f
ARG ZEPHYR_LICENSE_SHA256=b64bf58187d7e41a97b279930f1ce8d3b1f76fbe6acd2e59179f8f5e0db6c34a
ARG TARGETARCH
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl unzip \
 && rm -rf /var/lib/apt/lists/*
RUN set -eu; \
    arch="${TARGETARCH:-$(dpkg --print-architecture)}"; \
    case "$arch" in \
      amd64) asset=linux; sum="$ZEPHYR_ZIP_SHA256_AMD64" ;; \
      arm64) asset=aarch; sum="$ZEPHYR_ZIP_SHA256_ARM64" ;; \
      *) echo "unsupported architecture: $arch" >&2; exit 1 ;; \
    esac; \
    name="zephyr-cli-${asset}-${ZEPHYR_TAG}"; \
    mkdir /work && cd /work; \
    curl -fsSL --proto '=https' -o "$name.zip" \
      "https://github.com/ZephyrProtocol/zephyr/releases/download/${ZEPHYR_TAG}/$name.zip"; \
    curl -fsSL --proto '=https' -o LICENSE \
      "https://raw.githubusercontent.com/ZephyrProtocol/zephyr/${ZEPHYR_COMMIT}/LICENSE"; \
    printf '%s  %s\n%s  %s\n' "$sum" "$name.zip" "$ZEPHYR_LICENSE_SHA256" LICENSE > expected; \
    sha256sum -c expected; \
    unzip -q "$name.zip" "$name/zephyrd"; \
    mkdir -p /out/bin /out/doc; \
    install -m 0755 "$name/zephyrd" /out/bin/zephyrd; \
    cp LICENSE expected /out/doc/

FROM ${DEBIAN_IMAGE}
ARG ZEPHYR_TAG=v2.3.0
LABEL org.opencontainers.image.title="zephyr" \
      org.opencontainers.image.description="Zephyr daemon from the official ZephyrProtocol release ${ZEPHYR_TAG}, unchanged" \
      org.opencontainers.image.source="https://github.com/loki-notfound/lateo-node" \
      org.opencontainers.image.licenses="BSD-3-Clause" \
      org.opencontainers.image.version="${ZEPHYR_TAG}"
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl tini \
 && rm -rf /var/lib/apt/lists/* \
 && groupadd --gid 10001 zephyr \
 && useradd --uid 10001 --gid zephyr --home-dir /data --no-create-home --shell /usr/sbin/nologin zephyr \
 && mkdir -p /data \
 && chown zephyr:zephyr /data
COPY --from=fetch /out/bin/zephyrd /usr/local/bin/zephyrd
COPY --from=fetch /out/doc/ /usr/share/doc/zephyrd/
COPY docker/common/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY docker/common/healthcheck.sh /usr/local/bin/healthcheck.sh
# The two seed addresses built into v2.3.0 no longer answer. These are the
# extra seeds the myzephyr build carries (remote-node.zephyrprotocol.com
# resolves to the first). Set SEED_NODES to another list, or to empty, to change.
ENV SEED_NODES=24.199.101.125:17766,85.215.93.176:17766
USER zephyr
WORKDIR /data
VOLUME /data
EXPOSE 17766 17767
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
  CMD ["/usr/local/bin/healthcheck.sh"]
# tini is PID 1: a signal that arrives before zephyrd installs its own handlers
# would otherwise be dropped, because the kernel ignores unhandled signals to PID 1.
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
