# Security

## Reporting
Report a vulnerability privately through
[GitHub's private vulnerability reporting](https://github.com/loki-notfound/lateo-node/security/advisories/new)
for this repository. Please do not open a public issue for it. Expect a first
answer within a week; this is a one-person project.

## What belongs here
- The images' build and verification steps, entrypoint and health check.
- The Compose setups and the tunnel gate.
- The site of node.lateo.dev and the workflow that publishes the images.
- The public node itself: something on node.lateo.dev that exposes more than
  restricted RPC, or a way to take the service down that is specific to this
  setup. Please do not load-test the node.

## What belongs elsewhere
- A flaw in the Zephyr daemon: the
  [myzephyr](https://github.com/loki-notfound/myzephyr) repository for that
  build, and [ZephyrProtocol](https://github.com/ZephyrProtocol/zephyr) for the
  official release. A daemon flaw inherited from Monero is best reported to
  Monero's vulnerability response process first.
- cloudflared and Cloudflare's network: Cloudflare.

## Supported versions
The most recent image of each kind (`myzephyr`, `zephyr`). An image is rebuilt as
a `-r<N>` revision when its base image or scripts need a fix.
