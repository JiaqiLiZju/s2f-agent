# Tutorial 04: Track-Prediction Workflow

## Goal

Create a track-prediction plan with explicit species, assembly, and head definitions.

## Step 1: Generate routing + plan output

```bash
bash scripts/run_agent.sh \
  --task track-prediction \
  --query 'Need track prediction for human hg38 interval with explicit output head using $nucleotide-transformer-v3' \
  --format text
```

Expected output checkpoint:

- `decision: route`
- `required_inputs` includes `species`, `assembly`, `sequence-or-interval`, `output-head`
- `missing_inputs` is minimized or empty

## Step 2: Check JSON fields for downstream automation

```bash
bash scripts/run_agent.sh \
  --task track-prediction \
  --query 'Need track prediction for human hg38 interval with explicit output head using $nucleotide-transformer-v3' \
  --format json
```

Expected output checkpoint:

- `primary_skill` is present
- `plan.expected_outputs` includes track-oriented output hints

## Step 3: Dry-run execution contract

```bash
bash scripts/execute_plan.sh \
  --task track-prediction \
  --query 'Need track prediction for human hg38 interval with explicit output head using $nucleotide-transformer-v3' \
  --format text
```

Expected output checkpoint:

- dry-run summary indicates no failure

## Common Failure Signatures and Quick Fixes

- `missing_inputs` includes `output-head` -> name the expected output head/modality explicitly.
- `decision: clarify` -> add `--task track-prediction` and species/assembly details.
- unclear interval format -> specify chromosome + interval style consistently in query.

## Related Playbook

- [Track-Prediction Playbook](../playbooks/track-prediction/README.md)
