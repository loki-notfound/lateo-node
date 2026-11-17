# Site of node.lateo.dev

Three static pages, served by a Cloudflare Worker with static assets and no code:
what the node is (`/`), how to run a single node (`/own-node/`), and how to run a
highly available node behind Cloudflare Tunnel (`/ha-node/`). No scripts, no
external requests, a strict Content Security Policy (`public/_headers`).

## Style
The pages use the lateo house style, version 0.1.0 of 2026-11-17:
`public/assets/site.css` is its stylesheet for static content sites, copied
unchanged, and the favicons and the `node.lateo.dev` lockups come from it. The
mark files fall outside the repository's licence ([TRADEMARKS.md](../TRADEMARKS.md)).
`public/assets/node.css` holds the few additions of this site (code in tables
kept whole, the navigation on one line on narrow screens). To change the look,
change the house style and copy the new version in; edit `site.css` here only
together with the house style.

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
