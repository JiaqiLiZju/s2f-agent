#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_DEPLOY_ROOT="${S2F_DEPLOY_ROOT:-$REPO_ROOT/.deploy}"
DEFAULT_PERSISTENT_ROOT="${S2F_PERSISTENT_ROOT:-${XDG_CACHE_HOME:-$HOME/.cache}/s2f-skills}"
DEFAULT_SKILLS_DIR="${CODEX_HOME:-$HOME/.codex}/skills"
DEFAULT_REGISTRY_FILE="$REPO_ROOT/registry/skills.yaml"

source "$REPO_ROOT/scripts/lib_registry.sh"

usage() {
  cat <<'EOF'
Usage: clean_runtime.sh [options]

One-click cleanup for s2f configured runtime environments and temporary files.

By default, this script cleans:
  1) runtime paths: deploy root + persistent root
  2) repository temp paths: output/, __pycache__/, *.pyc, *.pyo, .pytest_cache/, .ruff_cache/, .mypy_cache/

Options:
  --repo-root DIR       Repository root to clean temp files from. Default: <repo>
  --deploy-root DIR     Deploy root to remove. Default: $S2F_DEPLOY_ROOT or <repo>/.deploy
  --persistent-root DIR Persistent root to remove. Default: $S2F_PERSISTENT_ROOT or ${XDG_CACHE_HOME:-$HOME/.cache}/s2f-skills
  --skills-dir DIR      Codex skills dir used with --clear-skills. Default: ${CODEX_HOME:-$HOME/.codex}/skills
  --registry FILE       Registry file used with --clear-skills. Default: <repo>/registry/skills.yaml
  --runtime-only        Clean only runtime paths (deploy/persistent roots).
  --temp-only           Clean only repository temp files.
  --clear-skills        Also remove installed skill links/copies listed in registry from --skills-dir.
  --dry-run             Print planned deletions without removing files.
  --yes                 Skip confirmation prompt.
  -h, --help            Show this help message.
EOF
}

repo_root="$REPO_ROOT"
deploy_root="$DEFAULT_DEPLOY_ROOT"
persistent_root="$DEFAULT_PERSISTENT_ROOT"
skills_dir="$DEFAULT_SKILLS_DIR"
registry_file="$DEFAULT_REGISTRY_FILE"
clean_runtime=1
clean_temp=1
clear_skills=0
dry_run=0
assume_yes=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-root)
      repo_root="$2"
      shift 2
      ;;
    --deploy-root)
      deploy_root="$2"
      shift 2
      ;;
    --persistent-root)
      persistent_root="$2"
      shift 2
      ;;
    --skills-dir)
      skills_dir="$2"
      shift 2
      ;;
    --registry)
      registry_file="$2"
      shift 2
      ;;
    --runtime-only)
      clean_runtime=1
      clean_temp=0
      shift
      ;;
    --temp-only)
      clean_runtime=0
      clean_temp=1
      shift
      ;;
    --clear-skills)
      clear_skills=1
      shift
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    --yes)
      assume_yes=1
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

if [[ "$clean_runtime" -eq 0 && "$clean_temp" -eq 0 && "$clear_skills" -eq 0 ]]; then
  echo "error: nothing selected to clean" >&2
  exit 1
fi

declare -a targets=()

target_exists() {
  local path="$1"
  local item
  for item in "${targets[@]:-}"; do
    [[ -z "$item" ]] && continue
    if [[ "$item" == "$path" ]]; then
      return 0
    fi
  done
  return 1
}

add_target() {
  local path="$1"
  [[ -z "$path" ]] && return 0
  if [[ "$path" == "/" || "$path" == "$HOME" || "$path" == "." ]]; then
    echo "error: refusing unsafe delete target: $path" >&2
    exit 2
  fi
  if target_exists "$path"; then
    return 0
  fi
  targets+=("$path")
}

if [[ "$clean_runtime" -eq 1 ]]; then
  add_target "$deploy_root"
  add_target "$persistent_root"
fi

if [[ "$clean_temp" -eq 1 ]]; then
  add_target "$repo_root/output"
  add_target "$repo_root/.pytest_cache"
  add_target "$repo_root/.ruff_cache"
  add_target "$repo_root/.mypy_cache"

  while IFS= read -r path; do
    [[ -n "$path" ]] && add_target "$path"
  done < <(find "$repo_root" -type d -name "__pycache__" 2>/dev/null || true)

  while IFS= read -r path; do
    [[ -n "$path" ]] && add_target "$path"
  done < <(find "$repo_root" -type f \( -name "*.pyc" -o -name "*.pyo" \) 2>/dev/null || true)
fi

if [[ "$clear_skills" -eq 1 ]]; then
  registry_require_file "$registry_file"
  while IFS= read -r sid; do
    [[ -z "$sid" ]] && continue
    add_target "$skills_dir/$sid"
  done < <(registry_list_ids "$registry_file")
fi

has_targets=0
for path in "${targets[@]:-}"; do
  [[ -z "$path" ]] && continue
  has_targets=1
  break
done

if [[ "$has_targets" -eq 0 ]]; then
  echo "nothing to clean"
  exit 0
fi

echo "cleanup plan:"
for path in "${targets[@]:-}"; do
  [[ -z "$path" ]] && continue
  if [[ -e "$path" || -L "$path" ]]; then
    echo "  - $path"
  fi
done

if [[ "$assume_yes" -ne 1 && "$dry_run" -ne 1 ]]; then
  read -r -p "Proceed with cleanup? [y/N] " answer
  answer="$(printf '%s' "$answer" | tr '[:upper:]' '[:lower:]')"
  if [[ "$answer" != "y" && "$answer" != "yes" ]]; then
    echo "aborted"
    exit 0
  fi
fi

deleted=0
skipped=0
for path in "${targets[@]:-}"; do
  [[ -z "$path" ]] && continue
  if [[ ! -e "$path" && ! -L "$path" ]]; then
    skipped=$((skipped + 1))
    continue
  fi
  if [[ "$dry_run" -eq 1 ]]; then
    echo "dry-run: rm -rf \"$path\""
    continue
  fi
  rm -rf "$path"
  echo "removed: $path"
  deleted=$((deleted + 1))
done

if [[ "$dry_run" -eq 1 ]]; then
  echo "dry-run complete"
else
  echo "cleanup complete: deleted=$deleted skipped_missing=$skipped"
fi
