#!/usr/bin/env bash
# Server live deploy (Cloudflare Tunnel). Prod machine only.
# Builds the currently checked-out branch via Dockerfile, then rebinds 127.0.0.1:18080.
# No Caddy — cloudflared on network `proxy` → onlyshrooms:8080.
#
# Does not use build-local / run-lan / run-local
set -euo pipefail

Tag="${Tag:-onlyshrooms}"
Configuration="${Configuration:-Release}"
SkipBuild=0
ComposeFile="compose.live.yml"
ProjectName="onlyshrooms"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag|-t) Tag="$2"; shift 2 ;;
    --configuration|-c) Configuration="$2"; shift 2 ;;
    --skip-build) SkipBuild=1; shift ;;
    -h|--help)
      cat <<'EOF'
Usage: ./deploy-live.sh [--tag NAME] [--configuration Release|Debug] [--skip-build]

  Build current git checkout → image → recreate onlyshrooms on :18080.
  Local: docker compose up (compose.yml). Not this script.
EOF
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      echo "Usage: $0 [--tag NAME] [--configuration Release|Debug] [--skip-build]" >&2
      exit 1
      ;;
  esac
done

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$root"

branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
sha="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
dirty=
if ! git diff --quiet HEAD -- 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
  dirty=' (dirty)'
fi

step() {
  local description="$1"
  shift
  echo "==> $description"
  "$@"
}

echo "==> Live deploy (Cloudflare / no Caddy)"
echo "    Branch: ${branch} @ ${sha}${dirty}"
echo "    Image:  ${Tag}"
echo "    Bind:   127.0.0.1:18080 → container :8080"

if [[ "$SkipBuild" -eq 0 ]]; then
  step 'docker build' \
    docker build \
      -f "$root/Dockerfile" \
      --build-arg "BUILD_CONFIGURATION=$Configuration" \
      -t "$Tag" \
      "$root"
else
  echo "==> Skipping build (--skip-build); using existing image '${Tag}'"
fi

export ONLYSHROOMS_IMAGE="$Tag"
compose=(docker compose -p "$ProjectName" -f "$root/$ComposeFile")

if [[ ! -f "$root/.env" ]]; then
  echo "Missing $root/.env (required for Jwt__Secret and Google auth)." >&2
  echo "Create it with at least:" >&2
  echo "  Jwt__Secret=..." >&2
  echo "  Authentication__Google__ClientId=..." >&2
  echo "  Authentication__Google__ClientSecret=..." >&2
  exit 1
fi

echo "==> Stopping previous container(s) so :18080 can rebind"
"${compose[@]}" down --remove-orphans >/dev/null 2>&1 || true
docker rm -f onlyshrooms onlyshrooms-dev zwinni-grzybiarze-onlyshrooms-1 >/dev/null 2>&1 || true

echo "==> Starting onlyshrooms (detached)"
"${compose[@]}" up -d --force-recreate --pull never

echo "==> Waiting for http://127.0.0.1:18080 ..."
ok=0
for _ in $(seq 1 45); do
  if curl -fsS "http://127.0.0.1:18080/version.json" >/dev/null 2>&1 \
    || curl -fsS "http://127.0.0.1:18080/" >/dev/null 2>&1; then
    ok=1
    break
  fi
  sleep 1
done

if [[ "$ok" -ne 1 ]]; then
  echo "Container did not become ready on 127.0.0.1:18080" >&2
  "${compose[@]}" ps >&2 || true
  docker logs onlyshrooms --tail 80 >&2 || true
  exit 1
fi

echo "==> Done. Subdomain should serve '${branch}' @ ${sha}${dirty}"
echo "    Hard-refresh the browser if a cached PWA still shows the old UI."
