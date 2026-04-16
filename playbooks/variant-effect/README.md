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

## Execution Modes

### 1) Orchestration (`run_agent.sh`)

Text output:

```bash
bash scripts/run_agent.sh \
  --task variant-effect \
  --query 'Use $alphagenome-api variant-effect on hg38 chr12 position 1000000 ALT G and save outputs to <output_dir>' \
  --format text
```

JSON output:

```bash
bash scripts/run_agent.sh \
  --task variant-effect \
  --query 'Use $alphagenome-api variant-effect on hg38 chr12 position 1000000 ALT G and save outputs to <output_dir>' \
  --format json
```

Expected checkpoint:

- `decision: route`
- `missing_inputs: []`
- `plan.runnable_steps` and `plan.expected_outputs` are present

### 2) Plan Validation (`execute_plan.sh`)

Dry-run:

```bash
bash scripts/execute_plan.sh \
  --task variant-effect \
  --query 'Use $alphagenome-api variant-effect on hg38 chr12 position 1000000 ALT G and save outputs to <output_dir>' \
  --format text
```

Real execution:

```bash
set -a; source .env; set +a
bash scripts/execute_plan.sh \
  --task variant-effect \
  --query 'Use $alphagenome-api variant-effect on hg38 chr12 position 1000000 ALT G and save outputs to <output_dir>' \
  --run \
  --format text
```

### 3) AlphaGenome Single-Variant Real Run

```bash
set -a; source .env; set +a
conda run -p /path/to/alphagenome-py310-env \
  python skills/alphagenome-api/scripts/run_alphagenome_predict_variant.py \
  --variant-spec chr12:1000000:G \
  --assembly hg38 \
  --output-dir <output_dir> \
  --request-timeout-sec 120
```

If `dna_client.create(...)` times out, retry once with proxy variables:

```bash
set -a; source .env; set +a
grpc_proxy=http://127.0.0.1:7890 \
http_proxy=http://127.0.0.1:7890 \
https_proxy=http://127.0.0.1:7890 \
conda run -p /path/to/alphagenome-py310-env \
  python skills/alphagenome-api/scripts/run_alphagenome_predict_variant.py \
  --variant-spec chr12:1000000:G \
  --assembly hg38 \
  --output-dir <output_dir> \
  --request-timeout-sec 120
```

### 4) AlphaGenome VCF Batch Real Run

```bash
set -a; source .env; set +a
conda run -p /path/to/alphagenome-py310-env \
  python skills/alphagenome-api/scripts/run_alphagenome_vcf_batch.py \
  --input <variants.vcf> \
  --assembly hg38 \
  --output-dir <output_dir> \
  --non-interactive \
  --request-timeout-sec 120
```

Notes:

- Output file pattern is `<vcf_stem>_tissues.tsv`.
- `run_alphagenome_vcf_batch.py` retries `dna_client.create(...)` once with proxy variables by default when the first attempt times out.
- Use `--proxy-url ''` to disable retry or `--proxy-url <url>` to set a custom proxy endpoint.

## Result Acceptance Template

1. File exists and is non-empty.
```bash
test -s <result_file> && echo "ok: result file exists and non-empty"
```

2. `assembly` column is consistent.
```bash
awk -F'\t' 'NR>1{c[$7]++} END{for(k in c) print k"\t"c[k]}' <result_file>
```

3. `status` distribution is visible.
```bash
awk -F'\t' 'NR==1{for(i=1;i<=NF;i++) if($i=="status") s=i; next} {cnt[$s]++} END{for(k in cnt) print k"\t"cnt[k]}' <result_file>
```

4. Inspect failed samples (if any).
```bash
awk -F'\t' 'NR==1{for(i=1;i<=NF;i++){if($i=="status")s=i; if($i=="error")e=i; if($i=="chrom")c=i; if($i=="position")p=i; if($i=="ref")r=i; if($i=="alt")a=i;} next} $s!="success"{print $c":"$p":"$r">"$a"\t"$e}' <result_file> | head -n 10
```

## Clarify & Retry

1. If `missing_inputs` is non-empty, clarify in this order: `assembly` -> `coordinate-or-interval` -> `ref-alt-or-variant-spec`.
2. Re-run `run_agent.sh` and confirm `missing_inputs: []`.
3. Re-run `execute_plan.sh --dry-run` before any heavy run.
4. If network timeout occurs, retry once with proxy variables (or use VCF batch script default retry behavior).

## Related Playbooks

- [Getting Started](../getting-started/README.md)
- [Troubleshooting](../troubleshooting/README.md)
