#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_REGISTRY_FILE="$REPO_ROOT/registry/skills.yaml"
source "$REPO_ROOT/scripts/lib_registry.sh"

usage() {
  cat <<'EOF_USAGE'
Usage: validate_registry_tracking.sh [options]

Validate registry skill paths against git tracking rules.

Default behavior:
- enabled=true skills must exist, must not be git-ignored, and must be tracked by git
- enabled=false skills are reported as info only

Options:
  --registry FILE       Skill registry file. Default: <repo>/registry/skills.yaml
  --include-disabled    Apply strict checks to disabled skills as well.
  -h, --help            Show this help message.
EOF_USAGE
}

registry_file="$DEFAULT_REGISTRY_FILE"
include_disabled=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --registry)
      registry_file="$2"
      shift 2
      ;;
    --include-disabled)
      include_disabled=1
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

registry_require_file "$registry_file"

if ! git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "error: repository root is not a git work tree: $REPO_ROOT" >&2
  exit 1
fi

failures=0
total=0

while IFS= read -r skill_id; do
  [[ -z "$skill_id" ]] && continue
  total=$((total + 1))

  skill_path="$(registry_get_path "$registry_file" "$skill_id" || true)"
  if [[ -z "$skill_path" ]]; then
    skill_path="$skill_id"
  fi

  enabled_state="false"
  if registry_skill_enabled "$registry_file" "$skill_id"; then
    enabled_state="true"
  fi

  strict_check=0
  if [[ "$enabled_state" == "true" || "$include_disabled" -eq 1 ]]; then
    strict_check=1
  fi

  if [[ "$strict_check" -eq 0 ]]; then
    echo "info: $skill_id is disabled; tracking checks skipped"
    continue
  fi

  skill_root="$REPO_ROOT/$skill_path"
  if [[ ! -d "$skill_root" ]]; then
    echo "fail: $skill_id path missing ($skill_root)" >&2
    failures=$((failures + 1))
    continue
  fi

  if git -C "$REPO_ROOT" check-ignore -q "$skill_path"; then
    echo "fail: $skill_id path is git-ignored ($skill_path)" >&2
    failures=$((failures + 1))
    continue
  fi

  tracked_count="$(git -C "$REPO_ROOT" ls-files "$skill_path" | wc -l | tr -d '[:space:]')"
  if [[ -z "$tracked_count" || "$tracked_count" == "0" ]]; then
    echo "fail: $skill_id path has no tracked files ($skill_path)" >&2
    failures=$((failures + 1))
    continue
  fi

  echo "ok: $skill_id tracking verified ($skill_path, tracked_files=$tracked_count)"
done < <(registry_list_ids "$registry_file")

if [[ "$total" -eq 0 ]]; then
  echo "fail: no skills found in registry ($registry_file)" >&2
  exit 1
fi

if [[ "$failures" -ne 0 ]]; then
  echo "registry tracking validation failed with $failures issue(s)" >&2
  exit 1
fi

echo "registry tracking validation passed for $total skill(s)"
