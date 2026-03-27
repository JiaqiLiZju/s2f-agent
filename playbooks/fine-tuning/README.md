# Fine-Tuning Playbook

## Purpose

Provide a consistent cross-skill workflow for fine-tuning requests.

## Minimum Input Contract

Required:

- task objective (classification, regression, profile prediction, etc.)
- dataset schema and split availability
- target framework or model family (if already chosen)

Optional:

- hardware budget (GPU count, memory, runtime limit)
- expected metrics and evaluation protocol
- checkpoint initialization preference

## Candidate Skills

- `dnabert2`: DNABERT-2 custom CSV and GUE-style fine-tuning.
- `bpnet`: profile-prediction training and SHAP workflows.
- `basset-workflows`: legacy Torch7 training path when existing legacy stack is required.

## Routing Heuristics

1. If user explicitly mentions DNABERT2 or CSV schema validation, use `dnabert2`.
2. If user asks for BPNet CLI workflows (`bpnet-train`, `bpnet-shap`), use `bpnet`.
3. If user requests legacy Torch7/Basset, use `basset-workflows`.

## Output Contract

A valid answer should include:

1. chosen skill and rationale
2. required dataset fields and assumptions
3. minimal runnable training command chain
4. expected outputs and troubleshooting caveats

## Minimal Repro Example

```bash
bash scripts/run_agent.sh \
  --task fine-tuning \
  --query "Need fine-tuning workflow for CSV labels and compute budget."
```
