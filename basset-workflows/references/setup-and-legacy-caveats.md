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

If your checkout places scripts at repository root (without `src/`), use:

```bash
export BASSETDIR=/path/to/basset
if [ -d "$BASSETDIR/src" ]; then
  export PATH=$BASSETDIR/src:$PATH
  export PYTHONPATH=$BASSETDIR/src:$PYTHONPATH
  export LUA_PATH="$BASSETDIR/src/?.lua;$LUA_PATH"
else
  export PATH=$BASSETDIR:$PATH
  export PYTHONPATH=$BASSETDIR:$PYTHONPATH
  export LUA_PATH="$BASSETDIR/?.lua;$LUA_PATH"
fi
```

## Torch7 and package assumptions

Grounded Torch7 modules listed in `docs/requirements.md` include:

- `nn`, `optim`, `cutorch`, `cunn`, `lfs`
- `hdf5`, `dp`, `dpnn`, `inn`

Python packages listed include `numpy`, `matplotlib`, `seaborn`, `pandas`, `h5py`, `sklearn`, `pysam`.

Bioinformatics tools listed include `bedtools`, `samtools`, with optional `WebLogo` and MEME Suite `Tomtom`.

## Real-execution preflight checks

Before proposing long command chains, verify these checks pass:

```bash
command -v th
command -v python2
command -v bedtools
command -v samtools
test -f /path/to/model.th
```

Also verify key script entry points exist under either `$BASSETDIR/src/` or `$BASSETDIR/`.

## Repository packaging caveat

- Some mirrors/checkouts ship Basset scripts but omit helper wrappers like `install_dependencies.py` / `install_data.py`.
- If those wrappers are missing, install dependencies manually (Torch7 modules + Python2 packages + `bedtools`/`samtools`) and proceed with direct script entry points.

## Python runtime caveat

- Core Basset Python scripts use legacy Python2 syntax.
- Treat `python2` as the default interpreter unless the specific script was ported and validated for Python3 in your environment.

## Failure routing matrix

| Symptom | Continue with Basset path | Optional fallback |
| --- | --- | --- |
| `th: command not found` | Install Torch7 and required Lua rocks, then re-run preflight. | Route new projects to Basenji. |
| Missing `.th` model file | Use an existing trained Basset model or train one with `basset_train.lua` first. | Switch to a supported modern model checkpoint for new analyses. |
| Network failures downloading legacy deps | Retry with explicit mirrors/proxies and pin conservative versions. | Use an already provisioned environment image or move to Basenji workflow. |

## Practical caveats

- Treat this stack as legacy and environment-sensitive.
- Confirm Torch7/CUDA compatibility before proposing GPU training commands.
- Keep command examples conservative and directly tied to documented script entry points.
