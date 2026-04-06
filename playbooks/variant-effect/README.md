# Variant-Effect Playbook

## Purpose

Provide a contract-aligned orchestration pattern for variant-effect requests.

## Use This When

- The user needs REF vs ALT impact guidance.
- The user asks for variant prioritization or variant scoring workflows.
- The user wants model-specific caveats before execution.

## Required Inputs (Canonical Keys)

Required task-contract keys:

- `assembly`
- `coordinate-or-interval`
- `ref-alt-or-variant-spec`

Optional context that improves routing quality:

- species
- output modality (for example RNA-related tracks)
- execution path preference (local vs hosted)

## Skill Selection Heuristics

1. Prefer `alphagenome-api` when the query explicitly asks for AlphaGenome API methods.
2. Prefer `borzoi-workflows` for Borzoi tutorial-grounded variant workflows.
3. Prefer `gpn-models` for framework-selection-heavy variant analysis.
4. Consider `evo2-inference` when local GPU constraints suggest hosted fallback.

## Runbook (Minimal Reproducible Commands)

Text output:

```bash
bash scripts/run_agent.sh \
  --task variant-effect \
  --query 'Use $alphagenome-api variant-effect on hg38 chr12 REF A ALT G' \
  --format text
```

JSON output:

```bash
bash scripts/run_agent.sh \
  --task variant-effect \
  --query 'Use $alphagenome-api variant-effect on hg38 chr12 REF A ALT G' \
  --format json
```

Dry-run execution validation:

```bash
bash scripts/execute_plan.sh \
  --task variant-effect \
  --query 'Use $alphagenome-api variant-effect on hg38 chr12 REF A ALT G' \
  --format text
```

Optional AlphaGenome real-run fast path:

```bash
set -a; source .env; set +a
conda run -p /path/to/alphagenome-py310-env \
  python skills/alphagenome-api/scripts/run_alphagenome_predict_variant.py \
  --chrom chr12 \
  --position 1000000 \
  --alt G \
  --assembly hg38 \
  --output-dir output/alphagenome
```

If client creation fails with `grpc.FutureTimeoutError`, retry via proxy:

```bash
set -a; source .env; set +a
grpc_proxy=http://127.0.0.1:7890 \
http_proxy=http://127.0.0.1:7890 \
https_proxy=http://127.0.0.1:7890 \
conda run -p /path/to/alphagenome-py310-env \
  python skills/alphagenome-api/scripts/run_alphagenome_predict_variant.py \
  --chrom chr12 \
  --position 1000000 \
  --alt G \
  --assembly hg38 \
  --output-dir output/alphagenome \
  --request-timeout-sec 120
```

## Learn (Step-by-step + checkpoints + common failures)

Step 1: run high-confidence orchestration.

```bash
bash scripts/run_agent.sh \
  --task variant-effect \
  --query 'Use $alphagenome-api predict_variant on hg38 chrom=chr12 position=1_000_000 alt=G and save outputs to output/alphagenome' \
  --format text
```

Expected checkpoint:

- `decision: route`
- `required_inputs_source: task-contract:variant-effect`
- `missing_inputs: none`

Step 2: inspect machine-consumable output.

```bash
bash scripts/run_agent.sh \
  --task variant-effect \
  --query 'Use $alphagenome-api predict_variant on hg38 chrom=chr12 position=1_000_000 alt=G and save outputs to output/alphagenome' \
  --format json
```

Expected checkpoint:

- `primary_skill` and `secondary_skills` are populated
- `plan.runnable_steps` and `plan.expected_outputs` are present

Step 3: dry-run plan execution.

```bash
bash scripts/execute_plan.sh \
  --task variant-effect \
  --query 'Use $alphagenome-api predict_variant on hg38 chrom=chr12 position=1_000_000 alt=G and save outputs to output/alphagenome' \
  --format text
```

Expected checkpoint:

- dry-run steps are listed
- `failed=0`

Common failure signatures and quick fixes:

- `missing_inputs` includes `assembly` -> add assembly string (for example `hg38`).
- `missing_inputs` includes `ref-alt-or-variant-spec` -> provide explicit REF/ALT or equivalent variant spec.
- `decision: clarify` with low confidence -> keep `--task variant-effect` and include explicit skill/model hint.
- parsed `position` looks wrong -> prefer either `position=1_000_000` or `chr12:1000000` in the query.

Accepted position formats for agent parsing:

- `chrom=chr12 position=1_000_000 alt=G`
- `chr12:1000000 alt=G`

## Clarify & Retry

1. Check `missing_inputs` in the `run_agent.sh` output.
2. Ask one focused follow-up per missing key, prioritizing `assembly` then coordinate and allele specification.
3. Re-run `run_agent.sh` with the clarified inputs.
4. Validate dry-run execution with `scripts/execute_plan.sh` before any real run.

## Related Playbooks

- [Getting Started](../getting-started/README.md)
- [Troubleshooting](../troubleshooting/README.md)
