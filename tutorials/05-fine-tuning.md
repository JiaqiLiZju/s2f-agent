# Tutorial 05: Fine-Tuning Workflow

## Goal

Generate a fine-tuning plan with explicit objective, dataset schema, and compute constraints.

## Step 1: Build a fine-tuning plan

```bash
bash scripts/run_agent.sh \
  --task fine-tuning \
  --query 'Use $dnabert2 for binary classification with CSV schema and limited GPU budget' \
  --format text
```

Expected output checkpoint:

- `decision: route` or focused `clarify`
- `required_inputs` includes `task-objective`, `dataset-schema`, `compute-constraints`

## Step 2: Review structured plan fields

```bash
bash scripts/run_agent.sh \
  --task fine-tuning \
  --query 'Use $dnabert2 for binary classification with CSV schema and limited GPU budget' \
  --format json
```

Expected output checkpoint:

- `plan.runnable_steps` exists
- `plan.expected_outputs` includes train/eval artifact hints

## Step 3: Validate dry-run execution path

```bash
bash scripts/execute_plan.sh \
  --task fine-tuning \
  --query 'Use $dnabert2 for binary classification with CSV schema and limited GPU budget' \
  --format text
```

Expected output checkpoint:

- summary indicates dry-run with no failures

## Common Failure Signatures and Quick Fixes

- `missing_inputs` includes `dataset-schema` -> state required columns and split assumptions.
- `missing_inputs` includes `compute-constraints` -> specify GPU/CPU and budget limits.
- low-confidence `clarify` decision -> keep explicit task plus skill hint in the query.

## Related Playbook

- [Fine-Tuning Playbook](../playbooks/fine-tuning/README.md)
