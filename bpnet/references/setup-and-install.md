# Setup And Install

Use this file when users ask how to install BPNet or choose among Docker, AnVIL, and local setup.

## Recommended prerequisites

- NVIDIA GPU drivers and CUDA configured when training locally.
- Sanity check GPU availability:

```bash
nvidia-smi
```

## Docker path

```bash
docker pull vivekramalingam/tf-atlas:gcp-modeling_v2.1.0-rc.1
docker run -it --rm --cpus=10 --memory=32g --gpus device=1 \
  --mount src=/mnt/bpnet-models/,target=/mydata,type=bind \
  vivekramalingam/tf-atlas:gcp-modeling_v2.1.0-rc.1
```

## AnVIL path

- Use when user wants click-through cloud execution with minimal local setup.
- Keep instructions high level unless user asks for workspace-level details.

## Local conda path

```bash
conda create --name bpnet python=3.7
conda activate bpnet
pip install bpnet
# or
pip install git+https://github.com/kundajelab/bpnet.git
```

## External genomics tools

BPNet workflows also rely on tools not installed by `pip install bpnet`:

```bash
conda install -y -c bioconda samtools=1.1 bedtools ucsc-bedgraphtobigwig
```

Install `bamtools` when preprocessing scripts or local pipelines require it.
