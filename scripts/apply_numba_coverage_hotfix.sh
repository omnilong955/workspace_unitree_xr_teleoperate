#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${CONDA_PREFIX:-}" ]]; then
  echo "Please activate conda env first (expected: unitree_sim_env)."
  exit 1
fi

TARGET="$CONDA_PREFIX/lib/python3.10/site-packages/numba/misc/coverage_support.py"
if [[ ! -f "$TARGET" ]]; then
  echo "File not found: $TARGET"
  exit 1
fi

python - <<'PY'
from pathlib import Path
import os
p = Path(os.environ["CONDA_PREFIX"]) / "lib/python3.10/site-packages/numba/misc/coverage_support.py"
s = p.read_text()
needle = "if not hasattr(coverage, \"types\") or not hasattr(coverage.types, \"Tracer\")"
if needle in s:
    print("Hotfix already applied.")
else:
    marker = "coverage_available = True\n"
    insert = (
        "    # Isaac Sim may inject an older/newer coverage module lacking Tracer.\n"
        "    # Gracefully disable Numba coverage hooks in that case.\n"
        "    if not hasattr(coverage, \"types\") or not hasattr(coverage.types, \"Tracer\"):\n"
        "        coverage_available = False\n"
    )
    i = s.find(marker)
    if i == -1:
        raise RuntimeError("Could not find insertion marker in coverage_support.py")
    i += len(marker)
    s = s[:i] + insert + s[i:]
    p.write_text(s)
    print("Hotfix applied.")
PY
