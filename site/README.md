# Site of node.lateo.dev

Three static pages, served by a Cloudflare Worker with static assets and no code:
what the node is (`/`), how to run a single node (`/own-node/`), and how to run a
highly available node behind Cloudflare Tunnel (`/ha-node/`). No scripts, no
external requests, a strict Content Security Policy (`public/_headers`).

## Routes
The Worker shares its hostname with the node's RPC, so it claims only what it
serves (`wrangler.jsonc`): the root, `/own-node*`, `/ha-node*`, `/assets/*` and
`/robots.txt`. None of these collides with a zephyrd RPC path. Never add a
catch-all route: every other path must reach the tunnel and zephyrd.

A request for the root with a query string (`/?x=1`) does not match the exact
root route and goes to zephyrd; a zone redirect rule that sends such requests to
`/` keeps the page reachable.

## Work on it

    npm install
    npm run check      # titles, descriptions, links, no scripts or external resources
    npx wrangler dev   # http://127.0.0.1:8787/

## Deploy
`npx wrangler deploy` with an account that holds the zone. The routes above must
not be claimed by another Worker on the same zone.
