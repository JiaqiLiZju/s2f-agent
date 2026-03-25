---
name: bpnet
description: Use BPNet workflows for base-resolution TF binding modeling, including installation choices, ChIP-seq preprocessing, input JSON/schema setup, training, prediction, SHAP attribution scoring, and downstream TF-MoDISco/Fi-NeMo integration. Use when Codex needs to write, fix, explain, or review BPNet CLI commands (`bpnet-train`, `bpnet-predict`, `bpnet-shap`, `bpnet-counts-loss-weight`, `bpnet-outliers`, `bpnet-gc-reference`, `bpnet-gc-background`), task JSON files, or BPNet troubleshooting.
---

# BPNet

## Overview

Use this skill for the Kundaje Lab BPNet repository workflow packaged around `bpnet-*` CLI commands.

## Follow This Decision Flow

1. Choose the execution path first.
- Use Docker or AnVIL when the user wants low-setup execution.
- Use local install when the user needs editable workflows or script-level debugging.

2. Lock versions and system prerequisites early.
- Prefer the repository-pinned path (`python=3.7`, `tensorflow==2.4.1`) for grounded behavior.
- Confirm GPU readiness (`nvidia-smi`) before suggesting long training runs.
- Install external genomics tools used by preprocessing and bigWig conversion.

3. Validate input schema before writing long commands.
- Keep `input_data.json` task-centric with `signal`, `loci`, optional `background_loci`, and `bias`.
- For current generator behavior, always include `bias` with both `source` and `smoothing` keys (empty lists are acceptable).
- Use ENCODE narrowPeak BED6+4 format for loci files.

4. Build training assets in this order.
- Create `input_data.json`.
- Create `bpnet_params.json`.
- Create `splits.json`.
- Compute or set counts loss weight before full training.

5. Use the modern CLI names.
- Prefer `bpnet-train`, `bpnet-predict`, `bpnet-shap`, and other `bpnet-*` commands.
- Do not default to legacy command names (`train`, `predict`, `shap_scores`) unless explicitly reproducing old docs.

6. Surface current runtime boundaries up front.
- `bpnet-predict` currently assumes single-task output tracks (1-2).
- SHAP bigWig export needs `--chrom-sizes`.
- `bpnet-shap` uses `--output-directory` (not `--output-dir`).

7. Keep motif discovery/hit calling explicitly external.
- Use `modisco-lite` for TF-MoDISco workflows.
- Use Fi-NeMo separately for motif hit localization.
- Do not claim `bpnet-motif` is available by default from package entry points.

## Grounded Command Surface

Treat the following commands as grounded:

- `pip install git+https://github.com/kundajelab/bpnet.git`
- `pip install bpnet`
- `bpnet-counts-loss-weight --input-data input_data.json`
- `bpnet-train ...`
- `bpnet-predict ...`
- `bpnet-shap ...`
- `bpnet-outliers ...`
- `bpnet-gc-reference ...`
- `bpnet-gc-background ...`
- `modisco motifs ...`
- `finemo extract-regions-bpnet-h5 ...`
- `finemo call-hits ...`
- `finemo report ...`

Do not invent alternate BPNet wrappers or unsupported in-repo motif entry points.

## Response Style

- Prefer minimal runnable command blocks over long prose.
- Call out required file schema and argument names when users report CLI errors.
- State clearly when a step depends on external tools (TF-MoDISco, Fi-NeMo, bedtools, UCSC tools).

## References

- Read [references/setup-and-install.md](references/setup-and-install.md) for installation paths and dependency setup.
- Read [references/data-and-preprocessing.md](references/data-and-preprocessing.md) for ChIP-seq preprocessing, schema, outlier removal, and GC background generation.
- Read [references/train-predict-shap.md](references/train-predict-shap.md) for grounded train/predict/SHAP command templates and outputs.
- Read [references/motif-and-hit-calling.md](references/motif-and-hit-calling.md) for TF-MoDISco and Fi-NeMo integration.
- Read [references/caveats.md](references/caveats.md) for known parameter and behavior pitfalls.
