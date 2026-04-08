#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <HOST_IPV4>"
  exit 1
fi

HOST_IP="$1"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CERT_DIR="$ROOT_DIR/xr_teleoperate/teleop/televuer"

cd "$CERT_DIR"
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout key.pem -out cert.pem \
  -subj "/CN=${HOST_IP}" \
  -addext "subjectAltName=DNS:localhost,IP:${HOST_IP},IP:127.0.0.1"

mkdir -p "$HOME/.config/xr_teleoperate"
cp -f cert.pem key.pem "$HOME/.config/xr_teleoperate/"

echo "Generated and installed cert for ${HOST_IP}"
openssl x509 -in cert.pem -noout -subject -dates -ext subjectAltName
