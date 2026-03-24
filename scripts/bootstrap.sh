#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_DEPLOY_ROOT="$REPO_ROOT/.deploy"
DEFAULT_SKILLS_DIR="${CODEX_HOME:-$HOME/.codex}/skills"
CORE_STACKS=("alphagenome" "gpn" "nt-jax")

usage() {
  cat <<'EOF'
Usage: bootstrap.sh [options]

One-step installer for a fresh machine. By default, it:
  1. Links all packaged skills into the Codex skills directory
  2. Provisions the core software stacks: alphagenome, gpn, nt-jax
  3. Runs the repository smoke test against the deployed paths

Options:
  --deploy-root DIR      Working root for virtual environments and upstream clones.
                         Default: <repo>/.deploy
  --skills-dir DIR       Destination Codex skills directory.
                         Default: ${CODEX_HOME:-$HOME/.codex}/skills
  --python BIN           Python executable to use for venv creation. Default: python3
  --copy-skills          Copy skills instead of symlinking them.
  --force-links          Replace existing paths in the skills directory.
  --with-evo2-light      Also provision evo2-light and include it in smoke tests.
  --with-evo2-full       Also provision evo2-full in the currently active conda env.
  --skip-link            Skip linking/copying skills.
  --skip-smoke           Skip the final smoke test.
  -h, --help             Show this help message.

Environment variables:
  JAX_INSTALL_CMD        Optional hardware-specific JAX install command for nt-jax.
  TORCH_INSTALL_CMD      Required when using --with-evo2-light.
EOF
}

deploy_root="$DEFAULT_DEPLOY_ROOT"
skills_dir="$DEFAULT_SKILLS_DIR"
python_bin="python3"
copy_skills=0
force_links=0
with_evo2_light=0
with_evo2_full=0
skip_link=0
skip_smoke=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --deploy-root)
      deploy_root="$2"
      shift 2
      ;;
    --skills-dir)
      skills_dir="$2"
      shift 2
      ;;
    --python)
      python_bin="$2"
      shift 2
      ;;
    --copy-skills)
      copy_skills=1
      shift
      ;;
    --force-links)
      force_links=1
      shift
      ;;
    --with-evo2-light)
      with_evo2_light=1
      shift
      ;;
    --with-evo2-full)
      with_evo2_full=1
      shift
      ;;
    --skip-link)
      skip_link=1
      shift
      ;;
    --skip-smoke)
      skip_smoke=1
      shift
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

if [[ "$with_evo2_light" -eq 1 && "$with_evo2_full" -eq 1 ]]; then
  echo "error: choose either --with-evo2-light or --with-evo2-full, not both" >&2
  exit 1
fi

if [[ "$skip_link" -ne 1 ]]; then
  link_args=(--skills-dir "$skills_dir")
  if [[ "$copy_skills" -eq 1 ]]; then
    link_args+=(--copy)
  fi
  if [[ "$force_links" -eq 1 ]]; then
    link_args+=(--force)
  fi
  bash "$REPO_ROOT/scripts/link_skills.sh" "${link_args[@]}"
fi

for stack in "${CORE_STACKS[@]}"; do
  bash "$REPO_ROOT/scripts/provision_stack.sh" "$stack" \
    --deploy-root "$deploy_root" \
    --python "$python_bin"
done

evo2_python=""
if [[ "$with_evo2_light" -eq 1 ]]; then
  bash "$REPO_ROOT/scripts/provision_stack.sh" evo2-light \
    --deploy-root "$deploy_root" \
    --python "$python_bin"
  evo2_python="$deploy_root/venvs/evo2-light/bin/python"
fi

if [[ "$with_evo2_full" -eq 1 ]]; then
  bash "$REPO_ROOT/scripts/provision_stack.sh" evo2-full \
    --deploy-root "$deploy_root" \
    --python "$python_bin"
  evo2_python="python"
fi

if [[ "$skip_smoke" -ne 1 ]]; then
  smoke_args=(--skills-dir "$skills_dir")
  smoke_args+=(--alphagenome-python "$deploy_root/venvs/alphagenome/bin/python")
  smoke_args+=(--gpn-python "$deploy_root/venvs/gpn/bin/python")
  smoke_args+=(--nt-python "$deploy_root/venvs/nt-jax/bin/python")
  if [[ -n "$evo2_python" ]]; then
    smoke_args+=(--evo2-python "$evo2_python")
  fi
  bash "$REPO_ROOT/scripts/smoke_test.sh" "${smoke_args[@]}"
fi

echo "bootstrap complete"
