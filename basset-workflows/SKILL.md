---
name: basset-workflows
description: Use legacy Basset Torch7 workflows for DNA accessibility/activity modeling, including preprocessing from BED/activity tables, HDF5 dataset construction, model training/testing/prediction, motif analysis, saturated mutagenesis, and SNP Accessibility Difference (SAD) analysis from VCF files. Use when Codex needs to write, fix, explain, or review Basset commands/scripts such as `preprocess_features.py`, `seq_hdf5.py`, `basset_train.lua`, `basset_test.lua`, `basset_predict.lua`, `basset_motifs.py`, `basset_sat.py`, `basset_sat_vcf.py`, or `basset_sad.py`.
---

# Basset Workflows

## Overview

Use this skill for legacy Basset workflows in the Torch7 codebase. Keep setup assumptions explicit, and default to the smallest runnable command chain for the requested task.

## Follow This Decision Flow

1. Choose legacy Basset versus newer alternatives.
- Mention that the Basset README recommends Basenji for ongoing support.
- Use Basset when the user explicitly needs Basset scripts, existing `.th` models, or a legacy Torch7 pipeline.

2. Validate environment before writing long command sequences.
- Run a hard preflight check first and stop immediately if any item is missing:
  - `th` (Torch7 entry point)
  - `python2` (legacy Basset Python scripts are Python2-oriented)
  - `bedtools` and `samtools`
  - a usable `.th` model file for `basset_predict.lua` / `basset_test.lua`
- Require Torch7 and key Lua packages.
- Require Python dependencies plus `bedtools` and `samtools` for preprocessing/data prep.
- Require `BASSETDIR`, `PATH`, `PYTHONPATH`, and `LUA_PATH` exports for command discovery.

3. Choose preprocessing mode.
- Use `preprocess_features.py` to merge feature BED inputs into a unified BED/activity table.
- Use `basset_sample.py` when negative examples are needed from an existing compendium.
- Use `seq_hdf5.py` to build train/valid/test HDF5 tensors.

4. Choose learning mode.
- Use `basset_train.lua` for training (`-job`, `-save`, optional `-cuda`, `-restart`, `-seed`).
- Use `basset_test.lua` for test-set performance outputs.
- Use `basset_predict.lua` for activity prediction on prepared sequence data.

5. Choose interpretation or variant analysis mode.
- Use `basset_motifs.py` and `basset_motifs_infl.py` for first-layer motif/influence analysis.
- Use `basset_sat.py` for saturated mutagenesis on HDF5 or FASTA input.
- Use `basset_sad.py` for SNP Accessibility Difference from VCF.
- Use `basset_sat_vcf.py` to inspect allele-local mutagenesis around SNP loci.

6. Validate input schemas before execution.
- Confirm BED/table/HDF5 conventions expected by Basset.
- For prediction flows, confirm `test_in` exists in HDF5 if not using FASTA input.
- Confirm VCF plus genome FASTA availability for SNP workflows.

## Grounded Command Surface

Treat the following commands and patterns as grounded:

- `export BASSETDIR=/path/to/basset`
- `export PATH=$BASSETDIR/src:$PATH`
- `export PYTHONPATH=$BASSETDIR/src:$PYTHONPATH`
- `export LUA_PATH="$BASSETDIR/src/?.lua;$LUA_PATH"`
- `./install_dependencies.py`
- `./install_data.py`
- `basset_sample.py ...`
- `preprocess_features.py ...`
- `seq_hdf5.py ...`
- `basset_train.lua ...`
- `basset_test.lua ...`
- `basset_predict.lua ...`
- `basset_motifs.py ...`
- `basset_motifs_infl.py ...`
- `basset_sat.py ...`
- `basset_sat_vcf.py ...`
- `basset_sad.py ...`

Grounded tutorial examples include:

- `basset_train.lua -cuda -job pretrained_params.txt -stagnant_t 10 all_data_ever.h5`
- `preprocess_features.py -y -m 200 -s 600 ...`
- `seq_hdf5.py -c -v <N> -t <N> ...`
- `basset_test.lua <model_file> <data_file> test_out`
- `basset_sat.py -t 46 -n 200 -s 10 -o satmut <model_file> <seqs_file>`
- `basset_sad.py -l 600 -i -o sad -s -t <targets_file> <model_file> <vcf_file>`

Do not invent non-documented Basset wrappers, alternate training entry points, or unsupported modern PyTorch-only equivalents under this skill.

## Response Style

- State up front when a request assumes a legacy Torch7 environment.
- Recommend Basenji for new projects unless the user explicitly requests legacy Basset.
- Prefer short, runnable command chains over architecture summaries.
- Surface file-format assumptions before training or SNP analysis commands.
- When preflight fails, report exact missing dependencies and provide the smallest next-step install commands before proposing downstream Basset commands.

## References

- Read [references/setup-and-legacy-caveats.md](references/setup-and-legacy-caveats.md) for dependencies, environment variables, and legacy status.
- Read [references/preprocess-and-training.md](references/preprocess-and-training.md) for grounded preprocess and training command flows.
- Read [references/evaluation-and-interpretation.md](references/evaluation-and-interpretation.md) for test/predict/motif/saturation/SAD workflows.
- Read [references/file-formats.md](references/file-formats.md) for BED/table/HDF5/model schema expectations.
