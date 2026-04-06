# Track-Prediction Playbook

## Purpose

Provide a contract-aligned orchestration pattern for sequence-to-track prediction tasks.

## Use This When

- The user requests signal track prediction from sequence or interval input.
- The user needs model-head-aware output planning.
- The user wants safe defaults for species and assembly handling.

## Required Inputs (Canonical Keys)

Required task-contract keys:

- `species`
- `assembly`
- `sequence-or-interval`
- `output-head`

Optional context that improves response quality:

- model preference
- output length or center-crop expectation
- desired plot/export format

## Skill Selection Heuristics

1. Prefer `nucleotide-transformer-v3` for NTv3 species-conditioned outputs.
2. Prefer `segment-nt` for SegmentNT-family segmentation-style outputs.
3. Prefer `borzoi-workflows` for Borzoi tutorial and interpretation workflows.

## Runbook (Minimal Reproducible Commands)

Text output:

```bash
bash scripts/run_agent.sh \
  --task track-prediction \
  --query 'Need track prediction for human hg38 interval with explicit output head' \
  --format text
```

JSON output:

```bash
bash scripts/run_agent.sh \
  --task track-prediction \
  --query 'Need track prediction for human hg38 interval with explicit output head' \
  --format json
```

Dry-run execution validation:

```bash
bash scripts/execute_plan.sh \
  --task track-prediction \
  --query 'Need track prediction for human hg38 interval with explicit output head' \
  --format text
```

## Learn (Step-by-step + checkpoints + common failures)

Step 1: generate routing + plan output.

```bash
bash scripts/run_agent.sh \
  --task track-prediction \
  --query 'Need track prediction for human hg38 interval with explicit output head using $nucleotide-transformer-v3' \
  --format text
```

Expected checkpoint:

- `decision: route`
- `required_inputs` includes `species`, `assembly`, `sequence-or-interval`, `output-head`
- `missing_inputs` is minimized or empty

Step 2: check JSON fields for downstream automation.

```bash
bash scripts/run_agent.sh \
  --task track-prediction \
  --query 'Need track prediction for human hg38 interval with explicit output head using $nucleotide-transformer-v3' \
  --format json
```

Expected checkpoint:

- `primary_skill` is present
- `plan.expected_outputs` includes track-oriented output hints

Step 3: dry-run execution contract.

```bash
bash scripts/execute_plan.sh \
  --task track-prediction \
  --query 'Need track prediction for human hg38 interval with explicit output head using $nucleotide-transformer-v3' \
  --format text
```

Expected checkpoint:

- dry-run summary indicates no failure

Common failure signatures and quick fixes:

- `missing_inputs` includes `output-head` -> name the expected output head/modality explicitly.
- `decision: clarify` -> add `--task track-prediction` and species/assembly details.
- unclear interval format -> specify chromosome + interval style consistently in query.

## Clarify & Retry

1. Read `missing_inputs` and resolve in this order: `species`, `assembly`, `sequence-or-interval`, `output-head`.
2. Ask one concrete follow-up question per unresolved key.
3. Re-run with clarified values and verify the generated `plan`.
4. Use `execute_plan.sh` dry-run to validate runnable steps.

## Related Playbooks

- [Getting Started](../getting-started/README.md)
- [Troubleshooting](../troubleshooting/README.md)
