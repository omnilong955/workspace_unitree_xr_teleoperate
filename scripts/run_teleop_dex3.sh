#!/usr/bin/env bash
set -euo pipefail

HOST_IP="${1:-192.168.137.134}"
NET_IFACE="${2:-wlx6c1ff7877849}"

source "$(cd "$(dirname "$0")/.." && pwd)/miniforge3/etc/profile.d/conda.sh"
conda activate tv
export LD_LIBRARY_PATH="$CONDA_PREFIX/lib:${LD_LIBRARY_PATH:-}"
cd "$(cd "$(dirname "$0")/.." && pwd)/xr_teleoperate/teleop"

python -u teleop_hand_and_arm.py \
  --input-mode hand \
  --arm G1_29 \
  --ee dex3 \
  --sim \
  --record \
  --img-server-ip "$HOST_IP" \
  --network-interface "$NET_IFACE"
