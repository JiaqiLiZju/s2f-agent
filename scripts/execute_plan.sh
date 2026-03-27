#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_RUN_AGENT_SCRIPT="$REPO_ROOT/scripts/run_agent.sh"

usage() {
  cat <<'EOF_USAGE'
Usage: execute_plan.sh [options]

Build and execute an s2f agent plan.

By default this command runs in dry-run mode and only prints what would execute.

Options:
  --query TEXT          Query to plan/execute. If omitted, read from stdin.
  --task TASK           Optional task hint.
  --run                 Execute runnable steps.
  --dry-run             Dry-run mode (default).
  --format FMT          Output format: text or json. Default: text
  --agent FILE          Path to run_agent.sh. Default: <repo>/scripts/run_agent.sh
  --include-disabled    Include disabled skills in upstream routing.
  -h, --help            Show this help message.
EOF_USAGE
}

json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

normalize_text() {
  printf '%s' "$1" | tr '\n' ' ' | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//'
}

extract_decision() {
  local json="$1"
  printf '%s\n' "$json" | sed -n 's/.*"decision":"\([^"]*\)".*/\1/p'
}

extract_clarify_question() {
  local json="$1"
  if printf '%s\n' "$json" | grep -q '"clarify_question":null'; then
    printf '\n'
    return 0
  fi
  printf '%s\n' "$json" | sed -n 's/.*"clarify_question":"\([^"]*\)".*/\1/p' | sed 's/\\"/"/g'
}

extract_plan_scalar() {
  local json="$1"
  local field="$2"
  printf '%s\n' "$json" | sed -n "s/.*\"plan\":{.*\"$field\":\"\([^\"]*\)\".*/\1/p" | sed 's/\\"/"/g'
}

extract_plan_array_csv() {
  local json="$1"
  local field="$2"
  local raw
  raw="$(printf '%s\n' "$json" | sed -n "s/.*\"plan\":{.*\"$field\":\[\([^]]*\)\].*/\1/p")"
  if [[ -z "$raw" ]]; then
    printf '\n'
    return 0
  fi
  printf '%s\n' "$raw" | sed 's/^"//; s/"$//' | sed 's/","/\n/g' | sed 's/\\"/"/g' | paste -sd ',' -
}

csv_to_lines() {
  local csv="${1:-}"
  if [[ -z "$csv" ]]; then
    return 0
  fi
  printf '%s\n' "$csv" | tr ',' '\n'
}

query=""
task=""
dry_run=1
format="text"
agent_script="$DEFAULT_RUN_AGENT_SCRIPT"
include_disabled=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --query)
      query="$2"
      shift 2
      ;;
    --task)
      task="$2"
      shift 2
      ;;
    --run)
      dry_run=0
      shift
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    --format)
      format="$2"
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

if [[ -z "$query" && ! -t 0 ]]; then
  query="$(cat)"
fi
query="$(normalize_text "$query")"

if [[ -z "$query" ]]; then
  echo "error: query is required (use --query or stdin)." >&2
  exit 1
fi

if [[ "$format" != "text" && "$format" != "json" ]]; then
  echo "error: --format must be 'text' or 'json'." >&2
  exit 1
fi

if [[ ! -f "$agent_script" ]]; then
  echo "error: run_agent script not found: $agent_script" >&2
  exit 1
fi

agent_cmd=(bash "$agent_script" --query "$query" --format json)
if [[ -n "$task" ]]; then
  agent_cmd+=(--task "$task")
fi
if [[ "$include_disabled" -eq 1 ]]; then
  agent_cmd+=(--include-disabled)
fi

agent_json=""
if ! agent_json="$("${agent_cmd[@]}" 2>&1)"; then
  echo "error: run_agent failed: $agent_json" >&2
  exit 1
fi

decision="$(extract_decision "$agent_json")"
if [[ "$decision" == "clarify" ]]; then
  question="$(extract_clarify_question "$agent_json")"
  if [[ "$format" == "text" ]]; then
    echo "decision: clarify"
    echo "clarify_question: ${question:-Please clarify task and inputs.}"
  else
    printf '{"decision":"clarify","clarify_question":"%s"}\n' "$(json_escape "${question:-Please clarify task and inputs.}")"
  fi
  exit 2
fi

plan_task="$(extract_plan_scalar "$agent_json" "task")"
selected_skill="$(extract_plan_scalar "$agent_json" "selected_skill")"
retry_policy="$(extract_plan_scalar "$agent_json" "retry_policy")"
steps_csv="$(extract_plan_array_csv "$agent_json" "runnable_steps")"
outputs_csv="$(extract_plan_array_csv "$agent_json" "expected_outputs")"
fallbacks_csv="$(extract_plan_array_csv "$agent_json" "fallbacks")"

if [[ -z "$steps_csv" ]]; then
  echo "error: plan has no runnable steps" >&2
  exit 1
fi

executed=0
failed=0
verified=0
verify_failed=0

if [[ "$format" == "text" ]]; then
  echo "task: ${plan_task:-unknown}"
  echo "selected_skill: ${selected_skill:-unknown}"
  echo "retry_policy: ${retry_policy:-none}"
fi

while IFS= read -r step; do
  [[ -z "$step" ]] && continue
  if [[ "$dry_run" -eq 1 ]]; then
    if [[ "$format" == "text" ]]; then
      echo "dry-run step: $step"
    fi
    continue
  fi

  if [[ "$format" == "text" ]]; then
    echo "run step: $step"
  fi
  if bash -lc "$step"; then
    executed=$((executed + 1))
  else
    failed=$((failed + 1))
    if [[ "$format" == "text" ]]; then
      echo "step failed: $step" >&2
    fi
  fi
done < <(csv_to_lines "$steps_csv")

while IFS= read -r item; do
  [[ -z "$item" ]] && continue
  case "$item" in
    expected-file:*|expected-plot:*)
      path_hint="${item#*:}"
      check_a="$REPO_ROOT/$path_hint"
      check_b="$REPO_ROOT/output/$path_hint"
      if [[ "$dry_run" -eq 1 ]]; then
        if [[ "$format" == "text" ]]; then
          echo "dry-run verify: $item"
        fi
        continue
      fi
      if [[ -e "$path_hint" || -e "$check_a" || -e "$check_b" ]]; then
        verified=$((verified + 1))
      else
        verify_failed=$((verify_failed + 1))
        if [[ "$format" == "text" ]]; then
          echo "verify failed: $item" >&2
        fi
      fi
      ;;
    *)
      if [[ "$format" == "text" ]]; then
        echo "note output contract: $item"
      fi
      ;;
  esac
done < <(csv_to_lines "$outputs_csv")

if [[ "$format" == "text" ]]; then
  echo "fallbacks: ${fallbacks_csv:-none}"
  echo "summary: dry_run=$dry_run executed=$executed failed=$failed verified=$verified verify_failed=$verify_failed"
else
  printf '{'
  printf '"decision":"route",'
  printf '"dry_run":%s,' "$([[ "$dry_run" -eq 1 ]] && echo true || echo false)"
  printf '"task":"%s",' "$(json_escape "${plan_task:-unknown}")"
  printf '"selected_skill":"%s",' "$(json_escape "${selected_skill:-unknown}")"
  printf '"retry_policy":"%s",' "$(json_escape "${retry_policy:-none}")"
  printf '"runnable_steps":"%s",' "$(json_escape "$steps_csv")"
  printf '"expected_outputs":"%s",' "$(json_escape "$outputs_csv")"
  printf '"fallbacks":"%s",' "$(json_escape "${fallbacks_csv:-}")"
  printf '"executed":%s,' "$executed"
  printf '"failed":%s,' "$failed"
  printf '"verified":%s,' "$verified"
  printf '"verify_failed":%s' "$verify_failed"
  printf '}\n'
fi

if [[ "$failed" -ne 0 || "$verify_failed" -ne 0 ]]; then
  exit 1
fi
