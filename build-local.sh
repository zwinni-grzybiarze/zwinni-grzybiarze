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

# Distro /usr/bin/dotnet is often older than ~/.dotnet (this repo targets net10.0).
resolve_dotnet() {
  local candidates=()
  [[ -n "${DOTNET:-}" ]] && candidates+=("$DOTNET")
  [[ -x "${HOME}/.dotnet/dotnet" ]] && candidates+=("${HOME}/.dotnet/dotnet")
  command -v dotnet >/dev/null 2>&1 && candidates+=("$(command -v dotnet)")

  local d
  for d in "${candidates[@]}"; do
    [[ -x "$d" ]] || continue
    if "$d" --list-sdks 2>/dev/null | grep -qE '^10\.'; then
      echo "$d"
      return 0
    fi
  done

  echo "No .NET 10 SDK found (projects target net10.0)." >&2
  echo "Install from https://aka.ms/dotnet/download or set DOTNET=/path/to/dotnet" >&2
  echo "If you already installed to ~/.dotnet, put it first on PATH:" >&2
  echo "  export PATH=\"\$HOME/.dotnet:\$PATH\"" >&2
  exit 1
}

DOTNET_BIN="$(resolve_dotnet)"
echo "==> using dotnet: $DOTNET_BIN ($("$DOTNET_BIN" --version))"

rm -rf "$artifacts"

pushd "$root/src/frontend" >/dev/null
step 'flutter pub get' flutter pub get
# Empty API_BASE => same-origin requests (required for LAN phone / PWA installs).
step 'flutter build web' flutter build web --release --no-wasm-dry-run \
  --dart-define=USE_MOCK_DATA=false \
  --dart-define=API_BASE=
popd >/dev/null

mkdir -p "$artifacts"
cp -a "$root/src/frontend/build/web" "$artifacts/web"

step 'dotnet publish' \
  "$DOTNET_BIN" publish "$root/src/backend/OnlyShrooms/OS.WebApi/OS.WebApi.csproj" \
    -c "$Configuration" -o "$artifacts/api" /p:UseAppHost=false

step 'docker build' \
  docker build -f "$root/Dockerfile.local" -t "$Tag" "$root"

echo "Image '$Tag' built. Run: docker run --rm -p 8080:8080 -v onlyshrooms-data:/data $Tag"
