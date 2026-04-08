#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "$0")/.." && pwd)/miniforge3/etc/profile.d/conda.sh"
conda activate unitree_sim_env
cd "$(cd "$(dirname "$0")/.." && pwd)/unitree_sim_isaaclab"

export UNITREE_DDS_NETWORK_INTERFACE="${UNITREE_DDS_NETWORK_INTERFACE:-wlx6c1ff7877849}"
python -u sim_main.py \
  --device cpu \
  --enable_cameras \
  --task Isaac-PickPlace-Cylinder-G129-Dex3-Joint \
  --enable_dex3_dds \
  --robot_type g129
