#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_CASES_FILE="$REPO_ROOT/evals/task_success/cases.yaml"
DEFAULT_AGENT_SCRIPT="$REPO_ROOT/scripts/run_agent.sh"

usage() {
  cat <<'EOF_USAGE'
Usage: validate_task_success.sh [options]

Evaluate task-plan completeness for core tasks.

Options:
  --cases FILE          Task-success cases file. Default: <repo>/evals/task_success/cases.yaml
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
      min_steps = "1"
      min_outputs = "1"
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
        print case_id, query, task, min_steps, min_outputs
      }
    }
    /^[[:space:]]*-[[:space:]]id:[[:space:]]*/ {
      emit_case()
      case_id = $0
      sub(/^[[:space:]]*-[[:space:]]id:[[:space:]]*/, "", case_id)
      case_id = unquote(case_id)
      query = ""
      task = ""
      min_steps = "1"
      min_outputs = "1"
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
    /^[[:space:]]*min_runnable_steps:[[:space:]]*/ {
      min_steps = $0
      sub(/^[[:space:]]*min_runnable_steps:[[:space:]]*/, "", min_steps)
      min_steps = unquote(min_steps)
      next
    }
    /^[[:space:]]*min_expected_outputs:[[:space:]]*/ {
      min_outputs = $0
      sub(/^[[:space:]]*min_expected_outputs:[[:space:]]*/, "", min_outputs)
      min_outputs = unquote(min_outputs)
      next
    }
    END {
      emit_case()
    }
  ' "$file"
}

extract_decision() {
  local json="$1"
  printf '%s\n' "$json" | sed -n 's/.*"decision":"\([^"]*\)".*/\1/p'
}

extract_plan_scalar() {
  local json="$1"
  local field="$2"
  printf '%s\n' "$json" | sed -n "s/.*\"plan\":{.*\"$field\":\"\([^\"]*\)\".*/\1/p"
}

plan_has_array_field() {
  local json="$1"
  local field="$2"
  printf '%s\n' "$json" | grep -q "\"plan\":{.*\"$field\":\["
}

extract_plan_array_count() {
  local json="$1"
  local field="$2"
  local raw
  raw="$(printf '%s\n' "$json" | sed -n "s/.*\"plan\":{.*\"$field\":\[\([^]]*\)\].*/\1/p")"
  if [[ -z "$raw" ]]; then
    printf '0\n'
    return 0
  fi
  printf '%s\n' "$raw" | sed 's/^"//; s/"$//' | sed 's/","/\n/g' | awk 'NF{c++} END{print c+0}'
}

required_plan_arrays=(
  assumptions
  required_inputs
  missing_inputs
  constraints
  runnable_steps
  expected_outputs
  fallbacks
)

total=0
passed=0
failed=0

while IFS=$'\x1f' read -r case_id query task min_steps min_outputs; do
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

  if printf '%s\n' "$output" | grep -q '"plan":null'; then
    failed=$((failed + 1))
    echo "fail: $case_id" >&2
    echo "  expected non-null plan" >&2
    continue
  fi

  plan_task="$(extract_plan_scalar "$output" "task")"
  selected_skill="$(extract_plan_scalar "$output" "selected_skill")"
  retry_policy="$(extract_plan_scalar "$output" "retry_policy")"

  if [[ -n "$task" && "$plan_task" != "$task" ]]; then
    failed=$((failed + 1))
    echo "fail: $case_id" >&2
    echo "  expected plan.task: $task" >&2
    echo "  got plan.task: ${plan_task:-none}" >&2
    continue
  fi

  if [[ -z "$selected_skill" || -z "$retry_policy" ]]; then
    failed=$((failed + 1))
    echo "fail: $case_id" >&2
    echo "  plan.selected_skill or plan.retry_policy is empty" >&2
    continue
  fi

  missing_array_field=0
  for field in "${required_plan_arrays[@]}"; do
    if ! plan_has_array_field "$output" "$field"; then
      missing_array_field=1
      echo "fail: $case_id" >&2
      echo "  missing plan array field: $field" >&2
      break
    fi
  done
  if [[ "$missing_array_field" -eq 1 ]]; then
    failed=$((failed + 1))
    continue
  fi

  runnable_count="$(extract_plan_array_count "$output" "runnable_steps")"
  expected_count="$(extract_plan_array_count "$output" "expected_outputs")"

  if [[ "$runnable_count" -lt "$min_steps" ]]; then
    failed=$((failed + 1))
    echo "fail: $case_id" >&2
    echo "  runnable_steps too short: got=$runnable_count expected_min=$min_steps" >&2
    continue
  fi

  if [[ "$expected_count" -lt "$min_outputs" ]]; then
    failed=$((failed + 1))
    echo "fail: $case_id" >&2
    echo "  expected_outputs too short: got=$expected_count expected_min=$min_outputs" >&2
    continue
  fi

  passed=$((passed + 1))
  echo "pass: $case_id (task=$plan_task skill=$selected_skill steps=$runnable_count outputs=$expected_count)"
done < <(parse_cases "$cases_file")

echo "task-success eval summary: $passed/$total passed"
if [[ "$failed" -ne 0 ]]; then
  exit 1
fi
