#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_REGISTRY_FILE="$REPO_ROOT/registry/skills.yaml"
DEFAULT_TAGS_FILE="$REPO_ROOT/registry/tags.yaml"
DEFAULT_ROUTING_FILE="$REPO_ROOT/registry/routing.yaml"
DEFAULT_CONTRACTS_FILE="$REPO_ROOT/registry/task_contracts.yaml"
DEFAULT_OUTPUT_CONTRACTS_FILE="$REPO_ROOT/registry/output_contracts.yaml"
DEFAULT_RECOVERY_POLICIES_FILE="$REPO_ROOT/registry/recovery_policies.yaml"
DEFAULT_ROUTER_SCRIPT="$REPO_ROOT/scripts/route_query.sh"
source "$REPO_ROOT/scripts/lib_registry.sh"

usage() {
  cat <<'EOF_USAGE'
Usage: run_agent.sh [options]

Run the s2f agent orchestration for one query:
- route to a primary skill
- provide secondary candidates
- map to playbook (if available)
- report required inputs and missing fields

Options:
  --query TEXT           Query text to process. If omitted, read from stdin.
  --task TASK            Optional task hint.
  --top-k N              Number of total candidates to include. Default: 3
  --format FMT           Output format: text or json. Default: text
  --registry FILE        Skill registry file. Default: <repo>/registry/skills.yaml
  --tags FILE            Task tag registry file. Default: <repo>/registry/tags.yaml
  --routing-config FILE  Routing config for router. Default: <repo>/registry/routing.yaml
  --contracts FILE       Task contracts file. Default: <repo>/registry/task_contracts.yaml
  --output-contracts FILE Output contracts file. Default: <repo>/registry/output_contracts.yaml
  --recovery FILE        Recovery policy file. Default: <repo>/registry/recovery_policies.yaml
  --router FILE          Router script path. Default: <repo>/scripts/route_query.sh
  --include-disabled     Include disabled skills in routing candidates.
  -h, --help             Show this help message.
EOF_USAGE
}

to_lower() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

normalize_text() {
  printf '%s' "$1" | tr '\n' ' ' | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//'
}

contains_token() {
  local haystack="$1"
  local needle="$2"
  if [[ -z "$needle" ]]; then
    return 1
  fi
  [[ "$haystack" == *"$needle"* ]]
}

in_csv_list() {
  local value="${1:-}"
  local csv="${2:-}"
  if [[ -z "$value" || -z "$csv" ]]; then
    return 1
  fi
  local -a arr=()
  IFS=',' read -r -a arr <<<"$csv"
  if [[ ${#arr[@]} -eq 0 ]]; then
    return 1
  fi
  for item in "${arr[@]}"; do
    if [[ "$item" == "$value" ]]; then
      return 0
    fi
  done
  return 1
}

append_csv() {
  local csv="$1"
  local value="$2"
  if [[ -z "$value" ]]; then
    printf '%s\n' "$csv"
    return 0
  fi
  if in_csv_list "$value" "$csv"; then
    printf '%s\n' "$csv"
    return 0
  fi
  if [[ -z "$csv" ]]; then
    printf '%s\n' "$value"
  else
    printf '%s\n' "$csv,$value"
  fi
}

csv_to_lines_prefixed() {
  local csv="${1:-}"
  local prefix="${2:-- }"
  if [[ -z "$csv" ]]; then
    return 0
  fi
  local -a arr=()
  IFS=',' read -r -a arr <<<"$csv"
  for item in "${arr[@]}"; do
    [[ -z "$item" ]] && continue
    printf '%s%s\n' "$prefix" "$item"
  done
}

emit_json_array_from_csv() {
  local csv="${1:-}"
  local first=1
  local item
  printf '['
  while IFS= read -r item; do
    [[ -z "$item" ]] && continue
    if [[ "$first" -eq 0 ]]; then
      printf ','
    fi
    printf '"%s"' "$(json_escape "$item")"
    first=0
  done < <(printf '%s\n' "$csv" | tr ',' '\n')
  printf ']'
}

emit_text_plan_block() {
  local plan_task="$1"
  local selected_skill="$2"
  local assumptions_csv="$3"
  local required_csv="$4"
  local missing_csv="$5"
  local constraints_csv="$6"
  local steps_csv="$7"
  local outputs_csv="$8"
  local fallbacks_csv="$9"
  local retry_policy="${10:-none}"

  echo "plan:"
  echo "  task: $plan_task"
  echo "  selected_skill: $selected_skill"
  echo "  assumptions:"
  if [[ -n "$assumptions_csv" ]]; then
    csv_to_lines_prefixed "$assumptions_csv" "    - "
  else
    echo "    - none"
  fi
  echo "  required_inputs:"
  if [[ -n "$required_csv" ]]; then
    csv_to_lines_prefixed "$required_csv" "    - "
  else
    echo "    - none"
  fi
  echo "  missing_inputs:"
  if [[ -n "$missing_csv" ]]; then
    csv_to_lines_prefixed "$missing_csv" "    - "
  else
    echo "    - none"
  fi
  echo "  constraints:"
  if [[ -n "$constraints_csv" ]]; then
    csv_to_lines_prefixed "$constraints_csv" "    - "
  else
    echo "    - none"
  fi
  echo "  runnable_steps:"
  if [[ -n "$steps_csv" ]]; then
    csv_to_lines_prefixed "$steps_csv" "    - "
  else
    echo "    - none"
  fi
  echo "  expected_outputs:"
  if [[ -n "$outputs_csv" ]]; then
    csv_to_lines_prefixed "$outputs_csv" "    - "
  else
    echo "    - none"
  fi
  echo "  fallbacks:"
  if [[ -n "$fallbacks_csv" ]]; then
    csv_to_lines_prefixed "$fallbacks_csv" "    - "
  else
    echo "    - none"
  fi
  echo "  retry_policy: ${retry_policy:-none}"
}

emit_json_plan_object() {
  local plan_task="$1"
  local selected_skill="$2"
  local assumptions_csv="$3"
  local required_csv="$4"
  local missing_csv="$5"
  local constraints_csv="$6"
  local steps_csv="$7"
  local outputs_csv="$8"
  local fallbacks_csv="$9"
  local retry_policy="${10:-none}"

  printf '{'
  printf '"task":"%s",' "$(json_escape "$plan_task")"
  printf '"selected_skill":"%s",' "$(json_escape "$selected_skill")"
  printf '"assumptions":'
  emit_json_array_from_csv "$assumptions_csv"
  printf ','
  printf '"required_inputs":'
  emit_json_array_from_csv "$required_csv"
  printf ','
  printf '"missing_inputs":'
  emit_json_array_from_csv "$missing_csv"
  printf ','
  printf '"constraints":'
  emit_json_array_from_csv "$constraints_csv"
  printf ','
  printf '"runnable_steps":'
  emit_json_array_from_csv "$steps_csv"
  printf ','
  printf '"expected_outputs":'
  emit_json_array_from_csv "$outputs_csv"
  printf ','
  printf '"fallbacks":'
  emit_json_array_from_csv "$fallbacks_csv"
  printf ','
  printf '"retry_policy":"%s"' "$(json_escape "${retry_policy:-none}")"
  printf '}'
}

json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

extract_decision_from_json() {
  local json="$1"
  printf '%s\n' "$json" | sed -n 's/.*"decision":"\([^"]*\)".*/\1/p'
}

extract_task_from_json() {
  local json="$1"
  if printf '%s\n' "$json" | grep -q '"task":null'; then
    printf '\n'
    return 0
  fi
  printf '%s\n' "$json" | sed -n 's/.*"task":"\([^"]*\)".*/\1/p'
}

extract_task_source_from_json() {
  local json="$1"
  printf '%s\n' "$json" | sed -n 's/.*"task_source":"\([^"]*\)".*/\1/p'
}

extract_confidence_level_from_json() {
  local json="$1"
  printf '%s\n' "$json" | sed -n 's/.*"confidence":{"level":"\([^"]*\)","score":[0-9.]*}.*/\1/p'
}

extract_confidence_score_from_json() {
  local json="$1"
  printf '%s\n' "$json" | sed -n 's/.*"confidence":{"level":"[^"]*","score":\([0-9.]*\)}.*/\1/p'
}

extract_clarify_question_from_json() {
  local json="$1"
  if printf '%s\n' "$json" | grep -q '"clarify_question":null'; then
    printf '\n'
    return 0
  fi
  printf '%s\n' "$json" | sed -n 's/.*"clarify_question":"\([^"]*\)".*/\1/p' | sed 's/\\"/"/g'
}

extract_primary_skill_from_json() {
  local json="$1"
  printf '%s\n' "$json" | sed -n 's/.*"primary":{"skill":"\([^"]*\)".*/\1/p'
}

extract_secondary_csv_from_json() {
  local json="$1"
  local csv=""
  local first=1
  local skill
  while IFS= read -r skill; do
    [[ -z "$skill" ]] && continue
    if [[ "$first" -eq 1 ]]; then
      first=0
      continue
    fi
    csv="$(append_csv "$csv" "$skill")"
  done < <(printf '%s\n' "$json" | grep -o '"skill":"[^"]*"' | sed 's/"skill":"//; s/"$//')
  printf '%s\n' "$csv"
}

render_plan_value() {
  local raw="$1"
  local plan_task="$2"
  local selected_skill="$3"
  local rendered="$raw"
  rendered="${rendered//\{task\}/$plan_task}"
  rendered="${rendered//\{selected_skill\}/$selected_skill}"
  printf '%s\n' "$rendered"
}

input_satisfied() {
  local input_name="$1"
  local query_lc="$2"
  local raw="$input_name"
  local phrase
  local token_hits=0
  local token_need=0

  phrase="$(to_lower "$raw")"
  phrase="${phrase//-/ }"
  phrase="${phrase//_/ }"

  if contains_token "$query_lc" "$phrase"; then
    return 0
  fi

  case "$raw" in
    sequence|sequence-or-interval)
      contains_token "$query_lc" "sequence" || contains_token "$query_lc" "interval" || contains_token "$query_lc" "fasta" || contains_token "$query_lc" "chr"
      return
      ;;
    embedding-target)
      contains_token "$query_lc" "embedding" || contains_token "$query_lc" "token" || contains_token "$query_lc" "pooled" || contains_token "$query_lc" "representation"
      return
      ;;
    assembly)
      contains_token "$query_lc" "assembly" || contains_token "$query_lc" "hg38" || contains_token "$query_lc" "hg19" || contains_token "$query_lc" "mm10" || contains_token "$query_lc" "chm13"
      return
      ;;
    chrom|chromosome)
      contains_token "$query_lc" "chr"
      return
      ;;
    coordinate-or-interval|interval-or-variant)
      contains_token "$query_lc" "position" || contains_token "$query_lc" "variant" || contains_token "$query_lc" "interval" || contains_token "$query_lc" "chr"
      return
      ;;
    ref-alt-or-variant-spec)
      contains_token "$query_lc" "ref" || contains_token "$query_lc" "alt" || contains_token "$query_lc" "a>" || contains_token "$query_lc" "g>" || contains_token "$query_lc" "variant"
      return
      ;;
    hardware-context)
      contains_token "$query_lc" "gpu" || contains_token "$query_lc" "cuda" || contains_token "$query_lc" "nvidia" || contains_token "$query_lc" "h100" || contains_token "$query_lc" "cpu" || contains_token "$query_lc" "mac"
      return
      ;;
    execution-path)
      contains_token "$query_lc" "local" || contains_token "$query_lc" "hosted" || contains_token "$query_lc" "api" || contains_token "$query_lc" "nim" || contains_token "$query_lc" "docker"
      return
      ;;
    runtime-context)
      contains_token "$query_lc" "linux" || contains_token "$query_lc" "mac" || contains_token "$query_lc" "wsl" || contains_token "$query_lc" "windows" || contains_token "$query_lc" "docker" || contains_token "$query_lc" "conda"
      return
      ;;
    target-stack-or-model-family)
      contains_token "$query_lc" "stack" || contains_token "$query_lc" "model" || contains_token "$query_lc" "family" || contains_token "$query_lc" "ntv3" || contains_token "$query_lc" "evo2" || contains_token "$query_lc" "gpn" || contains_token "$query_lc" "alphagenome"
      return
      ;;
    task-objective|objective|model-family-objective)
      contains_token "$query_lc" "classification" || contains_token "$query_lc" "regression" || contains_token "$query_lc" "objective" || contains_token "$query_lc" "variant" || contains_token "$query_lc" "embedding" || contains_token "$query_lc" "prediction"
      return
      ;;
    dataset-schema)
      contains_token "$query_lc" "csv" || contains_token "$query_lc" "schema" || contains_token "$query_lc" "columns" || contains_token "$query_lc" "label" || contains_token "$query_lc" "fasta"
      return
      ;;
    compute-constraints)
      contains_token "$query_lc" "gpu" || contains_token "$query_lc" "memory" || contains_token "$query_lc" "runtime" || contains_token "$query_lc" "budget" || contains_token "$query_lc" "batch"
      return
      ;;
    failing-step-or-error)
      contains_token "$query_lc" "error" || contains_token "$query_lc" "fail" || contains_token "$query_lc" "issue" || contains_token "$query_lc" "traceback" || contains_token "$query_lc" "loading" || contains_token "$query_lc" "cannot"
      return
      ;;
    output-head)
      contains_token "$query_lc" "head" || contains_token "$query_lc" "track" || contains_token "$query_lc" "output"
      return
      ;;
    species)
      contains_token "$query_lc" "human" || contains_token "$query_lc" "mouse" || contains_token "$query_lc" "species"
      return
      ;;
  esac

  for token in $phrase; do
    [[ ${#token} -lt 4 ]] && continue
    token_need=$((token_need + 1))
    if contains_token "$query_lc" "$token"; then
      token_hits=$((token_hits + 1))
    fi
  done

  if [[ "$token_need" -eq 0 ]]; then
    return 1
  fi
  if [[ "$token_hits" -ge "$token_need" ]]; then
    return 0
  fi
  return 1
}

query=""
task=""
top_k=3
format="text"
registry_file="$DEFAULT_REGISTRY_FILE"
tags_file="$DEFAULT_TAGS_FILE"
routing_file="$DEFAULT_ROUTING_FILE"
contracts_file="$DEFAULT_CONTRACTS_FILE"
output_contracts_file="$DEFAULT_OUTPUT_CONTRACTS_FILE"
recovery_policies_file="$DEFAULT_RECOVERY_POLICIES_FILE"
router_script="$DEFAULT_ROUTER_SCRIPT"
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
    --top-k)
      top_k="$2"
      shift 2
      ;;
    --format)
      format="$2"
      shift 2
      ;;
    --registry)
      registry_file="$2"
      shift 2
      ;;
    --tags)
      tags_file="$2"
      shift 2
      ;;
    --routing-config)
      routing_file="$2"
      shift 2
      ;;
    --contracts)
      contracts_file="$2"
      shift 2
      ;;
    --output-contracts)
      output_contracts_file="$2"
      shift 2
      ;;
    --recovery)
      recovery_policies_file="$2"
      shift 2
      ;;
    --router)
      router_script="$2"
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

if [[ ! "$top_k" =~ ^[1-9][0-9]*$ ]]; then
  echo "error: --top-k must be a positive integer." >&2
  exit 1
fi

if [[ "$format" != "text" && "$format" != "json" ]]; then
  echo "error: --format must be 'text' or 'json'." >&2
  exit 1
fi

registry_require_file "$registry_file"
registry_require_file "$tags_file"
registry_require_file "$routing_file"
registry_require_file "$contracts_file"
registry_require_file "$output_contracts_file"
registry_require_file "$recovery_policies_file"
if [[ ! -f "$router_script" ]]; then
  echo "error: router script not found: $router_script" >&2
  exit 1
fi

router_json=""
router_cmd=(bash "$router_script" --registry "$registry_file" --tags "$tags_file" --routing-config "$routing_file" --query "$query" --top-k "$top_k" --format json)
if [[ -n "$task" ]]; then
  router_cmd+=(--task "$task")
fi
if [[ "$include_disabled" -eq 1 ]]; then
  router_cmd+=(--include-disabled)
fi

if ! router_json="$("${router_cmd[@]}" 2>&1)"; then
  echo "error: routing failed: $router_json" >&2
  exit 1
fi

decision="$(extract_decision_from_json "$router_json")"
effective_task="$(extract_task_from_json "$router_json")"
task_source="$(extract_task_source_from_json "$router_json")"
confidence_level="$(extract_confidence_level_from_json "$router_json")"
confidence_score="$(extract_confidence_score_from_json "$router_json")"
clarify_question="$(extract_clarify_question_from_json "$router_json")"

if [[ -z "$decision" ]]; then
  echo "error: failed to parse routing decision from router output: $router_json" >&2
  exit 1
fi

if [[ "$decision" == "clarify" ]]; then
  if [[ "$format" == "text" ]]; then
    echo "query: $query"
    if [[ -n "$effective_task" ]]; then
      echo "task: $effective_task ($task_source)"
    else
      echo "task: none ($task_source)"
    fi
    echo "decision: clarify"
    echo "confidence: ${confidence_level:-unknown} (${confidence_score:-0})"
    echo "clarify_question: ${clarify_question:-Please specify task or preferred skill.}"
    echo "plan: none"
    exit 0
  fi

  printf '{'
  printf '"query":"%s",' "$(json_escape "$query")"
  if [[ -n "$effective_task" ]]; then
    printf '"task":"%s",' "$(json_escape "$effective_task")"
  else
    printf '"task":null,'
  fi
  printf '"task_source":"%s",' "$(json_escape "$task_source")"
  printf '"decision":"clarify",'
  printf '"confidence":{'
  printf '"level":"%s",' "$(json_escape "$confidence_level")"
  printf '"score":%s' "${confidence_score:-0}"
  printf '},'
  if [[ -n "$clarify_question" ]]; then
    printf '"clarify_question":"%s",' "$(json_escape "$clarify_question")"
  else
    printf '"clarify_question":"%s",' "Please specify task or preferred skill."
  fi
  printf '"playbook":null,'
  printf '"primary_skill":null,'
  printf '"primary_skill_path":null,'
  printf '"skill_doc":null,'
  printf '"skill_metadata":null,'
  printf '"secondary_skills":[],'
  printf '"required_inputs":[],'
  printf '"required_inputs_source":null,'
  printf '"provided_inputs":[],'
  printf '"missing_inputs":[],'
  printf '"constraints":[],'
  printf '"tools":[],'
  printf '"plan":null,'
  printf '"next_prompt":"%s"' "$(json_escape "Ask one focused clarification question before selecting a skill.")"
  printf '}\n'
  exit 0
fi

primary_skill="$(extract_primary_skill_from_json "$router_json")"
secondary_csv="$(extract_secondary_csv_from_json "$router_json")"

if [[ -z "$primary_skill" ]]; then
  echo "error: failed to resolve primary skill from router output: $router_json" >&2
  exit 1
fi

skill_path="$(registry_get_path "$registry_file" "$primary_skill" || true)"
if [[ -z "$skill_path" ]]; then
  skill_path="$primary_skill"
fi
skill_root="$REPO_ROOT/$skill_path"
skill_meta="$skill_root/skill.yaml"
skill_doc="$skill_root/SKILL.md"

skill_required_csv=""
required_csv=""
required_inputs_source="skill"
constraints_csv=""
tools_csv=""

while IFS= read -r v; do
  [[ -n "$v" ]] && skill_required_csv="$(append_csv "$skill_required_csv" "$v")"
done < <(yaml_get_list_field "$skill_meta" "required_inputs")

required_csv="$skill_required_csv"
if [[ -n "$effective_task" ]]; then
  task_required_csv=""
  while IFS= read -r v; do
    [[ -n "$v" ]] && task_required_csv="$(append_csv "$task_required_csv" "$v")"
  done < <(task_contract_list_required_inputs "$contracts_file" "$effective_task")

  if [[ -n "$task_required_csv" ]]; then
    required_csv="$task_required_csv"
    required_inputs_source="task-contract:$effective_task"
  else
    required_inputs_source="skill:$primary_skill"
  fi
else
  required_inputs_source="skill:$primary_skill"
fi

while IFS= read -r v; do
  [[ -n "$v" ]] && constraints_csv="$(append_csv "$constraints_csv" "$v")"
done < <(yaml_get_list_field "$skill_meta" "constraints")

while IFS= read -r v; do
  [[ -n "$v" ]] && tools_csv="$(append_csv "$tools_csv" "$v")"
done < <(yaml_get_list_field "$skill_meta" "tools")

plan_assumptions_csv=""
plan_steps_csv=""
plan_expected_outputs_csv=""
plan_fallbacks_csv=""
plan_retry_policy=""

if [[ -n "$effective_task" ]]; then
  while IFS= read -r v; do
    [[ -z "$v" ]] && continue
    rendered="$(render_plan_value "$v" "$effective_task" "$primary_skill")"
    plan_assumptions_csv="$(append_csv "$plan_assumptions_csv" "$rendered")"
  done < <(output_contract_list_field "$output_contracts_file" "$effective_task" "assumptions")

  while IFS= read -r v; do
    [[ -z "$v" ]] && continue
    rendered="$(render_plan_value "$v" "$effective_task" "$primary_skill")"
    plan_steps_csv="$(append_csv "$plan_steps_csv" "$rendered")"
  done < <(output_contract_list_field "$output_contracts_file" "$effective_task" "runnable_steps")

  while IFS= read -r v; do
    [[ -z "$v" ]] && continue
    rendered="$(render_plan_value "$v" "$effective_task" "$primary_skill")"
    plan_expected_outputs_csv="$(append_csv "$plan_expected_outputs_csv" "$rendered")"
  done < <(output_contract_list_field "$output_contracts_file" "$effective_task" "expected_outputs")

  while IFS= read -r v; do
    [[ -z "$v" ]] && continue
    rendered="$(render_plan_value "$v" "$effective_task" "$primary_skill")"
    plan_fallbacks_csv="$(append_csv "$plan_fallbacks_csv" "$rendered")"
  done < <(output_contract_list_field "$output_contracts_file" "$effective_task" "fallbacks")

  while IFS= read -r sid; do
    [[ -z "$sid" ]] && continue
    if [[ "$sid" == "$primary_skill" ]]; then
      continue
    fi
    plan_fallbacks_csv="$(append_csv "$plan_fallbacks_csv" "$sid")"
  done < <(recovery_policy_list_fallback_skills "$recovery_policies_file" "$effective_task")

  plan_retry_policy="$(recovery_policy_get_retry_policy "$recovery_policies_file" "$effective_task" || true)"
  if [[ -z "$plan_retry_policy" ]]; then
    plan_retry_policy="$(output_contract_get_scalar "$output_contracts_file" "$effective_task" "retry_policy" || true)"
  fi
fi

if [[ -z "$plan_retry_policy" ]]; then
  plan_retry_policy="single-pass-no-retry"
fi

query_lc="$(to_lower "$query")"
provided_csv=""
missing_csv=""
for req in $(printf '%s\n' "$required_csv" | tr ',' ' '); do
  [[ -z "$req" ]] && continue
  if input_satisfied "$req" "$query_lc"; then
    provided_csv="$(append_csv "$provided_csv" "$req")"
  else
    missing_csv="$(append_csv "$missing_csv" "$req")"
  fi
done

if [[ -n "$missing_csv" ]]; then
  while IFS= read -r req; do
    [[ -z "$req" ]] && continue
    plan_assumptions_csv="$(append_csv "$plan_assumptions_csv" "missing-input-needs-clarification:$req")"
  done < <(printf '%s\n' "$missing_csv" | tr ',' '\n')
fi

if [[ -z "$plan_assumptions_csv" ]]; then
  plan_assumptions_csv="follow-task-contract-and-skill-constraints"
fi

if [[ -z "$plan_steps_csv" ]]; then
  if [[ -n "$effective_task" ]]; then
    plan_steps_csv="bash scripts/run_agent.sh --task $effective_task --query follow-up-required --format json"
  else
    plan_steps_csv="bash scripts/run_agent.sh --query follow-up-required --format json"
  fi
fi

if [[ -z "$plan_expected_outputs_csv" ]]; then
  plan_expected_outputs_csv="structured-agent-plan-json"
fi

playbook_path=""
if [[ -n "$effective_task" && -f "$REPO_ROOT/playbooks/$effective_task/README.md" ]]; then
  playbook_path="playbooks/$effective_task/README.md"
fi

next_prompt="Use \$$primary_skill to handle this request"
if [[ -n "$effective_task" ]]; then
  next_prompt="$next_prompt for task '$effective_task'"
fi
if [[ -n "$missing_csv" ]]; then
  next_prompt="$next_prompt. Ask for missing inputs: $missing_csv."
fi

if [[ "$format" == "text" ]]; then
  echo "query: $query"
  if [[ -n "$effective_task" ]]; then
    echo "task: $effective_task ($task_source)"
  else
    echo "task: none ($task_source)"
  fi
  echo "decision: route"
  echo "confidence: ${confidence_level:-unknown} (${confidence_score:-0})"
  echo "primary_skill: $primary_skill"
  echo "primary_skill_path: $skill_path"
  echo "skill_doc: $skill_path/SKILL.md"
  echo "skill_metadata: $skill_path/skill.yaml"
  if [[ -n "$playbook_path" ]]; then
    echo "playbook: $playbook_path"
  else
    echo "playbook: none"
  fi

  if [[ -n "$secondary_csv" ]]; then
    echo "secondary_skills:"
    csv_to_lines_prefixed "$secondary_csv" "- "
  else
    echo "secondary_skills: none"
  fi

  if [[ -n "$required_csv" ]]; then
    echo "required_inputs_source: $required_inputs_source"
    echo "required_inputs:"
    csv_to_lines_prefixed "$required_csv" "- "
  else
    echo "required_inputs_source: none"
    echo "required_inputs: none"
  fi

  if [[ -n "$provided_csv" ]]; then
    echo "provided_inputs:"
    csv_to_lines_prefixed "$provided_csv" "- "
  else
    echo "provided_inputs: none"
  fi

  if [[ -n "$missing_csv" ]]; then
    echo "missing_inputs:"
    csv_to_lines_prefixed "$missing_csv" "- "
  else
    echo "missing_inputs: none"
  fi

  if [[ -n "$constraints_csv" ]]; then
    echo "constraints:"
    csv_to_lines_prefixed "$constraints_csv" "- "
  else
    echo "constraints: none"
  fi

  if [[ -n "$tools_csv" ]]; then
    echo "tools:"
    csv_to_lines_prefixed "$tools_csv" "- "
  else
    echo "tools: none"
  fi

  emit_text_plan_block \
    "${effective_task:-none}" \
    "$primary_skill" \
    "$plan_assumptions_csv" \
    "$required_csv" \
    "$missing_csv" \
    "$constraints_csv" \
    "$plan_steps_csv" \
    "$plan_expected_outputs_csv" \
    "$plan_fallbacks_csv" \
    "$plan_retry_policy"

  echo "next_prompt: $next_prompt"
  exit 0
fi

printf '{'
printf '"query":"%s",' "$(json_escape "$query")"
if [[ -n "$effective_task" ]]; then
  printf '"task":"%s",' "$(json_escape "$effective_task")"
else
  printf '"task":null,'
fi
printf '"task_source":"%s",' "$(json_escape "$task_source")"
printf '"decision":"route",'
printf '"confidence":{'
printf '"level":"%s",' "$(json_escape "$confidence_level")"
printf '"score":%s' "${confidence_score:-0}"
printf '},'
printf '"clarify_question":null,'
printf '"primary_skill":"%s",' "$(json_escape "$primary_skill")"
printf '"primary_skill_path":"%s",' "$(json_escape "$skill_path")"
printf '"skill_doc":"%s",' "$(json_escape "$skill_doc")"
printf '"skill_metadata":"%s",' "$(json_escape "$skill_meta")"
if [[ -n "$playbook_path" ]]; then
  printf '"playbook":"%s",' "$(json_escape "$playbook_path")"
else
  printf '"playbook":null,'
fi
printf '"secondary_skills":'
emit_json_array_from_csv "${secondary_csv:-}"
printf ','
printf '"required_inputs":'
emit_json_array_from_csv "${required_csv:-}"
printf ','
printf '"required_inputs_source":"%s",' "$(json_escape "$required_inputs_source")"
printf '"provided_inputs":'
emit_json_array_from_csv "${provided_csv:-}"
printf ','
printf '"missing_inputs":'
emit_json_array_from_csv "${missing_csv:-}"
printf ','
printf '"constraints":'
emit_json_array_from_csv "${constraints_csv:-}"
printf ','
printf '"tools":'
emit_json_array_from_csv "${tools_csv:-}"
printf ','
printf '"plan":'
emit_json_plan_object \
  "${effective_task:-none}" \
  "$primary_skill" \
  "$plan_assumptions_csv" \
  "$required_csv" \
  "$missing_csv" \
  "$constraints_csv" \
  "$plan_steps_csv" \
  "$plan_expected_outputs_csv" \
  "$plan_fallbacks_csv" \
  "$plan_retry_policy"
printf ','
printf '"next_prompt":"%s"' "$(json_escape "$next_prompt")"
printf '}\n'
