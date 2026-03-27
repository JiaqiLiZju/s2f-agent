#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_DEPLOY_ROOT="$REPO_ROOT/.deploy"
DEFAULT_CACHE_DIR="${HF_HOME:-${XDG_CACHE_HOME:-$HOME/.cache}/huggingface}/hub"

DEFAULT_MODELS=(
  "zhihan1996/DNABERT-2-117M"
  "songlab/gpn-brassicales"
  "InstaDeepAI/NTv3_8M_pre"
  "InstaDeepAI/NTv3_100M_post"
)

usage() {
  cat <<'EOF'
Usage: prefetch_models.sh [options]

Prefetch Hugging Face model snapshots into a persistent cache so later runs can reuse
already-downloaded model parameters.

Options:
  --deploy-root DIR   Working root used for helper venv. Default: <repo>/.deploy
  --python BIN        Python executable used to create helper venv. Default: python3
  --cache-dir DIR     Hugging Face cache dir used by snapshot_download.
                      Default: ${HF_HOME:-${XDG_CACHE_HOME:-$HOME/.cache}/huggingface}/hub
  --model ID          Additional model id to prefetch (repeatable).
  --no-defaults       Disable built-in default model list.
  --hf-token TOKEN    Hugging Face token for gated/private repos.
                      Falls back to HF_TOKEN or HUGGINGFACE_HUB_TOKEN if omitted.
  --list-defaults     Print default model ids and exit.
  -h, --help          Show this help message.
EOF
}

print_defaults() {
  printf '%s\n' "${DEFAULT_MODELS[@]}"
}

deploy_root="$DEFAULT_DEPLOY_ROOT"
python_bin="python3"
cache_dir="$DEFAULT_CACHE_DIR"
include_defaults=1
hf_token="${HF_TOKEN:-${HUGGINGFACE_HUB_TOKEN:-}}"
models=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --deploy-root)
      deploy_root="$2"
      shift 2
      ;;
    --python)
      python_bin="$2"
      shift 2
      ;;
    --cache-dir)
      cache_dir="$2"
      shift 2
      ;;
    --model)
      models+=("$2")
      shift 2
      ;;
    --no-defaults)
      include_defaults=0
      shift
      ;;
    --hf-token)
      hf_token="$2"
      shift 2
      ;;
    --list-defaults)
      print_defaults
      exit 0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unexpected argument '$1'" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ "$include_defaults" -eq 1 ]]; then
  for mid in "${DEFAULT_MODELS[@]}"; do
    models+=("$mid")
  done
fi

if [[ ${#models[@]} -eq 0 ]]; then
  echo "error: no models selected. Use --model or keep defaults enabled." >&2
  exit 1
fi

mkdir -p "$cache_dir"
prefetch_venv="$deploy_root/venvs/model-prefetch"
if [[ ! -x "$prefetch_venv/bin/python" ]]; then
  mkdir -p "$(dirname "$prefetch_venv")"
  "$python_bin" -m venv "$prefetch_venv"
fi

prefetch_python="$prefetch_venv/bin/python"
"$prefetch_python" -m pip install --upgrade pip >/dev/null
"$prefetch_python" -m pip install --upgrade "huggingface_hub>=0.23,<1" >/dev/null

"$prefetch_python" - "$cache_dir" "${hf_token:-}" "${models[@]}" <<'PY'
import os
import sys

from huggingface_hub import snapshot_download

cache_dir = sys.argv[1]
token = sys.argv[2] or None
model_ids = sys.argv[3:]

success = 0
failed = []

for model_id in model_ids:
    try:
        snapshot_download(
            repo_id=model_id,
            cache_dir=cache_dir,
            token=token,
        )
        success += 1
        print(f"ok: {model_id}")
    except Exception as exc:  # pragma: no cover
        failed.append((model_id, str(exc)))
        print(f"warn: failed to prefetch {model_id}: {exc}", file=sys.stderr)

print(
    f"prefetch summary: success={success} failed={len(failed)} cache_dir={cache_dir}"
)
if success == 0:
    raise SystemExit(2)
PY

echo "model prefetch complete"
