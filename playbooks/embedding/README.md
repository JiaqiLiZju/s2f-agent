# Embedding Playbook

## Purpose

Provide a contract-aligned orchestration pattern for embedding requests.

## Use This When

- The user asks for sequence or interval embeddings.
- The user needs token-level or pooled representation guidance.
- The user wants model-path selection before coding.

## Required Inputs (Canonical Keys)

Required task-contract keys:

- `sequence-or-interval`
- `embedding-target`

Optional context that improves execution quality:

- species and assembly for interval workflows
- model preference
- sequence length constraints

## Skill Selection Heuristics

1. Prefer `dnabert2` when the user explicitly mentions DNABERT-2.
2. Prefer `nucleotide-transformer-v3` for NTv3 species-conditioned embedding paths.
3. Prefer `nucleotide-transformer` only when classic NT v1/v2 JAX behavior is required.
4. Prefer `evo2-inference` when hosted fallback is important.

## Runbook (Minimal Reproducible Commands)

Text output:

```bash
bash scripts/run_agent.sh \
  --task embedding \
  --query 'Use $dnabert2 for pooled embedding on a genomic interval' \
  --format text
```

JSON output:

```bash
bash scripts/run_agent.sh \
  --task embedding \
  --query 'Use $dnabert2 for pooled embedding on a genomic interval' \
  --format json
```

Dry-run execution validation:

```bash
bash scripts/execute_plan.sh \
  --task embedding \
  --query 'Use $dnabert2 for pooled embedding on a genomic interval' \
  --format text
```

NTv3 case-study embedding route:

```bash
bash case-study/ntv3/run_ntv3_embedding.sh
```

NTv3 combined case-study route:

```bash
bash case-study/ntv3/run_ntv3_case_study.sh
```

## Learn (Step-by-step + checkpoints + common failures)

Step 1: build an embedding plan.

```bash
bash scripts/run_agent.sh \
  --task embedding \
  --query 'Use $dnabert2 for pooled embedding on a genomic interval' \
  --format text
```

Expected checkpoint:

- `decision: route`
- `task: embedding`
- `required_inputs` includes `sequence-or-interval` and `embedding-target`

Step 2: validate JSON structure.

```bash
bash scripts/run_agent.sh \
  --task embedding \
  --query 'Use $dnabert2 for pooled embedding on a genomic interval' \
  --format json
```

Expected checkpoint:

- `plan.assumptions` and `plan.runnable_steps` exist
- `plan.retry_policy` is present

Step 3: confirm dry-run behavior.

```bash
bash scripts/execute_plan.sh \
  --task embedding \
  --query 'Use $dnabert2 for pooled embedding on a genomic interval' \
  --format text
```

Expected checkpoint:

- dry-run summary prints no execution failures

Common failure signatures and quick fixes:

- `missing_inputs` includes `embedding-target` -> specify token-level or pooled target explicitly.
- `missing_inputs` includes `sequence-or-interval` -> provide sequence text or interval coordinates.
- command interpreted `$dnabert2` by shell -> use single quotes around query.

NTv3 case-study flow checkpoints:

- embedding artifacts exist in `case-study/ntv3/output`: `*_trackplot.png` and `*_result.json`
- result JSON includes workflow metadata (`model_name`, interval fields, output paths)
- combined flow summary (`case_study_summary.json`) links embedding outputs and fine-tuning prep placeholders
- validate workflow status and artifact presence, not fixed shape numbers

## Clarify & Retry

1. Inspect `missing_inputs` for `sequence-or-interval` and `embedding-target`.
2. Clarify one missing input at a time with concrete examples.
3. Re-run the same task query with clarified values.
4. Confirm plan fields before downstream execution.

## Related Playbooks

- [Getting Started](../getting-started/README.md)
- [Troubleshooting](../troubleshooting/README.md)
