#!/usr/bin/env bash
# Creates a self-signed cert for LAN HTTPS if missing (student demo / PWA).
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tls="$root/tls"
cert="$tls/cert.pem"
key="$tls/key.pem"

if [[ -f "$cert" && -f "$key" ]]; then
  exit 0
fi

mkdir -p "$tls"
echo "==> Generating self-signed TLS cert in deploy/tls (LAN PWA demo)"
openssl req -x509 -newkey rsa:2048 -sha256 -nodes \
  -keyout "$key" \
  -out "$cert" \
  -days 825 \
  -subj "/CN=onlyshrooms-lan" \
  -addext "subjectAltName=DNS:localhost,DNS:onlyshrooms.local,IP:127.0.0.1"
