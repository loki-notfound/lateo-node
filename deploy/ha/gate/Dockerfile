# The tunnel connector of an HA replica: Cloudflare's own cloudflared binary,
# copied unchanged from the official image, started and stopped by gate.sh
# according to the health of the local zephyrd.
#
# Compose builds this image on the host (deploy/ha/compose.yaml); it is not
# published. To update cloudflared, change CLOUDFLARED_IMAGE there and run
#   docker compose up -d --build

ARG CLOUDFLARED_IMAGE=cloudflare/cloudflared:2026.10.7
ARG DEBIAN_IMAGE=debian:trixie-20261104-slim@sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2

FROM ${CLOUDFLARED_IMAGE} AS cloudflared

FROM ${DEBIAN_IMAGE}
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl tini \
 && rm -rf /var/lib/apt/lists/* \
 && groupadd --gid 10002 tunnel \
 && useradd --uid 10002 --gid tunnel --home-dir /nonexistent --no-create-home --shell /usr/sbin/nologin tunnel
COPY --from=cloudflared /usr/local/bin/cloudflared /usr/local/bin/cloudflared
COPY --chmod=0755 gate.sh /usr/local/bin/gate.sh
USER tunnel
# tini is PID 1 so that stop signals reach gate.sh, which stops the connector.
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/gate.sh"]
CMD ["cloudflared", "tunnel", "--no-autoupdate", "run"]
