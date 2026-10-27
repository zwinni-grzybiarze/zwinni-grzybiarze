#!/usr/bin/env bash
# Builds the local image (build-local.sh) and runs it on http://localhost:8080.
set -euo pipefail

Tag="${Tag:-onlyshrooms}"
Name="${Name:-onlyshrooms-dev}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag|-t) Tag="$2"; shift 2 ;;
    --name|-n) Name="$2"; shift 2 ;;
    *)
      echo "Unknown argument: $1" >&2
      echo "Usage: $0 [--tag NAME] [--name CONTAINER]" >&2
      exit 1
      ;;
  esac
done

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$root/build-local.sh" --tag "$Tag"

docker rm -f "$Name" >/dev/null 2>&1 || true

echo "==> Running http://localhost:8080 (Ctrl+C to quit)"
docker run --rm --name "$Name" -p 8080:8080 -v onlyshrooms-data:/data "$Tag"
