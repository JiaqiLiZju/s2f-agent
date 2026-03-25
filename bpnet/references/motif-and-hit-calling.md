# Motif And Hit Calling

Use this file after SHAP score generation (`counts_scores.h5` and `profile_scores.h5`).

## TF-MoDISco (modisco-lite)

```bash
conda create --name tfmodisco python=3.10
conda activate tfmodisco
pip install modisco-lite
```

```bash
modisco motifs \
  --max_seqlets 50000 \
  --h5py shap/profile_scores.h5 \
  -o modisco/profile/profile_modisco_scores.h5 \
  --trim_size 20 \
  --initial_flank_to_add 5 \
  --final_flank_to_add 10

modisco motifs \
  --max_seqlets 50000 \
  --h5py shap/counts_scores.h5 \
  -o modisco/counts/counts_modisco_scores.h5 \
  --trim_size 20 \
  --initial_flank_to_add 5 \
  --final_flank_to_add 10
```

## Fi-NeMo hit calling

```bash
git clone https://github.com/austintwang/finemo_gpu.git
cd finemo_gpu
conda env create -f environment.yml -n finemo
conda activate finemo
pip install --editable .
cd ..
```

```bash
finemo extract-regions-bpnet-h5 \
  -c shap/counts_scores.h5 \
  -o hits/counts/regions_bw.npz \
  -w 400 \
  -p data/peaks_inliers.bed

finemo call-hits \
  -l ${lambda} \
  -r hits/counts/regions_bw.npz \
  -m ${modisco_h5} \
  -p data/peaks_inliers.bed \
  -C hg38.chrom.sizes \
  -o hits/counts \
  -t 0.7 \
  --compile

finemo report \
  -H hits/counts/hits.tsv \
  -r hits/counts/regions_bw.npz \
  -m ${modisco_h5} \
  -p data/peaks_inliers.bed \
  -o hits/counts \
  -t 0.7 \
  -W 400
```

## Boundary note

The repository contains `bpnet/cli/motif_discovery.py`, but default package entry points do not expose `bpnet-motif` by default. Prefer explicit external `modisco-lite` and Fi-NeMo commands unless users intentionally patch/enable local CLI wiring.
