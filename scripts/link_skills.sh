#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_SKILLS_DIR="${CODEX_HOME:-$HOME/.codex}/skills"
AVAILABLE_SKILLS=(
  "alphagenome-api"
  "evo2-inference"
  "gpn-models"
  "nucleotide-transformer"
  "nucleotide-transformer-v3"
  "segment-nt"
)

usage() {
  cat <<'EOF'
Usage: link_skills.sh [options] [skill-id ...]

Link or copy this repository's packaged skills into the Codex skills directory.

Options:
  --skills-dir DIR   Destination skills directory.
  --copy             Copy instead of symlink.
  --force            Replace an existing destination path.
  --list             Print the available skill IDs and exit.
  -h, --help         Show this help message.

If no skill IDs are passed, all packaged skills are installed.
EOF
}

print_available() {
  printf '%s\n' "${AVAILABLE_SKILLS[@]}"
}

copy_mode=0
force_mode=0
skills_dir="$DEFAULT_SKILLS_DIR"
selected=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skills-dir)
      skills_dir="$2"
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

if [[ ${#selected[@]} -eq 0 ]]; then
  selected=("${AVAILABLE_SKILLS[@]}")
fi

mkdir -p "$skills_dir"

for skill in "${selected[@]}"; do
  src="$REPO_ROOT/$skill"
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
