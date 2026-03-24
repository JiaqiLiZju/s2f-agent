#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat <<'EOF'
Usage: provision_stack.sh <stack> [options]

Create a fresh environment for one software stack on a new machine.
This script is intended to be run later on the target machine, not in the current workspace.

Stacks:
  alphagenome   AlphaGenome API software
  gpn           Song Lab GPN package
  nt-jax        Classic NT + SegmentNT-family JAX stack (source install)
  ntv3-hf       NTv3 tutorial stack (Hugging Face Transformers + PyTorch)
  evo2-light    Evo 2 light install (7B-class workflow)
  evo2-full     Evo 2 full install inside an active conda environment

Options:
  --deploy-root DIR   Working root for environments and upstream clones.
                      Default: <repo>/.deploy
  --python BIN        Python executable to use for venv creation. Default: python3
  -h, --help          Show this help message.

Environment variables:
  JAX_INSTALL_CMD     Optional command for hardware-specific JAX installation.
                      The script exposes $VENV_PYTHON for convenience.
  TORCH_INSTALL_CMD   Required for evo2-light. Example:
                      TORCH_INSTALL_CMD='$VENV_PYTHON -m pip install torch==2.7.1 --index-url https://download.pytorch.org/whl/cu128'
EOF
}

create_venv() {
  local python_bin="$1"
  local venv_dir="$2"

  if [[ ! -d "$venv_dir" ]]; then
    "$python_bin" -m venv "$venv_dir"
  fi

  echo "$venv_dir/bin/python"
}

clone_if_missing() {
  local url="$1"
  local target="$2"

  if [[ -d "$target/.git" ]]; then
    echo "using existing clone: $target"
    return 0
  fi

  mkdir -p "$(dirname "$target")"
  git clone "$url" "$target"
}

stack=""
deploy_root="$REPO_ROOT/.deploy"
python_bin="python3"

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
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -z "$stack" ]]; then
        stack="$1"
        shift
      else
        echo "error: unexpected argument '$1'" >&2
        usage >&2
        exit 1
      fi
      ;;
  esac
done

if [[ -z "$stack" ]]; then
  usage >&2
  exit 1
fi

venv_root="$deploy_root/venvs"
src_root="$deploy_root/src"
mkdir -p "$venv_root" "$src_root"

case "$stack" in
  alphagenome)
    venv_dir="$venv_root/alphagenome"
    venv_python="$(create_venv "$python_bin" "$venv_dir")"
    if ! "$venv_python" -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)'; then
      echo "error: alphagenome requires Python >= 3.10." >&2
      echo "hint: rerun with --python python3.10 (or newer)." >&2
      exit 2
    fi
    "$venv_python" -m pip install --upgrade pip setuptools wheel
    if clone_if_missing "https://github.com/google-deepmind/alphagenome.git" "$src_root/alphagenome"; then
      "$venv_python" -m pip install "$src_root/alphagenome"
    else
      echo "warn: failed to clone alphagenome from GitHub; falling back to package index install." >&2
      "$venv_python" -m pip install alphagenome
    fi
    echo "ready: alphagenome environment at $venv_dir"
    ;;
  gpn)
    venv_dir="$venv_root/gpn"
    venv_python="$(create_venv "$python_bin" "$venv_dir")"
    "$venv_python" -m pip install --upgrade pip setuptools wheel
    "$venv_python" -m pip install "git+https://github.com/songlab-cal/gpn.git"
    echo "ready: gpn environment at $venv_dir"
    ;;
  nt-jax)
    venv_dir="$venv_root/nt-jax"
    venv_python="$(create_venv "$python_bin" "$venv_dir")"
    if ! "$venv_python" -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)'; then
      echo "error: nt-jax source install requires Python >= 3.10 in practice (upstream JAX constraints)." >&2
      echo "hint: rerun with --python python3.10 (or newer), or use stack ntv3-hf for NTv3 tutorial workflows." >&2
      exit 2
    fi
    "$venv_python" -m pip install --upgrade pip setuptools wheel
    if [[ -n "${JAX_INSTALL_CMD:-}" ]]; then
      VENV_PYTHON="$venv_python" bash -lc "$JAX_INSTALL_CMD"
    else
      "$venv_python" -m pip install "jax>=0.3.25"
    fi
    clone_if_missing "https://github.com/instadeepai/nucleotide-transformer.git" "$src_root/nucleotide-transformer"
    "$venv_python" -m pip install "$src_root/nucleotide-transformer"
    echo "ready: nt-jax environment at $venv_dir"
    ;;
  ntv3-hf)
    venv_dir="$venv_root/ntv3-hf"
    venv_python="$(create_venv "$python_bin" "$venv_dir")"
    "$venv_python" -m pip install --upgrade pip setuptools wheel
    "$venv_python" -m pip install \
      "transformers>=4.55,<5" \
      "huggingface_hub>=0.23,<1" \
      safetensors \
      torch \
      "numpy<2"
    echo "ready: ntv3-hf environment at $venv_dir"
    ;;
  evo2-light)
    if [[ -z "${TORCH_INSTALL_CMD:-}" ]]; then
      echo "error: TORCH_INSTALL_CMD is required for evo2-light." >&2
      echo "example: TORCH_INSTALL_CMD='\$VENV_PYTHON -m pip install torch==2.7.1 --index-url https://download.pytorch.org/whl/cu128'" >&2
      exit 2
    fi
    venv_dir="$venv_root/evo2-light"
    venv_python="$(create_venv "$python_bin" "$venv_dir")"
    "$venv_python" -m pip install --upgrade pip setuptools wheel
    VENV_PYTHON="$venv_python" bash -lc "$TORCH_INSTALL_CMD"
    "$venv_python" -m pip install "flash-attn==2.8.0.post2" --no-build-isolation
    "$venv_python" -m pip install evo2
    echo "ready: evo2-light environment at $venv_dir"
    ;;
  evo2-full)
    if ! command -v conda >/dev/null 2>&1; then
      echo "error: conda must be installed for evo2-full." >&2
      exit 2
    fi
    if [[ -z "${CONDA_PREFIX:-}" ]]; then
      echo "error: activate a conda environment before running evo2-full." >&2
      exit 2
    fi
    conda install -y -c nvidia cuda-nvcc cuda-cudart-dev
    conda install -y -c conda-forge transformer-engine-torch=2.3.0
    python -m pip install "flash-attn==2.8.0.post2" --no-build-isolation
    python -m pip install evo2
    echo "ready: evo2-full installed into active conda environment $CONDA_PREFIX"
    ;;
  *)
    echo "error: unknown stack '$stack'" >&2
    usage >&2
    exit 1
    ;;
esac
