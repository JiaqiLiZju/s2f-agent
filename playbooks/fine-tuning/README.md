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

## Output Expectations (Mapped to Output Contract)

For `fine-tuning` in `registry/output_contracts.yaml`, a high-quality response should map to:

- `assumptions`: dataset schema validation and explicit evaluation artifact paths
- `runnable_steps`: fine-tuning orchestration command chain
- `expected_outputs`: train command and evaluation metrics artifacts
- `fallbacks`: reduced-scope minimal training run
- `retry_policy`: clarify dataset schema first, then retry once

## Minimal Reproducible Commands

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

## Clarify Flow (When Inputs Are Missing)

1. Read `missing_inputs` for any missing required key.
2. Clarify `task-objective`, `dataset-schema`, and `compute-constraints` explicitly.
3. Re-run with a concrete training objective and schema details.
4. Validate plan readiness before running any training commands.

## Matching Tutorial

- [Fine-Tuning Tutorial](../../tutorials/05-fine-tuning.md)
- [Troubleshooting and Clarify Tutorial](../../tutorials/06-troubleshooting-and-clarify.md)
