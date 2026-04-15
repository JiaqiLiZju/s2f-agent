#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.."; pwd)"
OUTPUT_DIR="$REPO_ROOT/case-study/track_prediction/borzoi_results"
MODEL_DIR="${BORZOI_MODEL_DIR:-$REPO_ROOT/case-study/borzoi_fast}"
PREFIX="borzoi_track_chr19_6700000_6732768"

PLOT_FILE="$OUTPUT_DIR/${PREFIX}_trackplot.png"
TSV_FILE="$OUTPUT_DIR/${PREFIX}_top_tracks.tsv"
NPZ_FILE="$OUTPUT_DIR/${PREFIX}_track_prediction.npz"
RESULT_FILE="$OUTPUT_DIR/${PREFIX}_result.json"

mkdir -p "$OUTPUT_DIR"

required_assets=(
  "model0_best.h5"
  "params.json"
  "hg38/targets.txt"
)
for rel in "${required_assets[@]}"; do
  if [[ ! -f "$MODEL_DIR/$rel" ]]; then
    echo "error: missing Borzoi model asset: $MODEL_DIR/$rel" >&2
    exit 1
  fi
done

RUN_PREFIX=()
CONDA_BIN="${CONDA_BIN:-}"
if [[ -z "$CONDA_BIN" && -x "/Users/jiaqili/miniconda3_arm/bin/conda" ]]; then
  CONDA_BIN="/Users/jiaqili/miniconda3_arm/bin/conda"
fi
if [[ -z "$CONDA_BIN" ]] && command -v conda >/dev/null 2>&1; then
  CONDA_BIN="$(command -v conda)"
fi

if [[ -n "$CONDA_BIN" ]]; then
  if "$CONDA_BIN" run -n borzoi_py310 python - <<'PY' >/dev/null 2>&1
import borzoi, baskerville, tensorflow, pysam
print("imports_ok")
PY
  then
    RUN_PREFIX=("$CONDA_BIN" run -n borzoi_py310 python)
  fi
fi

if [[ ${#RUN_PREFIX[@]} -eq 0 ]]; then
  if [[ -x "/Users/jiaqili/miniconda3_arm/envs/borzoi_py310/bin/python" ]]; then
    RUN_PREFIX=("/Users/jiaqili/miniconda3_arm/envs/borzoi_py310/bin/python")
  fi
fi

if [[ ${#RUN_PREFIX[@]} -eq 0 ]]; then
  PYTHON_BIN="${PYTHON_BIN:-python3}"
  if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
    PYTHON_BIN="python"
  fi
  if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
    echo "error: python interpreter not found (tried PYTHON_BIN/python3/python)." >&2
    exit 1
  fi
  RUN_PREFIX=("$PYTHON_BIN")
fi

echo "[borzoi-track] Running Borzoi track-prediction case..."
"${RUN_PREFIX[@]}" "$REPO_ROOT/skills/borzoi-workflows/scripts/run_borzoi_track_prediction.py" \
  --interval chr19:6700000-6732768 \
  --assembly hg38 \
  --model-dir "$MODEL_DIR" \
  --output-dir "$OUTPUT_DIR" \
  --output-prefix "$PREFIX"

for f in "$PLOT_FILE" "$TSV_FILE" "$NPZ_FILE" "$RESULT_FILE"; do
  if [[ ! -s "$f" ]]; then
    echo "error: expected output not found: $f" >&2
    exit 1
  fi
done

echo "[borzoi-track] Checkpoints:"
"${RUN_PREFIX[@]}" - "$RESULT_FILE" "$NPZ_FILE" <<'PY'
import json
import numpy as np
import pathlib
import sys

result_path = pathlib.Path(sys.argv[1])
npz_path = pathlib.Path(sys.argv[2])
payload = json.loads(result_path.read_text(encoding="utf-8"))
npz = np.load(npz_path)

print(f"  status={payload.get('status')}")
print(f"  interval={payload.get('chrom')}:{payload.get('requested_interval')[0]}-{payload.get('requested_interval')[1]} ({payload.get('assembly')})")
print(f"  input_window={payload.get('input_window')}")
print(f"  output_window={payload.get('output_window')}")
print(f"  preds_shape={tuple(npz['preds'].shape)}")
print(f"  plot_path={payload.get('plot_path')}")
print(f"  result_json={result_path}")
PY

echo "[borzoi-track] Completed."
