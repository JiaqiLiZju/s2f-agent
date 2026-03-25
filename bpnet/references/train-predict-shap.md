# Train Predict SHAP

Use this file for minimal grounded command templates after data is prepared.

## Required config files

- `input_data.json`
- `bpnet_params.json`
- `splits.json`

Use counts-loss helper before full training:

```bash
bpnet-counts-loss-weight --input-data input_data.json
```

## Train

```bash
bpnet-train \
  --input-data input_data.json \
  --output-dir models \
  --reference-genome hg38.genome.fa \
  --chroms $(paste -s -d ' ' chroms.txt) \
  --chrom-sizes hg38.chrom.sizes \
  --splits splits.json \
  --model-arch-name BPNet \
  --model-arch-params-json bpnet_params.json \
  --sequence-generator-name BPNet \
  --model-output-filename model \
  --input-seq-len 2114 \
  --output-len 1000 \
  --threads 10 \
  --epochs 100 \
  --batch-size 64 \
  --reverse-complement-augmentation
```

## Predict

```bash
bpnet-predict \
  --model models/model_split000 \
  --chrom-sizes hg38.chrom.sizes \
  --chroms chr7 chr13 chr17 chr19 chr21 chrX \
  --test-indices-file None \
  --reference-genome hg38.genome.fa \
  --output-dir predictions_and_metrics \
  --input-data input_data.json \
  --sequence-generator-name BPNet \
  --input-seq-len 2114 \
  --output-len 1000 \
  --output-window-size 1000 \
  --batch-size 64 \
  --reverse-complement-average \
  --threads 2 \
  --generate-predicted-profile-bigWigs
```

Main outputs:
- `*_predictions.h5`
- `*_predictions_track_<i>.bw` (if bigWig export enabled)
- summary metric files (`pearson.txt`, `spearman.txt`, `jsd.txt`) and `.npz/.npy` arrays

## SHAP scores

Use `--output-directory` (not `--output-dir`):

```bash
bpnet-shap \
  --reference-genome hg38.genome.fa \
  --model models/model_split000 \
  --bed-file data/peaks_inliers.bed \
  --output-directory shap \
  --input-seq-len 2114 \
  --control-len 1000 \
  --task-id 0 \
  --input-data input_data.json \
  --chrom-sizes hg38.chrom.sizes \
  --generate-shap-bigWigs
```

Main outputs:
- `counts_scores.h5`
- `profile_scores.h5`
- `peaks_valid_scores.bed`
- optional `counts_scores.bw`, `profile_scores.bw`
