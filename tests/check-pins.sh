#!/bin/sh
# Reports pins that have fallen behind their upstream. Needs network access,
# curl and jq; meant for the scheduled CI run, which fails when something is
# stale so that the maintainer hears about it. Run from the repository root.
#
# GH_TOKEN, if set, authenticates the GitHub API requests (rate limit).
# CLOUDFLARED_MIN_AGE_DAYS (14): a cloudflared release younger than this is not
# yet expected to be adopted.
set -eu

rc=0
stale() { echo "stale: $*"; rc=1; }
arg() { grep -m1 "^ARG $2=" "$1" | cut -d= -f2-; }
gh() {
  if [ -n "${GH_TOKEN:-}" ]; then
    curl -fsSL --proto '=https' -H "Authorization: Bearer $GH_TOKEN" "https://api.github.com/$1"
  else
    curl -fsSL --proto '=https' "https://api.github.com/$1"
  fi
}

my=$(arg docker/myzephyr/Dockerfile MYZEPHYR_TAG)
latest=$(gh repos/loki-notfound/myzephyr/releases/latest | jq -r .tag_name)
[ "$latest" = "$my" ] || stale "myzephyr $my, latest release $latest"

up=$(arg docker/zephyr/Dockerfile ZEPHYR_TAG)
latest=$(gh repos/ZephyrProtocol/zephyr/releases/latest | jq -r .tag_name)
[ "$latest" = "$up" ] || stale "zephyr $up, latest release $latest"

cf=$(arg deploy/ha/gate/Dockerfile CLOUDFLARED_IMAGE); cf=${cf##*:}
days=${CLOUDFLARED_MIN_AGE_DAYS:-14}
latest=$(gh 'repos/cloudflare/cloudflared/releases?per_page=30' | jq -r --argjson days "$days" \
  '[.[] | select(.draft or .prerelease | not)
        | select((.published_at | fromdateiso8601) < (now - $days * 86400))][0].tag_name')
[ "$latest" = "$cf" ] || stale "cloudflared $cf, latest release older than $days days $latest"

debian=$(arg docker/myzephyr/Dockerfile DEBIAN_IMAGE); debian=${debian#*:}; debian=${debian%%@*}
latest=$(curl -fsSL --proto '=https' \
  'https://hub.docker.com/v2/repositories/library/debian/tags?name=trixie-20&page_size=100' \
  | jq -r '[.results[].name | select(test("^trixie-[0-9]{8}-slim$"))] | sort | last')
[ "$latest" = "$debian" ] || stale "debian $debian, latest $latest"

[ "$rc" -eq 0 ] && echo "check-pins OK"
exit "$rc"
