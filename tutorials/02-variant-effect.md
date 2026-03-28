# Tutorial 02: Variant-Effect Workflow

## Goal

Generate a variant-effect orchestration plan with explicit required inputs.

## Step 1: Run high-confidence orchestration

```bash
bash scripts/run_agent.sh \
  --task variant-effect \
  --query 'Use $alphagenome-api predict_variant on hg38 chrom=chr12 position=1_000_000 alt=G and save outputs to output/alphagenome' \
  --format text
```

Expected output checkpoint:

- `decision: route`
- `required_inputs_source: task-contract:variant-effect`
- `missing_inputs: none`

## Step 2: Inspect machine-consumable output

```bash
bash scripts/run_agent.sh \
  --task variant-effect \
  --query 'Use $alphagenome-api predict_variant on hg38 chrom=chr12 position=1_000_000 alt=G and save outputs to output/alphagenome' \
  --format json
```

Expected output checkpoint:

- `primary_skill` and `secondary_skills` are populated
- `plan.runnable_steps` and `plan.expected_outputs` are present

## Step 3: Dry-run plan execution

```bash
bash scripts/execute_plan.sh \
  --task variant-effect \
  --query 'Use $alphagenome-api predict_variant on hg38 chrom=chr12 position=1_000_000 alt=G and save outputs to output/alphagenome' \
  --format text
```

Expected output checkpoint:

- dry-run steps are listed
- `failed=0`

## Common Failure Signatures and Quick Fixes

- `missing_inputs` includes `assembly` -> add assembly string (for example `hg38`).
- `missing_inputs` includes `ref-alt-or-variant-spec` -> provide explicit REF/ALT or equivalent variant spec.
- `decision: clarify` with low confidence -> keep `--task variant-effect` and include explicit skill/model hint.
- parsed `position` looks wrong -> prefer either `position=1_000_000` or `chr12:1000000` in the query.

## Accepted Position Formats for Agent Parsing

- `chrom=chr12 position=1_000_000 alt=G`
- `chr12:1000000 alt=G`

## Related Playbook

- [Variant-Effect Playbook](../playbooks/variant-effect/README.md)
