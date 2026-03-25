# Setup and Legacy Caveats

Use this file when users need reproducible Basset environment setup.

## Legacy status and routing

- Basset README points users to Basenji for continued development/support.
- Keep Basset guidance for legacy Torch7 workflows, existing `.th` models, and script compatibility.

## Core installation expectations

Grounded install notes from Basset README:

1. Install Torch7 first.
2. Install Python dependencies (Anaconda recommended in upstream docs).
3. Install `bedtools` for preprocessing and `samtools` for FASTA indexing/data helpers.
4. Optionally run dependency helper scripts in the Basset repo.

```bash
./install_dependencies.py
./install_data.py
```

## Required environment variables

Set Basset pathing so Lua/Python scripts are discoverable:

```bash
export BASSETDIR=/path/to/basset
export PATH=$BASSETDIR/src:$PATH
export PYTHONPATH=$BASSETDIR/src:$PYTHONPATH
export LUA_PATH="$BASSETDIR/src/?.lua;$LUA_PATH"
```

## Torch7 and package assumptions

Grounded Torch7 modules listed in `docs/requirements.md` include:

- `nn`, `optim`, `cutorch`, `cunn`, `lfs`
- `hdf5`, `dp`, `dpnn`, `inn`

Python packages listed include `numpy`, `matplotlib`, `seaborn`, `pandas`, `h5py`, `sklearn`, `pysam`.

Bioinformatics tools listed include `bedtools`, `samtools`, with optional `WebLogo` and MEME Suite `Tomtom`.

## Practical caveats

- Treat this stack as legacy and environment-sensitive.
- Confirm Torch7/CUDA compatibility before proposing GPU training commands.
- Keep command examples conservative and directly tied to documented script entry points.
