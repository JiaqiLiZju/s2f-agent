# Fine-Tuning Playbook

## Purpose

Provide a contract-aligned orchestration pattern for fine-tuning requests.

## Use This When

- The user asks for training setup and command planning.
- The user needs dataset contract checks before training.
- The user wants compute-aware routing and fallback choices.

## Required Inputs (Canonical Keys)

Required task-contract keys:

- `task-objective`
- `dataset-schema`
- `compute-constraints`

Optional context that improves execution quality:

- preferred model family
- expected evaluation metrics
- checkpoint initialization preference

## Skill Selection Heuristics

1. Prefer `dnabert2` for CSV-oriented genomics fine-tuning workflows.
2. Prefer `bpnet` for profile-prediction-focused training stacks.
3. Prefer `basset-workflows` only when legacy Torch7 compatibility is required.

## Runbook (Minimal Reproducible Commands)

Text output:

```bash
bash scripts/run_agent.sh \
  --task fine-tuning \
  --query 'Use $dnabert2 for binary classification fine-tuning with CSV labels and compute budget' \
  --format text
```

JSON output:

```bash
bash scripts/run_agent.sh \
  --task fine-tuning \
  --query 'Use $dnabert2 for binary classification fine-tuning with CSV labels and compute budget' \
  --format json
```

Dry-run execution validation:

```bash
bash scripts/execute_plan.sh \
  --task fine-tuning \
  --query 'Use $dnabert2 for binary classification fine-tuning with CSV labels and compute budget' \
  --format text
```

## Learn (Step-by-step + checkpoints + common failures)

Step 1: build a fine-tuning plan.

```bash
bash scripts/run_agent.sh \
  --task fine-tuning \
  --query 'Use $dnabert2 for binary classification with CSV schema and limited GPU budget' \
  --format text
```

Expected checkpoint:

- `decision: route` or focused `clarify`
- `required_inputs` includes `task-objective`, `dataset-schema`, `compute-constraints`

Step 2: review structured plan fields.

```bash
bash scripts/run_agent.sh \
  --task fine-tuning \
  --query 'Use $dnabert2 for binary classification with CSV schema and limited GPU budget' \
  --format json
```

Expected checkpoint:

- `plan.runnable_steps` exists
- `plan.expected_outputs` includes train/eval artifact hints

Step 3: validate dry-run execution path.

```bash
bash scripts/execute_plan.sh \
  --task fine-tuning \
  --query 'Use $dnabert2 for binary classification with CSV schema and limited GPU budget' \
  --format text
```

Expected checkpoint:

- summary indicates dry-run with no failures

Common failure signatures and quick fixes:

- `missing_inputs` includes `dataset-schema` -> state required columns and split assumptions.
- `missing_inputs` includes `compute-constraints` -> specify GPU/CPU and budget limits.
- low-confidence `clarify` decision -> keep explicit task plus skill hint in the query.

## Clarify & Retry

1. Read `missing_inputs` for any missing required key.
2. Clarify `task-objective`, `dataset-schema`, and `compute-constraints` explicitly.
3. Re-run with a concrete training objective and schema details.
4. Validate plan readiness before running any training commands.

## Related Playbooks

- [Getting Started](../getting-started/README.md)
- [Troubleshooting](../troubleshooting/README.md)
