# Caveats

Use this file for frequent BPNet troubleshooting and mismatch handling.

## Argument name mismatch

- README examples may show `bpnet-shap --output-dir`.
- Current CLI parser expects `--output-directory`.

## Prediction scope

- `bpnet-predict` currently asserts single-task-style output handling (`1 <= num_output_tracks <= 2`).
- Be careful with multi-task assumptions in generated commands.

## SHAP bigWig requirement

- `--generate-shap-bigWigs` requires `--chrom-sizes`; otherwise bigWig output is skipped with a warning.

## Required output directories

- `bpnet-train`, `bpnet-predict`, and `bpnet-shap` expect output directories to already exist (unless using timestamp subdir options).

## Input schema constraints

- Include `bias` with both `source` and `smoothing` keys in `input_data.json`.
- If no controls are used, use `source: []` and `smoothing: []`.
- Keep `background_loci.ratio` aligned with how negatives were generated.

## SHAP selector constraint

- Use only one of `--chroms` or `--sample` in `bpnet-shap`.

## Legacy-vs-current command naming

- Prefer `bpnet-train`, `bpnet-predict`, `bpnet-shap`, `bpnet-counts-loss-weight`.
- Old docs may use legacy names (`train`, `predict`, `shap_scores`) from historical packages.

## Version pin expectation

- Package metadata is pinned to `tensorflow==2.4.1` and `python=3.7` era behavior.
- If users try newer TensorFlow/Python stacks, present them as unverified adaptations.
