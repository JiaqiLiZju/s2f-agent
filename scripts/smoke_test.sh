#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_IDS=(
  "alphagenome-api"
  "evo2-inference"
  "gpn-models"
  "nucleotide-transformer"
  "nucleotide-transformer-v3"
  "segment-nt"
)

usage() {
  cat <<'EOF'
Usage: smoke_test.sh [options]

Check that the repository layout, skill links, helper scripts, and optional software imports
look correct on a target machine.

Options:
  --skills-dir DIR         Check linked/copied skills in this Codex skills directory.
  --alphagenome-python P   Run AlphaGenome import checks with this Python executable.
  --gpn-python P           Run GPN import checks with this Python executable.
  --nt-python P            Run NT / NTv3 / SegmentNT import checks with this Python executable.
  --evo2-python P          Run Evo 2 import checks with this Python executable.
  -h, --help               Show this help message.
EOF
}

skills_dir=""
alphagenome_python=""
gpn_python=""
nt_python=""
evo2_python=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skills-dir)
      skills_dir="$2"
      shift 2
      ;;
    --alphagenome-python)
      alphagenome_python="$2"
      shift 2
      ;;
    --gpn-python)
      gpn_python="$2"
      shift 2
      ;;
    --nt-python)
      nt_python="$2"
      shift 2
      ;;
    --evo2-python)
      evo2_python="$2"
      shift 2
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

failures=0

check_exists() {
  local path="$1"
  local label="$2"
  if [[ -e "$path" ]]; then
    echo "ok: $label"
  else
    echo "fail: missing $label ($path)" >&2
    failures=$((failures + 1))
  fi
}

run_import_check() {
  local label="$1"
  local python_bin="$2"
  local code="$3"

  if [[ -z "$python_bin" ]]; then
    return 0
  fi

  if "$python_bin" -c "$code" >/dev/null; then
    echo "ok: $label imports"
  else
    echo "fail: $label imports" >&2
    failures=$((failures + 1))
  fi
}

check_exists "$REPO_ROOT/README.md" "repo README"
check_exists "$REPO_ROOT/Makefile" "Makefile"
check_exists "$REPO_ROOT/scripts/link_skills.sh" "link_skills.sh"
check_exists "$REPO_ROOT/scripts/bootstrap.sh" "bootstrap.sh"
check_exists "$REPO_ROOT/scripts/provision_stack.sh" "provision_stack.sh"
check_exists "$REPO_ROOT/scripts/smoke_test.sh" "smoke_test.sh"
check_exists "$REPO_ROOT/nucleotide-transformer-v3/scripts/check_valid_length.py" "NTv3 helper script"
check_exists "$REPO_ROOT/segment-nt/scripts/compute_rescaling_factor.py" "SegmentNT helper script"

for skill in "${SKILL_IDS[@]}"; do
  check_exists "$REPO_ROOT/$skill/SKILL.md" "$skill SKILL.md"
  check_exists "$REPO_ROOT/$skill/agents/openai.yaml" "$skill agents/openai.yaml"

  if [[ -n "$skills_dir" ]]; then
    check_exists "$skills_dir/$skill" "$skill installed in skills dir"
  fi
done

run_import_check \
  "alphagenome" \
  "$alphagenome_python" \
  'from alphagenome.data import genome; from alphagenome.models import dna_client'

run_import_check \
  "gpn" \
  "$gpn_python" \
  'import gpn.model; import gpn.star.model; from transformers import AutoModel; from transformers import AutoModelForMaskedLM'

run_import_check \
  "nt-stack" \
  "$nt_python" \
  'from nucleotide_transformer.pretrained import get_pretrained_model, get_pretrained_segment_nt_model; from nucleotide_transformer_v3.pretrained import get_pretrained_ntv3_model, get_posttrained_ntv3_model'

run_import_check \
  "evo2" \
  "$evo2_python" \
  'from evo2 import Evo2'

if python3 "$REPO_ROOT/nucleotide-transformer-v3/scripts/check_valid_length.py" 32768 >/dev/null; then
  echo "ok: NTv3 helper script"
else
  echo "fail: NTv3 helper script" >&2
  failures=$((failures + 1))
fi

if python3 "$REPO_ROOT/segment-nt/scripts/compute_rescaling_factor.py" --sequence-length-bp 40008 >/dev/null; then
  echo "ok: SegmentNT helper script"
else
  echo "fail: SegmentNT helper script" >&2
  failures=$((failures + 1))
fi

if [[ "$failures" -ne 0 ]]; then
  echo "smoke test failed with $failures issue(s)" >&2
  exit 1
fi

echo "smoke test passed"
