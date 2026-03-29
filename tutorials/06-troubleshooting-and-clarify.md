# Tutorial 06: Troubleshooting and Clarify Flow

## Goal

Handle low-confidence routing and missing-input scenarios efficiently.

## Step 1: Trigger a clarify response intentionally

```bash
bash scripts/run_agent.sh --query 'Hello, can you help?' --format text
```

Expected output checkpoint:

- `decision: clarify`
- `clarify_question` is present

## Step 2: Respond with task and required context

```bash
bash scripts/run_agent.sh \
  --task variant-effect \
  --query 'Use $alphagenome-api predict_variant on hg38 chrom=chr12 position=1_000_000 alt=G' \
  --format text
```

Expected output checkpoint:

- `decision: route`
- `missing_inputs: none` (or reduced list)

## Step 3: Validate with dry-run execution

```bash
bash scripts/execute_plan.sh \
  --task variant-effect \
  --query 'Use $alphagenome-api predict_variant on hg38 chrom=chr12 position=1_000_000 alt=G' \
  --format text
```

Expected output checkpoint:

- dry-run summary shows no step failure

## Common Failure Signatures and Immediate Fix

- `decision: clarify` repeats -> provide missing required keys directly in query.
- `error: routing failed: ...` -> check registry files exist and run `make validate-agent`.
- `error: run_agent failed: ...` in execute step -> run `run_agent.sh --format json` first and inspect `plan`.
- `error: env precheck failed for skill '<skill>'` on `execute_plan.sh --run` -> set required env vars in process env or `.env`.
- Evo2 env precheck note: set at least one of `NVCF_RUN_KEY` or `EVO2_API_KEY`.

## ENV Precheck Quick Validation

```bash
# expected to fail early if ALPHAGENOME_API_KEY is not available
env -u ALPHAGENOME_API_KEY bash scripts/execute_plan.sh \
  --run \
  --task variant-effect \
  --query 'Use $alphagenome-api predict_variant on hg38 chrom=chr12 position=1_000_000 alt=G' \
  --format text
```

Expected output checkpoint:

- includes `env_precheck:` block
- reports missing required env var names (never values)
- exits before running the first real step

## Related Playbooks

- [Variant-Effect Playbook](../playbooks/variant-effect/README.md)
- [Environment-Setup Playbook](../playbooks/environment-setup/README.md)
- [Embedding Playbook](../playbooks/embedding/README.md)
- [Track-Prediction Playbook](../playbooks/track-prediction/README.md)
- [Fine-Tuning Playbook](../playbooks/fine-tuning/README.md)
