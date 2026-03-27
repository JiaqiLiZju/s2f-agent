# Tutorial 03: Embedding Workflow

## Goal

Produce a consistent embedding plan using canonical embedding task keys.

## Step 1: Build an embedding plan

```bash
bash scripts/run_agent.sh \
  --task embedding \
  --query 'Use $dnabert2 for pooled embedding on a genomic interval' \
  --format text
```

Expected output checkpoint:

- `decision: route`
- `task: embedding`
- `required_inputs` includes `sequence-or-interval` and `embedding-target`

## Step 2: Validate JSON structure

```bash
bash scripts/run_agent.sh \
  --task embedding \
  --query 'Use $dnabert2 for pooled embedding on a genomic interval' \
  --format json
```

Expected output checkpoint:

- `plan.assumptions` and `plan.runnable_steps` exist
- `plan.retry_policy` is present

## Step 3: Confirm dry-run behavior

```bash
bash scripts/execute_plan.sh \
  --task embedding \
  --query 'Use $dnabert2 for pooled embedding on a genomic interval' \
  --format text
```

Expected output checkpoint:

- dry-run summary prints no execution failures

## Common Failure Signatures and Quick Fixes

- `missing_inputs` includes `embedding-target` -> specify token-level or pooled target explicitly.
- `missing_inputs` includes `sequence-or-interval` -> provide sequence text or interval coordinates.
- command interpreted `$dnabert2` by shell -> use single quotes around query.

## Related Playbook

- [Embedding Playbook](../playbooks/embedding/README.md)
