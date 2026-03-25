# Setup and Environment

Use this file when the user needs reproducible Borzoi installation and environment setup.

## Core dependency stack

Grounded major requirements from Borzoi docs:

- Python `3.10` (recommended tutorial path)
- TensorFlow `2.15.x`
- `baskerville` repository install
- `borzoi` repository install
- `westminster` repository install for training/data processing flows

Minimal installation order:

```bash
git clone https://github.com/calico/baskerville.git
cd baskerville
pip install -e .

git clone https://github.com/calico/borzoi.git
cd borzoi
pip install -e .
```

Training-oriented add-on:

```bash
git clone https://github.com/calico/westminster.git
cd westminster
pip install -e .
```

## Conda baseline

```bash
conda create -n borzoi_py310 python=3.10
conda activate borzoi_py310
```

Notebook users should install Jupyter:

```bash
pip install notebook
```

## Environment variables

Borzoi docs provide an `env_vars.sh` script in each repository. It configures:

- `BORZOI_DIR`
- `BORZOI_HG38`
- `BORZOI_MM10`
- `BORZOI_CONDA`
- `PATH`/`PYTHONPATH` entries for Borzoi scripts

`baskerville` and `westminster` variables are only required for workflows that use those repositories (especially training/data processing).

## Model and annotation download

For published-model workflows, run:

```bash
cd borzoi
./download_models.sh
```

This script downloads:

- pre-trained replicate `.h5` models
- hg38 gene annotations (GTF/BED/GFF)
- helper annotation tables
- hg38 FASTA plus indexing

## Data and compute caveats

- Full training-data bucket is multi-terabyte and requester-pays on GCP.
- Some scripts in the Borzoi repository launch multi-process jobs and assume SLURM-style environments.
