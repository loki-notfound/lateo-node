# The myzephyr image: zephyrd from the signed myzephyr release archives.
#
# Build from the repository root (the release key lives in keys/):
#   docker build -f docker/myzephyr/Dockerfile -t myzephyr .
#
# The archive is accepted only if SHA256SUMS.asc carries a valid signature by
# MYZEPHYR_KEY_FPR and the archive's hash matches the signed list.

# Tag and multi-platform index digest; each platform resolves its own image.
ARG DEBIAN_IMAGE=debian:trixie-20261104-slim@sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2

FROM ${DEBIAN_IMAGE} AS fetch
ARG MYZEPHYR_TAG=v2.3.0-sec.2-my.2
ARG MYZEPHYR_KEY_FPR=31DA39AB43E0CA67F1F3A661BA2AFF22DF8A4A13
ARG TARGETARCH
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl gnupg \
 && rm -rf /var/lib/apt/lists/*
COPY keys/myzephyr-release.asc /tmp/release-key.asc
RUN set -eu; \
    arch="${TARGETARCH:-$(dpkg --print-architecture)}"; \
    case "$arch" in \
      amd64) platform=linux-x86_64 ;; \
      arm64) platform=linux-aarch64 ;; \
      *) echo "unsupported architecture: $arch" >&2; exit 1 ;; \
    esac; \
    name="zephyrd-${MYZEPHYR_TAG}-${platform}"; \
    url="https://github.com/loki-notfound/myzephyr/releases/download/${MYZEPHYR_TAG}"; \
    mkdir /work && cd /work; \
    curl -fsSL --proto '=https' -o SHA256SUMS.asc "$url/SHA256SUMS.asc"; \
    curl -fsSL --proto '=https' -o "$name.tar.gz" "$url/$name.tar.gz"; \
    export GNUPGHOME=/work/gnupg; mkdir -m 700 "$GNUPGHOME"; \
    gpg --batch --quiet --import /tmp/release-key.asc; \
    gpg --batch --status-file status --output SHA256SUMS --decrypt SHA256SUMS.asc; \
    grep -q "^\[GNUPG:\] VALIDSIG $MYZEPHYR_KEY_FPR " status \
      || { echo "SHA256SUMS.asc is not signed by $MYZEPHYR_KEY_FPR" >&2; exit 1; }; \
    grep "  $name.tar.gz\$" SHA256SUMS > expected; \
    test "$(wc -l < expected)" -eq 1; \
    sha256sum -c expected; \
    tar xzf "$name.tar.gz"; \
    mkdir -p /out/bin /out/doc; \
    install -m 0755 "$name/zephyrd" /out/bin/zephyrd; \
    cp -r "$name/LICENSE" "$name/README.txt" "$name/THIRD-PARTY-LICENSES" /out/doc/; \
    cp SHA256SUMS SHA256SUMS.asc /out/doc/

FROM ${DEBIAN_IMAGE}
ARG MYZEPHYR_TAG=v2.3.0-sec.2-my.2
LABEL org.opencontainers.image.title="myzephyr" \
      org.opencontainers.image.description="Zephyr daemon from the signed myzephyr release ${MYZEPHYR_TAG}" \
      org.opencontainers.image.source="https://github.com/loki-notfound/lateo-node" \
      org.opencontainers.image.licenses="BSD-3-Clause" \
      org.opencontainers.image.version="${MYZEPHYR_TAG}"
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
USER zephyr
WORKDIR /data
VOLUME /data
EXPOSE 17766 17767
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
  CMD ["/usr/local/bin/healthcheck.sh"]
# tini is PID 1: a signal that arrives before zephyrd installs its own handlers
# would otherwise be dropped, because the kernel ignores unhandled signals to PID 1.
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
