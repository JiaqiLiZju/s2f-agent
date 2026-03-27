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

## Output Expectations (Mapped to Output Contract)

For `track-prediction` in `registry/output_contracts.yaml`, a high-quality response should map to:

- `assumptions`: explicit species/assembly and output-head compatibility
- `runnable_steps`: task-specific orchestration command chain
- `expected_outputs`: track metadata and plot expectations
- `fallbacks`: secondary track skill fallback path
- `retry_policy`: clarify missing head definition, then retry once

## Minimal Reproducible Commands

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

## Clarify Flow (When Inputs Are Missing)

1. Read `missing_inputs` and resolve in this order: `species`, `assembly`, `sequence-or-interval`, `output-head`.
2. Ask one concrete follow-up question per unresolved key.
3. Re-run with clarified values and verify the generated `plan`.
4. Use `execute_plan.sh` dry-run to validate runnable steps.

## Matching Tutorial

- [Track-Prediction Tutorial](../../tutorials/04-track-prediction.md)
- [Troubleshooting and Clarify Tutorial](../../tutorials/06-troubleshooting-and-clarify.md)
