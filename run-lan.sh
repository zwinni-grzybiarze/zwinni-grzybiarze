#!/usr/bin/env bash
# Build the local image and start HTTPS (Caddy) for LAN phone / PWA testing.
set -euo pipefail

Tag="${Tag:-onlyshrooms}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag|-t) Tag="$2"; shift 2 ;;
    *)
      echo "Unknown argument: $1" >&2
      echo "Usage: $0 [--tag NAME]" >&2
      exit 1
      ;;
  esac
done

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$root/build-local.sh" --tag "$Tag"

"$root/deploy/ensure-tls.sh"

export ONLYSHROOMS_IMAGE="$Tag"

# Stop any leftover single-container run from run-local.sh
docker rm -f onlyshrooms-dev >/dev/null 2>&1 || true

lan_ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
echo "==> Starting LAN stack (HTTPS on :443, HTTP app on :8080)"
[[ -n "$lan_ip" ]] && echo "    Phone URL: https://${lan_ip}  (accept cert warning once, then Install app)"
docker compose -f "$root/docker-compose.yml" up --remove-orphans
