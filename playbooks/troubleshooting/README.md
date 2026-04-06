# Troubleshooting Playbook

## Purpose

Handle low-confidence routing and missing-input scenarios efficiently.

## Use This When

- `run_agent.sh` returns `decision: clarify` repeatedly.
- `missing_inputs` prevents runnable plans.
- `execute_plan.sh --run` exits early on env precheck.

## Runbook (Minimal Reproducible Commands)

Step 1: trigger a clarify response intentionally.

```bash
bash scripts/run_agent.sh --query 'Hello, can you help?' --format text
```

Expected checkpoint:

- `decision: clarify`
- `clarify_question` is present

Step 2: respond with task and required context.

```bash
bash scripts/run_agent.sh \
  --task variant-effect \
  --query 'Use $alphagenome-api predict_variant on hg38 chrom=chr12 position=1_000_000 alt=G' \
  --format text
```

Expected checkpoint:

- `decision: route`
- `missing_inputs: none` (or reduced list)

Step 3: validate with dry-run execution.

```bash
bash scripts/execute_plan.sh \
  --task variant-effect \
  --query 'Use $alphagenome-api predict_variant on hg38 chrom=chr12 position=1_000_000 alt=G' \
  --format text
```

Expected checkpoint:

- dry-run summary shows no step failure

## Common Failure Signatures and Immediate Fixes

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

Expected checkpoint:

- includes `env_precheck:` block
- reports missing required env var names (never values)
- exits before running the first real step

## Related Playbooks

- [Getting Started](../getting-started/README.md)
- [Variant-Effect](../variant-effect/README.md)
- [Environment-Setup](../environment-setup/README.md)
- [Embedding](../embedding/README.md)
- [Track-Prediction](../track-prediction/README.md)
- [Fine-Tuning](../fine-tuning/README.md)
