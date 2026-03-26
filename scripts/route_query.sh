#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_REGISTRY_FILE="$REPO_ROOT/registry/skills.yaml"
DEFAULT_TAGS_FILE="$REPO_ROOT/registry/tags.yaml"
source "$REPO_ROOT/scripts/lib_registry.sh"

usage() {
  cat <<'EOF'
Usage: route_query.sh [options]

Route a user query to a primary skill and secondary candidates using registry metadata.

Options:
  --query TEXT       Query text to route. If omitted, read from stdin.
  --task TASK        Optional task hint (for example: embedding, variant-effect).
  --top-k N          Number of total candidates to return (including primary). Default: 3
  --format FMT       Output format: text or json. Default: text
  --registry FILE    Skill registry file. Default: <repo>/registry/skills.yaml
  --tags FILE        Task tag registry file. Default: <repo>/registry/tags.yaml
  -h, --help         Show this help message.
EOF
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

append_unique_csv() {
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

csv_count() {
  local csv="${1:-}"
  if [[ -z "$csv" ]]; then
    printf '0\n'
    return 0
  fi
  awk -F',' '{print NF}' <<<"$csv"
}

append_reason() {
  local current="${1:-}"
  local msg="${2:-}"
  if [[ -z "$msg" ]]; then
    printf '%s\n' "$current"
    return 0
  fi
  if [[ -z "$current" ]]; then
    printf '%s\n' "$msg"
  else
    printf '%s\n' "$current|$msg"
  fi
}

skill_has_task() {
  local skill_id="$1"
  local task_name="$2"
  while IFS= read -r task_item; do
    if [[ "$task_item" == "$task_name" ]]; then
      return 0
    fi
  done < <(registry_get_list_field "$registry_file" "$skill_id" "tasks")
  return 1
}

matched_triggers_csv() {
  local skill_id="$1"
  local query_lc="$2"
  local csv=""
  while IFS= read -r trigger; do
    [[ -z "$trigger" ]] && continue
    trigger_lc="$(to_lower "$trigger")"
    if contains_token "$query_lc" "$trigger_lc"; then
      csv="$(append_unique_csv "$csv" "$trigger")"
    fi
  done < <(registry_get_list_field "$registry_file" "$skill_id" "triggers")
  printf '%s\n' "$csv"
}

score_skill_for_query() {
  local skill_id="$1"
  local query_lc="$2"
  local task_name="${3:-}"
  local score=0
  local skill_lc
  skill_lc="$(to_lower "$skill_id")"

  if contains_token "$query_lc" "\$$skill_lc"; then
    score=$((score + 120))
  fi
  if contains_token "$query_lc" "$skill_lc"; then
    score=$((score + 80))
  fi

  while IFS= read -r trigger; do
    [[ -z "$trigger" ]] && continue
    trigger_lc="$(to_lower "$trigger")"
    if contains_token "$query_lc" "$trigger_lc"; then
      score=$((score + 25))
    fi
  done < <(registry_get_list_field "$registry_file" "$skill_id" "triggers")

  if [[ -n "$task_name" ]] && skill_has_task "$skill_id" "$task_name"; then
    score=$((score + 20))
  fi

  printf '%s\n' "$score"
}

infer_task() {
  local query_lc="$1"
  local best_task=""
  local best_score=0

  while IFS= read -r candidate_task; do
    [[ -z "$candidate_task" ]] && continue
    local score=0
    local candidate_lc
    local phrase
    local term_count
    candidate_lc="$(to_lower "$candidate_task")"
    phrase="${candidate_lc//-/ }"
    phrase="${phrase//_/ }"
    term_count="$(awk '{print NF}' <<<"$phrase")"

    if contains_token "$query_lc" "$phrase"; then
      score=$((score + 60 + (term_count - 1) * 12))
    elif contains_token "$query_lc" "$candidate_lc"; then
      score=$((score + 35))
    fi

    for token in $phrase; do
      if [[ ${#token} -ge 4 ]] && contains_token "$query_lc" "$token"; then
        score=$((score + 8))
      fi
    done

    while IFS= read -r sid; do
      [[ -z "$sid" ]] && continue
      sid_lc="$(to_lower "$sid")"
      if contains_token "$query_lc" "$sid_lc"; then
        score=$((score + 6))
      fi

      local trigger_hits=0
      while IFS= read -r trigger; do
        [[ -z "$trigger" ]] && continue
        trigger_lc="$(to_lower "$trigger")"
        if contains_token "$query_lc" "$trigger_lc"; then
          score=$((score + 4))
          trigger_hits=$((trigger_hits + 1))
          if [[ "$trigger_hits" -ge 3 ]]; then
            break
          fi
        fi
      done < <(registry_get_list_field "$registry_file" "$sid" "triggers")
    done < <(tag_registry_list_for_task "$tags_file" "$candidate_task")

    if [[ "$score" -gt "$best_score" ]]; then
      best_score="$score"
      best_task="$candidate_task"
    elif [[ "$score" -eq "$best_score" && -n "$candidate_task" && ( -z "$best_task" || "$candidate_task" < "$best_task" ) ]]; then
      best_task="$candidate_task"
    fi
  done < <(tag_registry_list_tasks "$tags_file")

  if [[ "$best_score" -gt 0 ]]; then
    printf '%s\n' "$best_task"
  fi
}

build_reasons_pipe() {
  local skill_id="$1"
  local score="$2"
  local query_lc="$3"
  local task_name="$4"
  local from_tag_fallback="$5"
  local reasons=""
  local skill_lc
  local trigger_csv

  skill_lc="$(to_lower "$skill_id")"

  if contains_token "$query_lc" "\$$skill_lc"; then
    reasons="$(append_reason "$reasons" "explicit skill mention: \$$skill_lc")"
  fi
  if contains_token "$query_lc" "$skill_lc"; then
    reasons="$(append_reason "$reasons" "query mentions skill id")"
  fi

  trigger_csv="$(matched_triggers_csv "$skill_id" "$query_lc")"
  if [[ -n "$trigger_csv" ]]; then
    reasons="$(append_reason "$reasons" "matched triggers: $trigger_csv")"
  fi

  if [[ -n "$task_name" ]] && skill_has_task "$skill_id" "$task_name"; then
    reasons="$(append_reason "$reasons" "task alignment: $task_name")"
  fi

  if [[ "$from_tag_fallback" -eq 1 ]]; then
    reasons="$(append_reason "$reasons" "task-tag fallback candidate: $task_name")"
  fi

  if [[ -z "$reasons" ]]; then
    reasons="heuristic score: $score"
  fi

  printf '%s\n' "$reasons"
}

print_reasons_text() {
  local reasons_pipe="${1:-}"
  if [[ -z "$reasons_pipe" ]]; then
    echo "- heuristic rank"
    return 0
  fi
  local -a arr=()
  IFS='|' read -r -a arr <<<"$reasons_pipe"
  for reason in "${arr[@]}"; do
    [[ -z "$reason" ]] && continue
    echo "- $reason"
  done
}

json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

print_reasons_json() {
  local reasons_pipe="${1:-}"
  local -a arr=()
  local first=1
  if [[ -z "$reasons_pipe" ]]; then
    printf '[]'
    return 0
  fi
  IFS='|' read -r -a arr <<<"$reasons_pipe"
  printf '['
  for reason in "${arr[@]}"; do
    [[ -z "$reason" ]] && continue
    escaped="$(json_escape "$reason")"
    if [[ "$first" -eq 0 ]]; then
      printf ','
    fi
    printf '"%s"' "$escaped"
    first=0
  done
  printf ']'
}

query=""
task=""
top_k=3
format="text"
registry_file="$DEFAULT_REGISTRY_FILE"
tags_file="$DEFAULT_TAGS_FILE"

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

query_lc="$(to_lower "$query")"

effective_task=""
task_source="none"
if [[ -n "$task" ]]; then
  effective_task="$task"
  task_source="provided"
else
  inferred_task="$(infer_task "$query_lc" || true)"
  if [[ -n "$inferred_task" ]]; then
    effective_task="$inferred_task"
    task_source="inferred"
  fi
fi

skill_ids=()
while IFS= read -r sid; do
  [[ -n "$sid" ]] && skill_ids+=("$sid")
done < <(registry_list_ids "$registry_file")

if [[ ${#skill_ids[@]} -eq 0 ]]; then
  echo "error: no skills found in registry: $registry_file" >&2
  exit 1
fi

score_table=""
for sid in "${skill_ids[@]}"; do
  score="$(score_skill_for_query "$sid" "$query_lc" "$effective_task")"
  score_table+="$score"$'\t'"$sid"$'\n'
done

sorted_scores="$(printf '%s' "$score_table" | sort -t$'\t' -k1,1nr -k2,2)"
primary_skill="$(printf '%s\n' "$sorted_scores" | awk 'NF{print $2; exit}')"
primary_score="$(printf '%s\n' "$sorted_scores" | awk 'NF{print $1; exit}')"
primary_from_tag_fallback=0

if [[ -z "$primary_skill" ]]; then
  echo "error: failed to select a primary skill." >&2
  exit 1
fi

if [[ -z "$primary_score" ]]; then
  primary_score=0
fi

if [[ "$primary_score" -le 0 ]]; then
  if [[ -n "$effective_task" ]]; then
    fallback_primary="$(tag_registry_list_for_task "$tags_file" "$effective_task" | head -n 1 || true)"
    if [[ -n "$fallback_primary" ]]; then
      primary_skill="$fallback_primary"
      primary_score=0
      primary_from_tag_fallback=1
    else
      echo "error: no confident route and no task fallback candidates for '$effective_task'." >&2
      exit 1
    fi
  else
    echo "error: no confident route for query. Provide --task or mention a model/skill explicitly." >&2
    exit 2
  fi
fi

secondary_csv=""
secondary_rows=""
secondary_limit=$((top_k - 1))

while IFS=$'\t' read -r score sid; do
  [[ -z "$sid" ]] && continue
  if [[ "$sid" == "$primary_skill" ]]; then
    continue
  fi
  if [[ "$score" -le 0 ]]; then
    continue
  fi
  secondary_csv="$(append_unique_csv "$secondary_csv" "$sid")"
  secondary_rows+="$score"$'\t'"$sid"$'\t'"0"$'\n'
  if [[ "$(csv_count "$secondary_csv")" -ge "$secondary_limit" ]]; then
    break
  fi
done <<<"$sorted_scores"

if [[ "$secondary_limit" -gt 0 && -n "$effective_task" && "$(csv_count "$secondary_csv")" -lt "$secondary_limit" ]]; then
  while IFS= read -r sid; do
    [[ -z "$sid" ]] && continue
    if [[ "$sid" == "$primary_skill" ]] || in_csv_list "$sid" "$secondary_csv"; then
      continue
    fi
    score="$(score_skill_for_query "$sid" "$query_lc" "$effective_task")"
    secondary_csv="$(append_unique_csv "$secondary_csv" "$sid")"
    secondary_rows+="$score"$'\t'"$sid"$'\t'"1"$'\n'
    if [[ "$(csv_count "$secondary_csv")" -ge "$secondary_limit" ]]; then
      break
    fi
  done < <(tag_registry_list_for_task "$tags_file" "$effective_task")
fi

primary_reasons="$(build_reasons_pipe "$primary_skill" "$primary_score" "$query_lc" "$effective_task" "$primary_from_tag_fallback")"

if [[ "$format" == "text" ]]; then
  echo "query: $query"
  if [[ -n "$effective_task" ]]; then
    echo "task: $effective_task ($task_source)"
  else
    echo "task: none ($task_source)"
  fi
  echo "primary: $primary_skill (score=$primary_score)"
  echo "primary_reasons:"
  print_reasons_text "$primary_reasons"

  if [[ -z "$secondary_rows" ]]; then
    echo "secondary: none"
    exit 0
  fi

  echo "secondary:"
  while IFS=$'\t' read -r score sid from_tag; do
    [[ -z "$sid" ]] && continue
    secondary_reasons="$(build_reasons_pipe "$sid" "$score" "$query_lc" "$effective_task" "$from_tag")"
    echo "- $sid (score=$score)"
    print_reasons_text "$secondary_reasons" | sed 's/^/  /'
  done <<<"$secondary_rows"
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
printf '"primary":{'
printf '"skill":"%s",' "$(json_escape "$primary_skill")"
printf '"score":%s,' "$primary_score"
printf '"reasons":'
print_reasons_json "$primary_reasons"
printf '},'
printf '"secondary":['
first_secondary=1
while IFS=$'\t' read -r score sid from_tag; do
  [[ -z "$sid" ]] && continue
  secondary_reasons="$(build_reasons_pipe "$sid" "$score" "$query_lc" "$effective_task" "$from_tag")"
  if [[ "$first_secondary" -eq 0 ]]; then
    printf ','
  fi
  printf '{'
  printf '"skill":"%s",' "$(json_escape "$sid")"
  printf '"score":%s,' "$score"
  printf '"reasons":'
  print_reasons_json "$secondary_reasons"
  printf '}'
  first_secondary=0
done <<<"$secondary_rows"
printf ']'
printf '}\n'
