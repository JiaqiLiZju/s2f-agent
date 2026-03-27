# Tutorial 01: Quickstart Agent

## Goal

Run one complete agent loop: route -> plan -> dry-run validation.

## Step 1: Validate the repository wiring

```bash
make validate-agent
```

Expected output checkpoint:

- validation commands finish with exit code `0`
- routing eval summary reports all cases passed

## Step 2: Route a request

```bash
bash scripts/route_query.sh \
  --query "Need variant-effect guidance around chr12 with REF/ALT." \
  --format text
```

Expected output checkpoint:

- includes `decision: route` or `decision: clarify`
- includes a confidence value and candidate skill(s)

## Step 3: Build a full structured plan

```bash
bash scripts/run_agent.sh \
  --task variant-effect \
  --query 'Use $alphagenome-api variant-effect on hg38 chr12 REF A ALT G' \
  --format json
```

Expected output checkpoint:

- `decision` is `route`
- `primary_skill` is present
- `plan` is non-null

## Step 4: Validate execution path in dry-run mode

```bash
bash scripts/execute_plan.sh \
  --task variant-effect \
  --query 'Use $alphagenome-api variant-effect on hg38 chr12 REF A ALT G' \
  --format text
```

Expected output checkpoint:

- summary contains `dry_run=1`
- summary contains `failed=0` and `verify_failed=0`

## Common Failure Signatures and Quick Fixes

- `error: query is required` -> add `--query "..."` or provide stdin.
- `decision: clarify` on broad input -> add `--task` and required input details.
- `$alphagenome-api` becomes malformed in query -> wrap query in single quotes.

## Related Playbook

- [Environment-Setup Playbook](../playbooks/environment-setup/README.md)
