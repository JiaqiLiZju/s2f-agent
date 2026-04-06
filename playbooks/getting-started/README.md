# Getting-Started Playbook

## Purpose

Run one complete agent loop: route -> plan -> dry-run validation.

## Use This When

- You are new to the repository and need a first successful run.
- You want to verify routing, plan generation, and dry-run execution end to end.
- You need a baseline before task-specific playbooks.

## Runbook (Minimal Reproducible Commands)

Step 1: validate the repository wiring.

```bash
make validate-agent
```

Expected checkpoint:

- validation commands finish with exit code `0`
- routing eval summary reports all cases passed

Step 2: route a request.

```bash
bash scripts/route_query.sh \
  --query "Need variant-effect guidance around chr12 with REF/ALT." \
  --format text
```

Expected checkpoint:

- includes `decision: route` or `decision: clarify`
- includes a confidence value and candidate skill(s)

Step 3: build a structured plan.

```bash
bash scripts/run_agent.sh \
  --task variant-effect \
  --query 'Use $alphagenome-api predict_variant on hg38 chrom=chr12 position=1_000_000 alt=G' \
  --format json
```

Expected checkpoint:

- `decision` is `route`
- `primary_skill` is present
- `plan` is non-null

Step 4: validate execution path in dry-run mode.

```bash
bash scripts/execute_plan.sh \
  --task variant-effect \
  --query 'Use $alphagenome-api predict_variant on hg38 chrom=chr12 position=1_000_000 alt=G' \
  --format text
```

Expected checkpoint:

- summary contains `dry_run=1`
- summary contains `failed=0` and `verify_failed=0`

## Common Failure Signatures and Quick Fixes

- `error: query is required` -> add `--query "..."` or provide stdin.
- `decision: clarify` on broad input -> add `--task` and required input details.
- `$alphagenome-api` becomes malformed in query -> wrap query in single quotes.
- `error: env precheck failed for skill ...` on `execute_plan.sh --run` -> provide required env vars in process env or repo `.env` before rerunning.

## Related Playbooks

- [Variant-Effect](../variant-effect/README.md)
- [Environment-Setup](../environment-setup/README.md)
- [Troubleshooting](../troubleshooting/README.md)
