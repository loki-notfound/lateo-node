#!/bin/sh
# Every place that names a pinned version must agree with the Dockerfiles and
# with deploy/ha/compose.yaml. Run from the repository root; needs no network.
set -eu

rc=0
bad() { echo "check-versions: $*" >&2; rc=1; }
arg() { grep "^ARG $2=" "$1" | cut -d= -f2- | sort -u; }
one() {
  if [ -z "$1" ] || [ "$(printf '%s\n' "$1" | wc -l)" -ne 1 ]; then bad "$2 has differing or missing values"; fi
}

my=$(arg docker/myzephyr/Dockerfile MYZEPHYR_TAG); one "$my" MYZEPHYR_TAG
up=$(arg docker/zephyr/Dockerfile ZEPHYR_TAG); one "$up" ZEPHYR_TAG
debian=$(cat docker/myzephyr/Dockerfile docker/zephyr/Dockerfile deploy/ha/gate/Dockerfile \
  | grep '^ARG DEBIAN_IMAGE=' | sort -u); one "$debian" DEBIAN_IMAGE
cf=$(arg deploy/ha/gate/Dockerfile CLOUDFLARED_IMAGE)
grep -q "CLOUDFLARED_IMAGE: $cf\$" deploy/ha/compose.yaml \
  || bad "deploy/ha/compose.yaml and deploy/ha/gate/Dockerfile name different cloudflared images"

files=$(git ls-files | grep -v -e '^site/package-lock.json$' -e '^tests/check-versions.sh$')

# Image references carry the release tag (optionally -r<N>) or latest.
for pair in "myzephyr:$my" "zephyr:$up"; do
  image=${pair%%:*}; tag=${pair#*:}
  # shellcheck disable=SC2086
  other=$(grep -ohE "ghcr\.io/loki-notfound/$image:[A-Za-z0-9._-]+" $files | sort -u | while read -r ref; do
    case "${ref##*:}" in "$tag"|"$tag"-r[0-9]*|latest) ;; *) printf '%s ' "$ref" ;; esac
  done)
  [ -z "$other" ] || bad "$image references other than $tag: $other"
done

# The READMEs state the tags and the version the binary reports.
for image in myzephyr zephyr; do
  v=$(cat "docker/$image/zephyrd-version")
  grep -qF "\`$v\`" "docker/$image/README.md" || bad "docker/$image/README.md does not name $v"
done
grep -qF "\`$my\`" docker/README.md || bad "docker/README.md does not name $my"
grep -qF "\`$up\`" docker/README.md || bad "docker/README.md does not name $up"
grep -qF "\`$up\`" docker/zephyr/README.md || bad "docker/zephyr/README.md does not name $up"

[ "$rc" -eq 0 ] && echo "check-versions OK: myzephyr $my, zephyr $up, $cf"
exit "$rc"
