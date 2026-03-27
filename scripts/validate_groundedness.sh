#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_CASES_FILE="$REPO_ROOT/evals/groundedness/cases.yaml"
DEFAULT_AGENT_SCRIPT="$REPO_ROOT/scripts/run_agent.sh"

usage() {
  cat <<'EOF_USAGE'
Usage: validate_groundedness.sh [options]

Evaluate groundedness-oriented constraints with curated cases.

Options:
  --cases FILE          Groundedness cases file. Default: <repo>/evals/groundedness/cases.yaml
  --agent FILE          run_agent script path. Default: <repo>/scripts/run_agent.sh
  --include-disabled    Include disabled skills in upstream routing.
  -h, --help            Show this help message.
EOF_USAGE
}

cases_file="$DEFAULT_CASES_FILE"
agent_script="$DEFAULT_AGENT_SCRIPT"
include_disabled=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cases)
      cases_file="$2"
      shift 2
      ;;
    --agent)
      agent_script="$2"
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

if [[ ! -f "$cases_file" ]]; then
  echo "error: cases file not found: $cases_file" >&2
  exit 1
fi

if [[ ! -f "$agent_script" ]]; then
  echo "error: run_agent script not found: $agent_script" >&2
  exit 1
fi

parse_cases() {
  local file="$1"
  awk '
    BEGIN {
      OFS = "\037"
      case_id = ""
      query = ""
      task = ""
      expected_primary = ""
      required_constraint = ""
      forbidden_substring = ""
    }
    function trim(s) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", s)
      return s
    }
    function unquote(s) {
      s = trim(s)
      if (s ~ /^".*"$/) {
        sub(/^"/, "", s)
        sub(/"$/, "", s)
      }
      return s
    }
    function emit_case() {
      if (case_id != "") {
        print case_id, query, task, expected_primary, required_constraint, forbidden_substring
      }
    }
    /^[[:space:]]*-[[:space:]]id:[[:space:]]*/ {
      emit_case()
      case_id = $0
      sub(/^[[:space:]]*-[[:space:]]id:[[:space:]]*/, "", case_id)
      case_id = unquote(case_id)
      query = ""
      task = ""
      expected_primary = ""
      required_constraint = ""
      forbidden_substring = ""
      next
    }
    /^[[:space:]]*query:[[:space:]]*/ {
      query = $0
      sub(/^[[:space:]]*query:[[:space:]]*/, "", query)
      query = unquote(query)
      next
    }
    /^[[:space:]]*task:[[:space:]]*/ {
      task = $0
      sub(/^[[:space:]]*task:[[:space:]]*/, "", task)
      task = unquote(task)
      next
    }
    /^[[:space:]]*expected_primary_skill:[[:space:]]*/ {
      expected_primary = $0
      sub(/^[[:space:]]*expected_primary_skill:[[:space:]]*/, "", expected_primary)
      expected_primary = unquote(expected_primary)
      next
    }
    /^[[:space:]]*required_constraint_contains:[[:space:]]*/ {
      required_constraint = $0
      sub(/^[[:space:]]*required_constraint_contains:[[:space:]]*/, "", required_constraint)
      required_constraint = unquote(required_constraint)
      next
    }
    /^[[:space:]]*forbidden_substring:[[:space:]]*/ {
      forbidden_substring = $0
      sub(/^[[:space:]]*forbidden_substring:[[:space:]]*/, "", forbidden_substring)
      forbidden_substring = unquote(forbidden_substring)
      next
    }
    END {
      emit_case()
    }
  ' "$file"
}

to_lower() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

extract_decision() {
  local json="$1"
  printf '%s\n' "$json" | sed -n 's/.*"decision":"\([^"]*\)".*/\1/p'
}

extract_primary_skill() {
  local json="$1"
  printf '%s\n' "$json" | sed -n 's/.*"primary_skill":"\([^"]*\)".*/\1/p'
}

extract_constraints_csv() {
  local json="$1"
  local raw
  raw="$(printf '%s\n' "$json" | sed -n 's/.*"constraints":\[\([^]]*\)\].*/\1/p')"
  if [[ -z "$raw" ]]; then
    printf '\n'
    return 0
  fi
  printf '%s\n' "$raw" | sed 's/^"//; s/"$//' | sed 's/","/,/g' | sed 's/\\"/"/g'
}

total=0
passed=0
failed=0

while IFS=$'\x1f' read -r case_id query task expected_primary required_constraint forbidden_substring; do
  [[ -z "$case_id" ]] && continue
  total=$((total + 1))

  cmd=(bash "$agent_script" --query "$query" --format json)
  if [[ -n "$task" ]]; then
    cmd+=(--task "$task")
  fi
  if [[ "$include_disabled" -eq 1 ]]; then
    cmd+=(--include-disabled)
  fi

  output=""
  if ! output="$("${cmd[@]}" 2>&1)"; then
    failed=$((failed + 1))
    echo "fail: $case_id (run_agent failed)" >&2
    echo "  query: $query" >&2
    echo "  error: $output" >&2
    continue
  fi

  decision="$(extract_decision "$output")"
  if [[ "$decision" != "route" ]]; then
    failed=$((failed + 1))
    echo "fail: $case_id" >&2
    echo "  expected decision: route" >&2
    echo "  got: ${decision:-none}" >&2
    continue
  fi

  primary="$(extract_primary_skill "$output")"
  if [[ -n "$expected_primary" && "$primary" != "$expected_primary" ]]; then
    failed=$((failed + 1))
    echo "fail: $case_id" >&2
    echo "  expected primary: $expected_primary" >&2
    echo "  got primary: ${primary:-none}" >&2
    continue
  fi

  constraints_csv="$(extract_constraints_csv "$output")"
  constraints_lc="$(to_lower "$constraints_csv")"
  required_lc="$(to_lower "$required_constraint")"
  if [[ -n "$required_lc" && "$constraints_lc" != *"$required_lc"* ]]; then
    failed=$((failed + 1))
    echo "fail: $case_id" >&2
    echo "  required constraint fragment not found: $required_constraint" >&2
    echo "  constraints: ${constraints_csv:-none}" >&2
    continue
  fi

  full_lc="$(to_lower "$output")"
  forbidden_lc="$(to_lower "$forbidden_substring")"
  if [[ -n "$forbidden_lc" && "$full_lc" == *"$forbidden_lc"* ]]; then
    failed=$((failed + 1))
    echo "fail: $case_id" >&2
    echo "  forbidden substring found: $forbidden_substring" >&2
    continue
  fi

  passed=$((passed + 1))
  echo "pass: $case_id (primary=${primary:-none})"
done < <(parse_cases "$cases_file")

echo "groundedness eval summary: $passed/$total passed"
if [[ "$failed" -ne 0 ]]; then
  exit 1
fi
