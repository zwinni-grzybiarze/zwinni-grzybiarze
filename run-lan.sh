#!/usr/bin/env bash
# Full local rebuild + start via compose.yml (HTTP :18000 → container :8080).
# Removes any existing container named onlyshrooms so the name never conflicts.
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
cd "$root"

export ONLYSHROOMS_IMAGE="$Tag"

echo "==> Removing old containers (onlyshrooms / onlyshrooms-dev) if present"
docker rm -f onlyshrooms onlyshrooms-dev >/dev/null 2>&1 || true

lan_ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
echo "==> Building and starting local stack (HTTP on :18000)"
[[ -n "$lan_ip" ]] && echo "    Phone URL: http://${lan_ip}:18000"

docker compose -f "$root/compose.yml" up --build --force-recreate --remove-orphans
