#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_SKILLS_DIR="${CODEX_HOME:-$HOME/.codex}/skills"
DEFAULT_REGISTRY_FILE="$REPO_ROOT/registry/skills.yaml"
source "$REPO_ROOT/scripts/lib_registry.sh"

AVAILABLE_SKILLS=()

usage() {
  cat <<'EOF'
Usage: link_skills.sh [options] [skill-id ...]

Link or copy this repository's packaged skills into the Codex skills directory.

Options:
  --skills-dir DIR   Destination skills directory.
  --registry FILE    Skill registry file. Default: <repo>/registry/skills.yaml
  --copy             Copy instead of symlink.
  --force            Replace an existing destination path.
  --list             Print the available skill IDs and exit.
  -h, --help         Show this help message.

If no skill IDs are passed, all packaged skills are installed.
EOF
}

load_available_skills() {
  AVAILABLE_SKILLS=()
  while IFS= read -r skill_id; do
    if [[ -n "$skill_id" ]]; then
      AVAILABLE_SKILLS+=("$skill_id")
    fi
  done < <(registry_list_ids "$registry_file")

  if [[ ${#AVAILABLE_SKILLS[@]} -eq 0 ]]; then
    echo "error: no skills found in registry file: $registry_file" >&2
    exit 1
  fi
}

print_available() {
  load_available_skills
  printf '%s\n' "${AVAILABLE_SKILLS[@]}"
}

copy_mode=0
force_mode=0
skills_dir="$DEFAULT_SKILLS_DIR"
registry_file="$DEFAULT_REGISTRY_FILE"
selected=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skills-dir)
      skills_dir="$2"
      shift 2
      ;;
    --registry)
      registry_file="$2"
      shift 2
      ;;
    --copy)
      copy_mode=1
      shift
      ;;
    --force)
      force_mode=1
      shift
      ;;
    --list)
      print_available
      exit 0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      selected+=("$1")
      shift
      ;;
  esac
done

load_available_skills

if [[ ${#selected[@]} -eq 0 ]]; then
  selected=("${AVAILABLE_SKILLS[@]}")
fi

resolve_skill_source() {
  local skill_id="$1"
  local configured_path
  configured_path="$(registry_get_path "$registry_file" "$skill_id" || true)"
  if [[ -n "$configured_path" ]]; then
    printf '%s\n' "$REPO_ROOT/$configured_path"
    return 0
  fi
  printf '%s\n' "$REPO_ROOT/$skill_id"
}

mkdir -p "$skills_dir"

for skill in "${selected[@]}"; do
  src="$(resolve_skill_source "$skill")"
  dest="$skills_dir/$skill"

  if [[ ! -d "$src" ]]; then
    echo "error: unknown skill '$skill' (expected directory $src)" >&2
    exit 1
  fi

  if [[ -L "$dest" ]] && [[ "$(readlink "$dest")" == "$src" ]]; then
    echo "already linked: $skill -> $src"
    continue
  fi

  if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ "$force_mode" -ne 1 ]]; then
      echo "skip: $dest already exists (use --force to replace it)"
      continue
    fi
    rm -rf "$dest"
  fi

  if [[ "$copy_mode" -eq 1 ]]; then
    cp -R "$src" "$dest"
    echo "copied: $skill -> $dest"
  else
    ln -s "$src" "$dest"
    echo "linked: $skill -> $dest"
  fi
done
