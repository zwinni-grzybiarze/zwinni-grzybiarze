#!/usr/bin/env bash
# Builds Flutter web and the API on the host, then packages them into a Docker image.
# Useful when the Docker build can't reach pub.dev / nuget.org (e.g. TLS-intercepting proxy).
set -euo pipefail

Tag="${Tag:-onlyshrooms}"
Configuration="${Configuration:-Release}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag|-t) Tag="$2"; shift 2 ;;
    --configuration|-c) Configuration="$2"; shift 2 ;;
    *)
      echo "Unknown argument: $1" >&2
      echo "Usage: $0 [--tag NAME] [--configuration Release|Debug]" >&2
      exit 1
      ;;
  esac
done

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
artifacts="$root/artifacts"

step() {
  local description="$1"
  shift
  echo "==> $description"
  "$@"
}

rm -rf "$artifacts"

pushd "$root/src/frontend" >/dev/null
step 'flutter pub get' flutter pub get
step 'flutter build web' flutter build web --release --no-wasm-dry-run
popd >/dev/null

mkdir -p "$artifacts"
cp -a "$root/src/frontend/build/web" "$artifacts/web"

step 'dotnet publish' \
  dotnet publish "$root/src/backend/OnlyShrooms/OS.WebApi/OS.WebApi.csproj" \
    -c "$Configuration" -o "$artifacts/api" /p:UseAppHost=false

step 'docker build' \
  docker build -f "$root/Dockerfile.local" -t "$Tag" "$root"

echo "Image '$Tag' built. Run: docker run --rm -p 8080:8080 -v onlyshrooms-data:/data $Tag"
